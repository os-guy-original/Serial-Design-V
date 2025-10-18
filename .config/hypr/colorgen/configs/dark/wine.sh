#!/bin/bash

# ============================================================================
# Dark Theme Wine Script for Hyprland Colorgen
# 
# This script applies Material You dark theme colors to Wine using regedit
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"
DARK_COLORS_JSON="$COLORGEN_DIR/dark_colors.json"
WINE_USER_REG="$HOME/.wine/user.reg"
WINE_USER_REG_BACKUP="$HOME/.wine/user.reg.colorgen.bak"
TEMP_REG_FILE=$(mktemp --suffix=.reg)

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


log "INFO" "Applying Material You dark theme colors to Wine"

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

# Extract colors from the dark colors JSON
log "INFO" "Extracting Material You dark colors for Wine..."

# Use color_extract.sh for color extraction
extract_color() {
    local color_name=$1
    local default_color=$2
    extract_from_json "dark_colors.json" ".$color_name" "$default_color"
}

# Note: hex_to_rgb is now provided by color_utils.sh (already sourced above)
# Convert hex to space-separated RGB for Wine registry format
hex_to_rgb_wine() {
    local hex=$1
    local rgb=$(hex_to_rgb "$hex")
    echo "$rgb"
}

# Get required colors from Material You palette
background=$(extract_color "background" "#181115")
surface=$(extract_color "surface" "#181115")
surface_container=$(extract_color "surface_container" "#251d21")
surface_container_high=$(extract_color "surface_container_high" "#30282b")
on_surface=$(extract_color "on_surface" "#eedfe3")
on_surface_variant=$(extract_color "on_surface_variant" "#d4c2c8")
primary=$(extract_color "primary" "#fcb0d5")
primary_container=$(extract_color "primary_container" "#6c3353")
on_primary=$(extract_color "on_primary" "#521d3c")
on_primary_container=$(extract_color "on_primary_container" "#ffd8e8")
error=$(extract_color "error" "#ffb4ab")

# Convert hex colors to RGB format for Wine
background_rgb=$(hex_to_rgb_wine "$background")
surface_rgb=$(hex_to_rgb_wine "$surface")
surface_container_rgb=$(hex_to_rgb_wine "$surface_container")
surface_container_high_rgb=$(hex_to_rgb_wine "$surface_container_high")
on_surface_rgb=$(hex_to_rgb_wine "$on_surface")
on_surface_variant_rgb=$(hex_to_rgb_wine "$on_surface_variant")
primary_rgb=$(hex_to_rgb_wine "$primary")
primary_container_rgb=$(hex_to_rgb_wine "$primary_container")
on_primary_rgb=$(hex_to_rgb_wine "$on_primary")
on_primary_container_rgb=$(hex_to_rgb_wine "$on_primary_container")
error_rgb=$(hex_to_rgb_wine "$error")

# Define black for contrast
black_rgb="0 0 0"

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
"ButtonDkShadow"="$background_rgb"
"ButtonFace"="$surface_container_rgb"
"ButtonHilight"="$surface_container_high_rgb"
"ButtonLight"="$surface_container_high_rgb"
"ButtonShadow"="$surface_rgb"
"ButtonText"="$on_surface_rgb"
"Desktop"="$background_rgb"
"GradientActiveTitle"="$primary_rgb"
"GradientInactiveTitle"="$surface_container_high_rgb"
"GrayText"="$on_surface_variant_rgb"
"Hilight"="$primary_rgb"
"HilightText"="$black_rgb"
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
"TitleText"="$on_primary_container_rgb"
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

log "INFO" "Wine Material You dark theme applied successfully!"
log "INFO" "You may need to restart any running Wine applications for changes to take effect."

exit 0 