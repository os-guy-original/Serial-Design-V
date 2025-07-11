#!/bin/bash

# material_extract.sh - Material You color extraction with matugen
# Uses Google's Material You color scheme generator to extract colors from wallpaper

# Check if we're already running to prevent multiple executions
SCRIPT_NAME=$(basename "$0")
RUNNING_PROCESSES=$(pgrep -c -f "$SCRIPT_NAME")

if [ "$RUNNING_PROCESSES" -gt 1 ]; then
    echo "Another instance of $SCRIPT_NAME is already running. Exiting."
    exit 0
fi

# Create a main process lock - this is more effective than file locks
MAIN_PID=$$
echo "Starting Material You extraction - PID: $MAIN_PID"

# Change to script directory to ensure all relative paths work
cd "$(dirname "$(realpath "$0")")" || exit 1

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache"
STATE_DIR="$CACHE_DIR/state"
TEMP_DIR="$CACHE_DIR/temp"
THEME_TO_APPLY_FILE="$TEMP_DIR/theme-to-apply"

# Fast exit if no wallpaper
WALLPAPER_FILE="$STATE_DIR/last_wallpaper"
[ ! -f "$WALLPAPER_FILE" ] && exit 0

# Fast read wallpaper path
WALLPAPER=$(< "$WALLPAPER_FILE")
WALLPAPER=$(echo "$WALLPAPER" | tr -d '\n\r')
[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && exit 0

# Create colorgen directory
COLORGEN_DIR="$CONFIG_DIR/colorgen"
mkdir -p "$COLORGEN_DIR"

# Ensure wallpaper path consistency
if [ -f "$COLORGEN_DIR/ensure_wallpaper_path.sh" ]; then
    echo "Ensuring wallpaper path consistency..."
    bash "$COLORGEN_DIR/ensure_wallpaper_path.sh"
fi

# Function to convert hex to rgba with full opacity
hex_to_rgba() {
    local hex=$1
    echo "rgba(${hex:1:2}${hex:3:2}${hex:5:2}ff)"
}

# Check if matugen is installed
if ! command -v matugen >/dev/null 2>&1; then
    echo "matugen not found. Please install matugen for Material You colors."
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. Please install jq for JSON processing."
    echo "Install with: sudo pacman -S jq"
    exit 1
fi

echo "Generating Material You colors from wallpaper: $WALLPAPER"

# Create output directory
mkdir -p "$COLORGEN_DIR"

# Generate Material You colors directly with proper Material You settings
# Use scheme-tonal-spot which is the standard Material You palette
echo "Running matugen with Material You scheme-tonal-spot..."
matugen --mode dark -t scheme-tonal-spot --json hex image "$WALLPAPER" > "$COLORGEN_DIR/colors.json"

# Check if we got colors
if [ ! -s "$COLORGEN_DIR/colors.json" ]; then
    echo "Failed to generate Material You colors."
    exit 1
fi

# Extract the dark color palette (we're using dark mode)
jq -r '.colors.dark' "$COLORGEN_DIR/colors.json" > "$COLORGEN_DIR/dark_colors.json"

# Extract the light color palette too for brighter colors
jq -r '.colors.light' "$COLORGEN_DIR/colors.json" > "$COLORGEN_DIR/light_colors.json"

# Create a proper colors.conf based on Material You palette
{
    echo "# Material You color scheme from $WALLPAPER"
    echo "# Generated on $(date +%Y-%m-%d)"
    echo "# Using Material You scheme-tonal-spot algorithm"
    echo

    # Primary color
    primary=$(jq -r '.primary' "$COLORGEN_DIR/dark_colors.json")
    echo "primary = $primary"
    
    # Create a custom tonal palette from primary color
    # Check if jq is available to extract colors
    if command -v jq >/dev/null 2>&1; then
        # Get the surface colors from Material You - these represent different tonal values
        surface=$(jq -r '.surface' "$COLORGEN_DIR/dark_colors.json")
        surface_bright=$(jq -r '.surface_bright' "$COLORGEN_DIR/dark_colors.json")
        surface_container=$(jq -r '.surface_container' "$COLORGEN_DIR/dark_colors.json")
        surface_container_high=$(jq -r '.surface_container_high' "$COLORGEN_DIR/dark_colors.json")
        surface_container_highest=$(jq -r '.surface_container_highest' "$COLORGEN_DIR/dark_colors.json")
        surface_container_low=$(jq -r '.surface_container_low' "$COLORGEN_DIR/dark_colors.json")
        surface_container_lowest=$(jq -r '.surface_container_lowest' "$COLORGEN_DIR/dark_colors.json")
        
        # Get on-colors (contrasting colors)
        on_primary=$(jq -r '.on_primary' "$COLORGEN_DIR/dark_colors.json")
        on_primary_container=$(jq -r '.on_primary_container' "$COLORGEN_DIR/dark_colors.json")
        on_surface=$(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json")
        
        # Map to primary tones
        echo "primary-0 = $surface_container_lowest"
        echo "primary-10 = $surface_container_low"
        echo "primary-20 = $surface_container"
        echo "primary-30 = $surface_container_high"
        echo "primary-40 = $surface_container_highest"
        echo "primary-50 = $surface"
        echo "primary-60 = $surface_bright"
        echo "primary-80 = $primary"
        echo "primary-90 = $on_primary_container"
        echo "primary-95 = $on_surface"
        echo "primary-99 = #ffffff"
        echo "primary-100 = #ffffff"
    fi
    
    echo
    
    # Extract accent colors
    secondary=$(jq -r '.secondary' "$COLORGEN_DIR/dark_colors.json")
    tertiary=$(jq -r '.tertiary' "$COLORGEN_DIR/dark_colors.json")
    
    echo "secondary = $secondary"
    echo "tertiary = $tertiary"
    
    echo
    
    # Set standard accent values
    echo "accent = $primary"
    
    # Get primary container for accent_dark
    accent_dark=$(jq -r '.primary_container' "$COLORGEN_DIR/dark_colors.json")
    if [ "$accent_dark" = "null" ]; then accent_dark="#000000"; fi
    echo "accent_dark = $accent_dark"
    
    # Get on_surface for accent_light (should be closer to white)
    accent_light=$(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json") 
    if [ "$accent_light" = "null" ]; then accent_light="#ffffff"; fi
    echo "accent_light = $accent_light"
    
    echo
    
    # Map Material You tones to color0-7 for compatibility
    echo "color0 = $(jq -r '.surface_container_lowest' "$COLORGEN_DIR/dark_colors.json" || echo "#000000")"
    echo "color1 = $(jq -r '.surface_container_low' "$COLORGEN_DIR/dark_colors.json" || echo "#1a1a1a")"
    echo "color2 = $(jq -r '.surface_container' "$COLORGEN_DIR/dark_colors.json" || echo "#303030")"
    echo "color3 = $(jq -r '.surface_container_high' "$COLORGEN_DIR/dark_colors.json" || echo "#505050")"
    echo "color4 = $(jq -r '.primary_container' "$COLORGEN_DIR/dark_colors.json" || echo "#707070")"
    echo "color5 = $(jq -r '.primary' "$COLORGEN_DIR/dark_colors.json" || echo "#909090")"
    echo "color6 = $(jq -r '.on_primary_container' "$COLORGEN_DIR/dark_colors.json" || echo "#b0b0b0")"
    echo "color7 = $(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json" || echo "#ffffff")"
    
} > "$COLORGEN_DIR/colors.conf"

# Create a CSS file with Material You colors
{
    echo "/* Material You color scheme from $WALLPAPER */"
    echo "/* Generated on $(date +%Y-%m-%d) */"
    echo "/* Using Material You scheme-tonal-spot algorithm */"
    echo
    echo ":root {"
    
    # Extract all colors from the dark palette
    jq -r 'to_entries | .[] | "  --\(.key): \(.value);"' "$COLORGEN_DIR/dark_colors.json" || echo "  /* Error extracting colors */"
    
    echo
    echo "  /* Standard CSS variables */"
    echo "  --accent: $primary;"
    echo "  --accent-dark: $accent_dark;"
    echo "  --accent-light: $accent_light;"
    
    # Add color0-7 for legacy compatibility
    echo
    echo "  /* Legacy color variables */"
    echo "  --color0: $(jq -r '.surface_container_lowest' "$COLORGEN_DIR/dark_colors.json" || echo "#000000");"
    echo "  --color1: $(jq -r '.surface_container_low' "$COLORGEN_DIR/dark_colors.json" || echo "#1a1a1a");"
    echo "  --color2: $(jq -r '.surface_container' "$COLORGEN_DIR/dark_colors.json" || echo "#303030");"
    echo "  --color3: $(jq -r '.surface_container_high' "$COLORGEN_DIR/dark_colors.json" || echo "#505050");"
    echo "  --color4: $(jq -r '.primary_container' "$COLORGEN_DIR/dark_colors.json" || echo "#707070");"
    echo "  --color5: $(jq -r '.primary' "$COLORGEN_DIR/dark_colors.json" || echo "#909090");"
    echo "  --color6: $(jq -r '.on_primary_container' "$COLORGEN_DIR/dark_colors.json" || echo "#b0b0b0");"
    echo "  --color7: $(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json" || echo "#ffffff");"
    
    echo "}"
} > "$COLORGEN_DIR/colors.css"

# Get border color - lightest tone (on_surface) for Hyprland borders
# We want a light color, close to white
border_color_hex=$(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json")

# If the on_surface color isn't available or doesn't look white enough
# (check brightness using the red component as an approximation)
if [ -z "$border_color_hex" ] || [ "$border_color_hex" = "null" ] || 
   [ $(( 16#$(echo "$border_color_hex" | sed 's/^#\(..\).*/\1/') )) -lt $(( 16#c0 )) ]; then
    # Try inverse_surface which should be light-colored in dark mode
    border_color_hex=$(jq -r '.inverse_surface' "$COLORGEN_DIR/dark_colors.json")
fi

# If still not light enough, use a color from the light palette
if [ -z "$border_color_hex" ] || [ "$border_color_hex" = "null" ] || 
   [ $(( 16#$(echo "$border_color_hex" | sed 's/^#\(..\).*/\1/') )) -lt $(( 16#c0 )) ]; then
    border_color_hex=$(jq -r '.on_primary' "$COLORGEN_DIR/light_colors.json")
fi

# Ultimate fallback to white
if [ -z "$border_color_hex" ] || [ "$border_color_hex" = "null" ] || 
   [ $(( 16#$(echo "$border_color_hex" | sed 's/^#\(..\).*/\1/') )) -lt $(( 16#c0 )) ]; then
    border_color_hex="#ffffff"
fi

# Convert to rgba for Hyprland
border_color=$(hex_to_rgba "$border_color_hex")
echo "$border_color" > "$COLORGEN_DIR/border_color.txt"

# Debug output
echo "Primary color: $primary"
echo "Border color: $border_color_hex"
echo "Border color (rgba): $border_color"
echo "On surface color: $(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json")"

# Remove any existing finish indicator before starting
rm -f /tmp/done_color_application

# Check if theme-to-apply file exists and pass the appropriate theme flag
THEME_ARG=""
if [ -f "$THEME_TO_APPLY_FILE" ]; then
    theme=$(cat "$THEME_TO_APPLY_FILE")
    echo "Found theme-to-apply file with theme: $theme"
    
    if [ "$theme" = "light" ] || [ "$theme" = "dark" ]; then
        THEME_ARG="--force-$theme"
        echo "Using theme from theme-to-apply file: $theme"
        
        # Remove the theme-to-apply file after reading it
        rm -f "$THEME_TO_APPLY_FILE"
        echo "Removed theme-to-apply file"
    fi
# Check if theme was passed as command line argument
elif [ "$1" = "--force-light" ] || [ "$1" = "--force-dark" ]; then
    THEME_ARG="$1"
    echo "Using theme from command line argument: $THEME_ARG"
fi

# Run apply_colors.sh and wait for it to finish using && to ensure sequential execution
echo "Running apply_colors.sh..."
bash ./apply_colors.sh $THEME_ARG && \
sleep 2 && \
echo "$(date +%s)" > /tmp/done_color_application && \
echo "Created finish indicator file: /tmp/done_color_application"

echo "Material You colors generated and applied successfully!"
exit 0
