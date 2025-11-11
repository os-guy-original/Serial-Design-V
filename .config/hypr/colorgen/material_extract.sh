#!/bin/bash

# material_extract.sh - Material You color extraction with matugen
# Uses Google's Material You color scheme generator to extract colors from wallpaper

# Create a proper lock file to prevent multiple executions
LOCK_FILE="/tmp/material_extract.lock"
SCRIPT_NAME=$(basename "$0")

# Check if lock file exists and process is still running
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if ps -p "$LOCK_PID" > /dev/null 2>&1; then
        echo "Another instance of $SCRIPT_NAME is already running (PID: $LOCK_PID). Exiting."
        exit 0
    else
        echo "Removing stale lock file"
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file with current PID
MAIN_PID=$$
echo $MAIN_PID > "$LOCK_FILE"
echo "Starting Material You extraction - PID: $MAIN_PID"

# Ensure lock file is removed on exit
trap 'rm -f "$LOCK_FILE"' EXIT

# Usage function
show_usage() {
    echo "Material You Color Extraction Script"
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  --force-light                    Force light theme"
    echo "  --force-dark                     Force dark theme"
    echo "  --also-set-wallpaper <path>      Set wallpaper after theme selection"
    echo "  --help, -h                       Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                          # Extract colors from current wallpaper"
    echo "  $0 --force-dark                            # Extract colors and force dark theme"
    echo "  $0 --also-set-wallpaper /path/to/image.jpg # Select theme and set new wallpaper"
    echo "  $0 --force-light --also-set-wallpaper /path/to/image.jpg # Force light theme with new wallpaper"
}

# Parse command line arguments first
THEME_ARG=""
SET_WALLPAPER_AFTER=false
NEW_WALLPAPER=""

# Process arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --force-light|--force-dark)
            THEME_ARG="$1"
            echo "Using theme from command line argument: $THEME_ARG"
            shift
            ;;
        --also-set-wallpaper)
            if [ -z "$2" ]; then
                echo "Error: --also-set-wallpaper requires a wallpaper path"
                show_usage
                exit 1
            fi
            if [ ! -f "$2" ]; then
                echo "Error: Wallpaper file not found: $2"
                exit 1
            fi
            echo "Will set wallpaper after theme selection: $2"
            SET_WALLPAPER_AFTER=true
            NEW_WALLPAPER="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Change to script directory to ensure all relative paths work
cd "$(dirname "$(realpath "$0")")" || exit 1

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache"
STATE_DIR="$CACHE_DIR/state"
TEMP_DIR="$CACHE_DIR/temp"
THEME_TO_APPLY_FILE="$TEMP_DIR/theme-to-apply"

# Fast exit if no wallpaper (unless we're setting a new one)
WALLPAPER_FILE="$STATE_DIR/last_wallpaper"
if [ "$SET_WALLPAPER_AFTER" = "false" ] && [ ! -f "$WALLPAPER_FILE" ]; then
    echo "No wallpaper file found at $WALLPAPER_FILE"
    exit 0
fi

# Fast read wallpaper path (or use new wallpaper if provided)
if [ "$SET_WALLPAPER_AFTER" = "true" ]; then
    WALLPAPER="$NEW_WALLPAPER"
else
    WALLPAPER=$(< "$WALLPAPER_FILE")
    WALLPAPER=$(echo "$WALLPAPER" | tr -d '\n\r')
    if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
        echo "Invalid wallpaper path: $WALLPAPER"
        exit 0
    fi
fi

echo "Processing wallpaper: $WALLPAPER"

# Create colorgen directory
COLORGEN_DIR="$CONFIG_DIR/colorgen"
mkdir -p "$COLORGEN_DIR"

# Ensure wallpaper path consistency
if [ -f "$COLORGEN_DIR/ensure_wallpaper_path.sh" ]; then
    echo "Ensuring wallpaper path consistency..."
    bash "$COLORGEN_DIR/ensure_wallpaper_path.sh"
fi

# Source color utilities for hex_to_rgba and other functions
source "$COLORGEN_DIR/color_utils.sh"

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

# Check if ImageMagick is installed for empty area detection
if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick not found. Please install ImageMagick for wallpaper analysis."
    echo "Install with: sudo pacman -S imagemagick"
    exit 1
fi

