#!/usr/bin/env bash

# Script to initialize swww and set wallpaper

# Define cache directory
CACHE_DIR="$HOME/.config/hypr/cache/state"
mkdir -p "$CACHE_DIR"

# First, check if swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "Starting swww daemon..."
    swww-daemon
    # Wait for daemon to initialize
    sleep 0.5
fi

# Function to initialize swww if needed
initialize_swww() {
    if ! swww query; then
        echo "Initializing swww..."
        swww init
        # Give it a moment to initialize
        sleep 0.5
        return 0
    else
        echo "swww is already initialized"
        return 0
    fi
}

# Function to set wallpaper
set_wallpaper() {
    local wallpaper=$1
    
    if [ -f "$wallpaper" ]; then
        echo "Setting wallpaper: $wallpaper"
        swww img "$wallpaper" --transition-type grow --transition-pos center
        # Remember the wallpaper
        echo "$wallpaper" > "$CACHE_DIR/last_wallpaper"
        return 0
    else
        echo "Error: Wallpaper file not found: $wallpaper"
        return 1
    fi
}

# Main execution
initialize_swww

# Check if this is the first launch
FIRST_LAUNCH_FILE="$CACHE_DIR/.first_launch_done"

if [ ! -f "$FIRST_LAUNCH_FILE" ]; then
    # First launch - set the default wallpaper
    DEFAULT_BG="$HOME/.config/hypr/res/default_bg.png"
    echo "First launch detected, setting default wallpaper"
    if set_wallpaper "$DEFAULT_BG"; then
        # Create the marker file
        touch "$FIRST_LAUNCH_FILE"
        echo "First launch setup completed"
    fi
else
    # Not first launch - check for last used wallpaper
    LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        if [ -f "$LAST_WALLPAPER" ]; then
            echo "Restoring last wallpaper"
            set_wallpaper "$LAST_WALLPAPER"
        else
            # Last wallpaper file doesn't exist anymore
            DEFAULT_BG="$HOME/.config/hypr/res/default_bg.png"
            echo "Last wallpaper not found, falling back to default"
            set_wallpaper "$DEFAULT_BG"
        fi
    else
        # No last wallpaper record - use default
        DEFAULT_BG="$HOME/.config/hypr/res/default_bg.png"
        echo "No last wallpaper record, using default"
        set_wallpaper "$DEFAULT_BG"
    fi
fi

exit 0 