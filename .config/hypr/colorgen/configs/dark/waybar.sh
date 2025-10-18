#!/bin/bash

# ============================================================================
# Dark Theme Waybar Script for Hyprland Colorgen
# 
# This script applies Material You dark theme colors to Waybar
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
WAYBAR_STYLE="$XDG_CONFIG_HOME/waybar/style.css"

# Source color utilities library
source "$COLORGEN_DIR/color_utils.sh"
source "$COLORGEN_DIR/color_extract.sh"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"


# Note: get_contrast_color, darken_color, and lighten_color are provided by color_utils.sh

# Alias for compatibility
darker_color() {
    darken_color "$@"
}

# Alias for compatibility
lighter_color() {
    lighten_color "$@"
}

log "INFO" "Applying Waybar dark theme with Material You colors"

# Quick exit if files don't exist
if [ ! -f "$COLORGEN_DIR/dark_colors.json" ]; then
    log "ERROR" "Material You dark colors not found. Run material_extract.sh first."
    exit 1
fi

# Create backup once if it doesn't exist
WAYBAR_BACKUP="$XDG_CONFIG_HOME/waybar/backups/style.css.original"
if [ ! -f "$WAYBAR_BACKUP" ] && [ -f "$WAYBAR_STYLE" ]; then
    mkdir -p "$XDG_CONFIG_HOME/waybar/backups"
    cp "$WAYBAR_STYLE" "$WAYBAR_BACKUP" 2>/dev/null || true
    log "INFO" "Created backup of original waybar style"
fi

# Extract colors from dark_colors.json
log "INFO" "Extracting Material You dark colors for Waybar..."

# Extract dark theme colors using color_extract.sh
extract_dark_colors

# Use extracted variables with fallbacks
primary=${dark_primary:-"#bcc2ff"}
secondary=${dark_secondary:-"#c4c5dd"}
tertiary=${dark_tertiary:-"#e6bad6"}
surface=${dark_surface:-"#1b1b1f"}
surface_container=${dark_surface_container:-"#1f1f23"}
surface_container_low=${dark_surface_container_low:-"#1b1b1f"}
surface_container_high=${dark_surface_container_high:-"#26262a"}
on_surface=${dark_on_surface:-"#e4e1e9"}
on_primary=${dark_on_primary:-"#1e2578"}
error=${dark_error:-"#ffb4ab"}
on_error=${dark_on_error:-"#690005"}

# Debug color extraction
log "INFO" "Primary color: $primary"
log "INFO" "Surface color: $surface"
log "INFO" "Error color: $error"

# Set fallback colors for dark theme if needed
[ -z "$primary" ] || [ "$primary" = "null" ] && primary="#d0bcff"
[ -z "$secondary" ] || [ "$secondary" = "null" ] && secondary="#ccc2dc"
[ -z "$tertiary" ] || [ "$tertiary" = "null" ] && tertiary="#efb8c8"
[ -z "$surface" ] || [ "$surface" = "null" ] && surface="#141218"
[ -z "$surface_container" ] || [ "$surface_container" = "null" ] && surface_container="#211f26"
[ -z "$surface_container_low" ] || [ "$surface_container_low" = "null" ] && surface_container_low="#1d1b20"
[ -z "$surface_container_high" ] || [ "$surface_container_high" = "null" ] && surface_container_high="#2b2930"
[ -z "$on_surface" ] || [ "$on_surface" = "null" ] && on_surface="#e6e0e9"
[ -z "$on_primary" ] || [ "$on_primary" = "null" ] && on_primary="#381e72"
[ -z "$error" ] || [ "$error" = "null" ] && error="#f2b8b5"
[ -z "$on_error" ] || [ "$on_error" = "null" ] && on_error="#601410"

# For dark theme, match GTK by using primary_20 if available
if [ -f "$COLORGEN_DIR/colors.conf" ]; then
    primary_20=$(grep -E "^primary-20 = " "$COLORGEN_DIR/colors.conf" | cut -d" " -f3)
    [ -z "$primary_20" ] && primary_20=$(darker_color "$primary" 20)
    surface_container="$primary_20"
else
    surface_container=$(darker_color "$primary" 20)
fi

# Derive additional colors for waybar
accent="$primary"
accent_dark=$(extract_from_json "dark_colors.json" ".primary_dark" "" || echo "")
[ -z "$accent_dark" ] && accent_dark=$(darker_color "$primary" 20)
accent_light=$(extract_from_json "dark_colors.json" ".primary_light" "" || echo "")
[ -z "$accent_light" ] && accent_light=$(lighter_color "$primary" 20)

