#!/bin/bash

# swaync.sh (Light Theme) - Material You color application for swaync notification center
# Applies Material You light theme colors to swaync's style.css
# Matches ~/.config/swaync style and best practices

# Define paths
CONFIG_DIR="$HOME/.config/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
SWAYNC_DIR="$HOME/.config/swaync"
SWAYNC_STYLE="$SWAYNC_DIR/style.css"

# Check if swaync config exists
if [ ! -d "$SWAYNC_DIR" ]; then
    echo "Hata: swaync yapılandırma dizini $SWAYNC_DIR konumunda bulunamadı"
    exit 1
fi

# Always create a backup before modifying style.css
if [ -f "$SWAYNC_STYLE" ]; then
    cp "$SWAYNC_STYLE" "${SWAYNC_STYLE}.bak"
fi

# Load Material You colors
if [ ! -f "$COLORGEN_DIR/light_colors.json" ]; then
    echo "Hata: Material You renkleri bulunamadı. Önce material_extract.sh'i çalıştırın."
    exit 1
fi

echo "SwayNC için Material You açık renkleri çıkarılıyor..."

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
on_error_container=$(jq -r '.on_error_container' "$COLORGEN_DIR/light_colors.json")

# Debug color extraction
echo "Primary color: $primary"
echo "Surface color: $surface"
echo "Error color: $error"

# Set fallback colors if needed
[ -z "$primary" ] || [ "$primary" = "null" ] && primary="#7a555e"
[ -z "$secondary" ] || [ "$secondary" = "null" ] && secondary="#6d5c61"
[ -z "$tertiary" ] || [ "$tertiary" = "null" ] && tertiary="#915200"
[ -z "$surface" ] || [ "$surface" = "null" ] && surface="#fffbff"
[ -z "$surface_container" ] || [ "$surface_container" = "null" ] && surface_container="#f3edf1"
[ -z "$surface_container_low" ] || [ "$surface_container_low" = "null" ] && surface_container_low="#f8eef2"
[ -z "$surface_container_lowest" ] || [ "$surface_container_lowest" = "null" ] && surface_container_lowest="#ffffff"
[ -z "$surface_container_high" ] || [ "$surface_container_high" = "null" ] && surface_container_high="#eee7ec"
[ -z "$surface_container_highest" ] || [ "$surface_container_highest" = "null" ] && surface_container_highest="#e8e1e5"
[ -z "$on_surface" ] || [ "$on_surface" = "null" ] && on_surface="#1e1b1c"
[ -z "$on_surface_variant" ] || [ "$on_surface_variant" = "null" ] && on_surface_variant="#4f4448"
[ -z "$on_primary" ] || [ "$on_primary" = "null" ] && on_primary="#ffffff"
[ -z "$error" ] || [ "$error" = "null" ] && error="#ba1a1a"
[ -z "$on_error" ] || [ "$on_error" = "null" ] && on_error="#ffffff"
[ -z "$on_error_container" ] || [ "$on_error_container" = "null" ] && on_error_container="#ffdad6"

# Add opacity to some colors for visual effects
secondary_container="rgba(0, 0, 0, 0.2)"
secondary_container_pressed="rgba(0, 0, 0, 0.4)"
secondary_container_alt="rgba(0, 0, 0, 0.3)"
surface_container_high_hover="rgba(0, 0, 0, 0.1)"
surface_container_highest_hover="rgba(0, 0, 0, 0.15)"
scrim="rgba(0, 0, 0, 0.75)"
surface_bright="#fffbff"
surface_dim="#d0c3c7"

# Create temp file to avoid write issues
TEMP_STYLE="/tmp/swaync_light_style.css"

# Apply colors to swaync style
echo "SwayNC'ye Material You açık renkleri uygulanıyor..."

cat > "$TEMP_STYLE" << EOF
* {
  font-size: 14px;
  transition: 100ms;
  box-shadow: unset;
}

/* Add backdrop blur and transparency for modern look */
.control-center {
  background-color: rgba($(printf '%d' 0x${surface_container_lowest:1:2}) , $(printf '%d' 0x${surface_container_lowest:3:2}) , $(printf '%d' 0x${surface_container_lowest:5:2}), 0.7);
  backdrop-filter: blur(16px) saturate(120%);
  border-radius: 1.5rem;
  box-shadow: 0 8px 32px 0 rgba(0,0,0,0.15);
  border: 1px solid rgba(0,0,0,0.06);
}

/* Make floating notifications background completely transparent and remove noise */
.floating-notifications.background {
  background: transparent !important;
  box-shadow: none !important;
  border: none !important;
  pointer-events: none; /* Make notifications click-through */
}


.control-center .notification-row {
  background-color: unset;
}

