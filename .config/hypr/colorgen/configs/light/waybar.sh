#!/bin/bash

# ============================================================================
# Light Theme Waybar Script for Hyprland Colorgen
# 
# This script applies Material You light theme colors to Waybar
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
WAYBAR_STYLE="$XDG_CONFIG_HOME/waybar/style.css"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

# Function to darken a hex color
darker_color() {
    local hex=$1
    local percent=$2
    
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

# Function to lighten a hex color
lighter_color() {
    local hex=$1
    local percent=$2
    
    # Remove leading # if present
    hex="${hex#\#}"
    
    # Convert hex to RGB
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    # Lighten by increasing each component by the percentage of the distance to 255
    r=$(( r + (255 - r) * percent / 100 ))
    g=$(( g + (255 - g) * percent / 100 ))
    b=$(( b + (255 - b) * percent / 100 ))
    
    # Ensure values are within range
    r=$(( r > 255 ? 255 : r ))
    g=$(( g > 255 ? 255 : g ))
    b=$(( b > 255 ? 255 : b ))
    
    # Convert back to hex
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Function to determine if text should be dark or light based on background color
get_contrast_color() {
    local bg_color="$1"
    # Extract RGB components
    local r=$(printf "%d" 0x${bg_color:1:2})
    local g=$(printf "%d" 0x${bg_color:3:2})
    local b=$(printf "%d" 0x${bg_color:5:2})
    
    # Calculate luminance (perceived brightness)
    # Formula: (0.299*R + 0.587*G + 0.114*B)
    local luminance=$(( (299*r + 587*g + 114*b) / 1000 ))
    
    # Return black for light backgrounds, white for dark backgrounds
    if [ "$luminance" -gt 128 ]; then
        echo "#000000"  # Dark text for light background
    else
        echo "#ffffff"  # Light text for dark background
    fi
}

# Function to convert hex to RGB
hex_to_rgb() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r,$g,$b"
}

log "INFO" "Applying Waybar light theme with Material You colors"

# Quick exit if files don't exist
if [ ! -f "$COLORGEN_DIR/light_colors.json" ]; then
    log "ERROR" "Material You light colors not found. Run material_extract.sh first."
    exit 1
fi

# Create backup once if it doesn't exist
WAYBAR_BACKUP="$XDG_CONFIG_HOME/waybar/backups/style.css.original"
if [ ! -f "$WAYBAR_BACKUP" ] && [ -f "$WAYBAR_STYLE" ]; then
    mkdir -p "$XDG_CONFIG_HOME/waybar/backups"
    cp "$WAYBAR_STYLE" "$WAYBAR_BACKUP" 2>/dev/null || true
    log "INFO" "Created backup of original waybar style"
fi

# Extract colors from light_colors.json
log "INFO" "Extracting Material You light colors for Waybar..."

# Get required colors from Material You palette
primary=$(jq -r '.primary' "$COLORGEN_DIR/light_colors.json")
secondary=$(jq -r '.secondary' "$COLORGEN_DIR/light_colors.json")
tertiary=$(jq -r '.tertiary' "$COLORGEN_DIR/light_colors.json")
surface=$(jq -r '.surface' "$COLORGEN_DIR/light_colors.json")
surface_container=$(jq -r '.surface_container' "$COLORGEN_DIR/light_colors.json")
surface_container_low=$(jq -r '.surface_container_low' "$COLORGEN_DIR/light_colors.json")
surface_container_high=$(jq -r '.surface_container_high' "$COLORGEN_DIR/light_colors.json")
on_surface=$(jq -r '.on_surface' "$COLORGEN_DIR/light_colors.json")
on_primary=$(jq -r '.on_primary' "$COLORGEN_DIR/light_colors.json")
error=$(jq -r '.error' "$COLORGEN_DIR/light_colors.json")
on_error=$(jq -r '.on_error' "$COLORGEN_DIR/light_colors.json")

# Compute surface_container to match GTK light
surface_tint=$(lighter_color "$primary" 55)
surface_r=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:1:2})) / 100 ))
surface_g=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:3:2})) / 100 ))
surface_b=$(( (60 * 250 + 40 * $(printf "%d" 0x${surface_tint:5:2})) / 100 ))
surface_container=$(printf "#%02x%02x%02x" $surface_r $surface_g $surface_b)

