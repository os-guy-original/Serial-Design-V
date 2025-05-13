#!/usr/bin/env bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭────────────────────────────────────────────────────────────────╮
# │$(center_text "Graphite Cursor Theme Installer" 60)│
# │$(center_text "Simple installer for modern cursor themes" 60)│
# ╰────────────────────────────────────────────────────────────────╯

#==================================================================
# Pre-Installation Checks
#==================================================================

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_warning "This script should NOT be run as root!"
    print_info "Some AUR helpers like yay don't work properly with sudo."
    print_info "The script will ask for privileges when needed."
    
    if ! ask_yes_no "Continue anyway?" "n"; then
        exit 1
    fi
fi

# Clear screen for better presentation
clear

# Print welcome banner
print_banner "Serial Design V Cursor Installer" "Beautiful cursors for your desktop environment"

#==================================================================
# Installation Options
#==================================================================
print_section "Installation Options"

# Define installation mode
if command_exists pacman; then
    print_status "Detected pacman package manager. Using package installation..."
    INSTALL_MODE="package"
else
    print_status "Pacman not found. Trying other package managers..."
    INSTALL_MODE="package"
fi

# No GitHub installation option

#==================================================================
# Package Installation Method
#==================================================================
install_via_package() {
    print_section "Installing from Package Repositories"
    
    # Check if theme is already installed
    if [ -d "/usr/share/icons/Graphite-dark-cursors" ] || \
       [ -d "$HOME/.local/share/icons/Graphite-dark-cursors" ] || \
       [ -d "$HOME/.icons/Graphite-dark-cursors" ]; then
        print_warning "Graphite cursor theme is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            return 0
        fi
    fi
    
    # Try pacman repositories first
    if command_exists pacman; then
        print_status "Checking official repositories..."
        
        if pacman -Ss graphite-cursor-theme | grep -q "^extra/graphite-cursor-theme"; then
            print_status "Found graphite-cursor-theme in official repositories."
            sudo pacman -S --needed --noconfirm graphite-cursor-theme && {
                print_success "Successfully installed Graphite cursor theme via pacman!"
                return 0
            }
        fi
        
        # Try AUR if official repos don't have it
        print_status "Checking AUR..."
        
        # Find available AUR helper
        for helper in yay paru pamac; do
            if command_exists "$helper"; then
                print_status "Using $helper to install from AUR..."
                
                case "$helper" in
                    "yay")
                        yay -S --needed --noconfirm graphite-cursor-theme && {
                            print_success "Successfully installed via yay!"
                            return 0
                        }
                        ;;
                    "paru")
                        paru -S --needed --noconfirm graphite-cursor-theme && {
                            print_success "Successfully installed via paru!"
                            return 0
                        }
                        ;;
                    "pamac")
                        pamac install --no-confirm graphite-cursor-theme && {
                            print_success "Successfully installed via pamac!"
                            return 0
                        }
                        ;;
                esac
                break
            fi
        done
    fi
    
    # Try apt (Debian/Ubuntu-based)
    if command_exists apt-get; then
        print_status "Checking apt repositories..."
        
        if apt-cache search --names-only graphite-cursor-theme | grep -q "graphite-cursor-theme"; then
            sudo apt-get update && sudo apt-get install -y graphite-cursor-theme && {
                print_success "Successfully installed via apt!"
                return 0
            }
        fi
    fi
    
    # Try dnf (Fedora-based)
    if command_exists dnf; then
        print_status "Checking dnf repositories..."
        
        if dnf list graphite-cursor-theme 2>/dev/null | grep -q "graphite-cursor-theme"; then
            sudo dnf install -y graphite-cursor-theme && {
                print_success "Successfully installed via dnf!"
                return 0
            }
        fi
    fi
    
    print_warning "Package installation method failed."
    return 1
}

#==================================================================
# Installation Process
#==================================================================
print_section "Installing Cursor Theme"

print_status "Attempting package installation..."
    
if ! install_via_package; then
    print_error "Package installation failed."
    print_warning "Please try installing the cursor theme manually."
    exit 1
fi

#==================================================================
# Configuration
#==================================================================
print_section "Configuration"

# Offer to set as default cursor theme
if ask_yes_no "Would you like to set Serial Design V as your default cursor theme?" "y"; then
    print_status "Setting up Serial Design V cursor theme..."
    
    # Create necessary directories
    mkdir -p "$HOME/.icons/default"
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # Create default cursor configuration
    cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Inherits=Graphite-dark-cursors
EOF
    
    # Update GTK3 settings if the file exists
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        if grep -q "gtk-cursor-theme-name" "$HOME/.config/gtk-3.0/settings.ini"; then
            # Replace existing cursor theme setting
            sed -i 's/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Graphite-dark-cursors/' "$HOME/.config/gtk-3.0/settings.ini"
        else
            # Add cursor theme setting
            echo "gtk-cursor-theme-name=Graphite-dark-cursors" >> "$HOME/.config/gtk-3.0/settings.ini"
        fi
    else
        # Create new settings file
        cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-cursor-theme-name=Graphite-dark-cursors
EOF
    fi
    
    # Update GTK4 settings if the file exists
    if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
        if grep -q "gtk-cursor-theme-name" "$HOME/.config/gtk-4.0/settings.ini"; then
            # Replace existing cursor theme setting
            sed -i 's/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Graphite-dark-cursors/' "$HOME/.config/gtk-4.0/settings.ini"
        else
            # Add cursor theme setting
            echo "gtk-cursor-theme-name=Graphite-dark-cursors" >> "$HOME/.config/gtk-4.0/settings.ini"
        fi
    else
        # Create new settings file
        cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-cursor-theme-name=Graphite-dark-cursors
EOF
    fi
    
    print_success "Cursor theme configured successfully!"
    print_info "You may need to log out and log back in for changes to take effect."
fi

#==================================================================
# Completion
#==================================================================
print_success_banner "Serial Design V cursor theme installation complete!"

print_status "You can also configure your cursor theme with:"
echo -e "• ${BRIGHT_CYAN}nwg-look${RESET} - GTK theme configuration tool"
echo -e "• ${BRIGHT_CYAN}lxappearance${RESET} - Lightweight theme configuration tool"

exit 0 