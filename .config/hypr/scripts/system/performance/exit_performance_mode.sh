#!/bin/bash

# Simple script to exit performance mode
MODE_FILE="$HOME/.config/hypr/.performance_mode"
TOGGLE_SCRIPT="$HOME/.config/hypr/scripts/system/performance/toggle_performance_mode.sh"
SAVED_WALLPAPER_FILE="$HOME/.config/hypr/.saved_wallpaper"
SAVED_ANIMATION_FILE="$HOME/.config/hypr/.saved_animation_conf"

if [ -f "$MODE_FILE" ]; then
    notify-send -t 1000 "Mode" "Exiting performance mode..."
    
    # Run the toggle script to exit performance mode
    "$TOGGLE_SCRIPT" &>/dev/null &
    
    # Make sure swww-daemon is running
    (
        # Wait a moment for the toggle script to do its work
        sleep 1
        
        # Check if swww-daemon is running, if not start it
        if ! pgrep -x "swww-daemon" >/dev/null; then
            # Kill any existing instances first
            pkill -x swww-daemon 2>/dev/null
            
            # Start swww-daemon
            swww-daemon &>/dev/null &
            
            # Wait for daemon to initialize
            sleep 0.5
            
            # If we have a saved wallpaper, apply it
            if [ -f "$SAVED_WALLPAPER_FILE" ]; then
                WALLPAPER_PATH=$(cat "$SAVED_WALLPAPER_FILE")
                [ -f "$WALLPAPER_PATH" ] && swww img "$WALLPAPER_PATH" --transition-type none &>/dev/null &
            fi
        fi
        
        # Restore animation settings if saved file exists
        if [ -f "$SAVED_ANIMATION_FILE" ] && [ -s "$SAVED_ANIMATION_FILE" ]; then
            ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
            sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" "$HOME/.config/hypr/hyprland.conf"
            # Reload Hyprland config to apply animation changes
            hyprctl reload &>/dev/null
        fi
    ) &
else
    notify-send -t 1000 "Mode" "Not in performance mode"
fi
