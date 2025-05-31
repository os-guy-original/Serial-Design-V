#!/bin/bash

# Script to test sound playback
# Usage: ./play_test_sound.sh [sound_name]

# Default sound to play
SOUND_NAME="${1:-notification.ogg}"

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

# Full path to sound file
SOUND_FILE="$SOUNDS_DIR/$SOUND_NAME"

echo "Testing sound playback..."
echo "Sound theme: $SOUND_THEME"
echo "Sound directory: $SOUNDS_DIR"
echo "Sound file: $SOUND_FILE"

# Check if file exists
if [ ! -f "$SOUND_FILE" ]; then
    echo "Error: Sound file not found: $SOUND_FILE"
    exit 1
fi

echo "Playing sound with mpv..."
if command -v mpv >/dev/null 2>&1; then
    mpv --no-terminal --volume=100 "$SOUND_FILE"
    echo "mpv exit code: $?"
else
    echo "Error: mpv is not installed. Please install mpv to play sounds."
        exit 1
fi

echo "Sound playback test complete." 