primary_95=$(grep -E "^primary-95 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
[ -z "$primary_95" ] && primary_95=$(lighter_color "$primary" 50)

# Debug color extraction
log "INFO" "Primary color: $primary"
log "INFO" "Surface color: $surface"
log "INFO" "Error color: $error"

# Set fallback colors for light theme if needed
[ -z "$primary" ] || [ "$primary" = "null" ] && primary="#6750a4"
[ -z "$secondary" ] || [ "$secondary" = "null" ] && secondary="#625b71"
[ -z "$tertiary" ] || [ "$tertiary" = "null" ] && tertiary="#7d5260"
[ -z "$surface" ] || [ "$surface" = "null" ] && surface="#fffbfe"
[ -z "$surface_container" ] || [ "$surface_container" = "null" ] && surface_container="#f3edf7"
[ -z "$surface_container_low" ] || [ "$surface_container_low" = "null" ] && surface_container_low="#f7f2fa"
[ -z "$surface_container_high" ] || [ "$surface_container_high" = "null" ] && surface_container_high="#ece6f0"
[ -z "$on_surface" ] || [ "$on_surface" = "null" ] && on_surface="#1c1b1f"
[ -z "$on_primary" ] || [ "$on_primary" = "null" ] && on_primary="#ffffff"
[ -z "$error" ] || [ "$error" = "null" ] && error="#b3261e"
[ -z "$on_error" ] || [ "$on_error" = "null" ] && on_error="#ffffff"

# Derive additional colors for waybar
accent="$primary"
accent_dark=$(jq -r '.primary_dark' "$COLORGEN_DIR/light_colors.json" 2>/dev/null || echo "${primary}")
[ -z "$accent_dark" ] || [ "$accent_dark" = "null" ] && accent_dark=$(darker_color "$primary" 20)
accent_light=$(jq -r '.primary_light' "$COLORGEN_DIR/light_colors.json" 2>/dev/null || echo "${primary}")
[ -z "$accent_light" ] || [ "$accent_light" = "null" ] && accent_light=$(lighter_color "$primary" 20)

# Define primary with transparency for background - extract RGB components directly
primary_hex="${primary#\#}"
primary_r=$(printf "%d" 0x${primary_hex:0:2})
primary_g=$(printf "%d" 0x${primary_hex:2:2})
primary_b=$(printf "%d" 0x${primary_hex:4:2})

# Create a lighter version by blending with white (70% white, 30% primary)
primary_r=$(( (70 * 255 + 30 * primary_r) / 100 ))
primary_g=$(( (70 * 255 + 30 * primary_g) / 100 ))
primary_b=$(( (70 * 255 + 30 * primary_b) / 100 ))
primary_20="$primary_r,$primary_g,$primary_b"

# Set additional colors for light theme
color0="$surface"
color1=$(darker_color "$surface" 5)
color2=$(darker_color "$surface" 10)
color3="$surface_container_low"
color4="$surface_container"
color5="$surface_container_high"
color6=$(darker_color "$on_surface" 30)
color7="$on_surface"

# Assign semantic colors based on brightness
BORDER_COLOR="$accent"         # Accent color for borders
BACKGROUND_COLOR="$surface_container"     # Lightest for backgrounds
BACKGROUND_COLOR=$(darker_color "$BACKGROUND_COLOR" 10)
TEXT_COLOR="$(get_contrast_color "$BACKGROUND_COLOR")"  # Auto contrast for background
HOVER_TEXT_COLOR="$(get_contrast_color "$accent")"  # Auto contrast for accent when used as background
BORDER_HOVER_TEXT="$(get_contrast_color "$BORDER_COLOR")"  # Auto contrast for border color
WARNING_COLOR="$tertiary"      # Warning color (using tertiary)
CRITICAL_COLOR="$error"        # Critical color (using error)
CHARGING_COLOR="$color5"       # Charging color
POWER_FG_COLOR="$(get_contrast_color "$accent_light")"  # Auto contrast for power button
PANIC_COLOR="$accent_dark"     # Panic color

# Define variables used in the CSS
BORDER_RADIUS="30px"
MODULE_BORDER_RADIUS="12px"
CIRCULAR_BORDER_RADIUS="100%"
BORDER_WIDTH="2px"
FONT_SIZE="13px"
PADDING="0 12px"
CIRCULAR_PADDING="0 0"
MARGIN="0 2px"
CIRCULAR_MARGIN="0 3px"
TRANSITION="all 0.1s ease"
ICON_SIZE="40px"

# Add transparency variables - slightly less transparency for light theme
BACKGROUND_OPACITY="0.65"
BORDER_OPACITY="0.85"

# Convert hex colors to RGB format for CSS
BACKGROUND_RGB=$(hex_to_rgb "$BACKGROUND_COLOR")
BORDER_RGB=$(hex_to_rgb "$BORDER_COLOR")
TEXT_RGB=$(hex_to_rgb "$TEXT_COLOR")
WARNING_RGB=$(hex_to_rgb "$WARNING_COLOR")
CRITICAL_RGB=$(hex_to_rgb "$CRITICAL_COLOR")
PANIC_RGB=$(hex_to_rgb "$PANIC_COLOR")

# Generate the CSS file with direct values, not CSS variables
log "INFO" "Generating Waybar CSS with light theme colors..."

cat > "$WAYBAR_STYLE" << EOL
/* Generated light theme with direct values - $(date +%Y-%m-%d) */

* {
    font-family: "Fira Sans", "Material Design Icons";
    font-size: ${FONT_SIZE};
    font-weight: 500;
    padding: 0;
    margin: 3px;
    min-height: 0;
}

window#waybar {
    background: rgba(${primary_20}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    border: none;
    margin: 0;
    border-radius: 0;
}

.modules-left, .modules-right, .modules-center {
    padding: 0 4px;
    background: transparent;
    margin: 2px 0px;
}

.modules-center {
    padding: 0 6px;
}

.modules-left {
    border-radius: 0 ${BORDER_RADIUS} ${BORDER_RADIUS} 0;
}

.modules-right {
    border-radius: ${BORDER_RADIUS} 0 0 ${BORDER_RADIUS};
}

/* Common styling for all single-icon circular modules */
.circular-icon-module {
    border-radius: ${CIRCULAR_BORDER_RADIUS};
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    margin: ${CIRCULAR_MARGIN};
    font-size: 18px;
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

.circular-icon-module:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    /* Keep the same dimensions on hover */
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    padding: 0;
}

.circular-icon-module:active {
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

/* Apply circular module styling to specific modules */
#custom-launcher, #custom-power, #custom-notification-center, 
#custom-screenshot, #custom-color-picker, #custom-main-center, 
#idle_inhibitor, #custom-glava-toggle, #power-profiles-daemon,
#custom-wf-recorder, #custom-hypridle-toggle, #custom-performance-indicator {
    border-radius: ${CIRCULAR_BORDER_RADIUS};
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    margin: ${CIRCULAR_MARGIN};
    font-size: 18px;
    transition: ${TRANSITION};
}

/* Keep other modules with standard rounded corners */
#network, #pulseaudio, #battery, #tray, #custom-selected-color, 
#custom-system-monitor, #cava {
    border-radius: ${MODULE_BORDER_RADIUS};
}

