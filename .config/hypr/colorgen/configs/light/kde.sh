#!/bin/bash

# ============================================================================
# KDE Light Theme Application Script for Hyprland Colorgen
# 
# This script applies the Material You light theme settings to KDE by modifying
# the kdeglobals file with colors from colors.conf
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
KDE_CONFIG="$HOME/.config/kdeglobals"
KDE_TEMPLATE="$COLORGEN_DIR/templates/kde/kdeglobals"
KDE_BACKUP="$HOME/.config/kdeglobals.backup"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/kde"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying KDE light theme with Material You colors"

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

# Function to convert hex color to RGB format (r,g,b)
hex_to_rgb() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r,$g,$b"
}

# Function to convert hex color to RGBA format (r,g,b,a)
hex_to_rgba() {
    local hex=$1
    local alpha=$2
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r,$g,$b,$alpha"
}

# Function to darken a hex color by percentage
darken_color() {
    local hex=$1
    local percent=$2
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Darken by percentage
    r=$(( r * (100 - percent) / 100 ))
    g=$(( g * (100 - percent) / 100 ))
    b=$(( b * (100 - percent) / 100 ))
    
    # Ensure values are in range
    r=$(( r > 255 ? 255 : r ))
    g=$(( g > 255 ? 255 : g ))
    b=$(( b > 255 ? 255 : b ))
    
    # Convert back to hex
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Function to lighten a hex color by percentage
lighten_color() {
    local hex=$1
    local percent=$2
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Lighten by percentage
    r=$(( r + (255 - r) * percent / 100 ))
    g=$(( g + (255 - g) * percent / 100 ))
    b=$(( b + (255 - b) * percent / 100 ))
    
    # Ensure values are in range
    r=$(( r > 255 ? 255 : r ))
    g=$(( g > 255 ? 255 : g ))
    b=$(( b > 255 ? 255 : b ))
    
    # Convert back to hex
    printf "#%02x%02x%02x" "$r" "$g" "$b"
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

# Generate a hash for the color scheme
generate_color_hash() {
    echo "$(date +%s)_$(echo $RANDOM | md5sum | head -c 16)"
}

# Get icon theme from file or use default
get_icon_theme() {
    local default_theme="Papirus"
    if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
        local theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
        # Remove any -dark suffix for light theme
        theme=$(echo "$theme" | sed 's/-[Dd]ark$//')
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
    accent=$(grep -E "^accent = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    
    # Make primary more vibrant for KDE
    primary=$(increase_saturation "$primary" 20)
    accent=$(increase_saturation "$accent" 30)
    
    # For light theme, we use different color calculations
    
    # Set main colors
    decorationFocus=$(hex_to_rgb "$primary")
    decorationHover=$(hex_to_rgb "$primary")
    
    # Button colors - light theme uses lighter colors
    buttonBackground=$(hex_to_rgb $(lighten_color "$primary_90" 20))
    buttonBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary_80" 30))
    buttonForeground=$(hex_to_rgb "$primary_20")
    
    # Window colors - light theme uses white/light colors
    windowBackground=$(hex_to_rgb "#ffffff")
    windowBackgroundAlt=$(hex_to_rgb "#f8f8f8")
    windowForeground=$(hex_to_rgb "$primary_20")
    
    # View colors (content areas)
    viewBackground=$(hex_to_rgb "#ffffff")
    viewBackgroundAlt=$(hex_to_rgb "#f5f5f5")
    viewForeground=$(hex_to_rgb "$primary_20")
    
    # Header colors
    headerBackground=$(hex_to_rgb $(lighten_color "$primary_90" 10))
    headerBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary_90" 5))
    headerForeground=$(hex_to_rgb "$primary_20")
    
    # Header inactive colors
    headerInactiveBackground=$(hex_to_rgb $(lighten_color "$primary_80" 15))
    headerInactiveBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary_80" 10))
    headerInactiveForeground=$(hex_to_rgb "$primary_30")
    
    # Tooltip colors
    tooltipBackground=$(hex_to_rgb $(lighten_color "$primary_90" 5))
    tooltipBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary_90" 10))
    tooltipForeground=$(hex_to_rgb "$primary_20")
    
    # Complementary colors
    compBackground=$(hex_to_rgb $(lighten_color "$primary_90" 12))
    compBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary_80" 15))
    compForeground=$(hex_to_rgb "$primary_20")
    
    # Selection colors
    selectionBackground=$(hex_to_rgb "$primary")
    selectionBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary" 15))
    selectionForeground=$(hex_to_rgb "#ffffff")
    selectionActiveForeground=$(hex_to_rgb "#ffffff")
    selectionLinkForeground=$(hex_to_rgb $(increase_saturation "$secondary" 20))
    selectionNegativeForeground=$(hex_to_rgb $(increase_saturation "$secondary" 20))
    selectionNeutralForeground=$(hex_to_rgb $(increase_saturation "$tertiary" 20))
    selectionPositiveForeground=$(hex_to_rgb $(increase_saturation "$primary" 10))
    
    # Common foreground colors
    activeForeground=$(hex_to_rgb "$primary")
    inactiveForeground=$(hex_to_rgb "$primary_30")
    linkForeground=$(hex_to_rgb $(increase_saturation "$primary" 10))
    negativeForeground=$(hex_to_rgb $(increase_saturation "$secondary" 30))
    neutralForeground=$(hex_to_rgb $(increase_saturation "$tertiary" 30))
    positiveForeground=$(hex_to_rgb $(increase_saturation "$primary" 10))
    visitedForeground=$(hex_to_rgb $(increase_saturation "$tertiary" 10))
    
    # Window Manager colors
    wmActiveBackground=$(hex_to_rgb $(lighten_color "$primary_90" 10))
    wmActiveBlend=$(hex_to_rgb "$primary_20")
    wmActiveForeground=$(hex_to_rgb "$primary_20")
    wmInactiveBackground=$(hex_to_rgb $(lighten_color "$primary_90" 20))
    wmInactiveBlend=$(hex_to_rgb "$primary_30")
    wmInactiveForeground=$(hex_to_rgb "$primary_30")
    wmFrame=$(hex_to_rgb "$primary")
    wmInactiveFrame=$(hex_to_rgb $(lighten_color "$primary" 30))
    
    # Accent color with alpha
    accentColorRgba=$(hex_to_rgba "$primary" 1.0)
    
    # Get icon theme - ensure light theme
    iconTheme=$(get_icon_theme)
    
    # Generate a hash for the color scheme
    colorSchemeHash=$(generate_color_hash)
    
    log "INFO" "Primary color: $primary"
    log "INFO" "Accent color: $accent"
    log "INFO" "Icon theme: $iconTheme"
    
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
        ["{{ \$iconTheme }}"]="$iconTheme"
    )
    
    # Replace all placeholders in the template
    for key in "${!color_map[@]}"; do
        sed -i "s|$key|${color_map[$key]}|g" "$CACHE_DIR/generated/kde/kdeglobals"
    done
    
    # Apply the generated kdeglobals file
    cp "$CACHE_DIR/generated/kde/kdeglobals" "$KDE_CONFIG"
    log "INFO" "Applied KDE light color scheme to $KDE_CONFIG"
    
    # Create color scheme file in KDE's color schemes directory
    KDE_COLORS_DIR="$HOME/.local/share/color-schemes"
    mkdir -p "$KDE_COLORS_DIR"
    cp "$CACHE_DIR/generated/kde/kdeglobals" "$KDE_COLORS_DIR/MaterialYouLight.colors"
    log "INFO" "Saved light color scheme to $KDE_COLORS_DIR/MaterialYouLight.colors"
    
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

log "INFO" "KDE light theme application completed"
exit 0 