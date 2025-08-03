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

# Function to calculate brightness of a hex color (0-255)
calculate_brightness() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Calculate brightness
    local brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    
    echo "$brightness"
}

# Generate a hash for the color scheme
generate_color_hash() {
    echo "$(date +%s)_$(echo $RANDOM | md5sum | head -c 16)"
}

# Extract color variables from colors.conf
if [ -f "$COLORGEN_DIR/light_colors.json" ]; then
    # Function to extract colors from JSON
    extract_color() {
        local color_name=$1
        local default_color=$2
        local color=$(jq -r ".$color_name" "$COLORGEN_DIR/light_colors.json" 2>/dev/null)
        
        if [ -z "$color" ] || [ "$color" = "null" ]; then
            echo "$default_color"
        else
            echo "$color"
        fi
    }

    # Extract colors from light_colors.json
    primary=$(extract_color "primary" "#884b6b")
    secondary=$(extract_color "secondary" "#725763")
    tertiary=$(extract_color "tertiary" "#7f543a")
    
    # Calculate brightness of primary color
    primary_brightness=$(calculate_brightness "$primary")
    log "INFO" "Primary color brightness: $primary_brightness (0-255)"
    
    # Enhanced light theme colors for a more vibrant look
    # More colorful background with stronger tint (15% color instead of 10%)
    background_tint=$(lighten_color "$primary" 80)
    background_r=$(( (85 * 250 + 15 * $(printf "%d" 0x${background_tint:1:2})) / 100 ))
    background_g=$(( (85 * 250 + 15 * $(printf "%d" 0x${background_tint:3:2})) / 100 ))
    background_b=$(( (85 * 250 + 15 * $(printf "%d" 0x${background_tint:5:2})) / 100 ))
    background=$(printf "#%02x%02x%02x" $background_r $background_g $background_b)
    
    # More vibrant surface color for menus and popups (40% color instead of 30%)
    surface_tint=$(lighten_color "$primary" 55)
    surface_r=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:1:2})) / 100 ))
    surface_g=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:3:2})) / 100 ))
    surface_b=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:5:2})) / 100 ))
    surface=$(printf "#%02x%02x%02x" $surface_r $surface_g $surface_b)
    
    # Enhanced surfaceDim for better hover states and contrast (45% color)
    surfaceDim_tint=$(lighten_color "$primary" 45)
    surfaceDim_r=$(( (55 * 250 + 45 * $(printf "%d" 0x${surfaceDim_tint:1:2})) / 100 ))
    surfaceDim_g=$(( (55 * 250 + 45 * $(printf "%d" 0x${surfaceDim_tint:3:2})) / 100 ))
    surfaceDim_b=$(( (55 * 250 + 45 * $(printf "%d" 0x${surfaceDim_tint:5:2})) / 100 ))
    surfaceDim=$(printf "#%02x%02x%02x" $surfaceDim_r $surfaceDim_g $surfaceDim_b)
    
    # Boost primary color for more pop
    primary=$(increase_saturation "$primary" 30)
    
    # Make buttons use a light color matching the background tint
    buttonBgColor=$(lighten_color "$primary" 70)  # Light pink color similar to dialog background
    
    # More vibrant accent colors
    secondary=$(increase_saturation "$secondary" 40)
    tertiary=$(increase_saturation "$tertiary" 40)
    
    # Better text contrast - use Material You colors
    onBackground=$(extract_color "on_surface" "#1c1b1f")  # Use Material You on_surface for text
    onSurface=$(extract_color "on_surface" "#1c1b1f")  # Use Material You on_surface for text  
    onPrimary=$(extract_color "on_primary" "#ffffff")  # Use Material You on_primary for button text
    error=$(increase_saturation "$secondary" 40)  # More vibrant error color
    onError="#FFFFFF"  # White text on error color
    
    # Sidebar color with adjustable brightness (slightly darker than background)
    sidebarBg=$(darken_color "$background" 5)
    
    # Sidebar backdrop color
    sidebarBackdrop=$(lighten_color "$primary" 70)
    
    # Use accent color from primary
    accent=$primary
    
    log "INFO" "Using enhanced light theme with vibrant colors and darker buttons"
    log "INFO" "Primary color: $primary"
    log "INFO" "Background color: $background"
    log "INFO" "Surface color: $surface"
    log "INFO" "Sidebar color: $sidebarBg"
    
    # Set main colors for KDE
    decorationFocus=$(hex_to_rgb "$primary")
    decorationHover=$(hex_to_rgb "$primary")
    
    # Button colors - light theme uses lighter colors
    buttonBackground=$(hex_to_rgb "$surface")
    buttonBackgroundAlt=$(hex_to_rgb "$surfaceDim")
    buttonForeground=$(hex_to_rgb "$onSurface")
    
    # Window colors - light theme uses white/light colors
    windowBackground=$(hex_to_rgb "$background")
    windowBackgroundAlt=$(hex_to_rgb "#ffffff")
    windowForeground=$(hex_to_rgb "$onBackground")
    
    # View colors (content areas)
    viewBackground=$(hex_to_rgb "$surface")
    viewBackgroundAlt=$(hex_to_rgb "#f5f5f5")
    viewForeground=$(hex_to_rgb "$onSurface")
    
    # Header colors
    headerBackground=$(hex_to_rgb "$surfaceDim")
    headerBackgroundAlt=$(hex_to_rgb "$surface")
    headerForeground=$(hex_to_rgb "$onSurface")
    
    # Header inactive colors
    headerInactiveBackground=$(hex_to_rgb "#f0f0f0")
    headerInactiveBackgroundAlt=$(hex_to_rgb "$surface")
    headerInactiveForeground=$(hex_to_rgb "$onSurface")
    
    # Tooltip colors
    tooltipBackground=$(hex_to_rgb "$surfaceDim")
    tooltipBackgroundAlt=$(hex_to_rgb "$surface")
    tooltipForeground=$(hex_to_rgb "$onSurface")
    
    # Complementary colors
    compBackground=$(hex_to_rgb "$surfaceDim")
    compBackgroundAlt=$(hex_to_rgb "$surface")
    compForeground=$(hex_to_rgb "$onSurface")
    
    # Selection colors
    selectionBackground=$(hex_to_rgb "$primary")
    selectionBackgroundAlt=$(hex_to_rgb $(lighten_color "$primary" 15))
    selectionForeground=$(hex_to_rgb "$onPrimary")  # Proper contrast text for selected items
    selectionActiveForeground=$(hex_to_rgb "$onPrimary")  # Proper contrast text for active selected items
    selectionLinkForeground=$(hex_to_rgb "$secondary")
    selectionNegativeForeground=$(hex_to_rgb "$error")
    selectionNeutralForeground=$(hex_to_rgb "$tertiary")
    selectionPositiveForeground=$(hex_to_rgb "$primary")
    
    # Common foreground colors
    activeForeground=$(hex_to_rgb "$onSurface")  # Dark text for active elements on light backgrounds
    inactiveForeground=$(hex_to_rgb "$onSurface")
    linkForeground=$(hex_to_rgb "$primary")
    negativeForeground=$(hex_to_rgb "$error")
    neutralForeground=$(hex_to_rgb "$tertiary")
    positiveForeground=$(hex_to_rgb "$secondary")
    visitedForeground=$(hex_to_rgb "$tertiary")
    
    # Window Manager colors
    wmActiveBackground=$(hex_to_rgb "$surfaceDim")
    wmActiveBlend=$(hex_to_rgb "$onSurface")
    wmActiveForeground=$(hex_to_rgb "$onSurface")
    wmInactiveBackground=$(hex_to_rgb "#f0f0f0")
    wmInactiveBlend=$(hex_to_rgb "$onSurface")
    wmInactiveForeground=$(hex_to_rgb "$onSurface")
    wmFrame=$(hex_to_rgb "$primary")
    wmInactiveFrame=$(hex_to_rgb $(lighten_color "$primary" 30))
    
    # Accent color with alpha
    accentColorRgba=$(hex_to_rgba "$primary" 1.0)

    # Skip icon theme handling - it's handled by icon-theme.sh
    # Generate a hash for the color scheme
    colorSchemeHash=$(generate_color_hash)
    
    # Set LookAndFeelPackage for light theme
    lookAndFeelPackage="org.kde.breeze.desktop"
    
    # Get icon theme from icon_theme.txt if it exists
    iconTheme="Fluent"  # Default for light theme
    if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
        icon_theme_from_file=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt" | tr -d '\n')
        # If not empty, use the icon theme from file
        if [ -n "$icon_theme_from_file" ]; then
            # Make sure we're using the light version (remove any -dark suffix)
            iconTheme=$(echo "$icon_theme_from_file" | sed 's/-dark$//')
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
    
    # Fix hardcoded white colors in Colors:View section for light theme
    # Replace the hardcoded #FFFFFF values with proper dark text colors
    sed -i 's|ForegroundActive=#FFFFFF|ForegroundActive='"$viewForeground"'|g' "$CACHE_DIR/generated/kde/kdeglobals"
    sed -i 's|ForegroundNormal=#FFFFFF|ForegroundNormal='"$viewForeground"'|g' "$CACHE_DIR/generated/kde/kdeglobals"
    
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
    log "ERROR" "light_colors.json not found: $COLORGEN_DIR/light_colors.json"
    exit 1
fi

log "INFO" "KDE light theme application completed"
exit 0 