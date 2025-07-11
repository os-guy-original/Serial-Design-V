#!/bin/bash

# ============================================================================
# Dark/Light Mode Switch Script for Hyprland Colorgen
# 
# This script switches between dark and light themes, applying changes to
# various components like GTK, QT, Kitty, etc.
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
TEMP_DIR="$CACHE_DIR/temp"
THEME_TO_APPLY_FILE="$TEMP_DIR/theme-to-apply"
THEME_SELECTOR_PYTHON="$COLORGEN_DIR/theme-selectors/theme_selector_python.sh"

# Debug mode (set to true for more verbose output)
DEBUG_MODE=${DEBUG_MODE:-false}

# Default values
FORCE_THEME=""
BYPASS_SELECTOR=false

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$level" = "DEBUG" ] && [ "$DEBUG_MODE" != true ]; then
        # Skip debug messages unless debug mode is enabled
        return
    fi
    
    echo -e "[${timestamp}] [dark_light_switch.sh] [${level}] ${message}"
}

# Check for dependencies
check_dependency() {
    local cmd=$1
    local pkg=$2
    
    if ! command -v "$cmd" &> /dev/null; then
        log "WARN" "$cmd not found. Consider installing $pkg"
        return 1
    fi
    
    return 0
}

# Check for essential dependencies
check_dependency "python3" "python"
check_dependency "notify-send" "libnotify"

# Process command line arguments
if [ $# -gt 0 ]; then
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --light)
                FORCE_THEME="light"
                shift
                ;;
            --dark)
                FORCE_THEME="dark"
                shift
                ;;
            --force-light)
                FORCE_THEME="light"
                BYPASS_SELECTOR=true
                log "INFO" "Forcing light theme (bypassing selector)"
                shift
                ;;
            --force-dark)
                FORCE_THEME="dark"
                BYPASS_SELECTOR=true
                log "INFO" "Forcing dark theme (bypassing selector)"
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                log "INFO" "Debug mode enabled"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--light|--dark|--force-light|--force-dark|--debug]"
                echo "  --light: Use light theme if no user selection is made"
                echo "  --dark: Use dark theme if no user selection is made"
                echo "  --force-light: Force light theme (bypass theme selector)"
                echo "  --force-dark: Force dark theme (bypass theme selector)"
                echo "  --debug: Show detailed debug information"
                echo "  (no args): Show theme selector"
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

log "INFO" "Starting dark/light mode switch process"

# Determine the theme to use
if [ -n "$FORCE_THEME" ] && [ "$BYPASS_SELECTOR" = true ]; then
    # If force option is specified, bypass the selector
    log "INFO" "Forcing $FORCE_THEME theme (bypassing selector)"
    THEME="$FORCE_THEME"
# Check if theme-to-apply file exists
elif [ -f "$THEME_TO_APPLY_FILE" ]; then
    # Read theme from theme-to-apply file
    THEME=$(cat "$THEME_TO_APPLY_FILE")
    log "INFO" "Using theme from theme-to-apply file: $THEME"
    
    # Remove the theme-to-apply file after reading it
    rm -f "$THEME_TO_APPLY_FILE"
    log "DEBUG" "Removed theme-to-apply file"
else
    # Try to use the theme selector shell script
    if [ -f "$THEME_SELECTOR_PYTHON" ]; then
        log "INFO" "Running theme selector script"
        log "DEBUG" "Theme selector path: $THEME_SELECTOR_PYTHON"
        chmod +x "$THEME_SELECTOR_PYTHON"
        
        # Check if the script exists and is executable
        if [ ! -f "$THEME_SELECTOR_PYTHON" ]; then
            log "ERROR" "Theme selector script not found: $THEME_SELECTOR_PYTHON"
            log "ERROR" "Please make sure the theme selector script exists"
            # Default to dark theme if no script is found
            THEME="dark"
            log "INFO" "Defaulting to dark theme"
        elif [ ! -x "$THEME_SELECTOR_PYTHON" ]; then
            log "ERROR" "Theme selector script is not executable: $THEME_SELECTOR_PYTHON"
            log "ERROR" "Please make the script executable with: chmod +x $THEME_SELECTOR_PYTHON"
            # Default to dark theme if script is not executable
            THEME="dark"
            log "INFO" "Defaulting to dark theme"
        else
            log "DEBUG" "Theme selector script exists and is executable"
            
            # Run the theme selector script and capture its output
            SELECTED_THEME=$("$THEME_SELECTOR_PYTHON" 2>/dev/null)
            selector_exit=$?
            log "DEBUG" "Theme selector exit code: $selector_exit"
            
            # If the selector returned 0, it means it has provided a theme
            if [ $selector_exit -eq 0 ] && [ -n "$SELECTED_THEME" ]; then
                # Extract just the last line which should be the theme name
                THEME=$(echo "$SELECTED_THEME" | tail -n 1)
                log "INFO" "User selected theme: $THEME"
            else
                # If we get here, the selector returned non-zero or no output, which means
                # the user cancelled or there was an error
                log "INFO" "No theme selected from selector"
                
                # Use default or forced theme
                if [ -n "$FORCE_THEME" ]; then
                    THEME="$FORCE_THEME"
                    log "INFO" "Using $FORCE_THEME theme as default"
                else
                    # Default to dark if no force theme is specified
                    THEME="dark"
                    log "INFO" "No theme selected, defaulting to dark theme"
                fi
            fi
        fi
    else
        # If no theme selector is available, default to dark theme
        log "ERROR" "No theme selector available"
        log "INFO" "Please install Python 3 and PyGObject: sudo pacman -S python python-gobject gtk3"
        log "INFO" "Defaulting to dark theme"
        THEME="dark"
    fi
