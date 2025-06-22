#!/bin/bash

# screenshot_fullscreen.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound file
SCREENSHOT_SOUND="screenshot.ogg"

grim - | wl-copy

# Play screenshot sound
play_sound "$SCREENSHOT_SOUND"

notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
