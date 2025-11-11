#!/bin/bash

# ============================================================================
# Color Extraction Library for Hyprland Colorgen
# 
# This library provides functions to extract colors from various sources:
# - colors.conf (Material You palette)
# - colors.json (full Material You data)
# - dark_colors.json (dark theme specific)
# - light_colors.json (light theme specific)
# ============================================================================

# Source this file in your scripts with:
# source "$HOME/.config/hypr/colorgen/color_extract.sh"

# Define paths if not already defined
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${COLORGEN_DIR:=$XDG_CONFIG_HOME/hypr/colorgen}"

# ============================================================================
# Extract from colors.conf (Material You palette)
# ============================================================================

# Extract a specific color from colors.conf with fallback support
# Usage: extract_from_conf "primary" "primary-80" "primary-90"
# Returns the first found color, or empty string if none found
extract_from_conf() {
    local colors_conf="${COLORGEN_DIR}/colors.conf"
    
    if [ ! -f "$colors_conf" ]; then
        return 1
    fi
    
    # Try each color name in order
    for color_name in "$@"; do
        local color=$(grep -E "^${color_name} = " "$colors_conf" | cut -d" " -f3 | tr -d ' ')
        if [ -n "$color" ]; then
            # Ensure # prefix
            if [[ ! "$color" =~ ^# ]]; then
                color="#$color"
            fi
            echo "$color"
            return 0
        fi
    done
    
    return 1
}

# Extract all Material You tonal palette colors from colors.conf
# Sets variables: primary, primary_80, primary_90, primary_95, primary_99, etc.
extract_material_palette() {
    local colors_conf="${1:-$COLORGEN_DIR/colors.conf}"
    
    if [ ! -f "$colors_conf" ]; then
        return 1
    fi
    
    # Extract tonal palette for primary
    primary=$(extract_from_conf "primary")
    primary_80=$(extract_from_conf "primary-80" "primary")
    primary_90=$(extract_from_conf "primary-90" "primary-80" "primary")
    primary_95=$(extract_from_conf "primary-95" "primary-90" "primary-80" "primary")
    primary_99=$(extract_from_conf "primary-99" "primary-95" "primary-90")
    
    # Extract other colors
    secondary=$(extract_from_conf "secondary")
    tertiary=$(extract_from_conf "tertiary")
    error=$(extract_from_conf "error")
    
    # Extract accent colors
    accent=$(extract_from_conf "accent" "primary")
    accent_dark=$(extract_from_conf "accent_dark" "accent")
    accent_light=$(extract_from_conf "accent_light" "accent")
    
    # Extract surface colors (using color palette)
    surface_dim=$(extract_from_conf "color0")
    surface=$(extract_from_conf "color1")
    surface_bright=$(extract_from_conf "color7")
    
    # Extract outline colors
    outline=$(extract_from_conf "color3")
    outline_variant=$(extract_from_conf "color4")
}

# ============================================================================
# Extract from JSON files (colors.json, dark_colors.json, light_colors.json)
# ============================================================================

# Extract a color from a JSON file using jq
# Usage: extract_from_json "colors.json" ".colors.dark.primary"
extract_from_json() {
    local json_file="$1"
    local json_path="$2"
    local default_value="${3:-}"
    
    local full_path="${COLORGEN_DIR}/${json_file}"
    
    if [ ! -f "$full_path" ]; then
        echo "$default_value"
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "$default_value"
        return 1
    fi
    
    local color=$(jq -r "$json_path" "$full_path" 2>/dev/null)
    
    # Check if jq returned null or empty
    if [ -z "$color" ] || [ "$color" = "null" ]; then
        echo "$default_value"
        return 1
    fi
    
    # Ensure # prefix for hex colors
    if [[ "$color" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        color="#$color"
    fi
    
    echo "$color"
    return 0
}

# Extract dark theme colors from dark_colors.json
# Sets variables: dark_background, dark_surface, dark_primary, etc.
extract_dark_colors() {
    local json_file="${1:-dark_colors.json}"
    
    # Background and surface colors
    dark_background=$(extract_from_json "$json_file" ".background" "#1b1b1f")
    dark_surface=$(extract_from_json "$json_file" ".surface" "#1b1b1f")
    dark_surface_dim=$(extract_from_json "$json_file" ".surface_dim" "#131316")
    dark_surface_bright=$(extract_from_json "$json_file" ".surface_bright" "#3b3b3f")
    dark_surface_container=$(extract_from_json "$json_file" ".surface_container" "#1f1f23")
    dark_surface_container_low=$(extract_from_json "$json_file" ".surface_container_low" "#1b1b1f")
    dark_surface_container_high=$(extract_from_json "$json_file" ".surface_container_high" "#26262a")
    dark_surface_container_highest=$(extract_from_json "$json_file" ".surface_container_highest" "#313135")
    
    # Primary colors
    dark_primary=$(extract_from_json "$json_file" ".primary" "#bcc2ff")
    dark_on_primary=$(extract_from_json "$json_file" ".on_primary" "#1e2578")
    dark_primary_container=$(extract_from_json "$json_file" ".primary_container" "#353b90")
    dark_on_primary_container=$(extract_from_json "$json_file" ".on_primary_container" "#e0e0ff")
    
    # Secondary colors
    dark_secondary=$(extract_from_json "$json_file" ".secondary" "#c4c5dd")
    dark_on_secondary=$(extract_from_json "$json_file" ".on_secondary" "#2d2f42")
    dark_secondary_container=$(extract_from_json "$json_file" ".secondary_container" "#434559")
    dark_on_secondary_container=$(extract_from_json "$json_file" ".on_secondary_container" "#e0e0f9")
    
    # Tertiary colors
    dark_tertiary=$(extract_from_json "$json_file" ".tertiary" "#e6bad6")
    dark_on_tertiary=$(extract_from_json "$json_file" ".on_tertiary" "#44263d")
    dark_tertiary_container=$(extract_from_json "$json_file" ".tertiary_container" "#5d3c54")
    dark_on_tertiary_container=$(extract_from_json "$json_file" ".on_tertiary_container" "#ffd7f1")
    
    # Error colors
    dark_error=$(extract_from_json "$json_file" ".error" "#ffb4ab")
    dark_on_error=$(extract_from_json "$json_file" ".on_error" "#690005")
    dark_error_container=$(extract_from_json "$json_file" ".error_container" "#93000a")
    dark_on_error_container=$(extract_from_json "$json_file" ".on_error_container" "#ffdad6")
    
    # Text colors
    dark_on_surface=$(extract_from_json "$json_file" ".on_surface" "#e4e1e9")
    dark_on_surface_variant=$(extract_from_json "$json_file" ".on_surface_variant" "#c6c5d0")
    
    # Outline colors
    dark_outline=$(extract_from_json "$json_file" ".outline" "#90909a")
    dark_outline_variant=$(extract_from_json "$json_file" ".outline_variant" "#46464f")
}

# Extract light theme colors from light_colors.json
# Sets variables: light_background, light_surface, light_primary, etc.
extract_light_colors() {
    local json_file="${1:-light_colors.json}"
    
    # Background and surface colors
    light_background=$(extract_from_json "$json_file" ".background" "#fef7ff")
    light_surface=$(extract_from_json "$json_file" ".surface" "#fef7ff")
    light_surface_dim=$(extract_from_json "$json_file" ".surface_dim" "#ded8e1")
    light_surface_bright=$(extract_from_json "$json_file" ".surface_bright" "#fef7ff")
    light_surface_container=$(extract_from_json "$json_file" ".surface_container" "#f3edf7")
    light_surface_container_low=$(extract_from_json "$json_file" ".surface_container_low" "#f7f2fa")
    light_surface_container_high=$(extract_from_json "$json_file" ".surface_container_high" "#ece6f0")
    light_surface_container_highest=$(extract_from_json "$json_file" ".surface_container_highest" "#e6e0e9")
    
    # Primary colors
    light_primary=$(extract_from_json "$json_file" ".primary" "#4a4ba8")
    light_on_primary=$(extract_from_json "$json_file" ".on_primary" "#ffffff")
    light_primary_container=$(extract_from_json "$json_file" ".primary_container" "#e0e0ff")
    light_on_primary_container=$(extract_from_json "$json_file" ".on_primary_container" "#00006e")
    
    # Secondary colors
    light_secondary=$(extract_from_json "$json_file" ".secondary" "#5d5d72")
    light_on_secondary=$(extract_from_json "$json_file" ".on_secondary" "#ffffff")
    light_secondary_container=$(extract_from_json "$json_file" ".secondary_container" "#e2e0f9")
    light_on_secondary_container=$(extract_from_json "$json_file" ".on_secondary_container" "#191a2c")
    
    # Tertiary colors
    light_tertiary=$(extract_from_json "$json_file" ".tertiary" "#7d5260")
    light_on_tertiary=$(extract_from_json "$json_file" ".on_tertiary" "#ffffff")
    light_tertiary_container=$(extract_from_json "$json_file" ".tertiary_container" "#ffd8e4")
    light_on_tertiary_container=$(extract_from_json "$json_file" ".on_tertiary_container" "#31111d")
    
    # Error colors
    light_error=$(extract_from_json "$json_file" ".error" "#ba1a1a")
    light_on_error=$(extract_from_json "$json_file" ".on_error" "#ffffff")
    light_error_container=$(extract_from_json "$json_file" ".error_container" "#ffdad6")
    light_on_error_container=$(extract_from_json "$json_file" ".on_error_container" "#410002")
    
    # Text colors
    light_on_surface=$(extract_from_json "$json_file" ".on_surface" "#1c1b1f")
    light_on_surface_variant=$(extract_from_json "$json_file" ".on_surface_variant" "#49454f")
    
    # Outline colors
    light_outline=$(extract_from_json "$json_file" ".outline" "#79747e")
    light_outline_variant=$(extract_from_json "$json_file" ".outline_variant" "#c9c5d0")
}

# Extract colors from main colors.json (contains both dark and light)
# Usage: extract_colors_json "dark" or extract_colors_json "light"
extract_colors_json() {
    local theme="${1:-dark}"
    local json_file="colors.json"
    
    if [ "$theme" = "dark" ]; then
        # Extract from .colors.dark path
        dark_background=$(extract_from_json "$json_file" ".colors.dark.background")
        dark_surface=$(extract_from_json "$json_file" ".colors.dark.surface")
        dark_primary=$(extract_from_json "$json_file" ".colors.dark.primary")
        dark_on_primary=$(extract_from_json "$json_file" ".colors.dark.on_primary")
        dark_secondary=$(extract_from_json "$json_file" ".colors.dark.secondary")
        dark_tertiary=$(extract_from_json "$json_file" ".colors.dark.tertiary")
        dark_on_surface=$(extract_from_json "$json_file" ".colors.dark.on_surface")
    else
        # Extract from .colors.light path
        light_background=$(extract_from_json "$json_file" ".colors.light.background")
        light_surface=$(extract_from_json "$json_file" ".colors.light.surface")
        light_primary=$(extract_from_json "$json_file" ".colors.light.primary")
        light_on_primary=$(extract_from_json "$json_file" ".colors.light.on_primary")
        light_secondary=$(extract_from_json "$json_file" ".colors.light.secondary")
        light_tertiary=$(extract_from_json "$json_file" ".colors.light.tertiary")
        light_on_surface=$(extract_from_json "$json_file" ".colors.light.on_surface")
    fi
}

# ============================================================================
# Convenience Functions
# ============================================================================

# Get the best available primary color from any source
get_primary_color() {
    local color
    
    # Try colors.conf first
    color=$(extract_from_conf "primary")
    if [ -n "$color" ]; then
        echo "$color"
        return 0
    fi
    
    # Try dark_colors.json
    color=$(extract_from_json "dark_colors.json" ".primary")
    if [ -n "$color" ]; then
        echo "$color"
        return 0
    fi
    
    # Try light_colors.json
    color=$(extract_from_json "light_colors.json" ".primary")
    if [ -n "$color" ]; then
        echo "$color"
        return 0
    fi
    
    # Default fallback
    echo "#bcc2ff"
    return 1
}

# Get the best available accent color from any source
get_accent_color() {
    local color
    
    # Try colors.conf first
    color=$(extract_from_conf "accent" "primary")
    if [ -n "$color" ]; then
        echo "$color"
        return 0
    fi
    
    # Fallback to primary
    get_primary_color
}

# Get surface color for current theme
get_surface_color() {
    local theme="${1:-dark}"
    local color
    
    if [ "$theme" = "dark" ]; then
        color=$(extract_from_json "dark_colors.json" ".surface")
        [ -z "$color" ] && color="#1b1b1f"
    else
        color=$(extract_from_json "light_colors.json" ".surface")
        [ -z "$color" ] && color="#fef7ff"
    fi
    
    echo "$color"
}
