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

# Add transparency variables
BACKGROUND_OPACITY="0.9"
BORDER_OPACITY="0.9"

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
BACKGROUND_RGB=$(hex_to_rgb "$BACKGROUND_COLOR")
BORDER_RGB=$(hex_to_rgb "$BORDER_COLOR")

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
#custom-wf-recorder-status, #custom-main-center, #custom-hypridle-toggle, #custom-glava-toggle {
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-power {
    padding: ${PADDING};
    color: ${POWER_FG_COLOR};
    background: rgba(${TEXT_RGB}, ${BACKGROUND_OPACITY});
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
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
    border-radius: 6px;
    margin: 3px;
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
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
    box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.6);
    font-size: 13px;
    padding: 0 15px;
    margin: 0 5px;
    transition: ${TRANSITION};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava, #power-profiles-daemon, #custom-screenshot, #network, #pulseaudio, #battery, #tray, #custom-color-picker, #custom-selected-color, #custom-hypridle-toggle, #custom-glava-toggle {
    padding: ${PADDING};
    color: ${TEXT_COLOR};
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    transition: ${TRANSITION};
    margin: ${MARGIN};
    border: ${BORDER_WIDTH} solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
}

#cava:hover, #power-profiles-daemon:hover, #custom-screenshot:hover, #network:hover, #pulseaudio:hover, #battery:hover, #tray:hover, #custom-color-picker:hover, #custom-selected-color:hover, #custom-hypridle-toggle:hover, #custom-glava-toggle:hover {
    color: ${HOVER_TEXT_COLOR};
    background: ${BORDER_COLOR};
    transition: ${TRANSITION};
}

#cava:active, #power-profiles-daemon:active, #custom-screenshot:active, #network:active, #pulseaudio:active, #battery:active, #tray:active, #custom-color-picker:active, #custom-selected-color:active, #custom-hypridle-toggle:active, #custom-glava-toggle:active {
    background: ${BORDER_COLOR};
    color: ${HOVER_TEXT_COLOR};
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

#custom-hypridle-toggle.disabled {
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
    box-shadow: inset 0 0 4px rgba(0, 0, 0, 0.4);
}

tooltip {
    background: rgba(${BACKGROUND_RGB}, ${BACKGROUND_OPACITY});
    border: 1px solid rgba(${BORDER_RGB}, ${BORDER_OPACITY});
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
EOL

# Check if script was called with reload-only flag
if [ "$1" = "--reload-only" ]; then
    echo "CSS file updated. Waybar will reload automatically with reload_style_on_change."
    exit 0
fi

# Just update the CSS file, waybar will reload automatically with reload_style_on_change
echo "CSS file updated. Waybar will reload automatically with reload_style_on_change."

exit 0