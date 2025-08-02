#!/bin/bash

# Define the directory where all scripts are located
CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
CONFIGS_DIR="$COLORGEN_DIR/configs"
CACHE_DIR="$CONFIG_DIR/cache"

# Define lock file
LOCK_FILE="/tmp/colorgen_apply_colors.lock"

# Check if the script is already running
if [ -f "$LOCK_FILE" ]; then
    # Check if the process is still running
    if ps -p $(cat "$LOCK_FILE") > /dev/null 2>&1; then
        echo "Another instance of apply_colors.sh is already running. Exiting."
        exit 1
    else
        # Lock file exists but process is not running, remove stale lock
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file with current PID
echo $$ > "$LOCK_FILE"

# Ensure lock file is removed on exit
trap 'rm -f "$LOCK_FILE"' EXIT

# Parse command-line arguments
THEME_ARG=""
WALLPAPER_ARG=""
DEBUG_ARG=""
if [ $# -gt 0 ]; then
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --light|--dark|--force-light|--force-dark)
                THEME_ARG="$1"
                echo "Theme mode: $THEME_ARG"
                shift
                ;;
            --wallpaper)
                if [ -n "$2" ] && [ -f "$2" ]; then
                    WALLPAPER_ARG="--wallpaper $2"
                    echo "Using custom wallpaper: $2"
                    shift 2
                else
                    echo "Error: --wallpaper option requires a valid file path"
                    exit 1
                fi
                ;;
            --debug)
                DEBUG_ARG="--debug"
                echo "Debug mode enabled"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--light|--dark|--force-light|--force-dark] [--wallpaper FILE] [--debug]"
                echo "  --light: Use light theme if no user selection is made"
                echo "  --dark: Use dark theme if no user selection is made"
                echo "  --force-light: Force light theme (bypass theme selector)"
                echo "  --force-dark: Force dark theme (bypass theme selector)"
                echo "  --wallpaper FILE: Use specified wallpaper for theme detection"
                echo "  --debug: Show detailed wallpaper analysis information"
                echo "  (no args): Show theme selector dialog or use saved preference"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
fi

# Define a function to execute scripts
execute_script() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    local extra_args=$2  # Optional additional arguments
    local background=${3:-true}  # Run in background by default
    
    echo "Executing $script_name..."
    
    if [ -f "$script_path" ]; then
        # Always make the script executable to be sure
        chmod +x "$script_path"
        
        # Execute the script with full path and any extra arguments
        if [ -n "$extra_args" ]; then
            if [ "$background" = true ]; then
                cd "$(dirname "$script_path")" && /bin/bash "$(basename "$script_path")" "$extra_args" &
            else
                cd "$(dirname "$script_path")" && /bin/bash "$(basename "$script_path")" "$extra_args"
            fi
        else
            if [ "$background" = true ]; then
                cd "$(dirname "$script_path")" && /bin/bash "$(basename "$script_path")" &
            else
                cd "$(dirname "$script_path")" && /bin/bash "$(basename "$script_path")"
            fi
        fi
        execution_result=$?
        
        # Check if execution was successful
        if [ $execution_result -eq 0 ]; then
            echo "✅ $script_name executed successfully"
        else
            echo "❌ $script_name failed with exit code $execution_result"
        fi
    else
        echo "❌ ERROR: $script_name not found at $script_path"
    fi
}

# Create a function to determine script execution order
get_script_priority() {
    local script_name=$(basename "$1")
    
    case "$script_name" in
        dark_light_switch.sh) echo "10" ;;  # Run first
        hyprland.sh) echo "20" ;;          # Run early but after theme selection
        hyprlock.sh) echo "30" ;;          # Run after hyprland
        chrome.sh) echo "40" ;;            # Run after core components
        icon-theme.sh) echo "50" ;;        # Run after core components
        gtk-clock.sh) echo "55" ;;         # Run after core components but before glava
        glava.sh) echo "60" ;;             # Run last
        *) echo "100" ;;                   # Default priority for other scripts
    esac
}

