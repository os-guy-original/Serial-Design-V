#!/bin/bash

# Define cache directory
CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache/state"
mkdir -p "$CACHE_DIR"

# Force color extraction from the current wallpaper
WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
if [ ! -f "$WALLPAPER_FILE" ]; then
    # Check legacy location for backward compatibility
    if [ -f "$CONFIG_DIR/last_wallpaper" ]; then
        cp "$CONFIG_DIR/last_wallpaper" "$WALLPAPER_FILE"
    else
        echo "Error: No wallpaper file found"
        exit 1
    fi
fi

WALLPAPER=$(cat "$WALLPAPER_FILE")

if [ -f "$WALLPAPER" ]; then
    echo "Forcing color extraction from: $WALLPAPER"
    
    # Ensure the wallpaper file is properly set
    echo "$WALLPAPER" > "$WALLPAPER_FILE"
    
    # Force run the material extraction script
    "$CONFIG_DIR/colorgen/material_extract.sh"
    
    # Notify the user
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Color Extraction Complete" "Applied colors from $WALLPAPER"
    fi
    
    echo "Done! Colors have been extracted and applied."
else
    echo "Error: Wallpaper file not found: $WALLPAPER"
    exit 1
fi 