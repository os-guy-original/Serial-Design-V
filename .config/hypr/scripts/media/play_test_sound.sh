#!/bin/bash

# play_test_sound.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Script to test sound playback
# Usage: ./play_test_sound.sh [sound_name]

# Default sound to play
# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"
SOUND_NAME="${1:-notification.ogg}"


# Check if default-sound file exists and read its content
# Get sound theme from sound manager
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)
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
