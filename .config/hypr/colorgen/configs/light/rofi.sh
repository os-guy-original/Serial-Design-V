#!/bin/bash

# rofi.sh (Light Theme) - Generate a .rasi file with colors from colors.conf
# This script creates/updates a colors.rasi file for rofi with colors matching waybar
# Modified for light theme with appropriate contrast and readability

# Path to the generated color files
COLORS_CONF="$HOME/.config/hypr/colorgen/colors.conf"
COLORGEN_DIR="$HOME/.config/hypr/colorgen"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"
LIGHT_COLORS_JSON="$COLORGEN_DIR/light_colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"

# Quick exit if colors.conf doesn't exist
[ ! -f "$COLORS_CONF" ] && exit 1
[ ! -f "$LIGHT_COLORS_JSON" ] && exit 1

# Create backup once if it doesn't exist
ROFI_BACKUP="$HOME/.config/rofi/backups/colors.rasi.original"
if [ ! -f "$ROFI_BACKUP" ] && [ -f "$ROFI_COLORS" ]; then
    mkdir -p "$HOME/.config/rofi/backups"
    cp "$ROFI_COLORS" "$ROFI_BACKUP" 2>/dev/null || true
fi

# Load colors using color_utils library
load_colors "$COLORS_CONF"

# Get the primary color from light_colors.json
material_primary=$(jq -r '.primary' "$LIGHT_COLORS_JSON")
material_primary_container=$(jq -r '.primary_container' "$LIGHT_COLORS_JSON")
material_on_primary=$(jq -r '.on_primary' "$LIGHT_COLORS_JSON")

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
[ -z "$material_primary" ] && material_primary="#884b6b"
[ -z "$material_primary_container" ] && material_primary_container="#ffd8e8"
[ -z "$material_on_primary" ] && material_on_primary="#ffffff"

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

# Note: darken_color and lighten_color functions are now provided by color_utils.sh

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

# Note: ensure_dark_enough function is now provided by color_utils.sh

# Hex to RGB conversion for Rofi RGBA format (needs comma-space separation)
hex_to_rgb_rofi() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r, $g, $b"
}

# Get time of day to adjust color intensity
get_time_factor() {
    local hour=$(date +%H)
    local time_factor=60  # Default darkening factor
    
    # Morning (6-10): lighter colors (less darkening)
    if [ "$hour" -ge 6 ] && [ "$hour" -lt 10 ]; then
        time_factor=50
    # Midday (10-14): lightest colors (least darkening)
    elif [ "$hour" -ge 10 ] && [ "$hour" -lt 14 ]; then
        time_factor=45
    # Afternoon (14-18): medium colors
    elif [ "$hour" -ge 14 ] && [ "$hour" -lt 18 ]; then
        time_factor=55
    # Evening/Night: darker colors (more darkening)
    else
        time_factor=65
    fi
    
    echo "$time_factor"
}

# Get time-based darkening factor
TIME_FACTOR=$(get_time_factor)

# For light theme, we invert the color scheme
# Use white/light gray as background
BACKGROUND_COLOR="#ffffff"
before_accent_color="#f0f0f0"  # Light gray for non-selected items

# Use the material_primary color from light_colors.json instead of accent
SELECTED_BG="$material_primary"
BORDER_COLOR=$(darken_color "$material_primary" 10)
URGENT_COLOR=$(ensure_dark_enough "$tertiary")
ACTIVE_COLOR=$(lighten_color "$material_primary" 20)

# Darken accent colors to ensure visibility on light background
SELECTED_BG=$(ensure_dark_enough "$SELECTED_BG")
BORDER_COLOR=$(ensure_dark_enough "$BORDER_COLOR")

# Set text colors for light theme
FOREGROUND_FONT="#222222"  # Dark text for light background
SELECTED_TEXT_FONT="$material_on_primary"  # Text color for selected items
PLACEHOLDER_COLOR="#888888"  # Medium gray for placeholder text

BG_RGB=$(hex_to_rgb_rofi "$BACKGROUND_COLOR")
BEFORE_ACCENT_RGB=$(hex_to_rgb_rofi "$before_accent_color")
BORDER_RGB=$(hex_to_rgb_rofi "$BORDER_COLOR")

# Generate the colors.rasi file
mkdir -p "$(dirname "$ROFI_COLORS")"
cat > "$ROFI_COLORS" << EOL
/**
 * Rofi Colors - Generated from Hyprland colorgen (Light Theme)
 * Generated on $(date +%Y-%m-%d)
 */

* {
    /* Base colors from colorgen (Light Theme) */
    background:     ${BACKGROUND_COLOR};
    background-alt: ${before_accent_color};
    foreground:     ${FOREGROUND_FONT};
    selected:       ${SELECTED_BG};
    active:         ${ACTIVE_COLOR};
    urgent:         ${URGENT_COLOR};
    
    /* Derived colors with transparency */
    background-trans:     rgba(${BG_RGB}, 0.65);
    background-alt-trans: rgba(${BEFORE_ACCENT_RGB}, 0.80);
    border-color:         rgba(${BORDER_RGB}, 0.9);
    selected-text:        ${SELECTED_TEXT_FONT};
    placeholder:          ${PLACEHOLDER_COLOR};
    
    /* Additional transparency options for light theme */
    background-solid:     rgba(${BG_RGB}, 1.0);
    background-slight:    rgba(${BG_RGB}, 0.92);
    background-medium:    rgba(${BG_RGB}, 0.85);
    background-high:      rgba(${BG_RGB}, 0.70);
    
    /* Selected item with transparency options */
    selected-slight:      rgba($(hex_to_rgb_rofi "$SELECTED_BG"), 0.95);
    selected-medium:      rgba($(hex_to_rgb_rofi "$SELECTED_BG"), 0.85);
    selected-high:        rgba($(hex_to_rgb_rofi "$SELECTED_BG"), 0.75);
}

/* Import this file in your other .rasi configs */
EOL

echo "Generated Rofi colors file (Light Theme) at $ROFI_COLORS" 