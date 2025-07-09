#!/bin/bash

# ============================================================================
# GTK Theme Application Script for Hyprland Colorgen (LIGHT MODE)
# 
# This script applies the Material You theme settings to GTK in light mode
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/gtk"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying GTK light theme with Material You colors"

# Compute checksum of the colors.conf used as the source of truth
COLOR_CONF_CHECKSUM_FILE="$CACHE_DIR/generated/gtk/colors.conf.md5"
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    CURRENT_CHECKSUM=$(md5sum "$COLORGEN_DIR/colors.conf" | cut -d" " -f1)
    # We still calculate the checksum for logging purposes but don't exit early
    log "INFO" "Processing colors.conf with checksum: $CURRENT_CHECKSUM"
fi

# Check if template exists
if [ ! -f "$COLORGEN_DIR/templates/gtk/gtk.css" ]; then
    log "ERROR" "Template file not found for gtk colors. Skipping that."
    exit 1
fi

# Copy template
cp "$COLORGEN_DIR/templates/gtk/gtk.css" "$CACHE_DIR/generated/gtk/gtk-colors.css"

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

# Function to calculate perceived brightness of a color (0-255)
# Using the formula: (0.299*R + 0.587*G + 0.114*B)
calculate_brightness() {
    local hex=$1
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Calculate perceived brightness (0-255)
    local brightness=$(( (299*r + 587*g + 114*b) / 1000 ))
    
    echo "$brightness"
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
    
    # Better text contrast
    onBackground="#101010"  # Darker text for better readability
    onSurface="#202020"  # Darker text for surfaces
    onPrimary="#202020"  # Dark text on light colored buttons for light theme
    error=$(increase_saturation "$secondary" 40)  # More vibrant error color
    onError="#FFFFFF"  # White text on error color
    
    log "INFO" "Using enhanced light theme with vibrant colors and darker buttons"
    
    log "INFO" "Primary color: $primary"
    log "INFO" "Background color: $background"
    log "INFO" "Surface color: $surface"
    
    # Define color arrays AFTER variables are set
    declare -a colorlist=("primary" "onPrimary" "background" "onBackground" "surface" "surfaceDim" "onSurface" "error" "onError" "tertiary" "secondary")
    declare -a colorvalues=("$primary" "$onPrimary" "$background" "$onBackground" "$surface" "$surfaceDim" "$onSurface" "$error" "$onError" "$tertiary" "$secondary")
    
    # Add buttonBgColor for light theme
    colorlist+=("buttonBgColor")
    colorvalues+=("$buttonBgColor")
    
    # Apply colors to the template
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ \$${colorlist[$i]} }}/${colorvalues[$i]}/g" "$CACHE_DIR/generated/gtk/gtk-colors.css"
    done
    
else
    log "ERROR" "colors.conf not found: $COLORGEN_DIR/colors.conf"
    exit 1
fi

# Apply to both GTK3 and GTK4
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"
cp "$CACHE_DIR/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
cp "$CACHE_DIR/generated/gtk/gtk-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"

# Get icon theme from file or use default
default_icon_theme="Papirus"

icon_theme="$default_icon_theme"
if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
    icon_theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
    # If icon theme doesn't specify -Dark or -Light, append based on theme
    if [[ "$icon_theme" != *"-Dark"* ]] && [[ "$icon_theme" != *"-Light"* ]]; then
        # Check if light version exists
        if [ -d "/usr/share/icons/${icon_theme}" ]; then
            log "INFO" "Using regular icon theme for light mode: $icon_theme"
        fi
    fi
fi

# Set GTK theme for light mode
gtk_theme="adw-gtk3"
color_scheme="prefer-light"
log "INFO" "Setting light theme for GTK"

# Apply settings.ini template
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"

# Copy and modify settings.ini template for both GTK3 and GTK4
for gtk_version in "gtk-3.0" "gtk-4.0"; do
    if [ -f "$COLORGEN_DIR/templates/gtk/settings.ini" ]; then
        cp "$COLORGEN_DIR/templates/gtk/settings.ini" "$XDG_CONFIG_HOME/$gtk_version/settings.ini"
        
        # Update theme settings in the copied file
        sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$XDG_CONFIG_HOME/$gtk_version/settings.ini"
        sed -i "s/gtk-theme-name=adw-gtk3-dark/gtk-theme-name=$gtk_theme/" "$XDG_CONFIG_HOME/$gtk_version/settings.ini"
        
        # Update icon theme
        sed -i "s/gtk-icon-theme-name=Papirus-Dark/gtk-icon-theme-name=$icon_theme/" "$XDG_CONFIG_HOME/$gtk_version/settings.ini"
        
        log "INFO" "Applied settings.ini template for $gtk_version"
    else
        log "WARNING" "settings.ini template not found, skipping for $gtk_version"
    fi
done

# Apply theme via gsettings
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" || true
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" || true
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" || true

# Set GTK_THEME environment variable
# Update in user's bashrc
if grep -q "export GTK_THEME=" "$HOME/.bashrc"; then
    # Replace existing GTK_THEME line
    sed -i "s|export GTK_THEME=.*|export GTK_THEME=$gtk_theme|" "$HOME/.bashrc"
    log "INFO" "Updated GTK_THEME in .bashrc to $gtk_theme"
else
    # Add new GTK_THEME line
    echo "export GTK_THEME=$gtk_theme" >> "$HOME/.bashrc"
    log "INFO" "Added GTK_THEME to .bashrc"
fi

# Set for current session
export GTK_THEME="$gtk_theme"

# Save the checksum for future fast-exit comparisons
if [ -n "${CURRENT_CHECKSUM:-}" ]; then
    echo "$CURRENT_CHECKSUM" > "$COLOR_CONF_CHECKSUM_FILE"
fi

# Save the theme mode for other scripts to reference
echo "true" > "$CACHE_DIR/generated/gtk/light_theme_mode"
log "INFO" "Saved theme mode preference to $CACHE_DIR/generated/gtk/light_theme_mode"

# Create libadwaita directories and copy CSS there too
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0/libadwaita"
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0/libadwaita"
touch "$XDG_CONFIG_HOME/gtk-3.0/libadwaita.css"
touch "$XDG_CONFIG_HOME/gtk-3.0/libadwaita-tweaks.css"

# Reload GTK3 settings if xsettingsd is available
if command -v xsettingsd &> /dev/null; then
    log "INFO" "Reloading xsettingsd to apply GTK3 settings"
    pkill -HUP xsettingsd || true
fi

log "INFO" "GTK light theme application completed" 