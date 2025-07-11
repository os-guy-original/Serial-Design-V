#!/bin/bash

# swaync.sh (Light Theme) - Material You color application for swaync notification center
# This script applies Material You light theme colors to swaync's style.css

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
if [ ! -f "$COLORGEN_DIR/light_colors.json" ]; then
    echo "Error: Material You light colors not found. Run material_extract.sh first."
    exit 1
fi

echo "Extracting Material You light colors for SwayNC..."

# Get required colors from Material You palette
primary=$(jq -r '.primary' "$COLORGEN_DIR/light_colors.json")
secondary=$(jq -r '.secondary' "$COLORGEN_DIR/light_colors.json")
tertiary=$(jq -r '.tertiary' "$COLORGEN_DIR/light_colors.json")
surface=$(jq -r '.surface' "$COLORGEN_DIR/light_colors.json")
surface_container=$(jq -r '.surface_container' "$COLORGEN_DIR/light_colors.json")
surface_container_low=$(jq -r '.surface_container_low' "$COLORGEN_DIR/light_colors.json")
surface_container_lowest=$(jq -r '.surface_container_lowest' "$COLORGEN_DIR/light_colors.json")
surface_container_high=$(jq -r '.surface_container_high' "$COLORGEN_DIR/light_colors.json")
surface_container_highest=$(jq -r '.surface_container_highest' "$COLORGEN_DIR/light_colors.json")
on_surface=$(jq -r '.on_surface' "$COLORGEN_DIR/light_colors.json")
on_surface_variant=$(jq -r '.on_surface_variant' "$COLORGEN_DIR/light_colors.json")
on_primary=$(jq -r '.on_primary' "$COLORGEN_DIR/light_colors.json")
error=$(jq -r '.error' "$COLORGEN_DIR/light_colors.json")
on_error=$(jq -r '.on_error' "$COLORGEN_DIR/light_colors.json")

# Debug color extraction
echo "Primary color: $primary"
echo "Surface color: $surface"
echo "Error color: $error"

# Set fallback colors for light theme if needed
[ -z "$primary" ] || [ "$primary" = "null" ] && primary="#884b6b"
[ -z "$secondary" ] || [ "$secondary" = "null" ] && secondary="#74565f"
[ -z "$tertiary" ] || [ "$tertiary" = "null" ] && tertiary="#7e5538"
[ -z "$surface" ] || [ "$surface" = "null" ] && surface="#fff8f8"
[ -z "$surface_container" ] || [ "$surface_container" = "null" ] && surface_container="#f8f0f2"
[ -z "$surface_container_low" ] || [ "$surface_container_low" = "null" ] && surface_container_low="#fff0f4"
[ -z "$surface_container_lowest" ] || [ "$surface_container_lowest" = "null" ] && surface_container_lowest="#ffffff"
[ -z "$surface_container_high" ] || [ "$surface_container_high" = "null" ] && surface_container_high="#e9e0e3"
[ -z "$surface_container_highest" ] || [ "$surface_container_highest" = "null" ] && surface_container_highest="#eedfe3"
[ -z "$on_surface" ] || [ "$on_surface" = "null" ] && on_surface="#21191d"
[ -z "$on_surface_variant" ] || [ "$on_surface_variant" = "null" ] && on_surface_variant="#504349"
[ -z "$on_primary" ] || [ "$on_primary" = "null" ] && on_primary="#ffffff"
[ -z "$error" ] || [ "$error" = "null" ] && error="#ba1a1a"
[ -z "$on_error" ] || [ "$on_error" = "null" ] && on_error="#ffffff"

# Add opacity to some colors for visual effects - adjusted for light theme
surface_container_high_hover="rgba(81, 67, 73, 0.15)"
surface_container_highest_hover="rgba(81, 67, 73, 0.25)"
secondary_container="rgba(128, 128, 128, 0.15)"
secondary_container_pressed="rgba(128, 128, 128, 0.25)"
secondary_container_alt="rgba(128, 128, 128, 0.2)"
outline="rgba(164, 162, 167, 0.3)"
outline_variant="rgba(128, 127, 132, 0.2)"
scrim="rgba(0, 0, 0, 0.2)"
surface_bright="#21191d"
surface_dim="#6f6a6d"

# Create temp file to avoid write issues
TEMP_STYLE="/tmp/swaync_style.css"

# Apply colors to swaync style
echo "Applying Material You light colors to swaync..."

cat > "$TEMP_STYLE" << EOF
* {
  font-size: 14px;
  transition: 100ms;
  box-shadow: unset;
}

.control-center .notification-row {
  background-color: unset;
}

.control-center .notification-row .notification-background .notification,
.control-center .notification-row .notification-background .notification .notification-content,
.floating-notifications .notification-row .notification-background .notification,
.floating-notifications.background .notification-background .notification .notification-content {
  margin-bottom: unset;
}

.control-center .notification-row .notification-background .notification {
  margin-top: 0.150rem;
}

