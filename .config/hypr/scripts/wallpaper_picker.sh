#!/bin/bash
# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
CONFIG_FILE="$CONFIG_DIR/last_wallpaper"

# Eğer betik açılışta çalıştırılıyorsa, son seçilen duvar kağıdını uygula
if [ "$1" == "--apply" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        WALLPAPER=$(cat "$CONFIG_FILE")
        swww img "$WALLPAPER"
    fi
    exit 0
fi

# Zenity ile yeni bir duvar kağıdı seç
WALLPAPER=$(zenity --file-selection --title="Select Wallpaper" \
--file-filter='Image files (png, jpg, jpeg) | *.png *.jpg *.jpeg')

if [ -n "$WALLPAPER" ]; then
    echo "$WALLPAPER" > "$CONFIG_FILE"
    swww img "$WALLPAPER" --transition-type wave
    # Generate colors from wallpaper
    /home/sd-v/.config/hypr/colorgen/material_extract.sh
    # Generate colors from wallpaper
    "$CONFIG_DIR/colorgen/material_extract.sh"
fi
