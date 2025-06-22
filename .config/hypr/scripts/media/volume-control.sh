#!/bin/bash

# volume-control.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound files
VOLUME_UP_SOUND="volume-up.ogg"
VOLUME_DOWN_SOUND="volume-down.ogg"

# Get the default audio device
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
