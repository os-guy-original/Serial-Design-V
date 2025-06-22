#!/bin/bash

# foot.sh - Update Material You colors for foot terminal
# Updates color settings in colors.ini based on Material You color palette

# Colors source
COLORS_CONF="/home/sd-v/.config/hypr/colorgen/colors.conf"
COLORS_JSON="/home/sd-v/.config/hypr/colorgen/colors.json"
FOOT_COLORS_CONFIG="/home/sd-v/.config/foot/colors.ini"
FOOT_TEMPLATE="/home/sd-v/.config/hypr/colorgen/templates/foot/colors.ini"

# Check if colors files exist
if [ ! -f "$COLORS_CONF" ]; then
    echo "Error: $COLORS_CONF not found"
    exit 1
fi

if [ ! -f "$COLORS_JSON" ]; then
    echo "Error: $COLORS_JSON not found"
    exit 1
fi

# Check if template exists
if [ ! -f "$FOOT_TEMPLATE" ]; then
    echo "Error: Template file $FOOT_TEMPLATE not found"
    exit 1
fi

# Check if foot colors config exists
if [ ! -f "$FOOT_COLORS_CONFIG" ]; then
    echo "Error: $FOOT_COLORS_CONFIG not found"
    mkdir -p "$(dirname "$FOOT_COLORS_CONFIG")"
    touch "$FOOT_COLORS_CONFIG"
    echo "Created empty foot colors config at $FOOT_COLORS_CONFIG"
fi

echo "Updating foot colors..."

# Create a backup of the config if it doesn't exist
BACKUP_FILE="${FOOT_COLORS_CONFIG}.original"
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$FOOT_COLORS_CONFIG" "$BACKUP_FILE"
    echo "Created backup of foot colors config at $BACKUP_FILE"
fi

# Extract colors from JSON for more complete Material You palette
# We use jq to parse the JSON and extract the dark theme colors
extract_color() {
    local color_name=$1
    # Extract color without # prefix for foot format (RRGGBB)
    jq -r ".colors.dark.$color_name" "$COLORS_JSON" | sed 's/#//'
}

# Extract all Material Design 3 colors from the JSON
background=$(extract_color "background")
on_background=$(extract_color "on_background")
surface=$(extract_color "surface")
on_surface=$(extract_color "on_surface")
surface_variant=$(extract_color "surface_variant")
on_surface_variant=$(extract_color "on_surface_variant")
primary=$(extract_color "primary")
on_primary=$(extract_color "on_primary")
primary_container=$(extract_color "primary_container")
on_primary_container=$(extract_color "on_primary_container")
secondary=$(extract_color "secondary")
on_secondary=$(extract_color "on_secondary")
tertiary=$(extract_color "tertiary")
on_tertiary=$(extract_color "on_tertiary")
tertiary_container=$(extract_color "tertiary_container")
on_tertiary_container=$(extract_color "on_tertiary_container")
error=$(extract_color "error")
on_error=$(extract_color "on_error")
error_container=$(extract_color "error_container")
on_error_container=$(extract_color "on_error_container")
surface_container=$(extract_color "surface_container")
primary_fixed=$(extract_color "primary_fixed")
primary_fixed_dim=$(extract_color "primary_fixed_dim")
secondary_fixed=$(extract_color "secondary_fixed")
secondary_fixed_dim=$(extract_color "secondary_fixed_dim")
tertiary_fixed=$(extract_color "tertiary_fixed")
tertiary_fixed_dim=$(extract_color "tertiary_fixed_dim")

# Get current date for template
date=$(date +"%Y-%m-%d %H:%M:%S")

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

echo "✅ foot colors updated successfully!" 