/* Notification group container improvements */
.control-center .notification-group {
  background: linear-gradient(90deg, rgba($(printf '%d' 0x${surface_container_low:1:2}) , $(printf '%d' 0x${surface_container_low:3:2}) , $(printf '%d' 0x${surface_container_low:5:2}), 0.85) 0%, rgba($(printf '%d' 0x${surface_container_low:1:2}) , $(printf '%d' 0x${surface_container_low:3:2}) , $(printf '%d' 0x${surface_container_low:5:2}), 0.95) 100%);
  border-radius: 1.2rem;
  box-shadow: 0 2px 12px 0 rgba(0,0,0,0.08);
  border: 1px solid rgba(0,0,0,0.04);
  margin-bottom: 0.7rem;
  padding: 0.5rem 0.7rem;
}


.control-center .notification-row .notification-background .notification,
.control-center .notification-row .notification-background .notification .notification-content,
.floating-notifications .notification-row .notification-background .notification,
.floating-notifications.background .notification-background .notification .notification-content {
  margin-bottom: unset;
  border: none !important;
}

.control-center .notification-row .notification-background .notification {
  margin-top: 0.150rem;
  background-color: ${surface_container};
  border-radius: 1.159rem;
  border: 1px solid transparent !important;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.08);
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

/* Add shadow to notifications */
.notification-background .notification {
  box-shadow: 0 4px 24px 0 rgba(0,0,0,0.08);
}

.floating-notifications.background .notification-background .notification .notification-content,
.control-center .notification-background .notification .notification-content {
  background-color: ${surface_container};
  padding: 0.818rem;
  padding-right: unset;
  margin-right: unset;
  border: 1px solid transparent !important;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.08);
  border-radius: 1.159rem;
}

/* Add urgency color highlights */
.notification.low .notification-content {
  border-left: 4px solid #6cbf43 !important;
  border-top: 1px solid transparent !important;
  border-right: 1px solid transparent !important;
  border-bottom: 1px solid transparent !important;
  background-color: ${surface_container};
  border: 1px solid transparent !important;
}
.notification.normal .notification-content {
  border-left: 4px solid #4a90e2 !important;
  border-top: 1px solid transparent !important;
  border-right: 1px solid transparent !important;
  border-bottom: 1px solid transparent !important;
  background-color: ${surface_container};
  border: 1px solid transparent !important;
}
.notification.critical .notification-content {
  border-left: 4px solid ${error} !important;
  border-top: 1px solid transparent !important;
  border-right: 1px solid transparent !important;
  border-bottom: 1px solid transparent !important;
  background-color: ${on_error_container} !important;
  border: 1px solid transparent !important;
}

/* Font and icon improvements */
.notification-content label, .notification-content {
  font-family: 'Fira Sans', 'Cantarell', 'Inter', sans-serif;
  font-size: 15px;
  color: ${on_surface};
  letter-spacing: 0.01em;
  line-height: 1.5;
}

/* Pop-up notification action buttons styled like quick action buttons */
.notification-content button,
.notification-content .notification-action,
.notification-content .notification-action-button,
.floating-notifications .notification-content button,
.floating-notifications .notification-content .notification-action,
.floating-notifications .notification-content .notification-action-button {
  border: none;
  background-color: ${surface_container_low};
  border-radius: 9999px;
  min-width: 5.522rem;
  min-height: 2.927rem;
  padding: 0.341rem 1.1rem;
  margin: 0.2rem 0.3rem;
  box-shadow: 0 1px 4px 0 rgba(0,0,0,0.08);
  transition: background 120ms, box-shadow 120ms;
  font-family: "Materials Symbol Rounded", 'Fira Sans', 'Cantarell', 'Inter', sans-serif;
  font-size: 1.05rem;
  color: ${on_surface};
}

.notification-content button:hover,
.notification-content .notification-action:hover,
.notification-content .notification-action-button:hover,
.floating-notifications .notification-content button:hover,
.floating-notifications .notification-content .notification-action:hover,
.floating-notifications .notification-content .notification-action-button:hover {
  background-color: ${surface_container_high};
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.12);
}

.notification-content button:active,
.notification-content .notification-action:active,
.notification-content .notification-action-button:active,
.floating-notifications .notification-content button:active,
.floating-notifications .notification-content .notification-action:active,
.floating-notifications .notification-content .notification-action-button:active {
  background-color: ${surface_container_highest};
}

.notification .notification-icon {
  border-radius: 0.7rem;
  background: rgba(0,0,0,0.05);
  padding: 0.2rem;
  border: none !important;
  box-shadow: 0 1px 4px 0 rgba(0,0,0,0.08);
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
  color: ${on_surface};
}

.control-center .notification-row .notification-background .notification.low .notification-content .body,
.control-center .notification-row .notification-background .notification.normal .notification-content .body,
.floating-notifications.background .notification-background .notification.low .notification-content .body,
.floating-notifications.background .notification-background .notification.normal .notification-content .body {
  color: ${on_surface_variant};
}

