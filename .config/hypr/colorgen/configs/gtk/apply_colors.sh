#!/bin/bash

# Script to apply custom colors to GTK themes
# This script should be called from gtk.sh after running the gtk3, gtk4, and libadw scripts

# Check if necessary variables are set from main script
if [ -z "$COLORGEN_CONF" ] || [ -z "$THEME_DIR" ]; then
    echo "Error: Required variables not set. This script should be called from gtk.sh."
    exit 1
fi

echo "Applying GTK color settings..."

# Update GTK_THEME environment variable for current session
export GTK_THEME="serial-design-V-dark"
export XCURSOR_THEME="Graphite-dark-cursors"

# Touch GTK config files to trigger reload
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    touch "$HOME/.config/gtk-3.0/settings.ini"
fi
if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
    touch "$HOME/.config/gtk-4.0/settings.ini"
fi

# Improved GTK4 theme application
echo "Applying theme settings to configuration files..."

# Ensure GTK4 settings directory exists
mkdir -p "$HOME/.config/gtk-4.0"
mkdir -p "$HOME/.config/gtk-3.0"

# Create or update settings.ini with theme information, preserving existing settings
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    # Backup existing settings
    cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini.bak"
    
    # Update only theme and icon theme in existing file
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=serial-design-V-dark/" "$HOME/.config/gtk-3.0/settings.ini"
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-3.0/settings.ini"
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/" "$HOME/.config/gtk-3.0/settings.ini"
else
    # Create new file if it doesn't exist
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-font-name=Cantarell 11
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-hint-font-metrics=1
EOF
fi

if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
    # Backup existing settings
    cp "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini.bak"
    
    # Update only theme and icon theme in existing file
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=serial-design-V-dark/" "$HOME/.config/gtk-4.0/settings.ini"
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$HOME/.config/gtk-4.0/settings.ini"
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/" "$HOME/.config/gtk-4.0/settings.ini"
else
    # Create new file if it doesn't exist
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-font-name=Cantarell 11
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-hint-font-metrics=1
EOF
fi

# Check for existing customizations and preserve them
if [ -f "$HOME/.config/gtk-4.0/gtk.css" ] && grep -q "/* User custom styles - DO NOT REMOVE */" "$HOME/.config/gtk-4.0/gtk.css"; then
    echo "Preserving user's custom GTK4 CSS styles..."
    # Extract user's custom styles
    USER_STYLES=$(sed -n '/\/\* User custom styles - DO NOT REMOVE \*\//,/\/\* End user custom styles \*\//p' "$HOME/.config/gtk-4.0/gtk.css")
    
    # Append to our new CSS
    echo "$USER_STYLES" >> "$HOME/.config/gtk-4.0/gtk.css"
fi

# Ensure gtk-4.0/assets and gtk-4.0/icons directories exist
mkdir -p "$HOME/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/icons"

# Create an empty CSS file for custom icons if it doesn't exist
if [ ! -f "$HOME/.config/gtk-4.0/icons.css" ]; then
    touch "$HOME/.config/gtk-4.0/icons.css"
fi

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting GTK environment variables via Hyprland..."
    hyprctl setcursor Graphite-dark-cursors 24
    hyprctl keyword env GTK_THEME=serial-design-V-dark
    hyprctl keyword env GTK2_RC_FILES="/usr/share/themes/serial-design-V-dark/gtk-2.0/gtkrc"
fi

# Create symbolic links to ensure GTK4 apps find the theme
mkdir -p "$HOME/.local/share/themes"
if [ ! -L "$HOME/.local/share/themes/serial-design-V-dark" ] && [ -d "$THEME_DIR" ]; then
    ln -sf "$THEME_DIR" "$HOME/.local/share/themes/serial-design-V-dark"
fi

echo "GTK color settings applied successfully!" 