#!/bin/bash

# rofi.sh (Light Theme) - Generate a .rasi file with colors from colors.conf
# This script creates/updates a colors.rasi file for rofi with colors matching waybar
# Modified for light theme with appropriate contrast and readability

# Path to the generated color files
COLORS_CONF="$HOME/.config/hypr/colorgen/colors.conf"
LIGHT_COLORS_JSON="$HOME/.config/hypr/colorgen/light_colors.json"
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"

# Quick exit if colors.conf doesn't exist
[ ! -f "$COLORS_CONF" ] && exit 1
[ ! -f "$LIGHT_COLORS_JSON" ] && exit 1

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

# Function to darken a color by reducing RGB values by a fixed percentage
darken_color() {
    local hex=$1
    local percent=$2
    [ -z "$percent" ] && percent=40  # Default: Darken by 40%
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
    local percent=$2
    [ -z "$percent" ] && percent=40  # Default: Lighten by 40%
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

# Function to ensure color has enough contrast with white background
ensure_dark_enough() {
    local color=$1
    local min_darkness=60  # Minimum darkness percentage
    
    # If the color is already dark enough, return it as is
    if [ "$(is_light "$color")" -eq 0 ]; then
        echo "$color"
        return
    fi
    
    # Otherwise darken it to ensure visibility on light background
    darken_color "$color" $min_darkness
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
    selected-slight:      rgba($(hex_to_rgb "$SELECTED_BG"), 0.95);
    selected-medium:      rgba($(hex_to_rgb "$SELECTED_BG"), 0.85);
    selected-high:        rgba($(hex_to_rgb "$SELECTED_BG"), 0.75);
}

/* Import this file in your other .rasi configs */
EOL

echo "Generated Rofi colors file (Light Theme) at $ROFI_COLORS" 