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

# Add a trap to ensure proper exit
trap 'exit' INT TERM

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Parse command-line arguments
LAUNCH_ONLY=false
if [ $# -gt 0 ]; then
    case "$1" in
        --launch-only)
            LAUNCH_ONLY=true
            ;;
        --help|-h)
            echo "Usage: $0 [--launch-only]"
            echo "  --launch-only: Just launch Chrome without updating theme"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying theme colors to Google Chrome"

# If launch-only mode is active, just launch Chrome and exit
if [ "$LAUNCH_ONLY" = true ]; then
    log "INFO" "Running in launch-only mode, starting Chrome without theme update"
    restart_chrome true
    exit 0
fi

# Find Chrome profiles directories - handles both Chrome and Chromium
find_chrome_profiles() {
    local chrome_dirs=()
    
    # Check for Google Chrome
    if [ -d "$HOME/.config/google-chrome" ]; then
        for profile in "$HOME/.config/google-chrome/"*; do
            if [ -f "$profile/Preferences" ]; then
                chrome_dirs+=("$profile")
            fi
        done
    fi
    
    # Check for Chromium
    if [ -d "$HOME/.config/chromium" ]; then
        for profile in "$HOME/.config/chromium/"*; do
            if [ -f "$profile/Preferences" ]; then
                chrome_dirs+=("$profile")
            fi
        done
    fi
    
    echo "${chrome_dirs[@]}"
}

# Convert hex color to signed 32-bit integer (ARGB format)
hex_to_chrome_color() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Ensure we have a full 6-digit hex color
    if [ ${#hex} -eq 3 ]; then
        # Convert 3-digit hex to 6-digit
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    
    # Add alpha channel (FF) for full opacity
    hex="FF$hex"
    
    # Convert hex to decimal
    local decimal=$(printf "%d" 0x$hex)
    
    # Calculate signed 32-bit integer value (Chrome's format)
    # This is necessary because Chrome stores colors as signed 32-bit integers
    if [ $decimal -gt 2147483647 ]; then
        decimal=$((decimal - 4294967296))
    fi
    
    echo $decimal
}

# Close Chrome before modifying preferences
close_chrome() {
    # Get our script's PID to exclude it
    SCRIPT_PID=$$
    
    # List of possible Chrome process patterns to look for
    chrome_patterns=("chrome" "google-chrome" "chromium" "google-chrome-stable" "chromium-browser")
    
    # Flag to track if any Chrome processes were found
    chrome_running=false
    
    # Check if any Chrome processes are running (excluding our script)
    for pattern in "${chrome_patterns[@]}"; do
        if pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh" > /dev/null; then
            chrome_running=true
            break
        fi
    done
    
    if [ "$chrome_running" = "true" ]; then
        log "INFO" "Closing Chrome/Chromium processes (excluding this script)"
        
        # Kill Chrome processes for each pattern (excluding our script)
        for pattern in "${chrome_patterns[@]}"; do
            for pid in $(pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh"); do
                log "DEBUG" "Killing Chrome process: $pid (pattern: $pattern)"
                kill "$pid" 2>/dev/null || true
            done
        done
        
        sleep 1
        
        # Check if any Chrome processes are still running
        chrome_still_running=false
        for pattern in "${chrome_patterns[@]}"; do
            if pgrep -f "$pattern" | grep -v "$SCRIPT_PID" | grep -v "chrome.sh" > /dev/null; then
                chrome_still_running=true
                break
            fi
        done
        
        # If Chrome is still running, try SIGKILL
        if [ "$chrome_still_running" = "true" ]; then
            log "WARN" "Chrome still running, using SIGKILL"
            
            for pattern in "${chrome_patterns[@]}"; do
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
    local preferences_file="$profile_dir/Preferences"
    
    # Check if Preferences file exists
    if [ ! -f "$preferences_file" ]; then
        log "ERROR" "Preferences file not found: $preferences_file"
        return 1
    fi
    
    # Create a backup of the Preferences file
    cp "$preferences_file" "$preferences_file.backup"
    
    # Check if the theme section already exists
    if grep -q '"theme":{' "$preferences_file"; then
        log "INFO" "Updating existing theme section in $profile_dir"
        # Use sed to replace the color values in the theme section
        # This is a bit complex because we need to handle JSON properly
        sed -i -E 's/("theme":\{)"color_variant2":[0-9]+,"user_color2":[-0-9]+/\1"color_variant2":1,"user_color2":'"$color_value"'/g' "$preferences_file"
    else
        log "INFO" "Adding new theme section in $profile_dir"
        # Add the theme section to the browser object
        sed -i -E 's/("browser":\{)/\1"theme":{"color_variant2":1,"user_color2":'"$color_value"'},/g' "$preferences_file"
    fi
    
    # Verify that the file is still valid JSON
    if command -v jq &> /dev/null; then
        if ! jq '.' "$preferences_file" > /dev/null 2>&1; then
            log "ERROR" "Invalid JSON after modification, restoring backup"
            cp "$preferences_file.backup" "$preferences_file"
            return 1
        fi
    else
        log "WARN" "jq not installed, skipping JSON validation"
    fi
    
    log "INFO" "Successfully updated theme in $profile_dir"
    return 0
}

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
        
        # List of Chrome executables to try in order of preference
        chrome_executables=(
            "google-chrome-stable"
            "google-chrome"
            "chromium"
            "chromium-browser"
        )
        
        # Try each executable until one works
        for exec_name in "${chrome_executables[@]}"; do
            if command -v "$exec_name" &> /dev/null; then
                log "INFO" "Launching Chrome using executable: $exec_name"
                
                # Launch Chrome in a completely separate process
                if [ -n "$wayland_flags" ]; then
                    ($exec_name $wayland_flags > /dev/null 2>&1 &)
                else
                    ($exec_name > /dev/null 2>&1 &)
                fi
                
                # Completely detach the process
                disown
                
                log "INFO" "Chrome launch initiated. Exiting script."
                return 0
            fi
        done
        
        log "WARN" "Could not find Chrome executable to restart"
    else
        log "INFO" "Chrome was not running with visible windows before, not restarting"
        return 0
    fi
}

# Extract accent color from colors.conf
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    # Get accent color
    accent=$(grep -E "^accent = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    
    if [ -z "$accent" ]; then
        # Fall back to primary if accent is not defined
        accent=$(grep -E "^primary = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    fi
    
    if [ -z "$accent" ]; then
        log "ERROR" "Could not find accent or primary color in colors.conf"
        exit 1
    fi
    
    # Convert hex color to Chrome's format
    chrome_color=$(hex_to_chrome_color "$accent")
    log "INFO" "Using accent color: $accent (Chrome value: $chrome_color)"
    
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
    chrome_patterns=("chrome" "google-chrome" "chromium" "google-chrome-stable" "chromium-browser")

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
    for pattern in "${chrome_patterns[@]}"; do
        if pgrep -f "$pattern" | grep -v "$$" | grep -v "chrome.sh" > /dev/null; then
            chrome_was_running=true
            log "INFO" "Detected Chrome was running before modifications (pattern: $pattern)"
            
            # Check if Chrome has visible windows
            if [ "$is_wayland" = "true" ] && command -v swaymsg &> /dev/null; then
                # Use swaymsg to check for Chrome windows in Sway/Wayland
                if swaymsg -t get_tree | grep -i "\"app_id\":\".*chrome\|chromium\"" > /dev/null || \
                   swaymsg -t get_tree | grep -i "\"class\":\".*chrome\|chromium\"" > /dev/null; then
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
        if ! update_chrome_theme "$profile" "$chrome_color"; then
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