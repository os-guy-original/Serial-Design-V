#!/bin/bash

# Force color extraction from the current wallpaper
WALLPAPER=$(cat "$HOME/.config/hypr/last_wallpaper")

if [ -f "$WALLPAPER" ]; then
    echo "Forcing color extraction from: $WALLPAPER"
    
    # Ensure the wallpaper file is properly set
    echo "$WALLPAPER" > "$HOME/.config/hypr/last_wallpaper"
    
    # Force run the material extraction script
    "$HOME/.config/hypr/colorgen/material_extract.sh"
    
    # Notify the user
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Color Extraction Complete" "Applied colors from $WALLPAPER"
    fi
    
    echo "Done! Colors have been extracted and applied."
else
    echo "Error: Wallpaper file not found: $WALLPAPER"
    exit 1
fi 