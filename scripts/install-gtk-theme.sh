#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                  GTK Theme Installation                   │
# │            Modern and Elegant Desktop Themes              │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments 
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure GTK themes"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs the Serial Design V GTK theme for GTK applications"
    echo -e "    and configures it system-wide."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE${RESET}"
    echo -e "    $(basename "$0")"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script must be run as root to properly configure system-wide settings."
    echo
    exit 0
fi

#==================================================================
# Privilege Check
#==================================================================
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

#==================================================================
# Welcome Message
#==================================================================

# Clear the screen
clear
print_banner "GTK Theme Installation" "Modern, elegant themes for your desktop environment"

#==================================================================
# Dependency Installation
#==================================================================
print_section "1. Dependencies"
print_info "Installing required packages for themes"

# Check and install dependencies
install_dependencies() {
    # Check for required tools
    print_status "Checking GTK theme dependencies..."
    
    if ! pacman -Q gnome-themes-extra gtk-engine-murrine &>/dev/null; then
        print_status "Installing GTK theme dependencies..."
        sudo pacman -S --needed --noconfirm gnome-themes-extra gtk-engine-murrine
    else
        print_success "All GTK theme dependencies are already installed"
    fi
}

# Install dependencies
install_dependencies

#==================================================================
# Theme Installation
#==================================================================
print_section "2. Theme Installation"
print_info "Installing and configuring the GTK theme"

# Install Serial Design V GTK theme
install_custom_theme() {
    # Get script directory
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"
    THEME_SOURCE_DIR="$PROJECT_ROOT/gtk-theme"
    
    print_status "Installing Serial Design V GTK theme..."
    
    # Check if the theme source directory exists
    if [ ! -d "$THEME_SOURCE_DIR" ]; then
        print_error "Theme source directory not found: $THEME_SOURCE_DIR"
        return 1
    fi
    
    print_status "Found theme source directory: $THEME_SOURCE_DIR"
    print_status "Available themes:"
    ls -la "$THEME_SOURCE_DIR"
    
    # Create user themes directory
    USER_THEMES_DIR="${HOME}/.themes"
    mkdir -p "$USER_THEMES_DIR"
    print_status "Created/verified user themes directory: $USER_THEMES_DIR"
    
    # Copy themes to user's .themes directory
    print_status "Copying themes to user's .themes directory..."
    cp -r "$THEME_SOURCE_DIR/"* "$USER_THEMES_DIR/"
    
    # Ensure proper permissions
    chown -R "$(logname):$(id -gn $(logname))" "$USER_THEMES_DIR"
    
    # Also copy to system-wide themes if available
    if [ -d "/usr/share/themes" ]; then
        print_status "Copying themes to system-wide directory..."
        cp -r "$THEME_SOURCE_DIR/"* "/usr/share/themes/"
    fi
    
    print_success "Serial Design V GTK theme installed successfully!"
    return 0
}

#==================================================================
# User Configuration
#==================================================================
print_section "3. User Configuration"
print_info "Setting up themes for your user account"

# Set up themes for users
setup_user_themes() {
    # Get the actual user (when running with sudo)
    ACTUAL_USER=$(logname)
    USER_HOME=$(eval echo ~$ACTUAL_USER)
    
    print_status "Configuring GTK theme for user: $ACTUAL_USER"
    
    # Create GTK configuration directories if they don't exist
    mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
    
    # Create or update GTK3 settings
    if [ -f "$USER_HOME/.config/gtk-3.0/settings.ini" ]; then
        # Backup existing settings
        cp "$USER_HOME/.config/gtk-3.0/settings.ini" "$USER_HOME/.config/gtk-3.0/settings.ini.bak"
    fi
    
    # Write GTK3 settings
    cat > "$USER_HOME/.config/gtk-3.0/settings.ini" << EOL
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-icon-theme-name=Fluent-grey-dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
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
EOL
    
    # Create or update GTK4 settings (if needed)
    mkdir -p "$USER_HOME/.config/gtk-4.0"
    if [ -f "$USER_HOME/.config/gtk-4.0/settings.ini" ]; then
        # Backup existing settings
        cp "$USER_HOME/.config/gtk-4.0/settings.ini" "$USER_HOME/.config/gtk-4.0/settings.ini.bak"
    fi
    
    # Write GTK4 settings - ensure this file is always created
    cat > "$USER_HOME/.config/gtk-4.0/settings.ini" << EOL
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-icon-theme-name=Fluent-grey
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
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
EOL
    
    # Fix permissions
    chown -R "$ACTUAL_USER:$(id -gn $ACTUAL_USER)" "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"
    
    print_success "GTK theme configurations set for user: $ACTUAL_USER"
    return 0
}

# Function to update environment settings to use the new theme
update_environment_settings() {
    print_status "Updating environment settings..."
    
    # Update Hypr config env.conf if it exists
    ACTUAL_USER=$(logname)
    USER_HOME=$(eval echo ~$ACTUAL_USER)
    HYPR_ENV_CONF="$USER_HOME/.config/hypr/configs/envs.conf"
    
    if [ -f "$HYPR_ENV_CONF" ]; then
        print_status "Updating Hyprland environment configuration..."
        
        # Back up the file
        cp "$HYPR_ENV_CONF" "$HYPR_ENV_CONF.bak"
        
        # Update the theme name
        sed -i 's/env = GTK_THEME,Graphite-Dark/env = GTK_THEME,serial-design-V-dark/g' "$HYPR_ENV_CONF"
        
        # Fix permissions
        chown "$ACTUAL_USER:$(id -gn $ACTUAL_USER)" "$HYPR_ENV_CONF" "$HYPR_ENV_CONF.bak"
        
        print_success "Hyprland environment configuration updated"
    fi
    
    # Update Flatpak GTK theme if Flatpak is installed
    if command -v flatpak &>/dev/null; then
        print_status "Updating Flatpak GTK theme..."
        
        # Run as the actual user
        sudo -u "$ACTUAL_USER" flatpak override --user --env=GTK_THEME=serial-design-V-dark
        
        print_success "Flatpak GTK theme updated"
    fi
    
    return 0
}

#==================================================================
# Main Installation
#==================================================================

# Install the custom theme
install_custom_theme

# Set up themes for the current user
setup_user_themes

# Update environment settings
update_environment_settings

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

# Print final success message
echo
print_success_banner "Serial Design V GTK themes have been successfully installed and configured!"
print_info "The theme will be applied after you log out and log back in, or restart the GTK session."

# Exit with success
exit 0 