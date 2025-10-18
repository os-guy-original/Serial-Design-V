#!/bin/bash

# hyprlock.sh - Material You colors for hyprlock
# Applies Material You colors to the hyprlock lockscreen

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"

# Path to the configuration files
HYPRLOCK_CONF="$CONFIG_DIR/hyprlock.conf"
COLORS_CONF="$COLORGEN_DIR/colors.conf"

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

# Extract colors using color_extract.sh
extract_material_palette

PRIMARY=${primary:-"#bcc2ff"}
PRIMARY_80=${primary_80:-"$PRIMARY"}
PRIMARY_LIGHT=${primary_95:-${primary_90:-${primary_99:-"#e4e1e9"}}}

SECONDARY=${secondary:-"#c4c5dd"}
TERTIARY=${tertiary:-"#e6bad6"}

DARK_BG=$(extract_from_conf "color0" || echo "#0d0e13")
DARK_SURFACE=$(extract_from_conf "color1" || echo "#1b1b21")
DARK_SURFACE_VARIANT=$(extract_from_conf "color2" || echo "#1f1f25")
ON_SURFACE=$(extract_from_conf "color7" || echo "#e4e1e9")
ON_SURFACE_VARIANT=$(extract_from_conf "color6" || echo "#dfe0ff")
OUTLINE=$(extract_from_conf "color3" || echo "#29292f")
ERROR=${accent_dark:-$(extract_from_conf "accent_dark" || echo "#3b4279")}

# Note: hex_to_rgb is provided by color_utils.sh, but we need rgb() format
hex_to_rgb_hyprlock() {
    local hex=$1
    local rgb_values=$(hex_to_rgb "$hex")
    echo "rgb(${rgb_values// /, })"
}

# Convert colors to rgb format
PRIMARY_RGB=$(hex_to_rgb_hyprlock "$PRIMARY")
PRIMARY_80_RGB=$(hex_to_rgb_hyprlock "$PRIMARY_80")
PRIMARY_LIGHT_RGB=$(hex_to_rgb_hyprlock "$PRIMARY_LIGHT")
SECONDARY_RGB=$(hex_to_rgb_hyprlock "$SECONDARY")
TERTIARY_RGB=$(hex_to_rgb_hyprlock "$TERTIARY")
DARK_BG_RGB=$(hex_to_rgb_hyprlock "$DARK_BG")
DARK_SURFACE_RGB=$(hex_to_rgb_hyprlock "$DARK_SURFACE")
DARK_SURFACE_VARIANT_RGB=$(hex_to_rgb_hyprlock "$DARK_SURFACE_VARIANT")
ON_SURFACE_RGB=$(hex_to_rgb_hyprlock "$ON_SURFACE")
ON_SURFACE_VARIANT_RGB=$(hex_to_rgb_hyprlock "$ON_SURFACE_VARIANT")
OUTLINE_RGB=$(hex_to_rgb_hyprlock "$OUTLINE")
ERROR_RGB=$(hex_to_rgb_hyprlock "$ERROR")

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