#!/bin/bash

# ============================================================================
# KDE Dark Theme Application Script for Hyprland Colorgen
# 
# This script applies the Material You dark theme settings to KDE by modifying
# the kdeglobals file with colors from colors.conf
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
KDE_CONFIG="$HOME/.config/kdeglobals"
KDE_TEMPLATE="$COLORGEN_DIR/templates/kde/kdeglobals"
KDE_BACKUP="$HOME/.config/kdeglobals.backup"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/kde"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


log "INFO" "Applying KDE dark theme with Material You colors"

# Create a backup of the original kdeglobals file if it doesn't exist
if [ -f "$KDE_CONFIG" ] && [ ! -f "$KDE_BACKUP" ]; then
    log "INFO" "Creating backup of original kdeglobals file"
    cp "$KDE_CONFIG" "$KDE_BACKUP"
fi

# Check if template exists
if [ ! -f "$KDE_TEMPLATE" ]; then
    log "ERROR" "Template file not found for KDE colors: $KDE_TEMPLATE"
    exit 1
fi

# Copy template to working file
cp "$KDE_TEMPLATE" "$CACHE_DIR/generated/kde/kdeglobals"

# Note: darken_color and lighten_color are now provided by color_utils.sh

# Function to convert hex color to RGB format (r,g,b) - KDE specific format
hex_to_rgb_kde() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r,$g,$b"
}

# Function to convert hex color to RGBA format (r,g,b,a) - KDE specific format
hex_to_rgba() {
    local hex=$1
    local alpha=$2
    local rgb=$(hex_to_rgb_kde "$hex")
    echo "$rgb,$alpha"
}

