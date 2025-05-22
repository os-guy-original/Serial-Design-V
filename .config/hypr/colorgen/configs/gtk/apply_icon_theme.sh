#!/bin/bash

# Script to apply the icon theme based on the selected accent color
# Consolidates all icon theme application functionality

# Define config directory path
CONFIG_DIR="$HOME/.config/hypr"
ICON_THEME_FILE="$CONFIG_DIR/colorgen/icon_theme.txt"
ICON_THEME_TMP_FILE="$CONFIG_DIR/colorgen/icon_theme.tmp"

# Check if icon theme file exists
if [ ! -f "$ICON_THEME_FILE" ] && [ ! -f "$ICON_THEME_TMP_FILE" ]; then
    echo "No saved icon theme found. Exiting."
    exit 0
fi

# Read saved icon theme (prefer the main file, fallback to tmp)
if [ -f "$ICON_THEME_FILE" ]; then
    ICON_THEME=$(cat "$ICON_THEME_FILE")
else
    ICON_THEME=$(cat "$ICON_THEME_TMP_FILE")
fi

if [ -z "$ICON_THEME" ]; then
    echo "Empty icon theme setting. Exiting."
    exit 0
fi

echo "Applying icon theme: $ICON_THEME"

# Update GTK2 settings
if [ -f "$HOME/.gtkrc-2.0" ]; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=\"$ICON_THEME\"/" "$HOME/.gtkrc-2.0"
fi

# Update GTK3 settings
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-3.0/settings.ini"
fi

# Update GTK4 settings
if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-4.0/settings.ini"
fi

# Apply through gsettings if available
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
fi

# Apply through Hyprland if running
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl keyword env GTK_ICON_THEME "$ICON_THEME"
fi

# Set environment variable for current session
export GTK_ICON_THEME="$ICON_THEME"

# Update GTK icon cache to ensure everything is refreshed
echo "Refreshing GTK icon cache..."
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "/usr/share/icons/$ICON_THEME" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi
if command -v gtk4-update-icon-cache >/dev/null 2>&1; then
    gtk4-update-icon-cache -f -t "/usr/share/icons/$ICON_THEME" 2>/dev/null || true
    gtk4-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk4-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi

echo "Icon theme applied successfully"
exit 0 