/* Workspace styling */
#workspaces {
    padding: 0;
    background: transparent;
    transition: ${TRANSITION};
    border-radius: 0;
    margin: ${MARGIN};
}

#workspaces button {
    border-radius: ${CIRCULAR_BORDER_RADIUS};
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    margin: ${CIRCULAR_MARGIN};
    font-size: 18px;
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
    border: none;
}

#workspaces button:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    padding: 0;
}

#workspaces button.active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

/* Custom styling for specific circular modules */
#custom-launcher {
    background: transparent;
    color: ${TEXT_COLOR};
}

#custom-launcher:hover {
    background: transparent;
    color: ${BORDER_COLOR};
}

#custom-launcher:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

#custom-power {
    color: ${POWER_FG_COLOR};
    background: rgba(${TEXT_RGB}, 0.1);
    transition: ${TRANSITION};
}

#custom-power:hover {
    background: ${BORDER_COLOR};
    color: ${POWER_FG_COLOR};
    transition: ${TRANSITION};
}

#custom-power:active {
    background: ${BORDER_COLOR};
    color: ${POWER_FG_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-notification-center {
    background: transparent;
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-notification-center:hover {
    background: transparent;
    color: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#custom-notification-center:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

#custom-main-center {
    background: transparent;
    color: ${TEXT_COLOR};
}

#custom-main-center:hover {
    background: transparent;
    color: ${BORDER_COLOR};
}

#custom-main-center:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

#custom-deco-switcher {
    background: transparent;
    color: ${TEXT_COLOR};
}