# Function to increase saturation (make more vibrant)
increase_saturation() {
    local hex=$1
    local percent=$2
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Convert RGB to HSL
    local max=$(( r > g ? (r > b ? r : b) : (g > b ? g : b) ))
    local min=$(( r < g ? (r < b ? r : b) : (g < b ? g : b) ))
    
    # Calculate lightness
    local l=$(( (max + min) / 2 ))
    
    # Calculate saturation
    local s=0
    if [ $max -ne $min ]; then
        if [ $l -le 127 ]; then
            s=$(( 255 * (max - min) / (max + min) ))
        else
            s=$(( 255 * (max - min) / (510 - max - min) ))
        fi
    fi
    
    # Increase saturation
    s=$(( s * (100 + percent) / 100 ))
    s=$(( s > 255 ? 255 : s ))
    
    # For simplicity, we'll just increase the difference between RGB values
    # This is a simplified approach to increase perceived saturation
    local avg=$(( (r + g + b) / 3 ))
    r=$(( r + (r - avg) * percent / 100 ))
    g=$(( g + (g - avg) * percent / 100 ))
    b=$(( b + (b - avg) * percent / 100 ))
    
    # Ensure values are in range
    r=$(( r > 255 ? 255 : (r < 0 ? 0 : r) ))
    g=$(( g > 255 ? 255 : (g < 0 ? 0 : g) ))
    b=$(( b > 255 ? 255 : (b < 0 ? 0 : b) ))
    
    # Convert back to hex
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Note: calculate_brightness is now provided by color_utils.sh

# Generate a hash for the color scheme
generate_color_hash() {
    echo "$(date +%s)_$(echo $RANDOM | md5sum | head -c 16)"
}

# Get icon theme from file or use default
get_icon_theme() {
    local default_theme="Papirus-Dark"
    if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
        local theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
        echo "${theme:-$default_theme}"
    else
        echo "$default_theme"
    fi
}

# Extract color variables from colors.conf
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    # Read key values from colors.conf
    primary=$(grep -E "^primary = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    primary_90=$(grep -E "^primary-90 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    primary_80=$(grep -E "^primary-80 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    primary_30=$(grep -E "^primary-30 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    primary_20=$(grep -E "^primary-20 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    secondary=$(grep -E "^secondary = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    tertiary=$(grep -E "^tertiary = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    
    # Calculate brightness of primary color
    primary_brightness=$(calculate_brightness "$primary")
    log "INFO" "Primary color brightness: $primary_brightness (0-255)"
    
    # Dark theme colors
    background=$(darken_color "$primary_20" 30)
    onBackground=$primary_90
    surface=$(darken_color "$primary_20" 20)
    surfaceDim=$(darken_color "$primary_30" 10)
    onSurface=$(increase_saturation "$primary_90" 10)
    # Ensure onPrimary has good contrast against primary (white text on colored buttons)
    onPrimary="#000000"
    error=$(increase_saturation "$primary" 30)
    onError=$(increase_saturation "$primary_20" 10)
    
    # Sidebar color with adjustable brightness (slightly lighter than background)
    sidebarBg=$(lighten_color "$background" 10)
    
    # Sidebar backdrop color
    sidebarBackdrop=$(darken_color "$primary" 50)
    
    # Boost primary color for more pop
    primary=$(increase_saturation "$primary" 30)
    
    # More vibrant accent colors
    secondary=$(increase_saturation "$secondary" 40)
    tertiary=$(increase_saturation "$tertiary" 40)
    
    # Use accent color from primary
    accent=$primary
    
    log "INFO" "Primary color: $primary"
    log "INFO" "Background color: $background"
    log "INFO" "Surface color: $surface"
    log "INFO" "Sidebar color: $sidebarBg"
    
    # Set main colors for KDE
    decorationFocus=$(hex_to_rgb_kde "$primary")
    decorationHover=$(hex_to_rgb_kde "$primary")
    
    # Button colors
    buttonBackground=$(hex_to_rgb_kde "$surface")
    buttonBackgroundAlt=$(hex_to_rgb_kde "$surfaceDim")
    buttonForeground=$(hex_to_rgb_kde "$onSurface")
    
    # Window colors
    windowBackground=$(hex_to_rgb_kde "$background")
    windowBackgroundAlt=$(hex_to_rgb_kde "$surface")
    windowForeground=$(hex_to_rgb_kde "$onBackground")
    
    # View colors (content areas)
    viewBackground=$(hex_to_rgb_kde "$surface")
    viewBackgroundAlt=$(hex_to_rgb_kde "$surfaceDim")
    viewForeground=$(hex_to_rgb_kde "$onSurface")
    
    # Header colors
    headerBackground=$(hex_to_rgb_kde "$surfaceDim")
    headerBackgroundAlt=$(hex_to_rgb_kde "$surface")
    headerForeground=$(hex_to_rgb_kde "$onSurface")
    
    # Header inactive colors
    headerInactiveBackground=$(hex_to_rgb_kde "$background")
    headerInactiveBackgroundAlt=$(hex_to_rgb_kde "$surface")
    headerInactiveForeground=$(hex_to_rgb_kde "$onBackground")
    
    # Tooltip colors
    tooltipBackground=$(hex_to_rgb_kde "$surfaceDim")
    tooltipBackgroundAlt=$(hex_to_rgb_kde "$surface")
    tooltipForeground=$(hex_to_rgb_kde "$onSurface")
    
    # Complementary colors
    compBackground=$(hex_to_rgb_kde "$surfaceDim")
    compBackgroundAlt=$(hex_to_rgb_kde "$surface")
    compForeground=$(hex_to_rgb_kde "$onSurface")
    
    # Selection colors
    selectionBackground=$(hex_to_rgb_kde "$primary")
    selectionBackgroundAlt=$(hex_to_rgb_kde "$primary")
    selectionForeground=$(hex_to_rgb_kde "$onPrimary")
    selectionActiveForeground=$(hex_to_rgb_kde "$onPrimary")
    selectionLinkForeground=$(hex_to_rgb_kde "$secondary")
    selectionNegativeForeground=$(hex_to_rgb_kde "$error")
    selectionNeutralForeground=$(hex_to_rgb_kde "$tertiary")
    selectionPositiveForeground=$(hex_to_rgb_kde "$primary")
    
    # Common foreground colors
    activeForeground=$(hex_to_rgb_kde "$primary")
    inactiveForeground=$(hex_to_rgb_kde "$onBackground")
    linkForeground=$(hex_to_rgb_kde "$primary")
    negativeForeground=$(hex_to_rgb_kde "$error")
    neutralForeground=$(hex_to_rgb_kde "$tertiary")
    positiveForeground=$(hex_to_rgb_kde "$secondary")
    visitedForeground=$(hex_to_rgb_kde "$tertiary")
    
    # Window Manager colors
    wmActiveBackground=$(hex_to_rgb_kde "$surfaceDim")
    wmActiveBlend=$(hex_to_rgb_kde "$onSurface")
    wmActiveForeground=$(hex_to_rgb_kde "$onSurface")
    wmInactiveBackground=$(hex_to_rgb_kde "$background")
    wmInactiveBlend=$(hex_to_rgb_kde "$onBackground")
    wmInactiveForeground=$(hex_to_rgb_kde "$onBackground")
    wmFrame=$(hex_to_rgb_kde "$primary")
    wmInactiveFrame=$(hex_to_rgb_kde "$surface")
    
    # Accent color with alpha
    accentColorRgba=$(hex_to_rgba "$primary" 1.0)

    # Generate a hash for the color scheme
    colorSchemeHash=$(generate_color_hash)
    
    # Set LookAndFeelPackage for dark theme
    lookAndFeelPackage="org.kde.breezedark.desktop"
    
    # Get icon theme from icon_theme.txt if it exists
    iconTheme="Fluent-dark"  # Default for dark theme
    if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
        icon_theme_from_file=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt" | tr -d '\n')
        # If not empty, use the icon theme from file
        if [ -n "$icon_theme_from_file" ]; then
            # Make sure we're using the dark version (add -dark suffix if not present)
            if [[ "$icon_theme_from_file" != *"-dark" ]]; then
                iconTheme="${icon_theme_from_file}-dark"
            else
                iconTheme="$icon_theme_from_file"
            fi
            log "INFO" "Using icon theme from icon_theme.txt: $iconTheme"
        fi
    fi

    log "INFO" "Primary color: $primary"
    log "INFO" "Accent color: $accent"
    
    # Define color arrays for template replacement
    declare -A color_map=(
        ["{{ \$buttonBackgroundAlt }}"]="$buttonBackgroundAlt"
        ["{{ \$buttonBackground }}"]="$buttonBackground"
        ["{{ \$decorationFocus }}"]="$decorationFocus"
        ["{{ \$decorationHover }}"]="$decorationHover"
        ["{{ \$activeForeground }}"]="$activeForeground"
        ["{{ \$inactiveForeground }}"]="$inactiveForeground"
        ["{{ \$linkForeground }}"]="$linkForeground"
        ["{{ \$negativeForeground }}"]="$negativeForeground"
        ["{{ \$neutralForeground }}"]="$neutralForeground"
        ["{{ \$buttonForeground }}"]="$buttonForeground"
        ["{{ \$positiveForeground }}"]="$positiveForeground"
        ["{{ \$visitedForeground }}"]="$visitedForeground"
        ["{{ \$compBackgroundAlt }}"]="$compBackgroundAlt"
        ["{{ \$compBackground }}"]="$compBackground"
        ["{{ \$compForeground }}"]="$compForeground"
        ["{{ \$headerBackgroundAlt }}"]="$headerBackgroundAlt"
        ["{{ \$headerBackground }}"]="$headerBackground"
        ["{{ \$headerForeground }}"]="$headerForeground"
        ["{{ \$headerInactiveBackgroundAlt }}"]="$headerInactiveBackgroundAlt"
        ["{{ \$headerInactiveBackground }}"]="$headerInactiveBackground"
        ["{{ \$headerInactiveForeground }}"]="$headerInactiveForeground"
        ["{{ \$selectionBackgroundAlt }}"]="$selectionBackgroundAlt"
        ["{{ \$selectionBackground }}"]="$selectionBackground"
        ["{{ \$selectionActiveForeground }}"]="$selectionActiveForeground"
        ["{{ \$selectionLinkForeground }}"]="$selectionLinkForeground"
        ["{{ \$selectionNegativeForeground }}"]="$selectionNegativeForeground"
        ["{{ \$selectionNeutralForeground }}"]="$selectionNeutralForeground"
        ["{{ \$selectionForeground }}"]="$selectionForeground"
        ["{{ \$selectionPositiveForeground }}"]="$selectionPositiveForeground"
        ["{{ \$tooltipBackgroundAlt }}"]="$tooltipBackgroundAlt"
        ["{{ \$tooltipBackground }}"]="$tooltipBackground"
        ["{{ \$tooltipForeground }}"]="$tooltipForeground"
        ["{{ \$viewBackgroundAlt }}"]="$viewBackgroundAlt"
        ["{{ \$viewBackground }}"]="$viewBackground"
        ["{{ \$viewForeground }}"]="$viewForeground"
        ["{{ \$windowBackgroundAlt }}"]="$windowBackgroundAlt"
        ["{{ \$windowBackground }}"]="$windowBackground"
        ["{{ \$windowForeground }}"]="$windowForeground"
        ["{{ \$colorSchemeHash }}"]="$colorSchemeHash"
        ["{{ \$wmActiveBackground }}"]="$wmActiveBackground"
        ["{{ \$wmActiveBlend }}"]="$wmActiveBlend"
        ["{{ \$wmActiveForeground }}"]="$wmActiveForeground"
        ["{{ \$wmInactiveBackground }}"]="$wmInactiveBackground"
        ["{{ \$wmInactiveBlend }}"]="$wmInactiveBlend"
        ["{{ \$wmInactiveForeground }}"]="$wmInactiveForeground"
        ["{{ \$wmFrame }}"]="$wmFrame"
        ["{{ \$wmInactiveFrame }}"]="$wmInactiveFrame"
        ["{{ \$accentColorRgba }}"]="$accentColorRgba"
        ["{{ \$lookAndFeelPackage }}"]="$lookAndFeelPackage"
        ["{{ \$iconTheme }}"]="$iconTheme"
    )
    
    # Replace all placeholders in the template
    for key in "${!color_map[@]}"; do
        sed -i "s|$key|${color_map[$key]}|g" "$CACHE_DIR/generated/kde/kdeglobals"
    done
    
    # Apply the generated kdeglobals file
    cp "$CACHE_DIR/generated/kde/kdeglobals" "$KDE_CONFIG"
    log "INFO" "Applied KDE dark color scheme to $KDE_CONFIG"
    
    # Create color scheme file in KDE's color schemes directory
    KDE_COLORS_DIR="$HOME/.local/share/color-schemes"
    mkdir -p "$KDE_COLORS_DIR"
    cp "$CACHE_DIR/generated/kde/kdeglobals" "$KDE_COLORS_DIR/MaterialYouDark.colors"
    log "INFO" "Saved dark color scheme to $KDE_COLORS_DIR/MaterialYouDark.colors"
    
    # Reload KDE settings if running in KDE
    if command -v qdbus &> /dev/null; then
        log "INFO" "Reloading KDE settings"
        if pgrep -x "plasmashell" > /dev/null; then
            qdbus org.kde.KWin /KWin reconfigure || true
            qdbus org.kde.plasmashell /PlasmaShell refreshCurrentShell || true
            log "INFO" "KDE Plasma settings reloaded"
        elif pgrep -x "kwin_x11" > /dev/null || pgrep -x "kwin_wayland" > /dev/null; then
            # For KDE without Plasma (KDE Neon, etc.)
            qdbus org.kde.KWin /KWin reconfigure || true
            log "INFO" "KWin settings reloaded"
        else
            log "INFO" "No running KDE components detected"
        fi
        
        # Reload GTK integration if available
        if command -v kde-gtk-config &> /dev/null; then
            kde-gtk-config --reload-gtk || true
            log "INFO" "GTK integration reloaded"
        fi
    else
        log "INFO" "qdbus not available, skipping KDE settings reload"
    fi
    
else
    log "ERROR" "colors.conf not found: $COLORGEN_DIR/colors.conf"
    exit 1
fi

log "INFO" "KDE dark theme application completed"
exit 0 