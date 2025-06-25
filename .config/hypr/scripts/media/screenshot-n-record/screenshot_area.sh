#!/bin/bash

# screenshot_area.sh - Script for taking area screenshots

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound file
SCREENSHOT_SOUND="$SOUNDS_DIR/screenshot.ogg"

# Capture area function
capture_area() {
    geometry=$(slurp)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return 1
    fi
    grim -g "$geometry" - | wl-copy
    
    # Play screenshot sound
    play_sound "$SCREENSHOT_SOUND"
    
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
    return 0
}

# Execute capture
capture_area
exit $? 