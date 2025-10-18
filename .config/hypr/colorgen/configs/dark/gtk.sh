#!/bin/bash

# ============================================================================
# GTK Theme Application Script for Hyprland Colorgen (DARK MODE)
# 
# This script applies the Material You theme settings to GTK in dark mode
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/gtk"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


log "INFO" "Applying GTK dark theme with Material You colors"

# Compute checksum of the colors.conf used as the source of truth
COLOR_CONF_CHECKSUM_FILE="$CACHE_DIR/generated/gtk/colors.conf.md5"
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    CURRENT_CHECKSUM=$(md5sum "$COLORGEN_DIR/colors.conf" | cut -d" " -f1)
    # We still calculate the checksum for logging purposes but don't exit early
    log "INFO" "Processing colors.conf with checksum: $CURRENT_CHECKSUM"
fi

# Check if template exists
if [ ! -f "$COLORGEN_DIR/templates/gtk/gtk-dark.css" ]; then
    log "ERROR" "Template file not found for gtk dark colors. Skipping that."
    exit 1
fi

# Copy template
cp "$COLORGEN_DIR/templates/gtk/gtk-dark.css" "$CACHE_DIR/generated/gtk/gtk-colors.css"

# Note: darken_color and lighten_color are now provided by color_utils.sh (already sourced above)

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

# Note: calculate_brightness is now provided by color_utils.sh (already sourced above)

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
    # Ensure onPrimary has good contrast against primary (black text on colored buttons)
    onPrimary="#000000"
    error=$(increase_saturation "$primary" 30)
    onError=$(increase_saturation "$primary_20" 10)
    
    # Sidebar color with adjustable brightness (slightly lighter than background)
    sidebarBg=$(lighten_color "$primary" -20)

    sidebarBackdrop=$(darken_color "$primary" 50)
    
    # Boost primary color for more pop
    primary=$(increase_saturation "$primary" 30)
    
    # More vibrant accent colors
    secondary=$(increase_saturation "$secondary" 40)
    tertiary=$(increase_saturation "$tertiary" 40)
    
    log "INFO" "Primary color: $primary"
    log "INFO" "Background color: $background"
    log "INFO" "Surface color: $surface"
    log "INFO" "Sidebar color: $sidebarBg"
    
    # Define color arrays AFTER variables are set
    declare -a colorlist=("primary" "onPrimary" "background" "onBackground" "surface" "surfaceDim" "onSurface" "error" "onError" "tertiary" "secondary" "surface_container" "sidebarBg" "sidebarBackdrop")
    declare -a colorvalues=("$primary" "$onPrimary" "$background" "$onBackground" "$surface" "$surfaceDim" "$onSurface" "$error" "$onError" "$tertiary" "$secondary" "$primary_20" "$sidebarBg" "$sidebarBackdrop")
    
    # For dark theme, we'll use primary directly as button background
    colorlist+=("buttonBgColor")
    colorvalues+=("$primary")
    
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
default_icon_theme="Papirus-Dark"

icon_theme="$default_icon_theme"
if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
    icon_theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
    log "INFO" "Using icon theme from icon_theme.txt: $icon_theme"
fi

# Set GTK theme for dark mode
gtk_theme="adw-gtk3-dark"
color_scheme="prefer-dark"
log "INFO" "Setting dark theme for GTK"

# Apply settings.ini template
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"

# Copy and modify settings.ini template for both GTK3 and GTK4
for gtk_version in "gtk-3.0" "gtk-4.0"; do
    if [ -f "$COLORGEN_DIR/templates/gtk/settings.ini" ]; then
        cp "$COLORGEN_DIR/templates/gtk/settings.ini" "$XDG_CONFIG_HOME/$gtk_version/settings.ini"
        
        # Update theme settings in the copied file
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
echo "false" > "$CACHE_DIR/generated/gtk/light_theme_mode"
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

# Restart xdg-desktop-portal-gtk to apply changes
log "INFO" "Restarting xdg-desktop-portal-gtk to apply changes"
systemctl --user restart xdg-desktop-portal-gtk || log "ERROR" "Failed to restart xdg-desktop-portal-gtk"

log "INFO" "GTK dark theme application completed" 