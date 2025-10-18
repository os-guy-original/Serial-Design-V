#!/bin/bash

# ============================================================================
# Dark Theme Foot Terminal Script for Hyprland Colorgen
# 
# This script applies Material You dark theme colors to Foot terminal
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
DARK_COLORS_JSON="$COLORGEN_DIR/dark_colors.json"
FOOT_COLORS_CONFIG="$XDG_CONFIG_HOME/foot/colors.ini"
FOOT_TEMPLATE="$COLORGEN_DIR/templates/foot/colors.ini"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


log "INFO" "Applying Foot terminal dark theme with Material You colors"

# Check if colors file exists
if [ ! -f "$DARK_COLORS_JSON" ]; then
    log "ERROR" "Material You dark colors not found. Run material_extract.sh first."
    exit 1
fi

# Check if template exists
if [ ! -f "$FOOT_TEMPLATE" ]; then
    log "ERROR" "Template file $FOOT_TEMPLATE not found"
    exit 1
fi

# Check if foot colors config exists
if [ ! -f "$FOOT_COLORS_CONFIG" ]; then
    log "INFO" "Creating foot colors config directory"
    mkdir -p "$(dirname "$FOOT_COLORS_CONFIG")"
    touch "$FOOT_COLORS_CONFIG"
    log "INFO" "Created empty foot colors config at $FOOT_COLORS_CONFIG"
fi

# Create a backup of the config if it doesn't exist
BACKUP_FILE="${FOOT_COLORS_CONFIG}.original"
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$FOOT_COLORS_CONFIG" "$BACKUP_FILE"
    log "INFO" "Created backup of foot colors config at $BACKUP_FILE"
fi

# Extract colors using color_extract.sh
# Wrapper to remove # prefix for foot format (RRGGBB)
extract_color() {
    local color_name=$1
    local default_color=$2
    local color=$(extract_from_json "dark_colors.json" ".$color_name" "$default_color")
    echo "${color#\#}"
}

# Extract Material You colors
background=$(extract_color "surface" "141218")
on_background=$(extract_color "on_surface" "e6e0e9")
surface=$(extract_color "surface" "141218")
on_surface=$(extract_color "on_surface" "e6e0e9")
surface_variant=$(extract_color "surface_variant" "49454f")
on_surface_variant=$(extract_color "on_surface_variant" "cac4d0")
primary=$(extract_color "primary" "d0bcff")
on_primary=$(extract_color "on_primary" "381e72")
primary_container=$(extract_color "primary_container" "4f378b")
on_primary_container=$(extract_color "on_primary_container" "eaddff")
secondary=$(extract_color "secondary" "ccc2dc")
on_secondary=$(extract_color "on_secondary" "332d41")
tertiary=$(extract_color "tertiary" "efb8c8")
on_tertiary=$(extract_color "on_tertiary" "492532")
tertiary_container=$(extract_color "tertiary_container" "633b48")
on_tertiary_container=$(extract_color "on_tertiary_container" "ffd8e4")
error=$(extract_color "error" "f2b8b5")
on_error=$(extract_color "on_error" "601410")
error_container=$(extract_color "error_container" "8c1d18")
on_error_container=$(extract_color "on_error_container" "f9dedc")
surface_container=$(extract_color "surface_container" "211f26")
primary_fixed=$(extract_color "primary" "d0bcff")
primary_fixed_dim=$(extract_color "primary" "b69df8")
secondary_fixed=$(extract_color "secondary" "ccc2dc")
secondary_fixed_dim=$(extract_color "secondary" "b8b0c7")
tertiary_fixed=$(extract_color "tertiary" "efb8c8")
tertiary_fixed_dim=$(extract_color "tertiary" "dba4b5")

# Get current date for template
date=$(date +"%Y-%m-%d %H:%M:%S")

log "INFO" "Applying dark theme colors to foot terminal"

# Apply the template with variable substitution
# Using envsubst to replace variables in the template
export background on_background surface on_surface surface_variant on_surface_variant \
       primary on_primary primary_container on_primary_container \
       secondary on_secondary tertiary on_tertiary tertiary_container on_tertiary_container \
       error on_error error_container on_error_container \
       surface_container primary_fixed primary_fixed_dim \
       secondary_fixed secondary_fixed_dim tertiary_fixed tertiary_fixed_dim date

# Use envsubst to replace variables in the template
envsubst < "$FOOT_TEMPLATE" > "$FOOT_COLORS_CONFIG"

log "INFO" "Dark theme applied to foot terminal successfully!" 