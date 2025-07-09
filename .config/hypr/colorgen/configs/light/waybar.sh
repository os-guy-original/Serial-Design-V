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

# Derive additional colors for waybar
accent="$primary"
accent_dark=$(jq -r '.primary_dark' "$COLORGEN_DIR/light_colors.json" 2>/dev/null || echo "${primary}")
[ -z "$accent_dark" ] || [ "$accent_dark" = "null" ] && accent_dark=$(darker_color "$primary" 20)
accent_light=$(jq -r '.primary_light' "$COLORGEN_DIR/light_colors.json" 2>/dev/null || echo "${primary}")
[ -z "$accent_light" ] || [ "$accent_light" = "null" ] && accent_light=$(lighter_color "$primary" 20)

# Set additional colors for light theme
color0="$surface"
color1=$(darker_color "$surface" 5)
color2=$(darker_color "$surface" 10)
color3="$surface_container_low"
color4="$surface_container"
color5="$surface_container_high"
color6=$(darker_color "$on_surface" 30)
color7="$on_surface"

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

# Assign semantic colors based on brightness
BORDER_COLOR="$accent"         # Accent color for borders
BACKGROUND_COLOR="$color0"     # Lightest for backgrounds
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
BORDER_WIDTH="2px"
FONT_SIZE="13px"
PADDING="0 14px"
MARGIN="0 4px"
TRANSITION="all 0.1s ease"

# Add transparency variables - slightly less transparency for light theme
BACKGROUND_OPACITY="0.95"
BORDER_OPACITY="0.95"

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
    border-radius: ${BORDER_RADIUS};
    padding: 0;
    margin: 0;
    min-height: 0;
}

window#waybar {
    background: transparent;
    color: ${TEXT_COLOR};
    border: none;
    margin: 6px;
}

.modules-left, .modules-right, .modules-center {
    padding: 0 6px;
    background: transparent;
    margin: 4px 0;
}

.modules-center {
    padding: 0 10px;
}

/* Common module styling with themed borders */
#clock, #workspaces, #pulseaudio, #battery, #tray, #cava, #power-profiles-daemon, 
#custom-launcher, #custom-power, #custom-notification-center, #custom-screenshot, 
#custom-color-picker, #custom-system-monitor, #custom-selected-color, #network, 
#custom-wf-recorder-status, #custom-main-center, #idle_inhibitor, #custom-glava-toggle {
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#custom-launcher {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#custom-launcher:hover {
    padding: 0 16px;
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
    margin: ${MARGIN};
}

#custom-launcher:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

#custom-power {
    padding: ${PADDING};
    color: ${POWER_FG_COLOR};
    background: rgba(${TEXT_RGB}, 0.1);
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
    border: none;
    font-size: 16px;
}

#custom-power:hover {
    padding: 0 16px;
    color: ${POWER_FG_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
}

#custom-power:active {
    background: ${BORDER_COLOR};
    color: ${POWER_FG_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

#custom-notification-center {
    padding: ${PADDING};
    margin: ${MARGIN};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    border-radius: ${BORDER_RADIUS};
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#custom-notification-center:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#custom-notification-center:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

#workspaces {
    padding: 0;
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#workspaces button {
    padding: 0 8px;
    color: ${TEXT_COLOR};
    background: transparent;
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: 3px;
    border: none;
}

#workspaces button:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#workspaces button.active {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
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
    box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.3);
    font-size: 13px;
    padding: 0 15px;
    margin: 0 5px;
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava, #power-profiles-daemon, #custom-screenshot, #network, #pulseaudio, #battery, #tray, #custom-color-picker, #custom-selected-color, #idle_inhibitor, #custom-glava-toggle {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava:hover, #power-profiles-daemon:hover, #custom-screenshot:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-color-picker:hover, #custom-selected-color:hover, #idle_inhibitor:hover, #custom-glava-toggle:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #power-profiles-daemon:active, #custom-screenshot:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-color-picker:active, #custom-selected-color:active, #idle_inhibitor:active, #custom-glava-toggle:active {
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

/* System monitor with special styling */
#custom-system-monitor {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
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

/* Add styling for the main-center button */
#custom-main-center {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
    font-size: 14px;
}

#custom-main-center:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
    padding: 0 16px;
}

#custom-main-center:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.2);
}

tooltip {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    padding: 18px;
    margin: 0;
    font-size: 15px;
    min-width: 1000px;
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

/* Add consistent button styling for all interactive elements */
button, #custom-launcher, #custom-power, #custom-notification-center, 
#clock, #cava, #power-profiles-daemon, #custom-screenshot, 
#network, #pulseaudio, #battery, #tray, #custom-color-picker, 
#custom-selected-color, #idle_inhibitor, #custom-glava-toggle,
#custom-system-monitor {
    border-radius: ${BORDER_RADIUS};
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