#!/bin/bash

# Script to play login sound using the sound theme system
# This should be called during Hyprland startup

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
    # Create default-sound file if it doesn't exist
    mkdir -p "$SOUNDS_BASE_DIR"
    echo "default" > "$DEFAULT_SOUND_FILE"
fi

# Define login sound file
LOGIN_SOUND="$SOUNDS_DIR/login.ogg"

# Direct sound playback using mpv only
if [ -f "$LOGIN_SOUND" ]; then
    if command -v mpv >/dev/null 2>&1; then
        mpv --no-terminal --volume=100 "$LOGIN_SOUND"
    else
        echo "Error: mpv is not installed. Please install mpv to play sounds."
    fi
fi 