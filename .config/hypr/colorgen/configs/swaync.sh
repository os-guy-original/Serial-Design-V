#!/bin/bash

# swaync.sh - Material You color application for swaync notification center
# This script applies Material You colors to swaync's style.css

# Define paths
CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
SWAYNC_DIR="$HOME/.config/swaync"
SWAYNC_STYLE="$SWAYNC_DIR/style.css"

# Check if swaync config exists
if [ ! -d "$SWAYNC_DIR" ]; then
    echo "Error: swaync config directory not found at $SWAYNC_DIR"
    exit 1
fi

# Create backup if it doesn't exist
if [ ! -f "${SWAYNC_STYLE}.bak" ]; then
    echo "Creating backup of original swaync style..."
    cp "$SWAYNC_STYLE" "${SWAYNC_STYLE}.bak"
fi

# Load Material You colors
if [ ! -f "$COLORGEN_DIR/dark_colors.json" ]; then
    echo "Error: Material You colors not found. Run material_extract.sh first."
    exit 1
fi

echo "Extracting Material You colors for SwayNC..."

# Get required colors from Material You palette
primary=$(jq -r '.primary' "$COLORGEN_DIR/dark_colors.json")
secondary=$(jq -r '.secondary' "$COLORGEN_DIR/dark_colors.json")
tertiary=$(jq -r '.tertiary' "$COLORGEN_DIR/dark_colors.json")
surface=$(jq -r '.surface' "$COLORGEN_DIR/dark_colors.json")
surface_container=$(jq -r '.surface_container' "$COLORGEN_DIR/dark_colors.json")
surface_container_low=$(jq -r '.surface_container_low' "$COLORGEN_DIR/dark_colors.json")
surface_container_lowest=$(jq -r '.surface_container_lowest' "$COLORGEN_DIR/dark_colors.json")
on_surface=$(jq -r '.on_surface' "$COLORGEN_DIR/dark_colors.json")
on_primary=$(jq -r '.on_primary' "$COLORGEN_DIR/dark_colors.json")
error=$(jq -r '.error' "$COLORGEN_DIR/dark_colors.json")

# Debug color extraction
echo "Primary color: $primary"
echo "Surface color: $surface"
echo "Error color: $error"

# Set fallback colors if needed
[ -z "$primary" ] || [ "$primary" = "null" ] && primary="#78aeed"
[ -z "$secondary" ] || [ "$secondary" = "null" ] && secondary="#5294e2"
[ -z "$tertiary" ] || [ "$tertiary" = "null" ] && tertiary="#5294e2"
[ -z "$surface" ] || [ "$surface" = "null" ] && surface="#333333"
[ -z "$surface_container" ] || [ "$surface_container" = "null" ] && surface_container="#2a2a2a"
[ -z "$surface_container_low" ] || [ "$surface_container_low" = "null" ] && surface_container_low="#222222"
[ -z "$surface_container_lowest" ] || [ "$surface_container_lowest" = "null" ] && surface_container_lowest="#1a1a1a"
[ -z "$on_surface" ] || [ "$on_surface" = "null" ] && on_surface="#e0e0e0"
[ -z "$on_primary" ] || [ "$on_primary" = "null" ] && on_primary="#ffffff"
[ -z "$error" ] || [ "$error" = "null" ] && error="#dd3a55"

# Add opacity to some colors for visual effects
primary_hover="${primary}e0"
primary_active="${primary}f0"
surface_container_hover="${surface_container}e0" 
surface_container_active="${surface_container}f0"
bg_color="${surface_container_lowest}f0"
border_color="rgba(255, 255, 255, 0.1)"

# Create temp file to avoid write issues
TEMP_STYLE="/tmp/swaync_style.css"

# Apply colors to swaync style
echo "Applying Material You colors to swaync..."

cat > "$TEMP_STYLE" << EOF
* {
  font-family: "Cantarell", "Roboto", sans-serif;
  font-size: 13px;
  font-weight: 400;
  border-radius: 8px;
  margin: 0;
  padding: 0;
  min-height: 0;
}

.notification-row {
  outline: none;
  margin: 6px;
  padding: 6px;
  background: ${surface_container_lowest};
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: all 0.2s ease;
}

