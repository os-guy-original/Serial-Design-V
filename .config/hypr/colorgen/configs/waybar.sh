#!/bin/bash

# Fast waybar.sh - Optimized script to apply colors to Waybar

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

# Path to the generated color files
COLORS_CONF="$CONFIG_DIR/colorgen/colors.conf"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

# Quick exit if files don't exist
[ ! -f "$COLORS_CONF" ] && exit 1

# Create backup once if it doesn't exist
WAYBAR_BACKUP="$HOME/.config/waybar/backups/style.css.original"
if [ ! -f "$WAYBAR_BACKUP" ] && [ -f "$WAYBAR_STYLE" ]; then
mkdir -p "$HOME/.config/waybar/backups"
    cp "$WAYBAR_STYLE" "$WAYBAR_BACKUP" 2>/dev/null || true
fi

# Read colors directly without sourcing
primary=$(grep -E '^primary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent=$(grep -E '^accent =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_dark=$(grep -E '^accent_dark =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_light=$(grep -E '^accent_light =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
secondary=$(grep -E '^secondary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
tertiary=$(grep -E '^tertiary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color0=$(grep -E '^color0 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color1=$(grep -E '^color1 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color2=$(grep -E '^color2 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color3=$(grep -E '^color3 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color4=$(grep -E '^color4 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color5=$(grep -E '^color5 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color6=$(grep -E '^color6 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color7=$(grep -E '^color7 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# Set defaults for missing values
[ -z "$primary" ] && primary="#808080"
[ -z "$accent" ] && accent="#808080"
[ -z "$accent_dark" ] && accent_dark="#606060"
[ -z "$accent_light" ] && accent_light="#a0a0a0"
[ -z "$secondary" ] && secondary="#707070"
[ -z "$tertiary" ] && tertiary="#909090"
[ -z "$color0" ] && color0="#000000"
[ -z "$color1" ] && color1="#202020"
[ -z "$color2" ] && color2="#404040"
[ -z "$color3" ] && color3="#606060"
[ -z "$color4" ] && color4="#808080"
[ -z "$color5" ] && color5="#a0a0a0"
[ -z "$color6" ] && color6="#c0c0c0"
[ -z "$color7" ] && color7="#e0e0e0"

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

# Assign semantic colors based on brightness
BORDER_COLOR="$accent"         # Accent color for borders
BACKGROUND_COLOR="$color0"     # Darkest for backgrounds
TEXT_COLOR="$(get_contrast_color "$BACKGROUND_COLOR")"  # Auto contrast for background
HOVER_TEXT_COLOR="$(get_contrast_color "$accent")"  # Auto contrast for accent when used as background
BORDER_HOVER_TEXT="$(get_contrast_color "$BORDER_COLOR")"  # Auto contrast for border color
WARNING_COLOR="$tertiary"      # Warning color (using tertiary)
CRITICAL_COLOR="$secondary"    # Critical color (using secondary)
CHARGING_COLOR="$color5"       # Charging color
POWER_FG_COLOR="$(get_contrast_color "$accent_light")"  # Auto contrast for power button
PANIC_COLOR="$accent_dark"     # Panic color

# Define variables used in the CSS
BORDER_RADIUS="8px"
BORDER_WIDTH="2px"
FONT_SIZE="13px"
PADDING="0 14px"
MARGIN="0 4px"
TRANSITION="all 0.1s ease"

# Simplified hex_to_rgb function
hex_to_rgb() {
    r=$(printf "%d" 0x${1:1:2})
    g=$(printf "%d" 0x${1:3:2})
    b=$(printf "%d" 0x${1:5:2})
    echo "$r, $g, $b"
}

WARNING_RGB=$(hex_to_rgb "$WARNING_COLOR")
CRITICAL_RGB=$(hex_to_rgb "$CRITICAL_COLOR")
PANIC_RGB=$(hex_to_rgb "$PANIC_COLOR")
TEXT_RGB=$(hex_to_rgb "$TEXT_COLOR")

# Generate the CSS file with direct values, not CSS variables
cat > "$WAYBAR_STYLE" << EOL
/* Generated theme with direct values - $(date +%Y-%m-%d) */

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
#custom-wf-recorder-status, #custom-main-center {
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
}

#custom-launcher {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: ${BACKGROUND_COLOR};
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-power {
    padding: ${PADDING};
    color: ${POWER_FG_COLOR};
    background: ${TEXT_COLOR};
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-notification-center {
    padding: ${PADDING};
    margin: ${MARGIN};
    background: ${BACKGROUND_COLOR};
    border-radius: ${BORDER_RADIUS};
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
}

#custom-notification-center:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#custom-notification-center:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#workspaces {
    padding: 0;
    color: ${TEXT_COLOR};
    background: ${BACKGROUND_COLOR};
    transition: ${TRANSITION};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
}

#workspaces button {
    padding: 0 8px;
    color: ${TEXT_COLOR};
    background: transparent;
    transition: ${TRANSITION};
    border-radius: 6px;
    margin: 3px;
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
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
    background: ${BORDER_COLOR};
    border-radius: ${BORDER_RADIUS};
    margin: ${MARGIN};
    color: ${BORDER_HOVER_TEXT};
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
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
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
}

#cava, #power-profiles-daemon, #custom-screenshot, #network, #pulseaudio, #battery, #tray, #custom-color-picker, #custom-selected-color {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: ${BACKGROUND_COLOR};
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
}

#cava:hover, #power-profiles-daemon:hover, #custom-screenshot:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-color-picker:hover, #custom-selected-color:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #power-profiles-daemon:active, #custom-screenshot:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-color-picker:active, #custom-selected-color:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

/* System monitor with special styling */
#custom-system-monitor {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: ${BACKGROUND_COLOR};
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
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
    background: rgba(${WARNING_RGB}, 0.9);
    color: $(get_contrast_color "$WARNING_COLOR");
}

#custom-system-monitor.critical {
    background: rgba(${CRITICAL_RGB}, 0.9);
    color: $(get_contrast_color "$CRITICAL_COLOR");
    animation: blink 1s infinite alternate;
    border: 1px solid rgba(${CRITICAL_RGB}, 0.9);
}

#custom-system-monitor.panic {
    background: rgba(${PANIC_RGB}, 0.9);
    color: $(get_contrast_color "$PANIC_COLOR");
    animation: panic-blink 0.7s cubic-bezier(.5, 0, 1, 1) infinite alternate;
    font-weight: bold;
    border: 1px solid rgba(${PANIC_RGB}, 0.9);
}

#custom-system-monitor.critical:hover {
    background: rgba(${PANIC_RGB}, 0.9);
}

#battery.charging {
    background: ${CHARGING_COLOR};
    color: $(get_contrast_color "$CHARGING_COLOR");
}

