#!/bin/bash

# gtk-clock.sh - GTK Layer Shell clock positioning script
# Reads empty area data and launches GTK clock at optimal position

# Change to script directory
cd "$(dirname "$(realpath "$0")")" || exit 1

CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
EMPTY_AREAS_FILE="$COLORGEN_DIR/empty_areas.json"
COLORS_FILE="$COLORGEN_DIR/colors.json"

# Check if empty areas analysis exists
if [ ! -f "$EMPTY_AREAS_FILE" ]; then
    echo "Empty areas analysis not found. Run material_extract.sh first."
    exit 1
fi

# Check if colors exist
if [ ! -f "$COLORS_FILE" ]; then
    echo "Colors not found. Run material_extract.sh first."
    exit 1
fi

# Extract position data and convert to integers
CLOCK_X=$(jq -r '.suggested_clock_position.x' "$EMPTY_AREAS_FILE" | cut -d'.' -f1)
CLOCK_Y=$(jq -r '.suggested_clock_position.y' "$EMPTY_AREAS_FILE" | cut -d'.' -f1)
ANCHOR=$(jq -r '.suggested_clock_position.anchor' "$EMPTY_AREAS_FILE")

# Extract colors for the clock
PRIMARY_COLOR=$(jq -r '.colors.dark.primary' "$COLORS_FILE")
ON_SURFACE_COLOR=$(jq -r '.colors.dark.on_surface' "$COLORS_FILE")
SURFACE_COLOR=$(jq -r '.colors.dark.surface' "$COLORS_FILE")

echo "Launching GTK clock at position: ${CLOCK_X},${CLOCK_Y}"
echo "Using colors: primary=$PRIMARY_COLOR, text=$ON_SURFACE_COLOR, bg=$SURFACE_COLOR"

# Check if clock is already running
if pgrep -f "gtk_layer_clock.py" > /dev/null; then
    echo "Clock is already running. Position and colors will be updated automatically."
    # Touch the files to trigger updates in the running clock
    touch "$EMPTY_AREAS_FILE" "$COLORS_FILE"
    exit 0
fi

# Launch the GTK clock with position and color arguments
python3 "$CONFIG_DIR/scripts/ui/gtk_layer_clock.py" \
    --x "$CLOCK_X" \
    --y "$CLOCK_Y" \
    --anchor "$ANCHOR" \
    --primary-color "$PRIMARY_COLOR" \
    --text-color "$ON_SURFACE_COLOR" \
    --bg-color "$SURFACE_COLOR" &

echo "GTK Layer Shell clock launched successfully!"