.control-center .notification-row .notification-background .notification box,
.control-center .notification-row .notification-background .notification widget,
.control-center .notification-row .notification-background .notification .notification-content,
.floating-notifications .notification-row .notification-background .notification box,
.floating-notifications .notification-row .notification-background .notification widget,
.floating-notifications.background .notification-background .notification .notification-content {
  border: unset;
  border-radius: 1.159rem;
  -gtk-outline-radius: 1.159rem;
  
}

.floating-notifications.background .notification-background .notification .notification-content,
.control-center .notification-background .notification .notification-content {
/*  border-top: 1px solid rgba(164, 162, 167, 0.15);
  border-left: 1px solid rgba(164, 162, 167, 0.15);
  border-right: 1px solid rgba(128, 127, 132, 0.15);
  border-bottom: 1px solid rgba(128, 127, 132, 0.15);*/
  background-color: ${surface_container};
  padding: 0.818rem;
  padding-right: unset;
  margin-right: unset;
}

.control-center .notification-row .notification-background .notification.low .notification-content label,
.control-center .notification-row .notification-background .notification.normal .notification-content label,
.floating-notifications.background .notification-background .notification.low .notification-content label,
.floating-notifications.background .notification-background .notification.normal .notification-content label {
  color: ${on_surface_variant};
}

.control-center .notification-row .notification-background .notification.low .notification-content image,
.control-center .notification-row .notification-background .notification.normal .notification-content image,
.floating-notifications.background .notification-background .notification.low .notification-content image,
.floating-notifications.background .notification-background .notification.normal .notification-content image {
  background-color: unset;
  color: ${surface_bright};
}

.control-center .notification-row .notification-background .notification.low .notification-content .body,
.control-center .notification-row .notification-background .notification.normal .notification-content .body,
.floating-notifications.background .notification-background .notification.low .notification-content .body,
.floating-notifications.background .notification-background .notification.normal .notification-content .body {
  color: ${surface_dim};
}

.control-center .notification-row .notification-background .notification.critical .notification-content,
.floating-notifications.background .notification-background .notification.critical .notification-content {
  background-color: ${error};
}

.control-center .notification-row .notification-background .notification.critical .notification-content image,
.floating-notifications.background .notification-background .notification.critical .notification-content image{
  background-color: unset;
  color: ${error};
}

.control-center .notification-row .notification-background .notification.critical .notification-content label,
.floating-notifications.background .notification-background .notification.critical .notification-content label {
  color: ${on_error};
}

.control-center .notification-row .notification-background .notification .notification-content .summary,
.floating-notifications.background .notification-background .notification .notification-content .summary {
  font-family: 'Gabarito', 'Lexend', sans-serif;
  font-size: 0.9909rem;
  font-weight: 500;
}

.control-center .notification-row .notification-background .notification .notification-content .time,
.floating-notifications.background .notification-background .notification .notification-content .time {
  font-family: 'Geist', 'AR One Sans', 'Inter', 'Roboto', 'Noto Sans', 'Ubuntu', sans-serif;
  font-size: 0.8291rem;
  font-weight: 500;
  margin-right: 1rem;
  padding-right: unset;
}

.control-center .notification-row .notification-background .notification .notification-content .body,
.floating-notifications.background .notification-background .notification .notification-content .body {
  font-family: 'Noto Sans', sans-serif;
  font-size: 0.8891rem;
  font-weight: 400;
  margin-top: 0.310rem;
  padding-right: unset;
  margin-right: unset;
}

.control-center .notification-row .close-button,
.floating-notifications.background .close-button {
  background-color: unset;
  border-radius: 100%;
  border: none;
  box-shadow: none;
  margin-right: 13px;
  margin-top: 6px;
  margin-bottom: unset;
  padding-bottom: unset;
  min-height: 20px;
  min-width: 20px;
  text-shadow: none;
}

.control-center .notification-row .close-button:hover,
.floating-notifications.background .close-button:hover {
  background-color: ${surface_container_highest_hover};
}

.control-center {
  border-radius: 1.705rem;
  -gtk-outline-radius: 1.705rem;
  border-top: 1px solid ${outline};
  border-left: 1px solid ${outline};
  border-right: 1px solid ${outline_variant};
  border-bottom: 1px solid ${outline_variant};
  box-shadow: 0px 2px 3px ${scrim};
  margin: 7px;
  background-color: ${surface};
  padding: 1.023rem;
}

.control-center trough {
  background-color: ${secondary};
  border-radius: 9999px;
  -gtk-outline-radius: 9999px;
  min-width: 0.545rem;
  background-color: transparent;  
}

.control-center slider {
  border-radius: 9999px;
  -gtk-outline-radius: 9999px;
  min-width: 0.273rem;
  min-height: 2.045rem;
  background-color: ${surface_container_high};
}

.control-center slider:hover {
  background-color: ${surface_container_high_hover};
}

.control-center slider:active {
  background-color: ${surface_container_highest};
}

/* title widget */

.widget-title {
  padding: 0.341rem;
  margin: unset;
}

.widget-title label {
  font-family: 'Gabarito', 'Lexend', sans-serif;
  font-size: 1.364rem;
  color: ${on_surface};
  margin-left: 0.941rem;
}

