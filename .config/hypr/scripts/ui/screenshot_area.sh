#!/bin/bash

# screenshot_area.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound file
SCREENSHOT_SOUND="screenshot.ogg"

get_geometry() {
    slurp "$@"
}

geometry=$(get_geometry)
# Check if user canceled the selection
if [ -n "$geometry" ]; then
    sleep 0.2
    grim -g "$geometry" - | wl-copy
    
    # Play screenshot sound
    play_sound "$SCREENSHOT_SOUND"
    
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
fi
