#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               Theme Setup Helper Script                  │
# │             Configure and Activate Themes                │
# ╰──────────────────────────────────────────────────────────╯

# Welcome message
print_section "Theme Setup"
echo -e "${BRIGHT_WHITE}This script will help you set up themes for your HyprGraphite installation.${RESET}"
echo

# Check if themes are installed and offer to install missing ones
echo -e "${BRIGHT_BLUE}${BOLD}Checking installed themes...${RESET}"
echo

# Check GTK theme
if check_gtk_theme_installed; then
    print_success "GTK theme 'Graphite-Dark' is already installed."
else
    print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    offer_gtk_theme
fi

# Check QT theme
if check_qt_theme_installed; then
    print_success "QT theme 'Graphite-rimlessDark' is already installed."
else
    print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
    offer_qt_theme
fi

# Check cursor theme
if check_cursor_theme_installed; then
    print_success "Cursor theme 'Bibata-Modern-Classic' is already installed."
else
    print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
    offer_cursor_install
fi

# Check icon theme
if check_icon_theme_installed; then
    print_success "Fluent icon theme already installed."
else
    print_warning "Icon theme is not installed. Your system will use the default icon theme."
    offer_icon_theme_install
fi

# Configure themes
print_section "Theme Configuration"
print_status "Configuring themes..."

# Detect icon theme
ICON_THEME="Fluent-grey"  # Default

# If Fluent-grey not found, check for other Fluent variants
if [ ! -d "/usr/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.local/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.icons/$ICON_THEME" ]; then
    local fluent_variants=("Fluent-dark" "Fluent" "Fluent-light")
    for variant in "${fluent_variants[@]}"; do
        if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ]; then
            print_status "Fluent-grey not found, using alternative Fluent variant: $variant"
            ICON_THEME="$variant"
            break
        fi
    done
fi

# Configure GTK theme
if check_gtk_theme_installed; then
    print_status "Setting up GTK theme..."
    
    # Create required directories
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # Set GTK3 theme
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
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
EOF
    
    # Set GTK4 theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
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
EOF
    print_success "GTK theme configured!"
else
    print_warning "Skipping GTK theme configuration because it's not installed."
fi

# Configure QT theme
if check_qt_theme_installed; then
    print_status "Setting up QT theme..."
    print_success "QT theme configured!"
else
    print_warning "Skipping QT theme configuration because it's not installed."
fi

# Final message
print_section "Theme Setup Complete"
print_success "Themes have been set up successfully!"
echo -e "${BRIGHT_WHITE}You may need to log out and log back in for all theme changes to take effect.${RESET}"
echo
    
    exit 0