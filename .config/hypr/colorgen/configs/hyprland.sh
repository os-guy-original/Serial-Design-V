#!/bin/bash

# Fast hyprland.sh - Material You border colors for Hyprland

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

# Path to the configuration files
BORDER_COLOR_FILE="$CONFIG_DIR/colorgen/border_color.txt"
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
    # Fall back to colors.conf method
    COLORS_CONF="$CONFIG_DIR/colorgen/colors.conf"
    if [ -f "$COLORS_CONF" ]; then
        # For Material You, we want to use a lighter tone from the tonal palette
        # Try primary-95 or primary-90 (Material Design convention for lightest tones)
        BRIGHTEST_COLOR=$(grep -E '^primary-95|^primary-90' "$COLORS_CONF" | head -1 | cut -d'=' -f2 | tr -d ' ')
        
        # If not found, try color7 (traditional brightest color) or primary
        if [ -z "$BRIGHTEST_COLOR" ]; then
            BRIGHTEST_COLOR=$(grep -E '^color7|^primary' "$COLORS_CONF" | head -1 | cut -d'=' -f2 | tr -d ' ')
        fi
        
        # Default to white if not found
        [ -z "$BRIGHTEST_COLOR" ] && BRIGHTEST_COLOR="#FFFFFF"
        # Convert hex to rgba
        BORDER_COLOR="rgba(${BRIGHTEST_COLOR:1:2}${BRIGHTEST_COLOR:3:2}${BRIGHTEST_COLOR:5:2}ff)"
    else
        # Default border color if no config file available
        BORDER_COLOR="rgba(E0E0E0ff)"
    fi
fi

# Update the border colors in-place with single sed command
sed -i -e "s/col.active_border = rgba([^)]*)/col.active_border = $BORDER_COLOR/g" \
       -e "s/col.inactive_border = rgba([^)]*)/col.inactive_border = rgba(00000000)/g" \
       "$HYPRLAND_GENERAL_CONF"

# Immediately reload Hyprland without checking (faster)
hyprctl reload &>/dev/null &

exit 0