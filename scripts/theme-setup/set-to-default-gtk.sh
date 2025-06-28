#!/bin/bash

# Source common functions
# Check if common_functions.sh exists in the utils directory
if [ -f "$(dirname "$0")/../utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../utils/common_functions.sh"
# Check if common_functions.sh exists in the scripts/utils directory
elif [ -f "$(dirname "$0")/../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../scripts/utils/common_functions.sh"
# Check if it exists in the parent directory's scripts/utils directory
elif [ -f "$(dirname "$0")/../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../scripts/utils/common_functions.sh"
# As a last resort, try the scripts/utils directory relative to current directory
elif [ -f "scripts/utils/common_functions.sh" ]; then
    source "scripts/utils/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    echo "Looked in: $(dirname "$0")/../utils/, $(dirname "$0")/../../scripts/utils/, $(dirname "$0")/../../../scripts/utils/, scripts/utils/"
    exit 1
fi

# Source common functions
# Function to silently set GTK theme to adw-gtk3-dark without user notification
set_gtk_theme_silently() {
    # Create GTK configuration directories if they don't exist
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    
    # Set GTK3 theme
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Fluent-grey
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF
    
    # Set GTK4 theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Fluent-grey
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

    # Update Hypr config env.conf if it exists
    HYPR_ENV_CONF="$HOME/.config/hypr/configs/envs.conf"
    if [ -f "$HYPR_ENV_CONF" ]; then
        # Back up the file
        cp "$HYPR_ENV_CONF" "$HYPR_ENV_CONF.bak"
        
        # Update the theme name
        sed -i 's/env = GTK_THEME,.*$/env = GTK_THEME,adw-gtk3-dark/g' "$HYPR_ENV_CONF"
    fi
    
    # Update Flatpak GTK theme if Flatpak is installed
    if command -v flatpak &>/dev/null; then
        # Get the path to the apply-flatpak-theme.sh script
        FLATPAK_THEME_SCRIPT="$(dirname "$0")/apply-flatpak-theme.sh"
        
        # Make the script executable if it isn't already
        if [ ! -x "$FLATPAK_THEME_SCRIPT" ]; then
            chmod +x "$FLATPAK_THEME_SCRIPT"
        fi
        
        # Execute the Flatpak theme application script silently
        "$FLATPAK_THEME_SCRIPT" > /dev/null 2>&1
    fi
}

# Execute the function to set the GTK theme
set_gtk_theme_silently 