#custom-deco-switcher:hover {
    background: transparent;
    color: ${BORDER_COLOR};
}

#custom-deco-switcher:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

/* Additional circular modules styling */
#custom-wf-recorder, #custom-hypridle-toggle, #custom-performance-indicator {
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-wf-recorder:hover, #custom-hypridle-toggle:hover, #custom-performance-indicator:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-wf-recorder:active, #custom-hypridle-toggle:active, #custom-performance-indicator:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#clock {
    padding: ${PADDING};
    font-weight: 600;
    background: rgba(${BORDER_RGB}, ${BACKGROUND_OPACITY});
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
    color: ${BORDER_HOVER_TEXT};
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
    font-size: 14px;
}

#clock:hover {
    color: ${BORDER_HOVER_TEXT};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
    font-size: 16px;
    padding: 0 18px;
}

#clock:active {
    background: ${BORDER_COLOR};
    color: ${BORDER_HOVER_TEXT};
    box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.4);
    font-size: 13px;
    padding: 0 15px;
    margin: 0 5px;
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava, #network, #pulseaudio, #battery, #tray, #custom-selected-color {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
}

#cava:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-selected-color:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-selected-color:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

#idle_inhibitor.activated {
    background: rgba(${BORDER_RGB}, ${BACKGROUND_OPACITY});
    color: ${HOVER_TEXT_COLOR};
}

#custom-glava-toggle.active {
    background: rgba(${BORDER_RGB}, ${BACKGROUND_OPACITY});
    color: ${HOVER_TEXT_COLOR};
}

tooltip {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    padding: 18px;
    margin: 0;
    font-size: 15px;
}

tooltip label {
    color: ${HOVER_TEXT_COLOR};
    font-weight: 400;
    font-size: 15px;
}

@keyframes blink {
    to {
        background-color: rgba(${TEXT_RGB}, 0.2);
    }
}

@keyframes panic-blink {
    to {
        background: rgba(${PANIC_RGB}, 0.9);
        color: $(get_contrast_color "$PANIC_COLOR");
    }
    from {
        background: rgba(${CRITICAL_RGB}, 0.9);
        color: $(get_contrast_color "$CRITICAL_COLOR");
    }
}

.warning, .critical {
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: cubic-bezier(.5, 0, 1, 1);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

/* Specific styling for cava module */
#cava {
    padding: 0 10px;
    min-width: 180px;
    background: rgba(${BACKGROUND_RGB}, 0.9);
}

#cava.left, #cava.right {
    min-width: 100px;
}

#cava:hover {
    background: ${BORDER_COLOR};
}

#cava.gradient {
    background: linear-gradient(90deg, rgba(${BACKGROUND_RGB}, 0.9) 0%, rgba(${BORDER_RGB}, 0.9) 100%);
}

/* Cava bars will use the format-icons colors */
#cava > * {
    color: ${BORDER_COLOR};
    font-size: 16px;
    font-weight: bold;
    padding: 0 1px;
    transition: color 0.1s ease;
}

#cava:hover > * {
    color: ${BACKGROUND_COLOR};
}

/* Make power-profiles-daemon circular with single icon */
#power-profiles-daemon {
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#power-profiles-daemon:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

#power-profiles-daemon:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

/* Make idle_inhibitor circular with single icon */
#idle_inhibitor {
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#idle_inhibitor:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