# Check if bc is installed for calculations
if ! command -v bc >/dev/null 2>&1; then
    echo "bc not found. Please install bc for mathematical calculations."
    echo "Install with: sudo pacman -S bc"
    exit 1
fi

echo "Generating Material You colors from wallpaper: $WALLPAPER"

# Create output directory
mkdir -p "$COLORGEN_DIR"

# Quick fallback position for immediate clock launch
create_fallback_position() {
    local wallpaper="$1"
    local output_file="$COLORGEN_DIR/empty_areas.json"
    
    # Get screen resolution
    local screen_info=$(hyprctl monitors | grep -A 1 "Monitor" | grep -o '[0-9]*x[0-9]*' | head -1)
    local screen_width=$(echo "$screen_info" | cut -d'x' -f1)
    local screen_height=$(echo "$screen_info" | cut -d'x' -f2)
    
    # Clock dimensions for visibility check
    local clock_width=280
    local clock_height=120
    local margin=50
    
    # Calculate safe bounds
    local min_x=$((clock_width / 2 + margin))
    local max_x=$((screen_width - clock_width / 2 - margin))
    local min_y=$((clock_height / 2 + margin))
    local max_y=$((screen_height - clock_height / 2 - margin))
    
    # Use a safe fallback position (upper third, horizontally centered)
    local fallback_x=$((screen_width / 2))
    local fallback_y=$((screen_height / 3))
    
    # Ensure fallback position is within safe bounds
    if [ "$fallback_x" -lt "$min_x" ]; then fallback_x=$min_x; fi
    if [ "$fallback_x" -gt "$max_x" ]; then fallback_x=$max_x; fi
    if [ "$fallback_y" -lt "$min_y" ]; then fallback_y=$min_y; fi
    if [ "$fallback_y" -gt "$max_y" ]; then fallback_y=$max_y; fi
    
    echo "Creating fallback position: ($fallback_x, $fallback_y) - visibility ensured"
    
    # Create temporary JSON for immediate use
    cat > "$output_file" << EOF
{
    "wallpaper": "$wallpaper",
    "screen_dimensions": {
        "width": $screen_width,
        "height": $screen_height
    },
    "clock_dimensions": {
        "width": $clock_width,
        "height": $clock_height
    },
    "analysis": {
        "status": "fallback",
        "best_score": 0.5,
        "background_brightness": 0.5,
        "is_bright_background": false,
        "is_dark_background": false,
        "corner_avoidance": true,
        "visibility_ensured": true,
        "note": "Advanced analysis running in background"
    },
    "suggested_clock_position": {
        "x": $fallback_x,
        "y": $fallback_y,
        "anchor": "center"
    }
}
EOF
}

# Preserve existing clock position if available, don't create fallback
echo "Preserving existing clock position while analysis runs in background..."
screen_width=$(hyprctl monitors | grep -A 1 "Monitor" | grep -o '[0-9]*x[0-9]*' | head -1 | cut -d'x' -f1)
screen_height=$(hyprctl monitors | grep -A 1 "Monitor" | grep -o '[0-9]*x[0-9]*' | head -1 | cut -d'x' -f2)

# Only create fallback if no existing position file exists
if [ ! -f "$COLORGEN_DIR/empty_areas.json" ]; then
    echo "No existing position found, creating initial fallback position"
    create_fallback_position "$WALLPAPER"
else
    echo "Existing clock position preserved, will be updated when analysis completes"
fi

# Kill any existing empty area analysis processes to save resources
echo "Killing existing empty area analysis processes..."
bash "$COLORGEN_DIR/kill_empty_area_finder.sh" >/dev/null 2>&1

