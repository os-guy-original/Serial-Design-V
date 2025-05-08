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
    echo -e "    This script installs the Graphite GTK theme for GTK applications"
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
print_info "Installing required packages for theme compilation"

# Check and install dependencies
install_dependencies() {
    # Check for required tools
    print_status "Checking GTK theme dependencies..."
    
    if ! pacman -Q gnome-themes-extra gtk-engine-murrine sassc &>/dev/null; then
        print_status "Installing GTK theme dependencies..."
        sudo pacman -S --needed --noconfirm gnome-themes-extra gtk-engine-murrine sassc
    else
        print_success "All GTK theme dependencies are already installed"
    fi
    
    # Check for git
    if ! command_exists git; then
        print_status "Installing git..."
        sudo pacman -S --needed --noconfirm git
    else
        print_success "Git is already installed"
    fi
}

# Install dependencies
install_dependencies

#==================================================================
# Theme Installation
#==================================================================
print_section "2. Theme Installation"
print_info "Installing and configuring the GTK theme"

# Install Graphite GTK theme
install_graphite_theme() {
    # Fixed theme values
    local theme_name="Graphite"
    local theme_variant="dark"
    local accent_color="blue"
    
    print_status "Installing $theme_name GTK theme with dark variant and blue accent..."
    
    # Create temp directory
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || {
        print_error "Failed to create temporary directory"
        return 1
    }
    
    # Clone the repository
    print_status "Cloning theme repository..."
    if ! git clone https://github.com/vinceliuice/Graphite-gtk-theme.git; then
        print_error "Failed to clone theme repository"
        rm -rf "$tmp_dir"
        return 1
    }
    
    cd "Graphite-gtk-theme" || {
        print_error "Failed to enter theme directory"
        rm -rf "$tmp_dir"
        return 1
    }
    
    # Install theme
    print_status "Running theme installer..."
    chmod +x ./install.sh
    ./install.sh -l
    
    # Cleanup
    cd / || true
    rm -rf "$tmp_dir"
    
    print_success "$theme_name GTK theme installed successfully!"
    return 0
}

#==================================================================
# User Configuration
#==================================================================
print_section "3. User Configuration"
print_info "Setting up themes for your user account"

# Set up themes for users
setup_user_themes() {
    # Configure GTK theme only for the current user
    print_status "Configuring GTK theme for current user..."
    
    # Create GTK configuration directories if they don't exist
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    
    # Create or update GTK3 settings
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        # Backup existing settings
        cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini.bak"
    fi
    
    # Write GTK3 settings
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOL
[Settings]
gtk-theme-name=Graphite-Dark
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
    mkdir -p "$HOME/.config/gtk-4.0"
    if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
        # Backup existing settings
        cp "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini.bak"
    fi
    
    # Write GTK4 settings - ensure this file is always created
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOL
[Settings]
gtk-theme-name=Graphite-Dark
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
    
    print_success "GTK theme configurations set for current user"
    print_success "GTK4 theme configuration created"
    return 0
}

#==================================================================
# Main Installation
#==================================================================

# Install the theme with fixed options
install_graphite_theme
setup_user_themes

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

# Print final success message
echo
print_success_banner "GTK themes have been successfully installed and configured!"

# Exit with success
exit 0 