.control-center .notification-row .notification-background .notification.critical .notification-content,
.floating-notifications.background .notification-background .notification.critical .notification-content {
  background-color: ${on_error_container};
}

.control-center .notification-row .notification-background .notification.critical .notification-content image,
.floating-notifications.background .notification-background .notification.critical .notification-content image{
  background-color: unset;
  color: ${error};
}

.control-center .notification-row .notification-background .notification.critical .notification-content label,
.floating-notifications.background .notification-background .notification.critical .notification-content label {
  color: ${error};
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

.control-center .notification-row .close-button:active,
.floating-notifications.background .close-button:active {
  background-color: ${secondary_container_pressed};
}


.control-center {
  border-radius: 1.705rem;
  -gtk-outline-radius: 1.705rem;
  border: none !important;
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
  border: none !important;
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
  box-shadow: 0 1px 4px 0 rgba(0,0,0,0.08);
  transition: background 120ms, box-shadow 120ms;
}

.widget-buttons-grid>flowbox>flowboxchild>button label {
  font-family: "Materials Symbol Rounded";
  font-size: 1.3027rem;
  color: ${on_surface};
}

.widget-buttons-grid>flowbox>flowboxchild>button:hover {
  background-color: ${surface_container_high};
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.12);
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
  background-color: ${surface_container_high};
}


.widget-volume trough slider {
  color:unset;
  background-color: ${primary};
  border-radius: 100%;
  min-height: 1.25rem;
}

/* Fix for volume widget app icons in dark theme */
.widget-volume image {
  color: ${on_surface};
}

.widget-volume label {
  color: ${on_surface};
}


/* Mpris widget - Updated for Material Design 3 */

.widget-mpris {
  background-color: ${surface_container_low};
  border-radius: 1.159rem;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.08);
  margin: 8px;
  padding: 1rem;
}

.widget-mpris-player {
  padding: unset;
  margin: unset;
}

.widget-mpris-player .mpris-art {
  border-radius: 0.7rem;
  margin-right: 1rem;
  box-shadow: 0 2px 8px 0 rgba(0,0,0,0.12);
}

.widget-mpris-title {
  font-family: 'Gabarito', 'Lexend', sans-serif;
  font-weight: bold;
  font-size: 1.25rem;
  color: ${on_surface};
  margin-bottom: 0.125rem;
}

.widget-mpris-subtitle {
  font-family: 'Noto Sans', sans-serif;
  font-size: 1.1rem;
  font-weight: 400;
  color: ${on_surface_variant};
}

.widget-mpris-controls {
  margin-top: 1rem;
}

/* Updated media player buttons */
.widget-mpris button {
  background-color: transparent;
  border: none;
  border-radius: 9999px;
  min-width: 2.5rem;
  min-height: 2.5rem;
  transition: background 120ms;
}

.widget-mpris button:hover {
  background-color: ${surface_container_high};
}

.widget-mpris button:active {
  background-color: ${surface_container_highest};
}

.widget-mpris image {
  color: ${on_surface};
  min-width: 1.5rem;
  min-height: 1.5rem;
}

.widget-mpris label {
  color: ${on_surface};
}
EOF

# Check if temp file was created
if [ ! -s "$TEMP_STYLE" ]; then
    echo "Hata: Geçici CSS dosyası oluşturulamadı"
    exit 1
fi

# Copy temp file to destination with sudo if needed
if [ ! -w "$SWAYNC_STYLE" ]; then
    echo "$SWAYNC_STYLE'e yazmak için yükseltilmiş izinler gerekiyor"
    sudo cp "$TEMP_STYLE" "$SWAYNC_STYLE"
else
    cp "$TEMP_STYLE" "$SWAYNC_STYLE"
fi

# Ensure correct permissions
chmod 644 "$SWAYNC_STYLE"

# Check if swaync is running
echo "swaync'nin çalışıp çalışmadığı kontrol ediliyor..."
SWAYNC_PID=$(pidof swaync)


# Restart swaync and restore DND state
SWAYNC_PID=$(pidof swaync)
SWAYNC_DND_STATE="false"
if [ -n "$SWAYNC_PID" ]; then
    SWAYNC_DND_STATE=$(swaync-client -D 2>/dev/null)
    killall -TERM swaync
    sleep 0.5
    if pidof swaync >/dev/null; then
        killall -9 swaync
    fi
    sleep 0.5
fi
GDK_BACKEND=wayland swaync &
sleep 1
if [ "$SWAYNC_DND_STATE" = "true" ]; then
    swaync-client -dn
fi
echo "Material You açık renkleri swaync'ye başarıyla uygulandı!"
echo "SwayNC yeniden başlatıldı."
