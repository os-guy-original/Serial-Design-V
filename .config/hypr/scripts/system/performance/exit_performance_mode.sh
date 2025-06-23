#!/bin/bash

# Simple script to exit performance mode
# Updated to use centralized swww_manager.sh

CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache"
STATE_DIR="$CACHE_DIR/state"
TEMP_DIR="$CACHE_DIR/temp"

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Create cache directories if they don't exist
mkdir -p "$STATE_DIR"
mkdir -p "$TEMP_DIR"

MODE_FILE="$STATE_DIR/.performance_mode"
SAVED_WALLPAPER_FILE="$STATE_DIR/.saved_wallpaper"
SAVED_ANIMATION_FILE="$STATE_DIR/.saved_animation_conf"

# Define performance sound file
PERFORMANCE_SOUND="toggle_performance.ogg"

if [ -f "$MODE_FILE" ]; then
    notify-send -t 1000 "Mode" "Exiting performance mode..."
    
    # Play the performance sound in reverse
    play_sound "$PERFORMANCE_SOUND" 100 true
    
    # Remove the performance mode file
    rm -f "$MODE_FILE"
    
    # Restore animation settings if saved file exists
    if [ -f "$SAVED_ANIMATION_FILE" ] && [ -s "$SAVED_ANIMATION_FILE" ]; then
        ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
        sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" "$HOME/.config/hypr/hyprland.conf"
        rm -f "$SAVED_ANIMATION_FILE"
    fi
    
    # Make sure swww is running
    ensure_swww_running
    
    # If we have a saved wallpaper, apply it
    if [ -f "$SAVED_WALLPAPER_FILE" ]; then
        WALLPAPER_PATH=$(cat "$SAVED_WALLPAPER_FILE")
        if [ -f "$WALLPAPER_PATH" ]; then
            set_wallpaper "$WALLPAPER_PATH"
        fi
    fi
    
    # Kill performance waybar and start normal waybar
    pkill -x waybar 2>/dev/null
    
    # Remove any performance config
    hyprctl reload &>/dev/null
    
    # Start normal waybar
    waybar &>/dev/null & disown
    
    notify-send -t 2000 "Mode" "Normal mode restored" &
else
    notify-send -t 1000 "Mode" "Not in performance mode"
fi
