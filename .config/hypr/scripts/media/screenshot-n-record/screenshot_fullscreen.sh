#!/bin/bash

# screenshot_fullscreen.sh - Script for taking fullscreen screenshots

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound file
SCREENSHOT_SOUND="$SOUNDS_DIR/screenshot.ogg"

# Capture fullscreen function
capture_fullscreen() {
    sleep 1.5  # Add a 1.5-second delay
    grim - | wl-copy
    
    # Play screenshot sound
    play_sound "$SCREENSHOT_SOUND"
    
    notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
    return 0
}

# Execute capture
capture_fullscreen
exit $? 