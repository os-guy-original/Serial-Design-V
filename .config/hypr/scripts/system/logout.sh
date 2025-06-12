#!/bin/bash

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

# Define sound files
LOGOUT_SOUND="$SOUNDS_DIR/logout.ogg"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal "$sound_file"
        else
            echo "Error: mpv is not installed. Please install mpv to play sounds."
        fi
    fi
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
            play_sound "$LOGOUT_SOUND"
            loginctl lock-session 
            ;;
        "Logout") 
            play_sound "$LOGOUT_SOUND"
            loginctl terminate-user "$USER" 
            ;;
        "Suspend") 
            play_sound "$LOGOUT_SOUND"
            systemctl suspend 
            ;;
        "Reboot") 
            play_sound "$LOGOUT_SOUND"
            systemctl reboot 
            ;;
        "Shutdown") 
            play_sound "$LOGOUT_SOUND"
            systemctl poweroff 
            ;;
        *) exit 0 ;;
    esac
fi
