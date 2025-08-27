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

# ╭──────────────────────────────────────────────────────────╮
# │                  GTK Theme Installation                   │
# │            Modern and Elegant Desktop Themes              │
# ╰──────────────────────────────────────────────────────────╯

# Parse command line arguments
CONFIGURE_ONLY=false
INSTALL_ONLY=false
SILENT_MODE=false

for arg in "$@"; do
    case $arg in
        --configure-only)
            CONFIGURE_ONLY=true
            ;;
        --install-only)
            INSTALL_ONLY=true
            ;;
        --silent)
            SILENT_MODE=true
            ;;
    esac
done

# Source common functions
# Process command line arguments 
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure GTK themes"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs the Adwaita GTK theme for GTK applications"
    echo -e "    and configures it for the current user."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE${RESET}"
    echo -e "    $(basename "$0") [OPTIONS]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS${RESET}"
    echo -e "    --configure-only    Skip installation and only update the configuration"
    echo -e "    --install-only      Only install the theme packages and skip configuration"
    echo -e "    --silent            Run in silent mode with minimal output"
    echo
    exit 0
fi

#==================================================================
# Welcome Message
#==================================================================

# Clear the screen and show welcome message only if not in silent mode
if [ "$SILENT_MODE" = false ]; then
    clear
    print_banner "GTK Theme Installation" "Modern, elegant themes for your desktop environment"
fi

#==================================================================
# Theme Installation
#==================================================================
if [ "$SILENT_MODE" = false ] && [ "$CONFIGURE_ONLY" = false ]; then
    print_section "1. Theme Installation"
    print_info "Installing and configuring the GTK theme"
fi

# Install Adwaita GTK theme from AUR
install_adwaita_theme() {
    print_status "Installing Adwaita GTK theme from AUR..."
    
    # Try to install dependencies from package list first
    if declare -f install_packages_by_category >/dev/null; then
        print_status "Using package list to install dependencies..."
        if install_packages_by_category "GTK_THEME" true; then
            print_success "Dependencies installed successfully from package list."
            
            # Copy themes to user's .themes directory if installation was successful
            copy_themes_to_user_dir
            
            return 0
        else
            print_warning "Failed to install dependencies from package list, falling back to direct installation."
        fi
    fi
    
    # Install GTK theme packages using the package list
    if install_packages_by_category "GTK_THEME" true; then
        print_success "Adwaita GTK theme installed successfully!"
        
        # Copy themes to user's .themes directory if installation was successful
        copy_themes_to_user_dir
        
        return 0
    else
        print_error "Failed to install Adwaita GTK theme."
        return 1
    fi
}

# Function to copy themes to user's .themes directory
copy_themes_to_user_dir() {
    print_status "Copying themes to user's .themes directory..."
    
    # Create .themes directory if it doesn't exist
    if [ ! -d "$HOME/.themes" ]; then
        mkdir -p "$HOME/.themes"
    fi
    
    # Check if the user has write permissions to the .themes directory
    if [ ! -w "$HOME/.themes" ]; then
        print_warning "User does not have write permissions for $HOME/.themes."
        print_info "Attempting to copy themes using sudo..."
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi

    # Check for adw-gtk3-dark and adw-gtk3 in system directories
    local theme_dirs=(
        "/usr/share/themes"
        "/usr/local/share/themes"
    )
    
    local found_dark=false
    local found_light=false
    
    for dir in "${theme_dirs[@]}"; do
        if [ -d "$dir/adw-gtk3-dark" ] && [ "$found_dark" = false ]; then
            print_status "Copying adw-gtk3-dark theme..."
            $SUDO_CMD cp -r "$dir/adw-gtk3-dark" "$HOME/.themes/"
            found_dark=true
        fi
        
        if [ -d "$dir/adw-gtk3" ] && [ "$found_light" = false ]; then
            print_status "Copying adw-gtk3 theme..."
            $SUDO_CMD cp -r "$dir/adw-gtk3" "$HOME/.themes/"
            found_light=true
        fi
        
        # Break if both themes are found
        if [ "$found_dark" = true ] && [ "$found_light" = true ]; then
            break
        fi
    done
    
    # Check if themes were found and copied
    if [ "$found_dark" = true ] || [ "$found_light" = true ]; then
        print_success "GTK themes copied to $HOME/.themes/"
        
        # Set appropriate permissions
        $SUDO_CMD chmod -R u+rw "$HOME/.themes/adw-gtk3-dark" 2>/dev/null || true
        $SUDO_CMD chmod -R u+rw "$HOME/.themes/adw-gtk3" 2>/dev/null || true
        if [ -n "$SUDO_CMD" ]; then
            $SUDO_CMD chown -R $USER:$USER "$HOME/.themes/adw-gtk3-dark"
            $SUDO_CMD chown -R $USER:$USER "$HOME/.themes/adw-gtk3"
        fi
    else
        print_warning "Could not find adw-gtk3 themes in system directories."
        print_info "You may need to manually copy the themes to your .themes directory."
    fi
}

#==================================================================
# User Configuration
#==================================================================
if [ "$SILENT_MODE" = false ] && [ "$INSTALL_ONLY" = false ]; then
    print_section "2. User Configuration"
    print_info "Setting up themes for your user account"
fi

# Set up themes for users
setup_user_themes() {
    print_status "Configuring GTK theme for your user account"
    
    # Create GTK configuration directories if they don't exist
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    
    # Create or update GTK3 settings
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        # Backup existing settings
        cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini.bak"
    fi
    
    # Write GTK3 settings with adw-gtk3-dark as the theme
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOL
[Settings]
gtk-theme-name=adw-gtk3-dark
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
    
    # Write GTK4 settings with adw-gtk3-dark as the theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOL
[Settings]
gtk-theme-name=adw-gtk3-dark
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
    
    print_success "GTK theme configurations set"
    return 0
}

# Function to update environment settings to use the new theme
update_environment_settings() {
    print_status "Updating environment settings..."
    
    # Update Hypr config env.conf if it exists
    HYPR_ENV_CONF="$HOME/.config/hypr/configs/envs.conf"
    
    if [ -f "$HYPR_ENV_CONF" ]; then
        print_status "Updating Hyprland environment configuration..."
        
        # Back up the file
        cp "$HYPR_ENV_CONF" "$HYPR_ENV_CONF.bak"
        
        # Update the theme name
        sed -i 's/env = GTK_THEME,.*$/env = GTK_THEME,adw-gtk3-dark/g' "$HYPR_ENV_CONF"
        
        print_success "Hyprland environment configuration updated"
    fi
    
    return 0
}

#==================================================================
# Main Installation
#==================================================================

# Only install the theme if not in configure-only mode
if [ "$CONFIGURE_ONLY" = false ]; then
    install_adwaita_theme
fi

# Only configure if not in install-only mode
if [ "$INSTALL_ONLY" = false ]; then
    # Set up themes for the current user
    setup_user_themes

    # Update environment settings
    update_environment_settings
fi

#==================================================================
# Installation Complete
#==================================================================
if [ "$SILENT_MODE" = false ]; then
    print_section "Installation Complete!"

    # Print final success message
    echo
    print_success_banner "Adwaita GTK theme has been successfully installed and configured!"
    if [ "$CONFIGURE_ONLY" = true ]; then
        print_info "The theme configuration has been updated successfully."
    elif [ "$INSTALL_ONLY" = true ]; then
        print_info "The theme packages have been installed successfully."
    else
        print_info "The theme will be applied after you log out and log back in, or restart the GTK session."
    fi
fi 
