#!/bin/bash

# ============================================================================
# Chrome Theme Application Script for Hyprland Colorgen
# 
# This script applies the Material You theme colors to Google Chrome by
# modifying the Preferences file with the accent color from colors.conf
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"

# Possible Chrome config directories (system packages, Flatpak, dev versions)
CHROME_CONFIG_DIRS=(
    "$HOME/.config/google-chrome"
    "$HOME/.config/google-chrome-unstable"
    "$HOME/.config/chromium"
    "$HOME/.var/app/com.google.Chrome/config/google-chrome"
    "$HOME/.var/app/com.google.ChromeDev/config/google-chrome-unstable"
    "$HOME/.var/app/org.chromium.Chromium/config/chromium"
)

# Possible Chrome executables and Flatpak apps
CHROME_EXECUTABLES=(
    "google-chrome-stable"
    "google-chrome"
    "google-chrome-unstable"
    "chromium"
    "chromium-browser"
)

CHROME_FLATPAKS=(
    "com.google.Chrome"
    "com.google.ChromeDev"
    "org.chromium.Chromium"
)

# Process patterns for detecting running Chrome instances
CHROME_PROCESS_PATTERNS=(
    "chrome"
    "google-chrome"
    "google-chrome-stable"
    "google-chrome-unstable"
    "chromium"
    "chromium-browser"
    "com.google.Chrome"
    "com.google.ChromeDev"
    "org.chromium.Chromium"
)

# Add a trap to ensure proper exit
trap 'exit' INT TERM

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default theme variant (1 = Vibrant, 2 = Less vibrant)
COLOR_VARIANT=1
# Default theme scheme (0=auto, 1=light, 2=dark)
COLOR_SCHEME=0

# Parse command-line arguments
LAUNCH_ONLY=false
if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            --launch-only)
                LAUNCH_ONLY=true
                shift
                ;;
            --vibrant)
                COLOR_VARIANT=1
                shift
                ;;
            --less-vibrant)
                COLOR_VARIANT=2
                shift
                ;;
            --scheme)
                case "$2" in
                    auto) COLOR_SCHEME=0 ;;
                    light) COLOR_SCHEME=1 ;;
                    dark) COLOR_SCHEME=2 ;;
                    *)
                        echo "Invalid scheme value: $2. Use auto, light, or dark."
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --force-light)
                COLOR_SCHEME=1
                shift
                ;;
            --force-dark)
                COLOR_SCHEME=2
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "  --launch-only:      Just launch Chrome without updating theme"
                echo "  --vibrant:          Use vibrant theme variant (default)"
                echo "  --less-vibrant:     Use less vibrant theme variant"
                echo "  --scheme <scheme>:  Set color scheme (auto, light, dark). Default: auto"
                echo "  --force-light:      Force light theme"
                echo "  --force-dark:       Force dark theme"
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

# Auto-detect current theme if COLOR_SCHEME is set to auto (0)
if [ "$COLOR_SCHEME" -eq 0 ]; then
    log "INFO" "Auto-detecting current theme..."
    
    # Check if current_theme file exists
    if [ -f "$CACHE_DIR/current_theme" ]; then
        CURRENT_THEME=$(cat "$CACHE_DIR/current_theme")
        log "INFO" "Detected theme from cache: $CURRENT_THEME"
        
        if [ "$CURRENT_THEME" = "light" ]; then
            COLOR_SCHEME=1
            log "INFO" "Setting Chrome to light theme"
        else
            COLOR_SCHEME=2
            log "INFO" "Setting Chrome to dark theme"
        fi
    else
        # Fallback: check light_theme_mode file
        if [ -f "$CACHE_DIR/generated/gtk/light_theme_mode" ]; then
            LIGHT_MODE=$(cat "$CACHE_DIR/generated/gtk/light_theme_mode")
            if [ "$LIGHT_MODE" = "true" ]; then
                COLOR_SCHEME=1
                log "INFO" "Setting Chrome to light theme (from GTK cache)"
            else
                COLOR_SCHEME=2
                log "INFO" "Setting Chrome to dark theme (from GTK cache)"
            fi
        else
            # Default to dark if no theme info found
            COLOR_SCHEME=2
            log "INFO" "No theme info found, defaulting to dark theme"
        fi
    fi
fi