fi

# Save the current theme selection to cache
mkdir -p "$CACHE_DIR"

# Check if the theme has changed recently (within the last 5 seconds)
LAST_SWITCH_FILE="$CACHE_DIR/last_theme_switch"
LAST_THEME_FILE="$CACHE_DIR/last_applied_theme"
CURRENT_TIME=$(date +%s)
DEBOUNCE_SECONDS=5

# Check if we need to debounce
if [ -f "$LAST_SWITCH_FILE" ] && [ -f "$LAST_THEME_FILE" ]; then
    LAST_SWITCH_TIME=$(cat "$LAST_SWITCH_FILE")
    LAST_APPLIED_THEME=$(cat "$LAST_THEME_FILE")
    TIME_DIFF=$((CURRENT_TIME - LAST_SWITCH_TIME))
    
    if [ "$TIME_DIFF" -lt "$DEBOUNCE_SECONDS" ]; then
        log "INFO" "Theme was switched ${TIME_DIFF}s ago, debouncing for ${DEBOUNCE_SECONDS}s"
        
        # If we're trying to apply the same theme as last time, exit early
        if [ "$LAST_APPLIED_THEME" = "$THEME" ]; then
            log "INFO" "Theme is already set to $THEME, no change needed"
            exit 0
        fi
        
        # If we're trying to apply a different theme within the debounce period,
        # and we're not using a force option, exit early
        if [ "$BYPASS_SELECTOR" != "true" ]; then
            log "INFO" "Debouncing theme switch from $LAST_APPLIED_THEME to $THEME"
            exit 0
        else
            log "INFO" "Force option used, bypassing debounce"
        fi
    fi
fi

# Update the last switch time and theme
echo "$CURRENT_TIME" > "$LAST_SWITCH_FILE"
echo "$THEME" > "$LAST_THEME_FILE"

# Save the current theme
echo "$THEME" > "$CACHE_DIR/current_theme"
log "INFO" "Set theme mode to: $THEME"

# Apply the theme
log "INFO" "Applying $THEME theme in parallel"

# Apply all theme scripts in parallel
for script in gtk.sh kitty.sh rofi.sh qt.sh kde.sh swaync.sh waybar.sh foot.sh glava.sh vscode.sh wine.sh; do
    script_path="$COLORGEN_DIR/configs/$THEME/$script"
    if [ -f "$script_path" ]; then
        log "INFO" "Running $script_path in background"
        bash "$script_path" &
        if [ "$DEBUG_MODE" = true ]; then
            log "DEBUG" "Started $script_path with PID $!"
        fi
    else
        log "WARN" "Script not found: $script_path"
    fi
done

# Wait for all background processes to finish
log "INFO" "Waiting for all theme components to complete..."
wait
log "INFO" "All theme components completed execution"

# Apply icon theme after theme components are complete
if [ -f "$COLORGEN_DIR/configs/icon-theme.sh" ]; then
    log "INFO" "Applying icon theme based on current theme mode"
    bash "$COLORGEN_DIR/configs/icon-theme.sh"
else
    log "WARN" "Icon theme script not found: $COLORGEN_DIR/configs/icon-theme.sh"
fi

# Notify user of theme change
if command -v notify-send &> /dev/null; then
    if [ "$THEME" = "light" ]; then
        notify-send "Theme Switched" "Light theme has been applied" -i "weather-clear"
        log "INFO" "Sent notification for light theme"
    else
        notify-send "Theme Switched" "Dark theme has been applied" -i "weather-clear-night"
        log "INFO" "Sent notification for dark theme"
    fi
else
    log "WARN" "notify-send not found, skipping notification"
fi

log "INFO" "Theme switching completed successfully with theme: $THEME"
exit 0 