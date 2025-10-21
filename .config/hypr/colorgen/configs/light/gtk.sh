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
LIGHT_COLORS_JSON="$COLORGEN_DIR/light_colors.json"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/gtk"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


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
    log "ERROR" "Template file not found for gtk light colors. Skipping that."
    exit 1
fi

# Function to extract sections from template
extract_gtk_sections() {
    local template_file="$1"
    local output_base="$2"
    local gtk_version="$3"
    
    local temp_common="$output_base.common.tmp"
    local temp_specific="$output_base.specific.tmp"
    local output_file="$output_base"
    
    # Extract common section (everything before first marker)
    awk '/^\/\* # For GTK[34] \*\/$/ {exit} {print}' "$template_file" > "$temp_common"
    
    # Extract version-specific section
    if [ "$gtk_version" = "gtk3" ]; then
        awk '/^\/\* # For GTK3 \*\/$/ {flag=1; next} /^\/\* # For GTK4 \*\/$/ {flag=0} flag' "$template_file" > "$temp_specific"
    else
        awk '/^\/\* # For GTK4 \*\/$/ {flag=1; next} /^\/\* # For GTK3 \*\/$/ {flag=0} flag' "$template_file" > "$temp_specific"
    fi
    
    # Combine common + specific sections
    cat "$temp_common" "$temp_specific" > "$output_file"
    
    # Clean up temp files
    rm -f "$temp_common" "$temp_specific"
}

# Generate separate templates for GTK3 and GTK4
log "INFO" "Generating GTK3 and GTK4 specific templates from master template"
extract_gtk_sections "$COLORGEN_DIR/templates/gtk/gtk.css" "$CACHE_DIR/generated/gtk/gtk3-colors.css" "gtk3"
extract_gtk_sections "$COLORGEN_DIR/templates/gtk/gtk.css" "$CACHE_DIR/generated/gtk/gtk4-colors.css" "gtk4"

# Source color extraction library
source "$COLORGEN_DIR/color_extract.sh"

# Note: extract_color is now provided by color_extract.sh as extract_from_json
# Keeping this wrapper for compatibility
extract_color() {
    local color_name=$1
    local default_color=$2
    extract_from_json "light_colors.json" ".$color_name" "$default_color"
}

# Note: darken_color() and lighten_color() are now provided by color_utils.sh

# Function to increase saturation (make more vibrant) - local utility
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

# Check if light_colors.json exists
if [ ! -f "$LIGHT_COLORS_JSON" ]; then
    log "ERROR" "light_colors.json not found: $LIGHT_COLORS_JSON"
    exit 1
fi

# Get primary color from light_colors.json
primary=$(extract_color "primary" "#884b6b")
secondary=$(extract_color "secondary" "#725763")
tertiary=$(extract_color "tertiary" "#7f543a")

# Extract Material You tonal colors for buttons
surfaceContainerHigh=$(extract_color "surface_container_high" "#f7e4df")
surfaceContainerHighest=$(extract_color "surface_container_highest" "#f1dfda")

log "INFO" "Using primary color from light_colors.json: $primary"

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
  
  # Sidebar color with adjustable brightness (slightly darker than background)
  sidebarBg=$(darken_color "$background" 5)
  
  # Sidebar backdrop color
  sidebarBackdrop=$(lighten_color "$primary" 70)

log "INFO" "Using enhanced light theme with vibrant colors and darker buttons"
log "INFO" "Primary color: $primary"
log "INFO" "Background color: $background"
log "INFO" "Surface color: $surface"
  log "INFO" "Sidebar color: $sidebarBg"

# Define color arrays AFTER variables are set
  declare -a colorlist=("primary" "onPrimary" "background" "onBackground" "surface" "surfaceDim" "onSurface" "error" "onError" "tertiary" "secondary" "surface_container" "sidebarBg" "sidebarBackdrop")
  declare -a colorvalues=("$primary" "$onPrimary" "$background" "$onBackground" "$surface" "$surfaceDim" "$onSurface" "$error" "$onError" "$tertiary" "$secondary" "$surface" "$sidebarBg" "$sidebarBackdrop")

# For light theme, we'll use primary directly as button background

# Add buttonBgColor for light theme
colorlist+=("buttonBgColor")
colorvalues+=("$buttonBgColor")

# Add Material You tonal colors for GTK4 buttons
colorlist+=("surfaceContainerHigh" "surfaceContainerHighest")
colorvalues+=("$surfaceContainerHigh" "$surfaceContainerHighest")

# Apply colors to GTK3 template
log "INFO" "Applying colors to GTK3 template"
for i in "${!colorlist[@]}"; do
    sed -i "s/{{ \$${colorlist[$i]} }}/${colorvalues[$i]}/g" "$CACHE_DIR/generated/gtk/gtk3-colors.css"
done

# Apply colors to GTK4 template
log "INFO" "Applying colors to GTK4 template"
for i in "${!colorlist[@]}"; do
    sed -i "s/{{ \$${colorlist[$i]} }}/${colorvalues[$i]}/g" "$CACHE_DIR/generated/gtk/gtk4-colors.css"
done

# Apply to GTK3 and GTK4 with their respective templates
mkdir -p "$XDG_CONFIG_HOME/gtk-3.0"
mkdir -p "$XDG_CONFIG_HOME/gtk-4.0"
cp "$CACHE_DIR/generated/gtk/gtk3-colors.css" "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
cp "$CACHE_DIR/generated/gtk/gtk4-colors.css" "$XDG_CONFIG_HOME/gtk-4.0/gtk.css"

log "INFO" "Applied GTK3-specific configuration to gtk-3.0/gtk.css"
log "INFO" "Applied GTK4-specific configuration to gtk-4.0/gtk.css"

# Get icon theme from file or use default
default_icon_theme="Papirus"

icon_theme="$default_icon_theme"
if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
    icon_theme=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt")
    log "INFO" "Using icon theme from icon_theme.txt: $icon_theme"
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

# Restart xdg-desktop-portal-gtk to apply changes
log "INFO" "Restarting xdg-desktop-portal-gtk to apply changes"
systemctl --user restart xdg-desktop-portal-gtk || log "ERROR" "Failed to restart xdg-desktop-portal-gtk"

log "INFO" "GTK light theme application completed" 