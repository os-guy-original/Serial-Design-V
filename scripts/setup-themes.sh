#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Set up and configure themes for Serial Design V"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script helps you configure the visual appearance of your"
    echo -e "    desktop environment by setting up GTK, Qt, icon, and cursor themes."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}FEATURES${RESET}"
    echo -e "    - Checks for installed themes"
    echo -e "    - Offers to install missing themes"
    echo -e "    - Configures GTK and Qt applications"
    echo -e "    - Sets up cursor and icon themes"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script may call other installer scripts to complete its tasks."
    echo
    exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │               Theme Setup Helper Script                  │
# │             Configure and Activate Themes                │
# ╰──────────────────────────────────────────────────────────╯

# Welcome message
print_section "Theme Setup"
echo -e "${BRIGHT_WHITE}This script will help you set up themes for your Serial Design V installation.${RESET}"
echo

# Check if themes are installed and offer to install missing ones
echo -e "${BRIGHT_BLUE}${BOLD}Checking installed themes...${RESET}"
echo

# Check GTK theme
if check_gtk_theme_installed; then
    print_success "GTK theme 'Graphite-Dark' is already installed."
    if ask_yes_no "Would you like to reinstall the GTK theme?" "n"; then
        SCRIPT_DIR="$(dirname "$0")"
        if [ -f "${SCRIPT_DIR}/install-gtk-theme.sh" ] && [ -x "${SCRIPT_DIR}/install-gtk-theme.sh" ]; then
            "${SCRIPT_DIR}/install-gtk-theme.sh"
        else
            print_status "Making GTK theme installer executable..."
            chmod +x "${SCRIPT_DIR}/install-gtk-theme.sh"
            "${SCRIPT_DIR}/install-gtk-theme.sh"
        fi
    fi
else
    print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    offer_gtk_theme
fi

# Check QT theme
if check_qt_theme_installed; then
    print_success "QT theme 'Graphite-rimlessDark' is already installed."
    if ask_yes_no "Would you like to reinstall the QT theme?" "n"; then
        SCRIPT_DIR="$(dirname "$0")"
        if [ -f "${SCRIPT_DIR}/install-qt-theme.sh" ] && [ -x "${SCRIPT_DIR}/install-qt-theme.sh" ]; then
            "${SCRIPT_DIR}/install-qt-theme.sh"
        else
            print_status "Making QT theme installer executable..."
            chmod +x "${SCRIPT_DIR}/install-qt-theme.sh"
            "${SCRIPT_DIR}/install-qt-theme.sh"
        fi
    fi
else
    print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
    offer_qt_theme
fi

# Check cursor theme
if check_cursor_theme_installed; then
    print_success "Cursor theme 'Graphite-dark-cursors' is already installed."
    if ask_yes_no "Would you like to reinstall the cursor theme?" "n"; then
        SCRIPT_DIR="$(dirname "$0")"
        if [ -f "${SCRIPT_DIR}/install-cursors.sh" ] && [ -x "${SCRIPT_DIR}/install-cursors.sh" ]; then
            "${SCRIPT_DIR}/install-cursors.sh"
        else
            print_status "Making cursor installer executable..."
            chmod +x "${SCRIPT_DIR}/install-cursors.sh"
            "${SCRIPT_DIR}/install-cursors.sh"
        fi
    fi
else
    print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
    offer_cursor_install
fi

# Check icon theme
if check_icon_theme_installed; then
    print_success "Fluent icon theme already installed."
    if ask_yes_no "Would you like to reinstall the icon theme?" "n"; then
        SCRIPT_DIR="$(dirname "$0")"
        if [ -f "${SCRIPT_DIR}/install-icon-theme.sh" ] && [ -x "${SCRIPT_DIR}/install-icon-theme.sh" ]; then
            "${SCRIPT_DIR}/install-icon-theme.sh" "fluent" "Fluent-grey"
        else
            print_status "Making icon theme installer executable..."
            chmod +x "${SCRIPT_DIR}/install-icon-theme.sh"
            "${SCRIPT_DIR}/install-icon-theme.sh" "fluent" "Fluent-grey"
        fi
    fi
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
EOF
    
    # Set GTK4 theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
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
EOF
    print_success "GTK theme configured!"
else
    print_warning "Skipping GTK theme configuration because it's not installed."
fi

# Configure QT theme
if check_qt_theme_installed; then
    print_status "Setting up QT theme..."
    
    # Create QT5 configuration directory
    mkdir -p "$HOME/.config/qt5ct"
    
    # Write QT5 configuration
    cat > "$HOME/.config/qt5ct/qt5ct.conf" << EOF
[Appearance]
color_scheme_path=~/.config/qt5ct/colors/Graphite-Dark.conf
custom_palette=true
icon_theme=$ICON_THEME
style=kvantum

[Fonts]
fixed="Noto Sans,11,-1,5,50,0,0,0,0,0"
general="Noto Sans,11,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOF

    # Create QT6 configuration directory
    mkdir -p "$HOME/.config/qt6ct"
    
    # Write QT6 configuration
    cat > "$HOME/.config/qt6ct/qt6ct.conf" << EOF
[Appearance]
color_scheme_path=~/.config/qt6ct/colors/Graphite-Dark.conf
custom_palette=true
icon_theme=$ICON_THEME
style=kvantum

[Fonts]
fixed="Noto Sans,11,-1,5,50,0,0,0,0,0"
general="Noto Sans,11,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOF

    # Add environment variables to ~/.profile if not already present
    if [ -f "$HOME/.profile" ]; then
        # Add QT_QPA_PLATFORMTHEME variable if not already set
        if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME/.profile"; then
            echo '# Set Qt theme' >> "$HOME/.profile"
            echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME/.profile"
        fi
        
        # Add QT_STYLE_OVERRIDE variable if not already set
        if ! grep -q "QT_STYLE_OVERRIDE" "$HOME/.profile"; then
            echo 'export QT_STYLE_OVERRIDE=kvantum' >> "$HOME/.profile"
        fi
    else
        # Create .profile file
        echo '# Set Qt theme' > "$HOME/.profile"
        echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME/.profile"
        echo 'export QT_STYLE_OVERRIDE=kvantum' >> "$HOME/.profile"
    fi
    
    print_success "QT theme configured!"
else
    print_warning "Skipping QT theme configuration because it's not installed."
fi

# Final message
print_section "Theme Setup Complete!"
print_success_banner "Themes have been set up successfully!"
print_status "You may need to log out and log back in for all changes to take effect."
echo
    
exit 0