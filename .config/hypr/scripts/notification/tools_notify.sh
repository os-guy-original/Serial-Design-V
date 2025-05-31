#!/bin/bash

# Tool notification system for Hyprland
# Shows notifications for required tools with sound effects

# Sound file paths
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    fi
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
fi

# Print the sound folder path
echo "Tools notify using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Define sound files
INFO_SOUND="$SOUNDS_DIR/notification.ogg"
WARNING_SOUND="$SOUNDS_DIR/device-removed.ogg"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal "$sound_file" &
        else
            echo "Error: mpv is not installed. Please install mpv to play sounds." >&2
        fi
    fi
}

# Function to check a specific tool and show notification
check_tool() {
    local tool_name=$1
    local tool_cmd=$2
    local key=$3
    local display_name=$4
    local icon=$5
    local pref_file="$HOME/.config/hypr/${tool_name}_notify_pref"
    
    # Check if tool is installed
    if command -v "$tool_cmd" &> /dev/null; then
        # If the command exists, check if notification has already been shown
        if [ ! -f "$pref_file" ]; then
            # Play info sound
            play_sound "$INFO_SOUND"
            
            # Notification hasn't been shown before, show it now
            notify-send --icon="$icon" --app-name="Hyprland" "$display_name Reminder" "Press SUPER + $key to ${display_name,,}" -a "Hyprland" -t 10000
            
            # Create preference file to remember we've shown the notification
            touch "$pref_file"
        fi
    else
        # If the command doesn't exist, show notification with reminder to install
        
        # Play warning sound
        play_sound "$WARNING_SOUND"
        
        notify-send --icon=dialog-warning --app-name="Hyprland" "$display_name Missing" "The '$tool_cmd' command is not installed. Please install it to use SUPER + $key for ${display_name,,}." -a "Hyprland" -t 10000
        
        # Simplified action handling - we'll just create the preference file
        # This removes the dependency on swaynotificationcenter-action
            touch "$pref_file"
    fi
}

# Sleep briefly to ensure notifications don't overlap
sleep 1

# Check for hyprland-keybinds
check_tool "keybinds" "hyprland-keybinds" "K" "Keybinds Viewer" "input-keyboard"

# Sleep briefly between notifications
sleep 2

# Check for main-center
check_tool "main_center" "main-center" "C" "Main Center" "preferences-system" 