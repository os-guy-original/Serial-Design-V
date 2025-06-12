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
VOLUME_UP_SOUND="$SOUNDS_DIR/volume-up.ogg"
VOLUME_DOWN_SOUND="$SOUNDS_DIR/volume-down.ogg"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal --volume=100 "$sound_file" &
        else
            echo "Error: mpv is not installed. Please install mpv to play sounds." >&2
        fi
    fi
}

DEVICE=$(pactl get-default-sink 2>/dev/null || echo "alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink")

case $1 in
    up)
        swayosd-client --output-volume raise --device "$DEVICE"
        play_sound "$VOLUME_UP_SOUND"
        ;;
    down)
        swayosd-client --output-volume lower --device "$DEVICE"
        play_sound "$VOLUME_DOWN_SOUND"
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
esac

# Logging for debugging
echo "[$(date)] Volume $1 - Device: $DEVICE - Status: $?" >> ~/.cache/hypr_volume.log
