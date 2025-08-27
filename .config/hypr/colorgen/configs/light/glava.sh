#!/bin/bash

# ============================================================================
# Light Theme GLava Script for Hyprland Colorgen
# 
# This script applies Material You light theme colors to GLava audio visualizer
# with darker colors to ensure visibility on light backgrounds
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
GLAVA_DIR="$XDG_CONFIG_HOME/glava"
COLORS_CONF="$COLORGEN_DIR/colors.conf"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying GLava light theme with Material You colors"

# First check if glava config exists, if not create it
if [ ! -d "$GLAVA_DIR" ]; then
    log "INFO" "GLava config not found. Creating it..."
    glava --copy-config || {
        log "ERROR" "Failed to create GLava config. Is GLava installed?"
        exit 1
    }
    log "INFO" "GLava config created at $GLAVA_DIR"
fi

# Create backup directory if it doesn't exist
BACKUP_DIR="$GLAVA_DIR/backups"
mkdir -p "$BACKUP_DIR"

# Function to backup a file if backup doesn't exist
backup_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    if [ ! -f "$BACKUP_DIR/$basename.original" ]; then
        cp "$file" "$BACKUP_DIR/$basename.original"
        log "INFO" "Created backup of $basename"
    fi
}

# Function to darken a hex color for better visibility in light mode
darken_color() {
    local hex=$1
    local percent=$2
    [ -z "$percent" ] && percent=40  # Default: Darken by 40%
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Darken by reducing each component by the percentage
    r=$(( r * (100 - percent) / 100 ))
    g=$(( g * (100 - percent) / 100 ))
    b=$(( b * (100 - percent) / 100 ))
    
    # Ensure values are within range
    r=$(( r > 255 ? 255 : r ))
    g=$(( g > 255 ? 255 : g ))
    b=$(( b > 255 ? 255 : b ))
    
    # Convert back to hex
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Get colors from colors.conf
if [ ! -f "$COLORS_CONF" ]; then
    log "ERROR" "Colors configuration not found at $COLORS_CONF"
    exit 1
fi

# Extract vibrant colors from colors.conf, avoiding white colors (primary-99 and primary-100)
# For primary color, use primary-80 or primary-90 which are vibrant but not white
PRIMARY=$(grep -E "^primary-80 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
if [ -z "$PRIMARY" ]; then
    # If primary-80 not found, try primary (but not if it's white)
    PRIMARY_TEMP=$(grep -E "^primary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
    if [ "$PRIMARY_TEMP" != "#ffffff" ]; then
        PRIMARY=$PRIMARY_TEMP
    else
        # If primary is white, try primary-90
        PRIMARY=$(grep -E "^primary-90 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
    fi
fi

# Get accent color (use the main accent, not white)
ACCENT=$(grep -E "^accent =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
if [ "$ACCENT" = "#ffffff" ]; then
    # If accent is white, try accent_dark
    ACCENT=$(grep -E "^accent_dark =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
fi

# Get secondary and tertiary colors
SECONDARY=$(grep -E "^secondary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
TERTIARY=$(grep -E "^tertiary =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# If we couldn't find the colors, or if they're white, use some vibrant defaults
[ -z "$PRIMARY" ] || [ "$PRIMARY" = "#ffffff" ] && PRIMARY="#bcc2ff"
[ -z "$ACCENT" ] || [ "$ACCENT" = "#ffffff" ] && ACCENT="#bcc2ff"
[ -z "$SECONDARY" ] || [ "$SECONDARY" = "#ffffff" ] && SECONDARY="#c4c5dd"
[ -z "$TERTIARY" ] || [ "$TERTIARY" = "#ffffff" ] && TERTIARY="#e6bad6"

# Get color4 for outline (avoid using black or white)
COLOR4=$(grep -E "^color4 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$COLOR4" ] || [ "$COLOR4" = "#ffffff" ] || [ "$COLOR4" = "#000000" ] && COLOR4="#3b4279"

# Get color5 for additional vibrant color
COLOR5=$(grep -E "^color5 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$COLOR5" ] || [ "$COLOR5" = "#ffffff" ] && COLOR5="#bcc2ff"

# Get color6 as another alternative
COLOR6=$(grep -E "^color6 =" "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$COLOR6" ] || [ "$COLOR6" = "#ffffff" ] && COLOR6="#dfe0ff"

# For light mode, darken the colors to make them more visible
log "INFO" "Darkening colors for better visibility in light mode"
PRIMARY=$(darken_color "$PRIMARY" 40)
ACCENT=$(darken_color "$ACCENT" 40)
SECONDARY=$(darken_color "$SECONDARY" 40)
TERTIARY=$(darken_color "$TERTIARY" 40)
COLOR4=$(darken_color "$COLOR4" 30)
COLOR5=$(darken_color "$COLOR5" 40)
COLOR6=$(darken_color "$COLOR6" 30)

log "INFO" "Using colors:"
log "INFO" "PRIMARY: $PRIMARY"
log "INFO" "ACCENT: $ACCENT"
log "INFO" "SECONDARY: $SECONDARY"
log "INFO" "TERTIARY: $TERTIARY"
log "INFO" "COLOR4: $COLOR4"
log "INFO" "COLOR5: $COLOR5"
log "INFO" "COLOR6: $COLOR6"

# Check if GLava is running before making changes
GLAVA_WAS_RUNNING=false
if pgrep glava >/dev/null; then
    GLAVA_WAS_RUNNING=true
    log "INFO" "GLava is currently running"
fi

# Update bars.glsl
if [ -f "$GLAVA_DIR/bars.glsl" ]; then
    backup_file "$GLAVA_DIR/bars.glsl"
    
    # Replace the outline color and bar color with vibrant colors
    sed -i "s/#define BAR_OUTLINE #[0-9a-fA-F]\{6\}/#define BAR_OUTLINE $COLOR4/g" "$GLAVA_DIR/bars.glsl"
    sed -i "s/#define COLOR (#[0-9a-fA-F]\{6\} \* GRADIENT)/#define COLOR ($COLOR5 \* GRADIENT)/g" "$GLAVA_DIR/bars.glsl"
    
    # Adjust gradient power for better visualization
    sed -i "s/#define GRADIENT_POWER [0-9]\+/#define GRADIENT_POWER 300/g" "$GLAVA_DIR/bars.glsl"
    
    log "INFO" "Updated bars.glsl with darker vibrant colors"
fi

# Update radial.glsl
if [ -f "$GLAVA_DIR/radial.glsl" ]; then
    backup_file "$GLAVA_DIR/radial.glsl"
    
    # Replace both outline colors and the bar color with vibrant colors
    sed -i "s/#define OUTLINE #[0-9a-fA-F]\{6\}/#define OUTLINE $TERTIARY/g" "$GLAVA_DIR/radial.glsl"
    sed -i "s/#define COLOR (#[0-9a-fA-F]\{6\} \* ((d \/ [0-9]\+) + 1))/#define COLOR ($ACCENT \* ((d \/ 30) + 1))/g" "$GLAVA_DIR/radial.glsl"
    
    log "INFO" "Updated radial.glsl with darker vibrant colors"
fi

# Update graph.glsl
if [ -f "$GLAVA_DIR/graph.glsl" ]; then
    backup_file "$GLAVA_DIR/graph.glsl"
    
    # Replace the color gradient and outline with vibrant colors
    sed -i "s/#define COLOR mix(#[0-9a-fA-F]\{6\}, #[0-9a-fA-F]\{6\}, clamp(pos \/ GRADIENT_SCALE, 0, 1))/#define COLOR mix($ACCENT, $COLOR6, clamp(pos \/ GRADIENT_SCALE, 0, 1))/g" "$GLAVA_DIR/graph.glsl"
    sed -i "s/#define OUTLINE #[0-9a-fA-F]\{6\}/#define OUTLINE $TERTIARY/g" "$GLAVA_DIR/graph.glsl"
    
    log "INFO" "Updated graph.glsl with darker vibrant colors"
fi

# Update wave.glsl
if [ -f "$GLAVA_DIR/wave.glsl" ]; then
    backup_file "$GLAVA_DIR/wave.glsl"
    
    # Use specific RGB values similar to the example (0.7, 0.2, 0.45, 1)
    # But adapt them to our color scheme
    
    # Extract RGB components from hex color (using accent color)
    R=$(printf "%d" 0x${ACCENT:1:2})
    G=$(printf "%d" 0x${ACCENT:3:2})
    B=$(printf "%d" 0x${ACCENT:5:2})
    
    # Find the max value to normalize
    MAX_VAL=$(( R > G ? R : G ))
    MAX_VAL=$(( MAX_VAL > B ? MAX_VAL : B ))
    
    # Calculate normalized values but keep them vibrant
    # We'll aim for values similar to the example but with our color's hue
    R_NORM=$(echo "scale=2; $R / $MAX_VAL * 0.7" | bc)
    G_NORM=$(echo "scale=2; $G / $MAX_VAL * 0.5" | bc)
    B_NORM=$(echo "scale=2; $B / $MAX_VAL * 0.6" | bc)
    
    # Ensure at least one component is high enough
    if (( $(echo "$R_NORM < 0.4 && $G_NORM < 0.4 && $B_NORM < 0.4" | bc) )); then
        # If all values are too low, use fixed vibrant values
        R_NORM=0.7
        G_NORM=0.2
        B_NORM=0.45
    fi
    
    # Replace the base color with these specific RGB values
    sed -i "s/#define BASE_COLOR vec4([0-9.]\+, [0-9.]\+, [0-9.]\+, [0-9.]\+)/#define BASE_COLOR vec4($R_NORM, $G_NORM, $B_NORM, 1)/g" "$GLAVA_DIR/wave.glsl"
    sed -i "s/#define OUTLINE #[0-9a-fA-F]\{6\}/#define OUTLINE $TERTIARY/g" "$GLAVA_DIR/wave.glsl"
    
    log "INFO" "Updated wave.glsl with darker vibrant colors (R:$R_NORM G:$G_NORM B:$B_NORM)"
fi

# Update circle.glsl
if [ -f "$GLAVA_DIR/circle.glsl" ]; then
    backup_file "$GLAVA_DIR/circle.glsl"
    
    # Replace the outline color with a vibrant color
    sed -i "s/#define OUTLINE #[0-9a-fA-F]\{6\}/#define OUTLINE $SECONDARY/g" "$GLAVA_DIR/circle.glsl"
    
    log "INFO" "Updated circle.glsl with darker vibrant colors"
fi

# Update rc.glsl to set a semi-transparent background
if [ -f "$GLAVA_DIR/rc.glsl" ]; then
    backup_file "$GLAVA_DIR/rc.glsl"
    
    # Extract RGB components from COLOR4 for background
    R=$(printf "%d" 0x${COLOR4:1:2})
    G=$(printf "%d" 0x${COLOR4:3:2})
    B=$(printf "%d" 0x${COLOR4:5:2})
    
    # Create a darker background with more opacity for light mode
    # Format is RRGGBBAA in hex (last two digits are alpha, 00=transparent, FF=opaque)
    # We'll use 55 for alpha (about 33% opacity) - more than dark mode for better visibility
    DARK_BG=$(printf "%02x%02x%02x55" $((R/2)) $((G/2)) $((B/2)))
    
    sed -i "s/#request setbg [0-9a-fA-F]\{8\}/#request setbg $DARK_BG/g" "$GLAVA_DIR/rc.glsl"
    
    log "INFO" "Updated rc.glsl with darker semi-transparent background for light mode"
fi

# If GLava was running before, restart it to apply changes
if [ "$GLAVA_WAS_RUNNING" = true ]; then
    log "INFO" "Restarting GLava to apply changes..."
    pkill glava
    # Wait a moment before restarting
    sleep 1
    # Start GLava in the background
    glava --desktop &>/dev/null &
    log "INFO" "GLava restarted with new colors"
else
    log "INFO" "GLava was not running before, not starting it"
fi

log "INFO" "GLava light theme updated successfully"
exit 0 