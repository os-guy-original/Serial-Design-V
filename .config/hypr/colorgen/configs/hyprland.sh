#!/bin/bash

# Fast hyprland.sh - Material You border colors for Hyprland

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"

# Path to the configuration files
BORDER_COLOR_FILE="$COLORGEN_DIR/border_color.txt"
HYPRLAND_GENERAL_CONF="$CONFIG_DIR/configs/general.conf"

# Quick exit if general.conf doesn't exist
[ ! -f "$HYPRLAND_GENERAL_CONF" ] && exit 1

# Create backup if it doesn't exist yet (only once)
HYPRLAND_GENERAL_BACKUP="$CONFIG_DIR/configs/backups/general.conf.original"
if [ ! -f "$HYPRLAND_GENERAL_BACKUP" ]; then
    mkdir -p "$CONFIG_DIR/configs/backups"
    cp "$HYPRLAND_GENERAL_CONF" "$HYPRLAND_GENERAL_BACKUP" 2>/dev/null || true
fi

# Get border color - either from border_color.txt or from colors.conf
if [ -f "$BORDER_COLOR_FILE" ]; then
    # Read direct rgba value from file
    BORDER_COLOR=$(cat "$BORDER_COLOR_FILE")
else
    # Use color_extract.sh to get the brightest color
    BRIGHTEST_COLOR=$(extract_from_conf "primary-95" "primary-90" "color7" "primary")
    
    # Default to white if not found
    [ -z "$BRIGHTEST_COLOR" ] && BRIGHTEST_COLOR="#FFFFFF"
    
    # Convert hex to rgba using color_utils
    BORDER_COLOR=$(hex_to_rgba "$BRIGHTEST_COLOR")
fi

# Update the border colors in-place with single sed command
sed -i -e "s/col.active_border = rgba([^)]*)/col.active_border = $BORDER_COLOR/g" \
       -e "s/col.inactive_border = rgba([^)]*)/col.inactive_border = rgba(00000000)/g" \
       "$HYPRLAND_GENERAL_CONF"

# Immediately reload Hyprland without checking (faster)
hyprctl reload &>/dev/null &

exit 0