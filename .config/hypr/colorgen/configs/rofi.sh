#!/bin/bash

# rofi.sh - Generate a .rasi file with colors from colors.conf
# This script creates/updates a colors.rasi file for rofi with colors matching waybar
# Modified to only apply colors, preserving existing size settings

# Path to the generated color files
COLORS_CONF="$HOME/.config/hypr/colorgen/colors.conf"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

# Quick exit if colors.conf doesn't exist
[ ! -f "$COLORS_CONF" ] && exit 1

# Create backup once if it doesn't exist
ROFI_BACKUP="$HOME/.config/rofi/backups/colors.rasi.original"
if [ ! -f "$ROFI_BACKUP" ] && [ -f "$ROFI_COLORS" ]; then
    mkdir -p "$HOME/.config/rofi/backups"
    cp "$ROFI_COLORS" "$ROFI_BACKUP" 2>/dev/null || true
fi

# Read colors directly without sourcing
primary=$(grep -E '^primary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent=$(grep -E '^accent =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_dark=$(grep -E '^accent_dark =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_light=$(grep -E '^accent_light =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
secondary=$(grep -E '^secondary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
tertiary=$(grep -E '^tertiary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color0=$(grep -E '^color0 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color1=$(grep -E '^color1 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color2=$(grep -E '^color2 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color3=$(grep -E '^color3 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color4=$(grep -E '^color4 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color5=$(grep -E '^color5 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color6=$(grep -E '^color6 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color7=$(grep -E '^color7 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# Set defaults for missing values
[ -z "$primary" ] && primary="#808080"
[ -z "$accent" ] && accent="#808080"
[ -z "$accent_dark" ] && accent_dark="#606060"
[ -z "$accent_light" ] && accent_light="#a0a0a0"
[ -z "$secondary" ] && secondary="#707070"
[ -z "$tertiary" ] && tertiary="#909090"
[ -z "$color0" ] && color0="#000000"
[ -z "$color1" ] && color1="#202020"
[ -z "$color2" ] && color2="#404040"
[ -z "$color3" ] && color3="#606060"
[ -z "$color4" ] && color4="#808080"
[ -z "$color5" ] && color5="#a0a0a0"
[ -z "$color6" ] && color6="#c0c0c0"
[ -z "$color7" ] && color7="#e0e0e0"

# Function to calculate color brightness
get_brightness() {
    # Convert hex to RGB
    r=$(printf "%d" 0x${1:1:2})
    g=$(printf "%d" 0x${1:3:2})
    b=$(printf "%d" 0x${1:5:2})
    
    # Calculate perceived brightness using the formula: (0.299*R + 0.587*G + 0.114*B)
    echo "scale=2; (0.299*$r + 0.587*$g + 0.114*$b)/255" | bc
}

# Function to determine if a color is light or dark
is_light() {
    brightness=$(get_brightness "$1")
    # If brightness > 0.5, consider it light
    echo "$(echo "$brightness > 0.5" | bc -l)"
}

# Function to darken a color by reducing RGB values by a fixed percentage
darken_color() {
    local hex=$1
    local percent=40  # Darken by 40% (increased from 20%)
    local r=$(printf "%d" 0x${hex:1:2})
    local g=$(printf "%d" 0x${hex:3:2})
    local b=$(printf "%d" 0x${hex:5:2})
    r=$(echo "scale=0; $r * (1 - $percent/100) / 1" | bc)
    g=$(echo "scale=0; $g * (1 - $percent/100) / 1" | bc)
    b=$(echo "scale=0; $b * (1 - $percent/100) / 1" | bc)
    printf "#%02x%02x%02x" $r $g $b
}

# Function to lighten a color by increasing RGB values by a fixed percentage
lighten_color() {
    local hex=$1
    local percent=40  # Lighten by 40%
    local r=$(printf "%d" 0x${hex:1:2})
    local g=$(printf "%d" 0x${hex:3:2})
    local b=$(printf "%d" 0x${hex:5:2})
    r=$(echo "scale=0; $r + ($percent/100) * (255 - $r) / 1" | bc)
    g=$(echo "scale=0; $g + ($percent/100) * (255 - $g) / 1" | bc)
    b=$(echo "scale=0; $b + ($percent/100) * (255 - $b) / 1" | bc)
    printf "#%02x%02x%02x" $r $g $b
}

# Function to determine text color based on background brightness
get_text_color() {
    local bg_color=$1
    local dark_text="#222222"
    local light_text="#ffffff"
    
    if [ "$(is_light "$bg_color")" -eq 1 ]; then
        echo "$dark_text"
    else
        echo "$light_text"
    fi
}

# Assign colors with intelligent defaults - using waybar style
BACKGROUND_COLOR="$color0"              # Darkest color for background
before_accent_color="$color2"          # Use color2 instead of secondary (darker)
SELECTED_BG="$accent"                  # Waybar accent for selected background
BORDER_COLOR="$accent_light"           # Border color

# Always darken the non-selected background color to ensure it's not too bright
before_accent_color=$(darken_color "$before_accent_color")

# Create a lighter placeholder color for the search field
PLACEHOLDER_COLOR=$(lighten_color "$color5")  # Use a lightened color5 for placeholder

# Decide font color based on background brightness
SELECTED_TEXT_FONT=$(get_text_color "$SELECTED_BG")
FOREGROUND_FONT=$(get_text_color "$before_accent_color")

# Hex to RGB conversion for transparency
hex_to_rgb() {
    r=$(printf "%d" 0x${1:1:2})
    g=$(printf "%d" 0x${1:3:2})
    b=$(printf "%d" 0x${1:5:2})
    echo "$r, $g, $b"
}

BG_RGB=$(hex_to_rgb "$BACKGROUND_COLOR")
BEFORE_ACCENT_RGB=$(hex_to_rgb "$before_accent_color")
BORDER_RGB=$(hex_to_rgb "$BORDER_COLOR")

# Generate the colors.rasi file
mkdir -p "$(dirname "$ROFI_COLORS")"
cat > "$ROFI_COLORS" << EOL
/**
 * Rofi Colors - Generated from Hyprland colorgen
 * Generated on $(date +%Y-%m-%d)
 */

* {
    /* Base colors from colorgen */
    background:     ${BACKGROUND_COLOR};
    background-alt: ${before_accent_color};
    foreground:     ${FOREGROUND_FONT};
    selected:       ${SELECTED_BG};
    active:         ${accent_light};
    urgent:         ${tertiary};
    
    /* Derived colors with transparency */
    background-trans:     rgba(${BG_RGB}, 0.4);
    background-alt-trans: rgba(${BEFORE_ACCENT_RGB}, 0.45);
    border-color:         rgba(${BORDER_RGB}, 0.8);
    selected-text:        ${SELECTED_TEXT_FONT};
    placeholder:          ${PLACEHOLDER_COLOR};
}

/* Import this file in your other .rasi configs */
EOL

echo "Generated Rofi colors file at $ROFI_COLORS" 