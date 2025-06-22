#!/bin/bash

# logout.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Define sound files
LOGOUT_SOUND="logout.ogg"

# Get the full path to the sound file with better fallback
get_logout_sound() {
    # First try using the sound manager
    local sound_file=$(get_sound_file "$LOGOUT_SOUND")
    
    # If that fails, try direct paths
    if [[ -z "$sound_file" || ! -f "$sound_file" ]]; then
        # Try default theme
        if [[ -f "$SOUNDS_BASE_DIR/default/$LOGOUT_SOUND" ]]; then
            sound_file="$SOUNDS_BASE_DIR/default/$LOGOUT_SOUND"
        # Try KDE-3-Sounds theme
        elif [[ -f "$SOUNDS_BASE_DIR/KDE-3-Sounds/$LOGOUT_SOUND" ]]; then
            sound_file="$SOUNDS_BASE_DIR/KDE-3-Sounds/$LOGOUT_SOUND"
        fi
    fi
    
    echo "$sound_file"
}

# Get the sound file path
SOUND_FILE=$(get_logout_sound)

# Function to play sound and execute command
play_and_execute() {
    local cmd="$1"
    
    # Play sound directly with mpv if file exists
    if [[ -n "$SOUND_FILE" && -f "$SOUND_FILE" ]]; then
        # Log the sound file we're using
        echo "Playing logout sound: $SOUND_FILE" >> "$CACHE_DIR/logout_debug.log"
        # Play sound in foreground to ensure it completes before action
        mpv --no-terminal --volume=100 "$SOUND_FILE"
    else
        echo "No logout sound file found" >> "$CACHE_DIR/logout_debug.log"
    fi
    
    # Execute the command
    eval "$cmd"
}

options=("Lock" "Logout" "Suspend" "Reboot" "Shutdown" "Cancel")
icons=("system-lock-screen" "system-log-out" "system-suspend" "system-reboot" "system-shutdown" "window-close")

# Build menu lines without trailing newline
menu=""
for i in "${!options[@]}"; do
    menu+="${options[$i]}\0icon\x1f${icons[$i]}\n"
done

# Remove the final \n to avoid empty entry
menu="${menu%\\n}"

# Pass to Rofi with printf (no auto-newline)
chosen=$(printf "%b" "$menu" | rofi -dmenu -theme ~/.config/rofi/logout.rasi -format i -no-fixed-num-lines -no-custom -disable-history -hide-scrollbar)

# Handle selection
if [[ -n "$chosen" ]]; then
    case "${options[$chosen]}" in
        "Lock") 
            play_and_execute "loginctl lock-session"
            ;;
        "Logout") 
            play_and_execute "loginctl terminate-user \"$USER\""
            ;;
        "Suspend") 
            play_and_execute "systemctl suspend"
            ;;
        "Reboot") 
            play_and_execute "systemctl reboot"
            ;;
        "Shutdown") 
            play_and_execute "systemctl poweroff"
            ;;
        *) exit 0 ;;
    esac
fi