#battery.warning:not(.charging) {
    background: ${WARNING_COLOR};
    color: $(get_contrast_color "$WARNING_COLOR");
}

#battery.critical:not(.charging) {
    background: ${CRITICAL_COLOR};
    color: $(get_contrast_color "$CRITICAL_COLOR");
}

/* Add styling for the main-center button */
#custom-main-center {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: ${BACKGROUND_COLOR};
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid ${BORDER_COLOR};
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

tooltip {
    background: ${BACKGROUND_COLOR};
    border: 1px solid ${BORDER_COLOR};
    border-radius: 6px;
    padding: 8px 12px;
}

tooltip label {
    color: ${TEXT_COLOR};
}

@keyframes blink {
    to {
        background-color: rgba(${TEXT_RGB}, 0.9);
    }
}

@keyframes panic-blink {
    from {
        background: rgba(${CRITICAL_RGB}, 0.9);
    }
    to {
        background: rgba(255, 255, 0, 0.9);
        color: #000000;
    }
}

.warning, .critical {
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
EOL

# Ensure waybar is always restarted with new colors
echo "Restarting Waybar with new colors..."

# Kill any existing waybar instances
pkill waybar &>/dev/null || true

# Wait briefly to ensure waybar is fully terminated
sleep 0.5

# Launch waybar directly - no need to check for flags
echo "Launching waybar..."
/bin/bash -c "waybar &>/dev/null &" 
echo "✅ Waybar launched successfully"

exit 0