# Set additional colors
color0="$surface"
color1=$(darker_color "$surface" 10)
color2=$(darker_color "$surface" 5)
color3="$surface_container_low"
color4="$surface_container"
color5="$surface_container_high"
color6=$(lighter_color "$on_surface" 10)
color7="$on_surface"

# Assign semantic colors based on brightness
BORDER_COLOR="$accent"         # Accent color for borders
BACKGROUND_COLOR="$surface_container"     # Darkest for backgrounds
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

# Add transparency variables
BACKGROUND_OPACITY="0.75"
BORDER_OPACITY="0.8"

# Convert hex_to_rgb output to CSS format (comma-separated)
hex_to_rgb_css() {
    local hex=$1
    local rgb_values=$(hex_to_rgb "$hex")  # Call color_utils version
    echo "${rgb_values// /, }"  # Replace spaces with ", " for CSS
}

WARNING_RGB=$(hex_to_rgb_css "$WARNING_COLOR")
CRITICAL_RGB=$(hex_to_rgb_css "$CRITICAL_COLOR")
PANIC_RGB=$(hex_to_rgb_css "$PANIC_COLOR")
TEXT_RGB=$(hex_to_rgb_css "$TEXT_COLOR")
BACKGROUND_RGB=$(hex_to_rgb_css "$BACKGROUND_COLOR")
BORDER_RGB=$(hex_to_rgb_css "$BORDER_COLOR")

# Generate the CSS file with direct values, not CSS variables
log "INFO" "Generating Waybar CSS with dark theme colors..."

cat > "$WAYBAR_STYLE" << EOL
/* Generated dark theme with direct values - $(date +%Y-%m-%d) */

* {
    font-family: "Fira Sans", "Material Design Icons";
    font-size: ${FONT_SIZE};
    font-weight: 500;
    padding: 0;
    margin: 3px;
    min-height: 0;
}

window#waybar {
    background: rgba($(hex_to_rgb_css "$primary_20"), ${BACKGROUND_OPACITY});
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    padding: 0 5px;
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
}

#workspaces button {
    border-radius: ${CIRCULAR_BORDER_RADIUS};
    padding: 0;
    min-width: 30px;
    min-height: 30px;
    margin: 5px 5px;
    font-size: 16px;
    background: transparent;
    color: ${TEXT_COLOR};
    transition: ${TRANSITION};
    border: none;
}

#workspaces button:hover {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
}

#workspaces button.active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    transition: ${TRANSITION};
    padding: 0 10px;
    border-radius: ${BORDER_RADIUS};
    font-size: 18px;
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
    background: rgba(${TEXT_RGB}, ${BACKGROUND_OPACITY});
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
    box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.6);
    font-size: 13px;
    padding: 0 15px;
    margin: 0 5px;
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava, #network, #pulseaudio, #battery, #tray, #custom-selected-color, #custom-system-monitor {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
}

#cava:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-selected-color:hover, #custom-system-monitor:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-selected-color:active, #custom-system-monitor:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    background: rgba($(hex_to_rgb_css "$CHARGING_COLOR"), ${BACKGROUND_OPACITY});
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
        background-color: rgba(${TEXT_RGB}, 0.9);
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
    background: rgba(${BACKGROUND_RGB}, 0.85);
}

#cava.left, #cava.right {
    min-width: 100px;
}

#cava:hover {
    background: ${BORDER_COLOR};
}

#cava.gradient {
    background: linear-gradient(90deg, rgba(${BACKGROUND_RGB}, 0.85) 0%, rgba(${BORDER_RGB}, 0.85) 100%);
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

#cava, #network, #pulseaudio, #battery, #tray, #custom-selected-color, #custom-system-monitor {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
}

#cava:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-selected-color:hover, #custom-system-monitor:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-selected-color:active, #custom-system-monitor:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    background: rgba($(hex_to_rgb_css "$CHARGING_COLOR"), ${BACKGROUND_OPACITY});
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
        background-color: rgba(${TEXT_RGB}, 0.9);
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
    background: rgba(${BACKGROUND_RGB}, 0.85);
}

#cava.left, #cava.right {
    min-width: 100px;
}

#cava:hover {
    background: ${BORDER_COLOR};
}

#cava.gradient {
    background: linear-gradient(90deg, rgba(${BACKGROUND_RGB}, 0.85) 0%, rgba(${BORDER_RGB}, 0.85) 100%);
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
EOL

# Check if script was called with reload-only flag
if [ "${1:-}" = "--reload-only" ]; then
    log "INFO" "CSS file updated. Waybar will reload automatically with reload_style_on_change."
    exit 0
fi

# Just update the CSS file, waybar will reload automatically with reload_style_on_change
log "INFO" "CSS file updated. Waybar will reload automatically with reload_style_on_change."
log "INFO" "Dark theme applied to Waybar successfully!" 