.notification-row:hover {
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.notification-row:focus {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.notification {
  margin: 6px;
  padding: 0;
  border-radius: 8px;
  background: transparent;
}

.notification-content {
  background: transparent;
  padding: 6px;
  border-radius: 8px;
}

.close-button {
  background: ${surface_container_low};
  color: ${on_surface};
  text-shadow: none;
  padding: 0;
  border-radius: 100%;
  margin-top: 10px;
  margin-right: 10px;
  box-shadow: none;
  border: none;
  min-width: 24px;
  min-height: 24px;
  transition: all 0.2s ease;
}

.close-button:hover {
  background: ${error};
  color: ${on_primary};
  transition: all 0.2s ease;
}

.notification-default-action,
.notification-action {
  padding: 4px;
  margin: 0;
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  color: ${on_surface};
  transition: all 0.2s ease;
}

.notification-default-action:hover,
.notification-action:hover {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: ${on_primary};
  transition: all 0.2s ease;
}

.notification-default-action:active,
.notification-action:active {
  background: ${surface};
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: ${on_primary};
}

/* When alternative actions are visible */
.notification-default-action:not(:only-child) {
  border-bottom-left-radius: 0px;
  border-bottom-right-radius: 0px;
}

.notification-action {
  border-radius: 0px;
  border-top: none;
  border-right: none;
}

/* add bottom border radius to last button */
.notification-action:last-child {
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

.inline-reply {
  margin-top: 8px;
}

.inline-reply-entry {
  background: ${surface_container_low};
  color: ${on_surface};
  caret-color: ${on_surface};
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  transition: all 0.2s ease;
}

.inline-reply-entry:focus {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.15);
  transition: all 0.2s ease;
}

.inline-reply-button {
  margin-left: 4px;
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  color: ${on_surface};
  transition: all 0.2s ease;
}

.inline-reply-button:hover {
  background: ${primary};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.2s ease;
}

.inline-reply-button:active {
  background: ${primary_active};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.image {
  margin-right: 8px;
  border-radius: 8px;
}

.body-image {
  margin-top: 6px;
  background-color: ${surface_container};
  border-radius: 8px;
}

.summary {
  font-size: 14px;
  font-weight: 500;
  background: transparent;
  color: ${on_primary};
  text-shadow: none;
}

.time {
  font-size: 12px;
  font-weight: normal;
  color: ${on_surface};
  margin-right: 6px;
  text-shadow: none;
}

.body {
  font-size: 13px;
  font-weight: normal;
  background: transparent;
  color: ${on_surface};
  text-shadow: none;
}

/* Control Center */

.control-center {
  background: ${surface_container_lowest};
  border: 1px solid ${border_color};
  border-radius: 12px;
  margin: 8px;
  padding: 12px;
}

.control-center-list {
  background: transparent;
}

.control-center-list-placeholder {
  opacity: 0.5;
}

.floating-notifications {
  background: transparent;
}

.blank-window {
  background: transparent;
}

.widget-title {
  color: ${on_primary};
  font-size: 1.3em;
  font-weight: bold;
  margin: 8px;
}

.widget-title button {
  font-size: 0.8em;
  font-weight: normal;
  color: ${on_surface};
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  margin-right: 8px;
  transition: all 0.2s ease;
}

.widget-title button:hover {
  background: ${primary};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.2s ease;
}

.widget-title button:active {
  background: ${primary_active};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.widget-dnd {
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  margin: 12px;
  padding: 6px 12px;
  color: ${on_surface};
}

.widget-dnd:hover {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.widget-dnd .toggle {
  background: ${surface};
  color: ${on_surface};
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  transition: all 0.2s ease;
}

.widget-dnd .toggle:checked {
  background: ${primary};
  color: ${on_primary};
}

.widget-dnd .toggle:active {
  background: ${primary_active};
}

.widget-dnd .toggle slider {
  background: ${on_surface};
  border-radius: 16px;
  min-width: 18px;
  min-height: 18px;
  transition: all 0.2s ease;
}

.widget-buttons-grid {
  margin: 8px;
  padding: 4px;
  border-radius: 12px;
  background: transparent;
}

.widget-buttons-grid > flowbox > flowboxchild > button {
  background: ${surface_container_low};
  color: ${on_surface};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 8px;
  margin: 4px;
  min-width: 70px;
  min-height: 50px;
  transition: all 0.2s ease;
}

.widget-buttons-grid > flowbox > flowboxchild > button:hover {
  background: ${primary_hover};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.widget-buttons-grid > flowbox > flowboxchild > button:active {
  background: ${primary_active};
  color: ${on_primary};
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.widget-buttons-grid > flowbox > flowboxchild > button label {
  font-size: 1.1em;
  font-weight: 500;
}

.widget-mpris {
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  margin: 8px;
  padding: 12px;
  color: ${on_surface};
}

.widget-mpris:hover {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.widget-mpris-player {
  padding: 8px;
  margin: 4px;
}

.widget-mpris-title {
  font-weight: bold;
  font-size: 1.1em;
}

.widget-mpris-subtitle {
  font-size: 0.9em;
}

.widget-mpris box.horizontal {
  padding: 0px;
}

.widget-mpris image {
  border-radius: 8px;
  padding: 0px;
  margin-right: 12px;
}

.widget-mpris .title {
  font-weight: bold;
  font-size: 1.1em;
  color: ${on_primary};
}

.widget-mpris .subtitle {
  font-size: 0.9em;
  color: ${on_surface};
}

.widget-mpris-player box {
  padding: 4px 0px;
}

.widget-mpris .progress-bar {
  min-height: 6px;
  border-radius: 3px;
  background: ${surface};
}

.widget-mpris .progress-bar highlight {
  border-radius: 3px;
  background: ${primary};
}

.widget-mpris .media-buttons {
  margin-top: 6px;
}

.widget-mpris-player button {
  background: ${surface_container};
  color: ${on_surface};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 100%;
  padding: 4px;
  margin: 2px;
  min-width: 32px;
  min-height: 32px;
}

.widget-mpris-player button.previous,
.widget-mpris-player button.next {
  padding: 4px 8px;
  margin: 2px;
}

.widget-mpris-player button.play-pause {
  padding: 6px;
  margin: 2px 4px;
}

.widget-mpris-player button:hover {
  background: ${primary_hover};
  color: ${on_primary};
}

.widget-mpris-player button:active {
  background: ${primary_active};
  color: ${on_primary};
}

.widget-mpris .time-info {
  font-size: 0.8em;
  color: ${on_surface};
}

.widget-volume {
  background: ${surface_container_low};
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  margin: 8px;
  padding: 12px;
}

.widget-volume:hover {
  background: ${surface_container};
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.widget-volume .title {
  font-weight: bold;
  color: ${on_primary};
}

.widget-volume trough {
  background: ${surface};
  border-radius: 8px;
  min-height: 14px;
}

.widget-volume trough highlight {
  background: ${primary};
  border-radius: 8px;
}

.widget-volume trough slider {
  background: ${on_primary};
  border-radius: 8px;
  min-width: 14px;
  min-height: 14px;
}

/* Critical notification styling */
.critical {
  background: ${error};
  color: ${on_primary};
}

.critical:hover {
  background: ${error}e0;
}

.critical:focus {
  background: ${error}d0;
}
EOF

# Check if temp file was created
if [ ! -s "$TEMP_STYLE" ]; then
    echo "Error: Failed to create temporary CSS file"
    exit 1
fi

# Copy temp file to destination with sudo if needed
if [ ! -w "$SWAYNC_STYLE" ]; then
    echo "Need elevated permissions to write to $SWAYNC_STYLE"
    sudo cp "$TEMP_STYLE" "$SWAYNC_STYLE"
else
    cp "$TEMP_STYLE" "$SWAYNC_STYLE"
fi

# Ensure correct permissions
chmod 644 "$SWAYNC_STYLE"

# Try multiple methods to reload swaync
echo "Reloading swaync..."

# Method 1: Using signal
if pidof swaync > /dev/null; then
    echo "Reloading swaync using SIGUSR2..."
    killall -SIGUSR2 swaync
    
    # Give some time for reload
    sleep 1
    
    # Method 2: Restart if needed
    if ! pidof swaync > /dev/null; then
        echo "Restarting swaync..."
        swaync &
    fi
else
    echo "SwayNC not running, starting it..."
    swaync &
fi

echo "Material You colors applied to swaync successfully!"
echo "If colors aren't applied, try manually restarting swaync with: killall swaync && swaync &"
exit 0 