# Function to find and execute scripts in order of priority
find_and_execute_scripts() {
    local dir=$1
    local pattern=$2
    local extra_args=$3
    local foreground=${4:-false}  # Whether to run in foreground
    
    # Find all matching scripts and sort by priority
    while IFS= read -r script; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            # Skip theme-specific scripts that are handled by dark_light_switch.sh
            script_name=$(basename "$script")
            script_dir=$(dirname "$script")
            base_dir=$(basename "$script_dir")
            
            # Skip scripts in dark/ or light/ directories as they're handled by dark_light_switch.sh
            if [[ "$base_dir" == "dark" || "$base_dir" == "light" ]]; then
                continue
            fi
            
            # Skip icon-theme.sh as it's already handled by dark_light_switch.sh
            if [[ "$script_name" == "icon-theme.sh" ]]; then
                echo "Skipping $script_name as it's already handled by dark_light_switch.sh"
                continue
            fi
            
            # Skip gtk-clock.sh as it's already handled by material_extract.sh
            if [[ "$script_name" == "gtk-clock.sh" ]]; then
                echo "Skipping $script_name as it's already handled by material_extract.sh"
                continue
            fi
            
            priority=$(get_script_priority "$script")
            echo "$priority:$script"
        fi
    done < <(find "$dir" -name "$pattern" -type f) | sort -n | while IFS=: read -r _ script; do
        if [ -n "$script" ]; then  # Only execute if script path is not empty
            if [ "$foreground" = true ]; then
                execute_script "$script" "$extra_args" false  # Run in foreground
            else
                execute_script "$script" "$extra_args" true   # Run in background
            fi
        fi
    done
}

echo "Starting Material You theme application..."

# First, run dark_light_switch.sh to handle theme selection
# This needs to run in the foreground as other scripts depend on its results
DARK_LIGHT_SWITCH="$COLORGEN_DIR/dark_light_switch.sh"
if [ -f "$DARK_LIGHT_SWITCH" ]; then
    echo "Determining and applying theme..."
    chmod +x "$DARK_LIGHT_SWITCH"
    
    # Build the command with all arguments
    SWITCH_CMD="$DARK_LIGHT_SWITCH"
    if [ -n "$THEME_ARG" ]; then
        # If we have a theme argument, use it directly with the force flag to bypass selector
        if [[ "$THEME_ARG" == "--light" ]]; then
            SWITCH_CMD="$SWITCH_CMD --force-light"
            echo "Forcing light theme (bypassing selector)"
        elif [[ "$THEME_ARG" == "--dark" ]]; then
            SWITCH_CMD="$SWITCH_CMD --force-dark"
            echo "Forcing dark theme (bypassing selector)"
        elif [[ "$THEME_ARG" == "--force-light" || "$THEME_ARG" == "--force-dark" ]]; then
            SWITCH_CMD="$SWITCH_CMD $THEME_ARG"
            echo "Using forced theme: $THEME_ARG"
        else
            SWITCH_CMD="$SWITCH_CMD $THEME_ARG"
        fi
    fi
    if [ -n "$WALLPAPER_ARG" ]; then
        SWITCH_CMD="$SWITCH_CMD $WALLPAPER_ARG"
    fi
    if [ -n "$DEBUG_ARG" ]; then
        SWITCH_CMD="$SWITCH_CMD $DEBUG_ARG"
    fi
    
    # Execute the command
    $SWITCH_CMD
    switch_exit=$?
    
    # Exit code 0 means continue with default theme or theme was applied
    # Any other exit code is an error
    if [ $switch_exit -eq 0 ]; then
        echo "✅ Theme selection successful, continuing with remaining components"
    else
        echo "❌ ERROR: Theme selection failed with exit code $switch_exit"
        exit 1
    fi
else
    echo "❌ ERROR: dark_light_switch.sh script not found"
    exit 1
fi

echo "Theme components (GTK, Kitty, Rofi, QT, KDE, SwayNC, Waybar, Foot) are handled by dark_light_switch.sh"

# Launch/update GTK clock after theme selection
echo "Launching/updating GTK clock after theme selection..."
if [ -f "$CONFIGS_DIR/gtk-clock.sh" ]; then
    bash "$CONFIGS_DIR/gtk-clock.sh"
    sleep 1  # Give clock time to start/update
else
    echo "GTK clock script not found at $CONFIGS_DIR/gtk-clock.sh"
fi

# Now run all remaining scripts in the configs directory in parallel
# These are the ones not handled by dark/light theme switching
echo "Applying remaining theme components in parallel..."

# Find and execute all remaining scripts in the configs directory
find_and_execute_scripts "$CONFIGS_DIR" "*.sh" "$THEME_ARG"

# Wait for all background processes to finish
echo "Waiting for all theme components to complete..."
wait

echo "✅ All theme components have been applied successfully!"