# Restart Chrome if it was running
restart_chrome() {
    if [ "${1:-false}" = "true" ]; then
        log "INFO" "Restarting Chrome (it was running before with visible windows)"
        
        # Check if we're running on Wayland
        is_wayland=false
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
            is_wayland=true
        elif [ -n "$WAYLAND_DISPLAY" ]; then
            is_wayland=true
        fi
        
        # Add Wayland flags if needed
        wayland_flags=""
        if [ "$is_wayland" = "true" ]; then
            wayland_flags="--ozone-platform=wayland --enable-features=WaylandWindowDecorations"
            log "INFO" "Adding Wayland flags for Chrome restart"
        fi
        
        # Try system executables first
        for exec_name in "${CHROME_EXECUTABLES[@]}"; do
            if command -v "$exec_name" &> /dev/null; then
                log "INFO" "Launching Chrome using executable: $exec_name"
                
                # Launch Chrome in a completely separate process
                if [ -n "$wayland_flags" ]; then
                    ($exec_name $wayland_flags > /dev/null 2>&1 &)
                else
                    ($exec_name > /dev/null 2>&1 &)
                fi
                
                # Completely detach the process if there's a job to disown
                jobs %% > /dev/null 2>&1 && disown || true
                
                log "INFO" "Chrome launch initiated. Exiting script."
                return 0
            fi
        done
        
        # Try Flatpak apps if system executables not found
        if command -v flatpak &> /dev/null; then
            for flatpak_id in "${CHROME_FLATPAKS[@]}"; do
                if flatpak list --app | grep -q "$flatpak_id"; then
                    log "INFO" "Launching Chrome using Flatpak: $flatpak_id"
                    
                    # Launch Flatpak Chrome in a completely separate process
                    if [ -n "$wayland_flags" ]; then
                        (flatpak run "$flatpak_id" $wayland_flags > /dev/null 2>&1 &)
                    else
                        (flatpak run "$flatpak_id" > /dev/null 2>&1 &)
                    fi
                    
                    # Completely detach the process if there's a job to disown
                    jobs %% > /dev/null 2>&1 && disown || true
                    
                    log "INFO" "Chrome launch initiated. Exiting script."
                    return 0
                fi
            done
        fi
        
        log "WARN" "Could not find Chrome executable to restart"
    else
        log "INFO" "Chrome was not running with visible windows before, not restarting"
        return 0
    fi
}

log "INFO" "Applying theme colors to Google Chrome"
log "INFO" "Using color variant: $COLOR_VARIANT ($([ "$COLOR_VARIANT" -eq 1 ] && echo "Vibrant" || echo "Less vibrant"))"
log "INFO" "Using color scheme: $COLOR_SCHEME"

# If launch-only mode is active, just launch Chrome and exit
if [ "$LAUNCH_ONLY" = true ]; then
    log "INFO" "Running in launch-only mode, starting Chrome without theme update"
    restart_chrome true
    exit 0
fi

# Find Chrome profiles directories - handles system packages, Flatpak, and dev versions
find_chrome_profiles() {
    local chrome_dirs=()
    
    # Check all possible Chrome config directories
    for config_dir in "${CHROME_CONFIG_DIRS[@]}"; do
        if [ -d "$config_dir" ]; then
            for profile in "$config_dir/"*; do
                if [ -f "$profile/Preferences" ]; then
                    chrome_dirs+=("$profile")
                fi
            done
        fi
    done
    
    echo "${chrome_dirs[@]}"
}

