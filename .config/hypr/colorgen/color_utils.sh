#!/bin/bash

# ============================================================================
# Color Utilities Library for Hyprland Colorgen
# 
# This library provides common color manipulation and extraction functions
# used across multiple colorgen scripts.
# ============================================================================

# Source this file in your scripts with:
# source "$HOME/.config/hypr/colorgen/color_utils.sh"

# Define paths if not already defined
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${COLORGEN_DIR:=$XDG_CONFIG_HOME/hypr/colorgen}"

# ============================================================================
# Logging Function
# ============================================================================

# Basic logging function with timestamp
# Usage: log "INFO" "message"
# Levels: INFO, WARN, ERROR, DEBUG
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local script_name="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[2]}")}"
    
    echo -e "[${timestamp}] [${script_name}] [${level}] ${message}"
}

# ============================================================================
# Color Extraction Functions
# ============================================================================

# Extract a color value from colors.conf
# Usage: get_color "primary" or get_color "accent"
get_color() {
    local color_name=$1
    local colors_conf="${2:-$COLORGEN_DIR/colors.conf}"
    
    if [ ! -f "$colors_conf" ]; then
        echo ""
        return 1
    fi
    
    local color=$(grep -E "^${color_name} = " "$colors_conf" | cut -d" " -f3)
    
    # Ensure the color has a # prefix
    if [ -n "$color" ] && [[ ! "$color" =~ ^# ]]; then
        color="#$color"
    fi
    
    echo "$color"
}

# Extract all common colors from colors.conf into variables
# Usage: load_colors
# Sets: primary, accent, accent_dark, accent_light, secondary, tertiary, 
#       error, color0-color7
load_colors() {
    local colors_conf="${1:-$COLORGEN_DIR/colors.conf}"
    
    if [ ! -f "$colors_conf" ]; then
        return 1
    fi
    
    primary=$(get_color "primary" "$colors_conf")
    accent=$(get_color "accent" "$colors_conf")
    accent_dark=$(get_color "accent_dark" "$colors_conf")
    accent_light=$(get_color "accent_light" "$colors_conf")
    secondary=$(get_color "secondary" "$colors_conf")
    tertiary=$(get_color "tertiary" "$colors_conf")
    error=$(get_color "error" "$colors_conf")
    
    # Load color palette
    for i in {0..7}; do
        eval "color$i=\$(get_color \"color$i\" \"$colors_conf\")"
    done
}

# ============================================================================
# Color Conversion Functions
# ============================================================================

# Convert hex color to RGB values
# Usage: hex_to_rgb "#ff5733"
# Returns: "255 87 51"
hex_to_rgb() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Handle 3-digit hex colors
    if [ ${#hex} -eq 3 ]; then
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r $g $b"
}

# Convert hex color to RGBA format
# Usage: hex_to_rgba "#ff5733"
# Returns: "rgba(ff5733ff)"
hex_to_rgba() {
    local hex=$1
    echo "rgba(${hex:1:2}${hex:3:2}${hex:5:2}ff)"
}

# Convert hex color to signed 32-bit integer (ARGB format for Chrome)
# Usage: hex_to_chrome_color "#ff5733"
# Returns: signed integer
hex_to_chrome_color() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Ensure we have a full 6-digit hex color
    if [ ${#hex} -eq 3 ]; then
        # Convert 3-digit hex to 6-digit
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    
    # Add alpha channel (FF) for full opacity
    hex="FF$hex"
    
    # Convert hex to decimal
    local decimal=$(printf "%d" 0x$hex)
    
    # Calculate signed 32-bit integer value (Chrome's format)
    if [ $decimal -gt 2147483647 ]; then
        decimal=$((decimal - 4294967296))
    fi
    
    echo $decimal
}

# ============================================================================
# Color Manipulation Functions
# ============================================================================

# Lighten a hex color by a percentage
# Usage: lighten_color "#ff5733" 20
# Returns: lightened hex color
lighten_color() {
    local hex=$1
    local percent=${2:-20}
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Lighten by increasing each component by the percentage of the distance to 255
    r=$(( r + (255 - r) * percent / 100 ))
    g=$(( g + (255 - g) * percent / 100 ))
    b=$(( b + (255 - b) * percent / 100 ))
    
    # Clamp values to 0-255
    [ $r -gt 255 ] && r=255
    [ $g -gt 255 ] && g=255
    [ $b -gt 255 ] && b=255
    
    printf "#%02x%02x%02x" $r $g $b
}

# Darken a hex color by a percentage
# Usage: darken_color "#ff5733" 20
# Returns: darkened hex color
darken_color() {
    local hex=$1
    local percent=${2:-20}
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Darken by reducing each component by the percentage
    r=$(( r * (100 - percent) / 100 ))
    g=$(( g * (100 - percent) / 100 ))
    b=$(( b * (100 - percent) / 100 ))
    
    # Clamp values to 0-255
    [ $r -lt 0 ] && r=0
    [ $g -lt 0 ] && g=0
    [ $b -lt 0 ] && b=0
    
    printf "#%02x%02x%02x" $r $g $b
}

# Calculate brightness of a hex color (0-255)
# Usage: calculate_brightness "#ff5733"
# Returns: brightness value (0-255)
calculate_brightness() {
    local hex=$1
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Use perceived brightness formula
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
}

# ============================================================================
# Color Analysis Functions
# ============================================================================

# Check if a color is grayscale or very desaturated
# Usage: is_grayscale "#808080"
# Returns: 0 if grayscale, 1 if not
is_grayscale() {
    local hex=$1
    local threshold=${2:-10}  # Default threshold: 10 units difference
    
    hex="${hex#\#}"
    
    # Handle 3-digit hex
    if [ ${#hex} -eq 3 ]; then
        if [ "${hex:0:1}" = "${hex:1:1}" ] && [ "${hex:1:1}" = "${hex:2:1}" ]; then
            return 0  # Is grayscale
        fi
        return 1  # Not grayscale
    fi
    
    # Handle 6-digit hex
    if [ ${#hex} -eq 6 ]; then
        local r=$(printf "%d" 0x${hex:0:2})
        local g=$(printf "%d" 0x${hex:2:2})
        local b=$(printf "%d" 0x${hex:4:2})
        
        # Calculate maximum difference between RGB components
        local rg_diff=$(( r > g ? r - g : g - r ))
        local rb_diff=$(( r > b ? r - b : b - r ))
        local gb_diff=$(( g > b ? g - b : b - g ))
        
        local max_diff=$rg_diff
        [ $rb_diff -gt $max_diff ] && max_diff=$rb_diff
        [ $gb_diff -gt $max_diff ] && max_diff=$gb_diff
        
        if [ $max_diff -le $threshold ]; then
            return 0  # Is grayscale
        fi
    fi
    
    return 1  # Not grayscale
}

# Get contrast color (black or white) for a given background color
# Usage: get_contrast_color "#ff5733"
# Returns: "#000000" or "#ffffff"
get_contrast_color() {
    local hex=$1
    local brightness=$(calculate_brightness "$hex")
    
    # If brightness is above 128, use black text, otherwise white
    if [ $brightness -gt 128 ]; then
        echo "#000000"
    else
        echo "#ffffff"
    fi
}

# Ensure a color is dark enough for visibility on light backgrounds
# Usage: ensure_dark_enough "#ff5733" 100
# Returns: darkened color if needed
ensure_dark_enough() {
    local hex=$1
    local min_darkness=${2:-100}  # Minimum darkness (lower brightness value)
    
    local brightness=$(calculate_brightness "$hex")
    
    if [ $brightness -gt $min_darkness ]; then
        # Color is too bright, darken it
        local darken_percent=$(( (brightness - min_darkness) * 100 / 255 ))
        darken_color "$hex" $darken_percent
    else
        echo "$hex"
    fi
}

# Ensure a color is light enough for visibility on dark backgrounds
# Usage: ensure_light_enough "#330000" 150
# Returns: lightened color if needed
ensure_light_enough() {
    local hex=$1
    local min_lightness=${2:-150}  # Minimum lightness (higher brightness value)
    
    local brightness=$(calculate_brightness "$hex")
    
    if [ $brightness -lt $min_lightness ]; then
        # Color is too dark, lighten it
        local lighten_percent=$(( (min_lightness - brightness) * 100 / 255 ))
        lighten_color "$hex" $lighten_percent
    else
        echo "$hex"
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Validate hex color format
# Usage: validate_hex_color "#ff5733"
# Returns: 0 if valid, 1 if invalid
validate_hex_color() {
    local hex=$1
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Check if it's 3 or 6 characters and only contains hex digits
    if [[ "$hex" =~ ^[0-9A-Fa-f]{3}$ ]] || [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        return 0
    fi
    
    return 1
}

# Normalize hex color (ensure # prefix and 6 digits)
# Usage: normalize_hex_color "ff5733"
# Returns: "#ff5733"
normalize_hex_color() {
    local hex=$1
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Expand 3-digit to 6-digit
    if [ ${#hex} -eq 3 ]; then
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    
    echo "#$hex"
}
