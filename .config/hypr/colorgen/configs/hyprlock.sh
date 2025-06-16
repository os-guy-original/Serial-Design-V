#!/bin/bash

# hyprlock.sh - Material You colors for hyprlock
# Applies Material You colors to the hyprlock lockscreen

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

# Path to the configuration files
HYPRLOCK_CONF="$CONFIG_DIR/hyprlock.conf"
COLORS_CONF="$CONFIG_DIR/colorgen/colors.conf"

# Quick exit if hyprlock.conf doesn't exist
[ ! -f "$HYPRLOCK_CONF" ] && exit 1

# Create backup if it doesn't exist yet (only once)
HYPRLOCK_BACKUP="$CONFIG_DIR/backups/hyprlock.conf.original"
if [ ! -f "$HYPRLOCK_BACKUP" ]; then
    mkdir -p "$CONFIG_DIR/backups"
    cp "$HYPRLOCK_CONF" "$HYPRLOCK_BACKUP" 2>/dev/null || true
fi

# Check if colors.conf exists
if [ ! -f "$COLORS_CONF" ]; then
    echo "Error: $COLORS_CONF not found!"
    exit 1
fi

# Extract colors from colors.conf
PRIMARY=$(grep "^primary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
PRIMARY_80=$(grep "^primary-80 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$PRIMARY_80" ] && PRIMARY_80=$(grep "^primary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
PRIMARY_LIGHT=$(grep "^primary-95 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$PRIMARY_LIGHT" ] && PRIMARY_LIGHT=$(grep "^primary-90 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$PRIMARY_LIGHT" ] && PRIMARY_LIGHT=$(grep "^primary-99 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

SECONDARY=$(grep "^secondary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
TERTIARY=$(grep "^tertiary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

DARK_BG=$(grep "^color0 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
DARK_SURFACE=$(grep "^color1 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
DARK_SURFACE_VARIANT=$(grep "^color2 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
ON_SURFACE=$(grep "^color7 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
ON_SURFACE_VARIANT=$(grep "^color6 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
OUTLINE=$(grep "^color3 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
ERROR=$(grep "^accent_dark =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# Default values if not found
[ -z "$PRIMARY" ] && PRIMARY="#bcc2ff"
[ -z "$PRIMARY_80" ] && PRIMARY_80="#bcc2ff"
[ -z "$PRIMARY_LIGHT" ] && PRIMARY_LIGHT="#e4e1e9"
[ -z "$SECONDARY" ] && SECONDARY="#c4c5dd"
[ -z "$TERTIARY" ] && TERTIARY="#e6bad6"
[ -z "$DARK_BG" ] && DARK_BG="#0d0e13"
[ -z "$DARK_SURFACE" ] && DARK_SURFACE="#1b1b21"
[ -z "$DARK_SURFACE_VARIANT" ] && DARK_SURFACE_VARIANT="#1f1f25"
[ -z "$ON_SURFACE" ] && ON_SURFACE="#e4e1e9"
[ -z "$ON_SURFACE_VARIANT" ] && ON_SURFACE_VARIANT="#dfe0ff"
[ -z "$OUTLINE" ] && OUTLINE="#29292f"
[ -z "$ERROR" ] && ERROR="#3b4279"

# Convert hex to rgb format
hex_to_rgb() {
    hex=$1
    r=$(printf "%d" 0x${hex:1:2})
    g=$(printf "%d" 0x${hex:3:2})
    b=$(printf "%d" 0x${hex:5:2})
    echo "rgb($r, $g, $b)"
}

# Convert colors to rgb format
PRIMARY_RGB=$(hex_to_rgb "$PRIMARY")
PRIMARY_80_RGB=$(hex_to_rgb "$PRIMARY_80")
PRIMARY_LIGHT_RGB=$(hex_to_rgb "$PRIMARY_LIGHT")
SECONDARY_RGB=$(hex_to_rgb "$SECONDARY")
TERTIARY_RGB=$(hex_to_rgb "$TERTIARY")
DARK_BG_RGB=$(hex_to_rgb "$DARK_BG")
DARK_SURFACE_RGB=$(hex_to_rgb "$DARK_SURFACE")
DARK_SURFACE_VARIANT_RGB=$(hex_to_rgb "$DARK_SURFACE_VARIANT")
ON_SURFACE_RGB=$(hex_to_rgb "$ON_SURFACE")
ON_SURFACE_VARIANT_RGB=$(hex_to_rgb "$ON_SURFACE_VARIANT")
OUTLINE_RGB=$(hex_to_rgb "$OUTLINE")
ERROR_RGB=$(hex_to_rgb "$ERROR")

# Update colors in hyprlock.conf for input field
sed -i \
    -e "s/outer_color = rgb([^)]*)/outer_color = $OUTLINE_RGB/g" \
    -e "s/inner_color = rgb([^)]*)/inner_color = $DARK_SURFACE_VARIANT_RGB/g" \
    -e "s/font_color = rgb([^)]*)/font_color = $ON_SURFACE_RGB/g" \
    -e "s/check_color = rgb([^)]*)/check_color = $PRIMARY_RGB/g" \
    -e "s/fail_color = rgb([^)]*)/fail_color = $ERROR_RGB/g" \
    "$HYPRLOCK_CONF"

# Update clock and other text labels to use primary-80
sed -i -e '/^label {/,/^}/ s/color = rgb([^)]*) \/\/ Material Design 3 Dark On-Surface/color = '"$PRIMARY_80_RGB"' \/\/ Material Design 3 Dark On-Surface/g' "$HYPRLOCK_CONF"

# Keep the date using the on-surface-variant color
sed -i -e '/text = cmd\[update:1000\] echo "\$\(date +"%a, %b %d"\)"/,/^}/ s/color = rgb([^)]*) \/\/ Material Design 3 Dark On-Surface-variant/color = '"$ON_SURFACE_VARIANT_RGB"' \/\/ Material Design 3 Dark On-Surface-variant/g' "$HYPRLOCK_CONF"

echo "Applied Material You colors to hyprlock configuration"
exit 0 