# Start empty area analysis in background - this won't block the main process
echo "Starting empty area analysis in background..."
(
    # Create a PID file to track this process
    echo $$ > "$COLORGEN_DIR/empty_area_analysis.pid"
    
    # Background process for empty area analysis
    empty_result=$(python3 "../scripts/ui/empty_area/empty_area_dispatcher.py" "$WALLPAPER" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$empty_result" ]; then
        # Try to parse JSON output first (more reliable)
        json_part=$(echo "$empty_result" | sed -n '/--- JSON ---/,$p' | tail -n +2)
        
        if [ -n "$json_part" ] && command -v jq >/dev/null 2>&1; then
            # Parse using jq for more reliable extraction
            center_x=$(echo "$json_part" | jq -r '.center[0] // 400' 2>/dev/null)
            center_y=$(echo "$json_part" | jq -r '.center[1] // 200' 2>/dev/null)
            square_size=$(echo "$json_part" | jq -r '.square_size // 280' 2>/dev/null)
            complexity_score=$(echo "$json_part" | jq -r '.complexity_score // 0.5' 2>/dev/null)
        else
            # Fallback to text parsing
            center_x=$(echo "$empty_result" | grep "center:" | sed 's/.*center: (\([0-9]*\), \([0-9]*\)).*/\1/')
            center_y=$(echo "$empty_result" | grep "center:" | sed 's/.*center: (\([0-9]*\), \([0-9]*\)).*/\2/')
            square_size=$(echo "$empty_result" | grep "square_size:" | sed 's/.*square_size: \([0-9]*\).*/\1/')
            complexity_score=$(echo "$empty_result" | grep "complexity_score:" | sed 's/.*complexity_score: \([0-9.]*\).*/\1/')
        fi
        
        # Fallback values if parsing fails
        if [ -z "$center_x" ] || [ -z "$center_y" ] || [ -z "$square_size" ] || [ -z "$complexity_score" ] || \
           [ "$center_x" = "null" ] || [ "$center_y" = "null" ] || [ "$square_size" = "null" ] || [ "$complexity_score" = "null" ]; then
            center_x=400
            center_y=200
            square_size=280
            complexity_score=0.5
        fi
        
        # Ensure clock position is visible on screen
        clock_width=280
        clock_height=120
        margin=50
        
        # Calculate bounds to keep clock fully visible
        min_x=$((clock_width / 2 + margin))
        max_x=$((screen_width - clock_width / 2 - margin))
        min_y=$((clock_height / 2 + margin))
        max_y=$((screen_height - clock_height / 2 - margin))
        
        # Clamp position to visible area
        if [ "$center_x" -lt "$min_x" ]; then center_x=$min_x; fi
        if [ "$center_x" -gt "$max_x" ]; then center_x=$max_x; fi
        if [ "$center_y" -lt "$min_y" ]; then center_y=$min_y; fi
        if [ "$center_y" -gt "$max_y" ]; then center_y=$max_y; fi
        
        # Extract background analysis from JSON if available
        background_brightness="0.5"
        is_bright_background="false"
        is_dark_background="false"
        
        if [ -n "$json_part" ] && command -v jq >/dev/null 2>&1; then
            background_brightness=$(echo "$json_part" | jq -r '.background_analysis.average_brightness // 0.5' 2>/dev/null)
            is_bright_background=$(echo "$json_part" | jq -r '.background_analysis.is_bright_background // false' 2>/dev/null)
            is_dark_background=$(echo "$json_part" | jq -r '.background_analysis.is_dark_background // false' 2>/dev/null)
        fi
        
        # Update JSON output with better analysis
        cat > "$COLORGEN_DIR/empty_areas.json" << EOF
{
    "wallpaper": "$WALLPAPER",
    "screen_dimensions": {
        "width": $screen_width,
        "height": $screen_height
    },
    "clock_dimensions": {
        "width": $clock_width,
        "height": $clock_height
    },
    "analysis": {
        "status": "complete",
        "best_score": $complexity_score,
        "background_brightness": $background_brightness,
        "is_bright_background": $is_bright_background,
        "is_dark_background": $is_dark_background,
        "corner_avoidance": true,
        "visibility_ensured": true
    },
    "suggested_clock_position": {
        "x": $center_x,
        "y": $center_y,
        "anchor": "center"
    }
}
EOF
        echo "Background empty area analysis complete. Best position: ($center_x,$center_y)"
        
        # Remove PID file and kill this process since analysis is complete
        rm -f "$COLORGEN_DIR/empty_area_analysis.pid"
        exit 0
    else
        # Analysis failed, remove PID file
        rm -f "$COLORGEN_DIR/empty_area_analysis.pid"
        exit 1
    fi
) &

# Store the background process PID for potential cleanup
EMPTY_AREA_PID=$!
echo $EMPTY_AREA_PID > "$COLORGEN_DIR/empty_area_analysis.pid"

# Continue with color extraction immediately - don't wait for empty area analysis
echo "Continuing with color extraction while empty area analysis runs in background..."

# Generate Material You colors using Python color generator
echo "Running Python Material You color generator..."
if command -v python3 >/dev/null 2>&1; then
    cd "$COLORGEN_DIR"
    python3 python_colorgen.py "$WALLPAPER" --colorgen-dir "$COLORGEN_DIR" --debug
    color_gen_result=$?
    if [ $color_gen_result -ne 0 ]; then
        echo "Python color generation failed. Exiting."
        exit 1
    fi
    cd - >/dev/null
else
    echo "Python3 not available, falling back to matugen..."
    matugen --mode dark -t scheme-tonal-spot --json hex image "$WALLPAPER" > "$COLORGEN_DIR/colors.json"
    
    if [ ! -s "$COLORGEN_DIR/colors.json" ]; then
        echo "Failed to generate Material You colors."
        exit 1
    fi
fi

# Verify that dark_colors.json exists and is valid
if [ ! -f "$COLORGEN_DIR/dark_colors.json" ]; then
    echo "ERROR: dark_colors.json not found at $COLORGEN_DIR/dark_colors.json"
    exit 1
fi

# Verify JSON is valid
if ! jq empty "$COLORGEN_DIR/dark_colors.json" 2>/dev/null; then
    echo "ERROR: dark_colors.json is not valid JSON"
    cat "$COLORGEN_DIR/dark_colors.json"
    exit 1
fi

# Create a proper colors.conf based on Material You palette
{
    echo "# Material You color scheme from $WALLPAPER"
    echo "# Generated on $(date +%Y-%m-%d)"
    echo "# Using Material You scheme-tonal-spot algorithm"
    echo

    # Primary color with null check
    primary=$(jq -r '.primary // "#6750a4"' "$COLORGEN_DIR/dark_colors.json")
    if [ "$primary" = "null" ] || [ -z "$primary" ]; then
        echo "ERROR: Failed to extract primary color from dark_colors.json"
        exit 1
    fi
    echo "primary = $primary"
    
    # Create a custom tonal palette from primary color
    # Check if jq is available to extract colors
    if command -v jq >/dev/null 2>&1; then
        # Get the surface colors from Material You with fallbacks
        surface=$(jq -r '.surface // "#141218"' "$COLORGEN_DIR/dark_colors.json")
        surface_bright=$(jq -r '.surface_bright // "#3b383e"' "$COLORGEN_DIR/dark_colors.json")
        surface_container=$(jq -r '.surface_container // "#211f26"' "$COLORGEN_DIR/dark_colors.json")
        surface_container_high=$(jq -r '.surface_container_high // "#2b2930"' "$COLORGEN_DIR/dark_colors.json")
        surface_container_highest=$(jq -r '.surface_container_highest // "#36343b"' "$COLORGEN_DIR/dark_colors.json")
        surface_container_low=$(jq -r '.surface_container_low // "#1d1b20"' "$COLORGEN_DIR/dark_colors.json")
        surface_container_lowest=$(jq -r '.surface_container_lowest // "#0f0d13"' "$COLORGEN_DIR/dark_colors.json")
        
        # Get on-colors (contrasting colors) with fallbacks
        on_primary=$(jq -r '.on_primary // "#381e72"' "$COLORGEN_DIR/dark_colors.json")
        on_primary_container=$(jq -r '.on_primary_container // "#eaddff"' "$COLORGEN_DIR/dark_colors.json")
        on_surface=$(jq -r '.on_surface // "#e6e0e9"' "$COLORGEN_DIR/dark_colors.json")
        
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
    
    # Extract accent colors with fallbacks
    secondary=$(jq -r '.secondary // "#625b71"' "$COLORGEN_DIR/dark_colors.json")
    tertiary=$(jq -r '.tertiary // "#7d5260"' "$COLORGEN_DIR/dark_colors.json")
    
    echo "secondary = $secondary"
    echo "tertiary = $tertiary"
    
    echo
    
    # Set standard accent values
    echo "accent = $primary"
    
    # Get primary container for accent_dark with fallback
    accent_dark=$(jq -r '.primary_container // "#4f378b"' "$COLORGEN_DIR/dark_colors.json")
    if [ "$accent_dark" = "null" ] || [ -z "$accent_dark" ]; then accent_dark="#4f378b"; fi
    echo "accent_dark = $accent_dark"
    
    # Get on_surface for accent_light with fallback
    accent_light=$(jq -r '.on_surface // "#e6e0e9"' "$COLORGEN_DIR/dark_colors.json") 
    if [ "$accent_light" = "null" ] || [ -z "$accent_light" ]; then accent_light="#e6e0e9"; fi
    echo "accent_light = $accent_light"
    
    echo
    
    # Map Material You tones to color0-7 for compatibility with fallbacks
    echo "color0 = $(jq -r '.surface_container_lowest // "#000000"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color1 = $(jq -r '.surface_container_low // "#1a1a1a"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color2 = $(jq -r '.surface_container // "#303030"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color3 = $(jq -r '.surface_container_high // "#505050"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color4 = $(jq -r '.primary_container // "#707070"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color5 = $(jq -r '.primary // "#909090"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color6 = $(jq -r '.on_primary_container // "#b0b0b0"' "$COLORGEN_DIR/dark_colors.json")"
    echo "color7 = $(jq -r '.on_surface // "#ffffff"' "$COLORGEN_DIR/dark_colors.json")"
    
} > "$COLORGEN_DIR/colors.conf"

# Create a CSS file with Material You colors
{
    echo "/* Material You color scheme from $WALLPAPER */"
    echo "/* Generated on $(date +%Y-%m-%d) */"
    echo "/* Using Material You scheme-tonal-spot algorithm */"
    echo
    echo ":root {"
    
    # Extract all colors from the dark palette with null filtering
    jq -r 'to_entries | .[] | select(.value != null) | "  --\(.key | gsub("_"; "-")): \(.value);"' "$COLORGEN_DIR/dark_colors.json" 2>/dev/null || echo "  /* Error extracting colors */"
    
    echo
    echo "  /* Standard CSS variables */"
    echo "  --accent: $primary;"
    echo "  --accent-dark: $accent_dark;"
    echo "  --accent-light: $accent_light;"
    
    # Add color0-7 for legacy compatibility with fallbacks
    echo
    echo "  /* Legacy color variables */"
    echo "  --color0: $(jq -r '.surface_container_lowest // "#000000"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color1: $(jq -r '.surface_container_low // "#1a1a1a"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color2: $(jq -r '.surface_container // "#303030"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color3: $(jq -r '.surface_container_high // "#505050"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color4: $(jq -r '.primary_container // "#707070"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color5: $(jq -r '.primary // "#909090"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color6: $(jq -r '.on_primary_container // "#b0b0b0"' "$COLORGEN_DIR/dark_colors.json");"
    echo "  --color7: $(jq -r '.on_surface // "#ffffff"' "$COLORGEN_DIR/dark_colors.json");"
    
    echo "}"
} > "$COLORGEN_DIR/colors.css"

# Get border color - lightest tone (on_surface) for Hyprland borders
# We want a light color, close to white
border_color_hex=$(jq -r '.on_surface // "#e6e0e9"' "$COLORGEN_DIR/dark_colors.json")

# Validate hex color format
if [ -z "$border_color_hex" ] || [ "$border_color_hex" = "null" ] || ! [[ "$border_color_hex" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    echo "Warning: Invalid on_surface color, trying inverse_surface"
    border_color_hex=$(jq -r '.inverse_surface // "#ffffff"' "$COLORGEN_DIR/dark_colors.json")
fi

# Check brightness using the red component as an approximation
if [[ "$border_color_hex" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    red_component=$(echo "$border_color_hex" | sed 's/^#\(..\).*/\1/')
    if [ $(( 16#$red_component )) -lt $(( 16#c0 )) ]; then
        echo "Warning: Border color not bright enough, trying light palette"
        # Try inverse_surface which should be light-colored in dark mode
        border_color_hex=$(jq -r '.inverse_surface // "#ffffff"' "$COLORGEN_DIR/dark_colors.json")
        
        # If still not light enough, use a color from the light palette
        if [[ "$border_color_hex" =~ ^#[0-9a-fA-F]{6}$ ]]; then
            red_component=$(echo "$border_color_hex" | sed 's/^#\(..\).*/\1/')
            if [ $(( 16#$red_component )) -lt $(( 16#c0 )) ]; then
                if [ -f "$COLORGEN_DIR/light_colors.json" ]; then
                    border_color_hex=$(jq -r '.on_primary // "#ffffff"' "$COLORGEN_DIR/light_colors.json")
                else
                    border_color_hex="#ffffff"
                fi
            fi
        fi
    fi
fi

# Ultimate fallback to white if still invalid
if [ -z "$border_color_hex" ] || [ "$border_color_hex" = "null" ] || ! [[ "$border_color_hex" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    echo "Warning: Using fallback white color for border"
    border_color_hex="#ffffff"
fi

# Convert to rgba for Hyprland
border_color=$(hex_to_rgba "$border_color_hex")
if [ -z "$border_color" ] || [ "$border_color" = "null" ]; then
    echo "ERROR: Failed to convert border color to rgba"
    border_color="rgba(ffffffff)"
fi
echo "$border_color" > "$COLORGEN_DIR/border_color.txt"

# Debug output
echo "Primary color: $primary"
echo "Border color: $border_color_hex"
echo "Border color (rgba): $border_color"
echo "On surface color: $(jq -r '.on_surface // "N/A"' "$COLORGEN_DIR/dark_colors.json")"

# Remove any existing finish indicator before starting
rm -f /tmp/done_color_application

# Check if theme-to-apply file exists and use it if no theme argument was provided
if [ -z "$THEME_ARG" ] && [ -f "$THEME_TO_APPLY_FILE" ]; then
    theme=$(cat "$THEME_TO_APPLY_FILE")
    echo "Found theme-to-apply file with theme: $theme"
    
    if [ "$theme" = "light" ] || [ "$theme" = "dark" ]; then
        THEME_ARG="--force-$theme"
        echo "Using theme from theme-to-apply file: $theme"
        
        # Remove the theme-to-apply file after reading it
        rm -f "$THEME_TO_APPLY_FILE"
        echo "Removed theme-to-apply file"
    fi
fi

# If --also-set-wallpaper flag was used, handle theme selection and wallpaper setting
if [ "$SET_WALLPAPER_AFTER" = "true" ]; then
    # Only run theme selector if no theme was forced via command line
    if [ -z "$THEME_ARG" ]; then
        echo "Running theme selector before applying colors..."
        if [ -f "theme-selectors/theme_selector_python.sh" ]; then
            bash "theme-selectors/theme_selector_python.sh" --wallpaper "$NEW_WALLPAPER"
            selector_exit=$?
            if [ $selector_exit -ne 0 ]; then
                echo "Theme selection cancelled, aborting"
                exit 1
            fi
            
            # Check if theme-to-apply file was created
            if [ -f "$THEME_TO_APPLY_FILE" ]; then
                theme=$(cat "$THEME_TO_APPLY_FILE")
                if [ "$theme" = "light" ] || [ "$theme" = "dark" ]; then
                    THEME_ARG="--force-$theme"
                    echo "Theme selected: $theme"
                    rm -f "$THEME_TO_APPLY_FILE"
                fi
            fi
        fi
    else
        echo "Using forced theme: $THEME_ARG"
    fi
    
    # Update wallpaper path and last_wallpaper file
    echo "Updating wallpaper to: $NEW_WALLPAPER"
    echo "$NEW_WALLPAPER" > "$WALLPAPER_FILE"
    WALLPAPER="$NEW_WALLPAPER"
    
    # Set wallpaper immediately
    echo "Setting wallpaper..."
    if [ -f "../scripts/ui/swww_manager.sh" ]; then
        bash "../scripts/ui/swww_manager.sh" set-with-transition "$NEW_WALLPAPER" "wave" "center"
        if [ $? -eq 0 ]; then
            echo "Wallpaper set successfully: $NEW_WALLPAPER"
        else
            echo "Failed to set wallpaper: $NEW_WALLPAPER"
        fi
    else
        echo "Warning: swww_manager.sh not found, wallpaper not set"
    fi
fi

# Run apply_colors.sh and wait for it to finish using && to ensure sequential execution
echo "Running apply_colors.sh..."
bash ./apply_colors.sh $THEME_ARG && \
sleep 2 && \
echo "$(date +%s)" > /tmp/done_color_application && \
echo "Created finish indicator file: /tmp/done_color_application"





echo "Material You colors generated and applied successfully!"
exit 0
