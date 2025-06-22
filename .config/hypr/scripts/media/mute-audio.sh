#!/bin/bash

# mute-audio.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Check if default-sound file exists and read its content
# Get sound theme from sound manager
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
fi

# Define sound files
MUTE_SOUND=
UNMUTE_SOUND=


# Toggle mute
pamixer -t

# Get the current mute status
if pamixer --get-mute | grep -q "true"; then
    swayosd --mute
    play_sound "$MUTE_SOUND"
else
    swayosd --unmute
    play_sound "$UNMUTE_SOUND"
fi
