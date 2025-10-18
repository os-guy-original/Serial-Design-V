#!/bin/bash

# ============================================================================
# Light Theme Foot Terminal Script for Hyprland Colorgen
# 
# This script applies Material You light theme colors to Foot terminal
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"

# Source color utilities
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"
LIGHT_COLORS_JSON="$COLORGEN_DIR/light_colors.json"
FOOT_COLORS_CONFIG="$XDG_CONFIG_HOME/foot/colors.ini"
FOOT_TEMPLATE="$COLORGEN_DIR/templates/foot/colors.ini"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


log "INFO" "Applying Foot terminal light theme with Material You colors"

# Check if colors file exists
if [ ! -f "$LIGHT_COLORS_JSON" ]; then
    log "ERROR" "Material You light colors not found. Run material_extract.sh first."
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
    local color=$(extract_from_json "light_colors.json" ".$color_name" "$default_color")
    echo "${color#\#}"
}

# Extract Material You colors for light theme
background=$(extract_color "surface" "fffbfe")
on_background=$(extract_color "on_surface" "1c1b1f")
surface=$(extract_color "surface" "fffbfe")
on_surface=$(extract_color "on_surface" "1c1b1f")
surface_variant=$(extract_color "surface_variant" "e7e0ec")
on_surface_variant=$(extract_color "on_surface_variant" "49454f")
primary=$(extract_color "primary" "6750a4")
on_primary=$(extract_color "on_primary" "ffffff")
primary_container=$(extract_color "primary_container" "eaddff")
on_primary_container=$(extract_color "on_primary_container" "21005d")
secondary=$(extract_color "secondary" "625b71")
on_secondary=$(extract_color "on_secondary" "ffffff")
tertiary=$(extract_color "tertiary" "7d5260")
on_tertiary=$(extract_color "on_tertiary" "ffffff")
tertiary_container=$(extract_color "tertiary_container" "ffd8e4")
on_tertiary_container=$(extract_color "on_tertiary_container" "31111d")
error=$(extract_color "error" "b3261e")
on_error=$(extract_color "on_error" "ffffff")
error_container=$(extract_color "error_container" "f9dedc")
on_error_container=$(extract_color "on_error_container" "410e0b")
surface_container=$(extract_color "surface_container" "f3edf7")
primary_fixed=$(extract_color "primary" "6750a4")
primary_fixed_dim=$(extract_color "primary" "4f378b")
secondary_fixed=$(extract_color "secondary" "625b71")
secondary_fixed_dim=$(extract_color "secondary" "4a4458")
tertiary_fixed=$(extract_color "tertiary" "7d5260")
tertiary_fixed_dim=$(extract_color "tertiary" "633b48")

# Get current date for template
date=$(date +"%Y-%m-%d %H:%M:%S")

log "INFO" "Applying light theme colors to foot terminal"

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

log "INFO" "Light theme applied to foot terminal successfully!" 