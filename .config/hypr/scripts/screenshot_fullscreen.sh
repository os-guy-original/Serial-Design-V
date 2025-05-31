#!/bin/bash
# THIS IS A PART OF THE screenshot_shot-record.sh FILE

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

# Define sound file
SCREENSHOT_SOUND="$SOUNDS_DIR/screenshot.ogg"

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

grim - | wl-copy

# Play screenshot sound
play_sound "$SCREENSHOT_SOUND"

notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
