#!/bin/bash

# gtk-clock.sh - GTK Layer Shell clock positioning script
# Reads empty area data and launches GTK clock at optimal position

# Change to script directory
cd "$(dirname "$(realpath "$0")")" || exit 1

CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
EMPTY_AREAS_FILE="$COLORGEN_DIR/empty_areas.json"
COLORS_FILE="$COLORGEN_DIR/colors.json"

# Check if empty areas analysis exists, create fallback if not
if [ ! -f "$EMPTY_AREAS_FILE" ]; then
    echo "Empty areas analysis not found. Creating fallback position..."
    
    # Get screen resolution using xrandr or fallback
    if command -v xrandr >/dev/null 2>&1; then
        SCREEN_INFO=$(xrandr --current | grep '*' | head -n1 | awk '{print $1}')
        SCREEN_WIDTH=$(echo "$SCREEN_INFO" | cut -d'x' -f1)
        SCREEN_HEIGHT=$(echo "$SCREEN_INFO" | cut -d'x' -f2)
    else
        # Fallback screen dimensions
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
    fi
    
    # Create fallback empty areas file
    mkdir -p "$COLORGEN_DIR"
    cat > "$EMPTY_AREAS_FILE" << EOF
{
    "wallpaper": "fallback",
    "screen_dimensions": {
        "width": $SCREEN_WIDTH,
        "height": $SCREEN_HEIGHT
    },
    "clock_dimensions": {
        "width": 280,
        "height": 120
    },
    "analysis": {
        "status": "fallback",
        "best_score": 0.5,
        "background_brightness": 0.5,
        "is_bright_background": false,
        "is_dark_background": false
    },
    "suggested_clock_position": {
        "x": $((SCREEN_WIDTH / 4)),
        "y": $((SCREEN_HEIGHT / 4)),
        "anchor": "center"
    }
}
EOF
    echo "Created fallback empty areas file"
fi

# Check if colors exist, create fallback if not
if [ ! -f "$COLORS_FILE" ]; then
    echo "Colors not found. Creating fallback colors..."
    
    mkdir -p "$COLORGEN_DIR"
    cat > "$COLORS_FILE" << EOF
{
    "colors": {
        "dark": {
            "primary": "#6750a4",
            "on_surface": "#e6e0e9",
            "surface": "#141218",
            "secondary": "#625b71",
            "tertiary": "#7d5260"
        },
        "light": {
            "primary": "#6750a4",
            "on_surface": "#1c1b1f",
            "surface": "#fffbfe"
        }
    }
}
EOF
    echo "Created fallback colors file"
fi

# Extract position data and convert to integers
CLOCK_X=$(jq -r '.suggested_clock_position.x' "$EMPTY_AREAS_FILE" | cut -d'.' -f1)
CLOCK_Y=$(jq -r '.suggested_clock_position.y' "$EMPTY_AREAS_FILE" | cut -d'.' -f1)
ANCHOR=$(jq -r '.suggested_clock_position.anchor' "$EMPTY_AREAS_FILE")

# Get screen dimensions for visibility check
SCREEN_WIDTH=$(jq -r '.screen_dimensions.width' "$EMPTY_AREAS_FILE")
SCREEN_HEIGHT=$(jq -r '.screen_dimensions.height' "$EMPTY_AREAS_FILE")

# Ensure position values are valid integers
if ! [[ "$CLOCK_X" =~ ^[0-9]+$ ]] || ! [[ "$CLOCK_Y" =~ ^[0-9]+$ ]]; then
    echo "Invalid position values, using fallback"
    CLOCK_X=$((SCREEN_WIDTH / 2))
    CLOCK_Y=$((SCREEN_HEIGHT / 3))
fi

# Ensure clock position is visible on screen
CLOCK_WIDTH=280
CLOCK_HEIGHT=120
MARGIN=50

# Calculate bounds to keep clock fully visible
MIN_X=$((CLOCK_WIDTH / 2 + MARGIN))
MAX_X=$((SCREEN_WIDTH - CLOCK_WIDTH / 2 - MARGIN))
MIN_Y=$((CLOCK_HEIGHT / 2 + MARGIN))
MAX_Y=$((SCREEN_HEIGHT - CLOCK_HEIGHT / 2 - MARGIN))

# Clamp position to visible area
if [ "$CLOCK_X" -lt "$MIN_X" ]; then
    CLOCK_X=$MIN_X
    echo "Adjusted X position to $CLOCK_X for visibility"
elif [ "$CLOCK_X" -gt "$MAX_X" ]; then
    CLOCK_X=$MAX_X
    echo "Adjusted X position to $CLOCK_X for visibility"
fi

if [ "$CLOCK_Y" -lt "$MIN_Y" ]; then
    CLOCK_Y=$MIN_Y
    echo "Adjusted Y position to $CLOCK_Y for visibility"
elif [ "$CLOCK_Y" -gt "$MAX_Y" ]; then
    CLOCK_Y=$MAX_Y
    echo "Adjusted Y position to $CLOCK_Y for visibility"
fi

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

# Kill the empty area finder script to conserve resources
if [ -f "$COLORGEN_DIR/kill_empty_area_finder.sh" ]; then
    bash "$COLORGEN_DIR/kill_empty_area_finder.sh"
fi