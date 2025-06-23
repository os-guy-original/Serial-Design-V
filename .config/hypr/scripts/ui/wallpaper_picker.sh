#!/bin/bash
# Wallpaper picker script
# Updated to use centralized swww_manager.sh

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# If script is run with --apply, apply the last selected wallpaper
if [ "$1" == "--apply" ]; then
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        if [ -f "$WALLPAPER" ]; then
            echo "Applying wallpaper: $WALLPAPER"
            set_wallpaper "$WALLPAPER"
        else
            echo "Wallpaper file not found: $WALLPAPER"
        fi
    else
        echo "No saved wallpaper configuration found"
    fi
    exit 0
fi

# Select a new wallpaper using Zenity
WALLPAPER=$(zenity --file-selection --title="Select Wallpaper" \
--file-filter='Image files (png, jpg, jpeg) | *.png *.jpg *.jpeg')

if [ -n "$WALLPAPER" ]; then
    # Set wallpaper with color generation
    set_wallpaper_with_colorgen "$WALLPAPER" "wave"
fi