# Close Chrome before modifying preferences
close_chrome() {
    # Get our script's PID to exclude it
    SCRIPT_PID=$$
    
    # List of possible Chrome process patterns to look for
    # Use global CHROME_PROCESS_PATTERNS array
    
    # Flag to track if any Chrome processes were found
    chrome_running=false
    
    # Check if any Chrome processes are running (excluding our script)
    for pattern in "${CHROME_PROCESS_PATTERNS[@]}"; do
        if pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh" > /dev/null; then
            chrome_running=true
            break
        fi
    done
    
    if [ "$chrome_running" = "true" ]; then
        log "INFO" "Closing Chrome/Chromium processes (excluding this script)"
        
        # Kill Chrome processes for each pattern (excluding our script)
        for pattern in "${CHROME_PROCESS_PATTERNS[@]}"; do
            for pid in $(pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh"); do
                log "DEBUG" "Killing Chrome process: $pid (pattern: $pattern)"
                kill "$pid" 2>/dev/null || true
            done
        done
        
        sleep 1
        
        # Check if any Chrome processes are still running
        chrome_still_running=false
        for pattern in "${CHROME_PROCESS_PATTERNS[@]}"; do
            if pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh" > /dev/null; then
                chrome_still_running=true
                break
            fi
        done
        
        # If Chrome is still running, try SIGKILL
        if [ "$chrome_still_running" = "true" ]; then
            log "WARN" "Chrome still running, using SIGKILL"
            
            for pattern in "${CHROME_PROCESS_PATTERNS[@]}"; do
                for pid in $(pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh"); do
                    log "DEBUG" "Force killing Chrome process: $pid (pattern: $pattern)"
                    kill -9 "$pid" 2>/dev/null || true
                done
            done
            
            sleep 1
        fi
    else
        log "INFO" "Chrome is not running"
    fi
}

# Update Chrome preferences with theme color
update_chrome_theme() {
    local profile_dir=$1
    local color_value=$2
    local scheme=$3
    local is_grayscale=$4
    local preferences_file="$profile_dir/Preferences"
    
    # Check if Preferences file exists
    if [ ! -f "$preferences_file" ]; then
        log "ERROR" "Preferences file not found: $preferences_file"
        return 1
    fi
    
    # Create a backup of the Preferences file
    cp "$preferences_file" "$preferences_file.backup"
    
    # Use jq for proper JSON manipulation. It is required.
    if ! command -v jq &> /dev/null; then
        log "ERROR" "jq is not installed. This script requires jq to modify Chrome preferences."
        return 1
    fi

    log "INFO" "Using jq for JSON manipulation in $profile_dir"
    
    # Create a temporary file for the modified preferences
    local temp_file=$(mktemp)
    
    local success=false

    if [ "$is_grayscale" = true ]; then
        if jq --argjson scheme "$scheme" \
              '.browser.theme = {"color_scheme2": $scheme, "is_grayscale2": true} | del(.browser.theme.user_color2) | del(.browser.theme.color_variant2)' \
              "$preferences_file" > "$temp_file"; then
            success=true
        fi
    else
        if jq --argjson color "$color_value" \
              --argjson variant "$COLOR_VARIANT" \
              --argjson scheme "$scheme" \
              '.browser.theme = {"color_scheme2": $scheme, "color_variant2": $variant, "user_color2": $color} | del(.browser.theme.is_grayscale2)' \
              "$preferences_file" > "$temp_file"; then
            success=true
        fi
    fi

    if [ "$success" = true ]; then
        # Replace the original file with the modified one
        mv "$temp_file" "$preferences_file"
        log "INFO" "Successfully updated theme in $profile_dir using jq"
        return 0
    else
        log "ERROR" "jq failed to modify JSON. The original file is preserved."
        rm -f "$temp_file"
        return 1
    fi
}

# Extract accent color from colors.conf
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    # Get accent color using color_utils
    accent=$(get_color "accent")
    
    if [ -z "$accent" ]; then
        # Fall back to primary if accent is not defined
        accent=$(get_color "primary")
    fi
    
    if [ -z "$accent" ]; then
        log "ERROR" "Could not find accent or primary color in colors.conf"
        exit 1
    fi
    
    # Check if the color is grayscale or very desaturated using color_utils
    IS_GRAYSCALE=false
    if is_grayscale "$accent"; then
        IS_GRAYSCALE=true
        log "INFO" "Detected grayscale/desaturated color - using grayscale theme"
    fi
    
    # Convert hex color to Chrome's format (not used for grayscale)
    chrome_color=$(hex_to_chrome_color "$accent")
    if [ "$IS_GRAYSCALE" = true ]; then
        log "INFO" "Using grayscale theme (ignoring color: $accent)"
    else
        log "INFO" "Using accent color: $accent (Chrome value: $chrome_color)"
    fi
    
    # Find all Chrome/Chromium profiles
    chrome_profiles=($(find_chrome_profiles))
    
    if [ ${#chrome_profiles[@]} -eq 0 ]; then
        log "WARN" "No Chrome/Chromium profiles found"
        exit 0
    fi
    
    # Check if Chrome is running (excluding our script)
    chrome_was_running=false
    chrome_was_visible=false

    # List of possible Chrome process patterns to look for
    # Use global CHROME_PROCESS_PATTERNS array

    # Check if we're running on Wayland
    is_wayland=false
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        is_wayland=true
        log "INFO" "Detected Wayland session"
    elif [ -n "$WAYLAND_DISPLAY" ]; then
        is_wayland=true
        log "INFO" "Detected Wayland display"
    fi

    # Check each pattern while excluding our script
    for pattern in "${CHROME_PROCESS_PATTERNS[@]}"; do
        if pgrep -f "$pattern" | grep -v "$$" | grep -v "chrome.sh" > /dev/null; then
            chrome_was_running=true
            log "INFO" "Detected Chrome was running before modifications (pattern: $pattern)"
            
            # Check if Chrome has visible windows
            if [ "$is_wayland" = "true" ] && command -v swaymsg &> /dev/null; then
                # Use swaymsg to check for Chrome windows in Sway/Wayland
                if swaymsg -t get_tree | grep -E '"(app_id|class)":\s?".*(chrome|chromium).*"' > /dev/null; then
                    chrome_was_visible=true
                    log "INFO" "Chrome has visible windows in Wayland - will restart after modifications"
                else
                    log "INFO" "Chrome is running in background in Wayland (no visible windows) - will not restart"
                fi
            elif [ "$is_wayland" = "true" ] && command -v hyprctl &> /dev/null; then
                # Use hyprctl to check for Chrome windows in Hyprland
                if hyprctl clients | grep -i "class: .*chrome\|chromium" > /dev/null; then
                    chrome_was_visible=true
                    log "INFO" "Chrome has visible windows in Hyprland - will restart after modifications"
                else
                    log "INFO" "Chrome is running in background in Hyprland (no visible windows) - will not restart"
                fi
            elif command -v xdotool &> /dev/null; then
                # Use xdotool to check for visible Chrome windows in X11
                if xdotool search --onlyvisible --class "Google-chrome" > /dev/null 2>&1 || \
                   xdotool search --onlyvisible --class "Chromium" > /dev/null 2>&1 || \
                   xdotool search --onlyvisible --class "google-chrome" > /dev/null 2>&1; then
                    chrome_was_visible=true
                    log "INFO" "Chrome has visible windows in X11 - will restart after modifications"
                else
                    log "INFO" "Chrome is running in background in X11 (no visible windows) - will not restart"
                fi
            elif command -v wmctrl &> /dev/null; then
                # Alternative check using wmctrl for X11
                if wmctrl -l | grep -i "chrome\|chromium" > /dev/null; then
                    chrome_was_visible=true
                    log "INFO" "Chrome has visible windows (wmctrl) - will restart after modifications"
                else
                    log "INFO" "Chrome is running in background (wmctrl shows no visible windows) - will not restart"
                fi
            else
                # If we can't check for windows, let's look at the process list for hints
                # If we find --type=renderer processes, Chrome likely has open windows
                if ps aux | grep "$pattern" | grep -v grep | grep -v "chrome.sh" | grep -- "--type=renderer" > /dev/null; then
                    chrome_was_visible=true
                    log "WARN" "Assuming Chrome has visible windows based on renderer processes - will restart"
                else
                    log "WARN" "Cannot determine if Chrome has visible windows - assuming background only"
                fi
            fi
            
            break
        fi
    done

    if [ "$chrome_was_running" = "false" ]; then
        log "INFO" "Chrome was not running before modifications"
    fi
    
    # Close Chrome
    close_chrome
    
    # Update each profile
    success=true
    for profile in "${chrome_profiles[@]}"; do
        log "INFO" "Processing profile: $profile"
        if ! update_chrome_theme "$profile" "$chrome_color" "$COLOR_SCHEME" "$IS_GRAYSCALE"; then
            success=false
            log "ERROR" "Failed to update theme for profile: $profile"
        fi
    done
    
    # Restart Chrome if it was running with visible windows
    restart_chrome "$chrome_was_visible"
    
    # Make sure we exit after attempting to restart Chrome
    log "INFO" "Chrome theme application completed"
    if [ "$success" = true ]; then
        log "INFO" "Chrome theme updated successfully"
        exit 0
    else
        log "WARN" "Some profiles failed to update"
        exit 1
    fi
else
    log "ERROR" "colors.conf not found: $COLORGEN_DIR/colors.conf"
    exit 1
fi
