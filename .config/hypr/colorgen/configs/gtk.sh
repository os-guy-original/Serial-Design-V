#!/bin/bash

# ============================================================================
# GTK Theme Application Script for Hyprland Colorgen
# 
# This script applies the Material You theme settings to GTK
# Based on the implementation in dots-hyprland
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

log "INFO" "Applying GTK theme with Material You colors"

# ---------------------------------------------------------------------------
# REMOVED EARLY EXIT CONDITION - Always apply colors regardless of changes
# ---------------------------------------------------------------------------

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
    
    # Make primary more vibrant
    primary=$(increase_saturation "$primary" 20)
    
    # Set the derived colors - darker but more vibrant
    background=$(darken_color "$primary_20" 30)
    onBackground=$primary_90
    surface=$(darken_color "$primary_20" 20)
    surfaceDim=$(darken_color "$primary_30" 10)
    onSurface=$(increase_saturation "$primary_90" 10)
    onPrimary=$(increase_saturation "$primary_20" 10)
    error=$(increase_saturation "$primary" 30)
    onError=$(increase_saturation "$primary_20" 10)
    
    # Make secondary and tertiary more vibrant
    secondary=$(increase_saturation "$secondary" 30)
    tertiary=$(increase_saturation "$tertiary" 30)
    
    log "INFO" "Primary color: $primary"
    log "INFO" "Background color: $background"
    log "INFO" "Surface color: $surface"
    
    # Define color arrays AFTER variables are set
    declare -a colorlist=("primary" "onPrimary" "background" "onBackground" "surface" "surfaceDim" "onSurface" "error" "onError" "tertiary" "secondary")
    declare -a colorvalues=("$primary" "$onPrimary" "$background" "$onBackground" "$surface" "$surfaceDim" "$onSurface" "$error" "$onError" "$tertiary" "$secondary")
    
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
icon_theme="Papirus-Dark"
if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
    icon_theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
fi

# Always use dark theme
gtk_theme="adw-gtk3-dark"
log "INFO" "Setting dark theme for GTK"

# Apply theme via gsettings
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" || true
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" || true

# Set GTK_THEME environment variable
# Add to user's bashrc if not already there
if ! grep -q "export GTK_THEME=adw-gtk3-dark" "$HOME/.bashrc"; then
    echo 'export GTK_THEME=adw-gtk3-dark' >> "$HOME/.bashrc"
    log "INFO" "Added GTK_THEME to .bashrc"
fi

# Set for current session
export GTK_THEME=adw-gtk3-dark

# Save the checksum for future fast-exit comparisons
if [ -n "${CURRENT_CHECKSUM:-}" ]; then
    echo "$CURRENT_CHECKSUM" > "$COLOR_CONF_CHECKSUM_FILE"
fi

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

log "INFO" "GTK theme application completed"