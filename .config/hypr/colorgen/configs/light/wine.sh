#!/bin/bash

# ============================================================================
# Light Theme Wine Script for Hyprland Colorgen
# 
# This script applies Material You light theme colors to Wine using regedit
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
LIGHT_COLORS_JSON="$COLORGEN_DIR/light_colors.json"
WINE_USER_REG="$HOME/.wine/user.reg"
WINE_USER_REG_BACKUP="$HOME/.wine/user.reg.colorgen.bak"
TEMP_REG_FILE=$(mktemp --suffix=.reg)

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying Material You light theme colors to Wine"

# Kill any running winecfg processes to prevent conflicts
if pgrep winecfg > /dev/null; then
    log "INFO" "Killing running winecfg processes to prevent conflicts"
    kill -KILL $(pgrep winecfg) 2>/dev/null || true
fi

# Check if Wine is installed
if ! command -v wine &> /dev/null; then
    log "ERROR" "Wine is not installed or not in PATH. Please install Wine first."
    exit 1
fi

# Create backup of Wine registry if it exists and backup doesn't
if [ -f "$WINE_USER_REG" ] && [ ! -f "$WINE_USER_REG_BACKUP" ]; then
    log "INFO" "Creating backup of Wine registry at $WINE_USER_REG_BACKUP"
    cp "$WINE_USER_REG" "$WINE_USER_REG_BACKUP"
fi

# Extract colors from the light colors JSON
log "INFO" "Extracting Material You light colors for Wine..."

# Function to extract colors from JSON
extract_color() {
    local color_name=$1
    local default_color=$2
    local color=$(jq -r ".$color_name" "$LIGHT_COLORS_JSON" 2>/dev/null)
    
    if [ -z "$color" ] || [ "$color" = "null" ]; then
        echo "$default_color"
    else
        echo "$color"
    fi
}

# Function to convert hex color to RGB format
hex_to_rgb() {
    local hex=$1
    hex="${hex#\#}" # Remove leading # if present
    
    # Extract RGB components
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r $g $b"
}

# Get required colors from Material You palette
background=$(extract_color "background" "#fff8f8")
surface=$(extract_color "surface" "#fff8f8")
surface_container=$(extract_color "surface_container" "#f9eaee")
surface_container_high=$(extract_color "surface_container_high" "#f3e4e9")
on_surface=$(extract_color "on_surface" "#21191d")
on_surface_variant=$(extract_color "on_surface_variant" "#504349")
# Use the primary color directly from light_colors.json instead of a different value
primary=$(extract_color "primary" "#884b6b")
primary_container=$(extract_color "primary_container" "#ffd8e8")
on_primary=$(extract_color "on_primary" "#ffffff")
on_primary_container=$(extract_color "on_primary_container" "#380726")
error=$(extract_color "error" "#ba1a1a")

# Convert hex colors to RGB format for Wine
background_rgb=$(hex_to_rgb "$background")
surface_rgb=$(hex_to_rgb "$surface")
surface_container_rgb=$(hex_to_rgb "$surface_container")
surface_container_high_rgb=$(hex_to_rgb "$surface_container_high")
on_surface_rgb=$(hex_to_rgb "$on_surface")
on_surface_variant_rgb=$(hex_to_rgb "$on_surface_variant")
primary_rgb=$(hex_to_rgb "$primary")
primary_container_rgb=$(hex_to_rgb "$primary_container")
on_primary_rgb=$(hex_to_rgb "$on_primary")
on_primary_container_rgb=$(hex_to_rgb "$on_primary_container")
error_rgb=$(hex_to_rgb "$error")

# Define white for contrast
white_rgb="255 255 255"

log "INFO" "Primary color: $primary (RGB: $primary_rgb)"
log "INFO" "Background color: $background (RGB: $background_rgb)"

# Create a Windows registry file
log "INFO" "Creating temporary registry file at $TEMP_REG_FILE"

# Write registry file
cat > "$TEMP_REG_FILE" << EOF
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Control Panel\Colors]
"3DObjects"="$surface_container_rgb"
"ActiveBorder"="$surface_container_rgb"
"ActiveTitle"="$primary_rgb"
"AppWorkSpace"="$surface_rgb"
"Background"="$background_rgb"
"ButtonAlternateFace"="$surface_container_rgb"
"ButtonDkShadow"="$on_surface_variant_rgb"
"ButtonFace"="$surface_container_rgb"
"ButtonHilight"="$surface_rgb"
"ButtonLight"="$surface_rgb"
"ButtonShadow"="$surface_container_high_rgb"
"ButtonText"="$on_surface_rgb"
"Desktop"="$background_rgb"
"GradientActiveTitle"="$primary_rgb"
"GradientInactiveTitle"="$surface_container_high_rgb"
"GrayText"="$on_surface_variant_rgb"
"Hilight"="$primary_rgb"
"HilightText"="$white_rgb"
"HotTrackingColor"="$primary_rgb"
"InactiveBorder"="$surface_container_rgb"
"InactiveTitle"="$surface_container_high_rgb"
"InactiveTitleText"="$on_surface_variant_rgb"
"InfoText"="$on_surface_rgb"
"InfoWindow"="$surface_rgb"
"Menu"="$surface_rgb"
"MenuBar"="$surface_rgb"
"MenuHilight"="$primary_rgb"
"MenuText"="$on_surface_rgb"
"Scrollbar"="$surface_container_high_rgb"
"TitleText"="$on_primary_rgb"
"Window"="$surface_rgb"
"WindowFrame"="$surface_container_high_rgb"
"WindowText"="$on_surface_rgb"
EOF

# Apply the registry file using wine regedit
log "INFO" "Applying registry file using wine regedit..."
wine regedit "$TEMP_REG_FILE" 2>/dev/null || {
    log "ERROR" "Failed to apply registry file. Wine might not be properly configured."
    log "INFO" "You can try manually importing the registry file: wine regedit $TEMP_REG_FILE"
    exit 1
}

# Clean up
log "INFO" "Cleaning up temporary files..."
rm -f "$TEMP_REG_FILE"

log "INFO" "Wine Material You light theme applied successfully!"
log "INFO" "You may need to restart any running Wine applications for changes to take effect."

exit 0 