.widget-title button {
  border: unset;
  background-color: unset;
  border-radius: 1.159rem;
  -gtk-outline-radius: 1.159rem;
  padding: 0.141rem 0.141rem;
  margin-right: 0.841rem;
}

.widget-title button label {
  font-family: 'Gabarito', sans-serif;
  font-size: 1.0409rem;
  color: ${on_surface};
  margin-right: 0.841rem;
}

.widget-title button:hover {
  background-color: ${secondary_container};
}

.widget-title button:active {
  background-color: ${secondary_container_pressed};
}

/* Buttons widget */

.widget-buttons-grid {
  border-radius: 1.159rem;
  -gtk-outline-radius: 1.159rem;
  padding: 0.341rem;
  background-color: ${surface_container_low};
  padding: unset;
}

.widget-buttons-grid>flowbox {
  padding: unset;
}

.widget-buttons-grid>flowbox>flowboxchild>button:first-child {
  margin-left:unset ;
}

.widget-buttons-grid>flowbox>flowboxchild>button {
  border:none;
  background-color: unset;
  border-radius: 9999px;
  min-width: 5.522rem;
  min-height: 2.927rem;
  padding: unset;
  margin: unset;
}

.widget-buttons-grid>flowbox>flowboxchild>button label {
  font-family: "Materials Symbol Rounded";
  font-size: 1.3027rem;
  color: ${on_surface};
}

.widget-buttons-grid>flowbox>flowboxchild>button:hover {
  background-color: ${secondary_container};
}

.widget-buttons-grid>flowbox>flowboxchild>button:checked {
  background-color: ${primary};
}

.widget-buttons-grid>flowbox>flowboxchild>button:checked label {
  color: ${on_primary};
}


/* Volume widget */

.widget-volume {
  background-color: ${surface_container_low};
  padding: 8px;
  margin: 8px;
  -gtk-outline-radius: 1.159rem;
  -gtk-outline-radius: 1.159rem;
}

.widget-volume trough {
  border:unset;
  background-color: ${secondary_container_alt};
}


.widget-volume trough slider {
  color:unset;
  background-color: ${primary};
  border-radius: 100%;
  min-height: 1.25rem;
}

/* Fix for volume widget app icons in light theme */
.widget-volume image {
  color: ${on_surface};
}

.widget-volume label {
  color: ${on_surface};
}


/* Mpris widget */

.widget-mpris {
  background-color: ${primary};  /* Use primary color as background */
  padding: 8px;
  margin: 8px;  
  border-radius: 1.159rem;
  -gtk-outline-radius: 1.159rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);  /* Add shadow for depth */
}

.widget-mpris-player {
  padding: 8px;
  margin: 8px;
}

.widget-mpris-title {
  font-weight: bold;
  font-size: 1.25rem;
  color: #ffffff;  /* White text */
  text-shadow: 0 1px 1px rgba(0, 0, 0, 0.2);  /* Subtle shadow for readability */
}

.widget-mpris-subtitle {
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.9);  /* Slightly transparent white */
  text-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
}

/* Fix for media player controls in light theme */
.widget-mpris image {
  color: ${primary};
}

.widget-mpris button {
  background-color: #ffffff;  /* White background */
  border-radius: 9999px;
  padding: 4px;
  margin: 2px;
  color: ${primary};
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);  /* Subtle shadow for depth */
}

.widget-mpris button:hover {
  background-color: #f8f8f8;  /* Very slightly off-white on hover */
  box-shadow: 0 2px 3px rgba(0, 0, 0, 0.15);  /* Slightly stronger shadow on hover */
}

.widget-mpris button:active {
  background-color: #f0f0f0;  /* Light gray when pressed */
  box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);  /* Reduced shadow when pressed */
}

.widget-mpris label {
  color: #ffffff;  /* White text */
  text-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
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

# Check if swaync is running
echo "Checking if swaync is running..."
SWAYNC_PID=$(pidof swaync)

# Properly restart swaync
if [ -n "$SWAYNC_PID" ]; then
    echo "SwayNC is running. Killing process..."
    # Save the current state of swaync
    SWAYNC_DND_STATE=$(swaync-client -D 2>/dev/null)
    
    # Kill swaync gracefully first
    killall -TERM swaync
    
    # Give it a moment to terminate
    sleep 0.5
    
    # Force kill if still running
    if pidof swaync >/dev/null; then
        echo "Force killing swaync..."
        killall -9 swaync
    fi
    
    # Wait a moment before restarting
    sleep 0.5
else
    echo "SwayNC not currently running."
    SWAYNC_DND_STATE="false"
fi

# Start swaync
echo "Starting swaync..."
GDK_BACKEND=wayland swaync &

# Wait for swaync to initialize
sleep 1

# Restore DND state if it was on
if [ "$SWAYNC_DND_STATE" = "true" ]; then
    echo "Restoring Do Not Disturb state..."
    swaync-client -dn
fi

echo "Material You light colors applied to swaync successfully!"
echo "SwayNC has been restarted." 