#!/bin/bash

# Simple script to exit performance mode
MODE_FILE="$HOME/.config/hypr/.performance_mode"
TOGGLE_SCRIPT="$HOME/.config/hypr/scripts/toggle_performance_mode.sh"
SAVED_WALLPAPER_FILE="$HOME/.config/hypr/.saved_wallpaper"

if [ -f "$MODE_FILE" ]; then
    notify-send -t 1000 "Mode" "Exiting performance mode..."
    
    # Toggle script'i çalıştır
    "$TOGGLE_SCRIPT" &>/dev/null &
    
    # Eğer toggle_script swww-daemon'u başlatmakta başarısız olursa kontrol et
    (
        sleep 0.5
        if ! pgrep -x "swww-daemon" >/dev/null; then
            hyprctl dispatch exec "swww-daemon" &>/dev/null
        fi
    ) &
else
    notify-send -t 1000 "Mode" "Not in performance mode"
fi
