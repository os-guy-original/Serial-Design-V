#!/bin/bash

# Script to set default wallpaper only on first launch
# Check if HYPRLAND_FIRST_LAUNCH env var is set
FIRST_LAUNCH_FILE="$HOME/.config/hypr/.first_launch_done"

# Check if the first launch file exists
if [ ! -f "$FIRST_LAUNCH_FILE" ]; then
    # Wait for swww daemon to start
    sleep 1
    
    # Initialize swww if not already running
    swww query || swww init
    
    # Set the default background
    DEFAULT_BG="$HOME/.config/hypr/res/default_bg.jpg"
    if [ -f "$DEFAULT_BG" ]; then
        echo "Setting default wallpaper on first launch"
        swww img "$DEFAULT_BG" --transition-type grow --transition-pos center
    else
        echo "Default background not found: $DEFAULT_BG"
    fi
    
    # Create the file to indicate first launch is done
    touch "$FIRST_LAUNCH_FILE"
    echo "First launch setup completed"
fi

exit 0 