#idle_inhibitor:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

/* Make glava-toggle circular with single icon */
#custom-glava-toggle {
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-glava-toggle:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-glava-toggle:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-glava-toggle.active {
    background: rgba(${BORDER_RGB}, ${BACKGROUND_OPACITY});
    color: ${HOVER_TEXT_COLOR};
}

/* Make screenshot button circular with transparent background */
#custom-screenshot {
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    background: transparent;
    color: ${TEXT_COLOR};
}

#custom-screenshot:hover {
    background: transparent;
    color: ${BORDER_COLOR};
}

#custom-screenshot:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

/* Make color-picker circular with transparent background */
#custom-color-picker {
    padding: 0;
    min-width: ${ICON_SIZE};
    min-height: ${ICON_SIZE};
    background: transparent;
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
}

#custom-color-picker:hover {
    background: transparent;
    color: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#custom-color-picker:active {
    color: ${BORDER_COLOR};
    box-shadow: none;
}

/* Add consistent button styling for all interactive elements */
button, #custom-launcher, #custom-power, #custom-notification-center, 
#clock, #cava, #power-profiles-daemon, #custom-screenshot, 
#network, #pulseaudio, #battery, #tray, #custom-color-picker, 
#custom-selected-color, #idle_inhibitor, #custom-glava-toggle,
#custom-system-monitor, #custom-wf-recorder, #custom-hypridle-toggle,
#custom-performance-indicator {
    border-radius: ${BORDER_RADIUS};
}

/* Override border-radius for circular buttons */
#custom-launcher, #custom-power, #custom-notification-center, 
#custom-screenshot, #custom-color-picker, #custom-main-center, 
#idle_inhibitor, #custom-glava-toggle, #power-profiles-daemon,
#custom-wf-recorder, #custom-hypridle-toggle, #custom-performance-indicator {
    border-radius: ${CIRCULAR_BORDER_RADIUS};
}

/* System monitor with special styling */
#custom-system-monitor {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    font-family: "Fira Sans", "Material Design Icons", monospace;
    letter-spacing: 1px;
}

#custom-system-monitor:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
    padding: 0 18px;
}

#custom-system-monitor:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

#custom-system-monitor.warning {
    background: rgba(${WARNING_RGB}, 0.8);
    color: $(get_contrast_color "$WARNING_COLOR");
}

#custom-system-monitor.critical {
    background: rgba(${CRITICAL_RGB}, 0.8);
    color: $(get_contrast_color "$CRITICAL_COLOR");
    animation: blink 1s infinite alternate;
    border: 1px solid rgba(${CRITICAL_RGB}, 0.8);
}

#custom-system-monitor.panic {
    background: rgba(${PANIC_RGB}, 0.8);
    color: $(get_contrast_color "$PANIC_COLOR");
    animation: panic-blink 0.7s cubic-bezier(.5, 0, 1, 1) infinite alternate;
    font-weight: bold;
    border: 1px solid rgba(${PANIC_RGB}, 0.8);
}

#custom-system-monitor.critical:hover {
    background: rgba(${PANIC_RGB}, 0.8);
}

#battery.charging {
    background: rgba($(hex_to_rgb "$CHARGING_COLOR"), ${BACKGROUND_OPACITY});
    color: $(get_contrast_color "$CHARGING_COLOR");
}

#battery.warning:not(.charging) {
    background: rgba(${WARNING_RGB}, 0.8);
    color: $(get_contrast_color "$WARNING_COLOR");
}

#battery.critical:not(.charging) {
    background: rgba(${CRITICAL_RGB}, 0.8);
    color: $(get_contrast_color "$CRITICAL_COLOR");
}

EOL

# Check if script was called with reload-only flag
if [ "${1:-}" = "--reload-only" ]; then
    log "INFO" "CSS file updated. Waybar will reload automatically with reload_style_on_change."
    exit 0
fi

# Just update the CSS file, waybar will reload automatically with reload_style_on_change
log "INFO" "CSS file updated. Waybar will reload automatically with reload_style_on_change."
log "INFO" "Light theme applied to Waybar successfully!" 
