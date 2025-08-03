#!/usr/bin/env bash

# Script to initialize swww
# Updated to use centralized swww_manager.sh

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Make sure swww is running
ensure_swww_running

# Restore last wallpaper if available
if [ -f "$LAST_WALLPAPER_FILE" ]; then
    LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
    if [ -f "$LAST_WALLPAPER" ]; then
        echo "Restoring last wallpaper: $LAST_WALLPAPER"
        set_wallpaper "$LAST_WALLPAPER"
    else
        echo "Last wallpaper file not found: $LAST_WALLPAPER"
    fi
fi

exit 0 