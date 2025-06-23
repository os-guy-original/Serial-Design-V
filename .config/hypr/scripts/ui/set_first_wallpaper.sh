#!/bin/bash

# Script to set default wallpaper only on first launch
# Updated to use centralized swww_manager.sh

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Set the first wallpaper with color generation
set_first_wallpaper_with_colorgen

exit $? 
