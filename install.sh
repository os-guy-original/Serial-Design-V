#!/bin/bash

# Source common functions
source "$(dirname "$0")/scripts/common_functions.sh"

# Store the original installation directory for reference
ORIGINAL_INSTALL_DIR="$(pwd)"

#==================================================================
# Pre-Installation Checks
#==================================================================

# Custom help function for install.sh
show_install_help() {
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./install.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo
    
    # Show available scripts
    show_available_scripts
    
    # Show installation options
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}INSTALLATION PROCESS:${RESET}"
    echo -e "  1. The installer will auto-detect your Linux distribution"
    echo -e "  2. It will run the appropriate installation script for your distribution"
    echo -e "  3. You will be prompted to install theme components"
    echo -e "  4. Configuration files will be managed and installed"
    echo -e "  5. Themes will be activated if desired"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTE:${RESET}"
    echo -e "  You can run any of the scripts individually as needed"
    echo -e "  All scripts have good defaults for a quick installation"
    echo
}

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    # Use our custom help function instead of print_help
    print_banner "HyprGraphite Installation Wizard" "A Nice Hyprland Rice Install Helper"
    show_install_help
    exit 0
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
print_banner "HyprGraphite Installation Wizard" "A Nice Hyprland Rice Install Helper"

#==================================================================
# System Detection
#==================================================================
print_section "System Detection"
print_info "Checking system compatibility and determining best installation path"

# Make sure the scripts directory is accessible
if [ ! -d "scripts" ]; then
    print_error "Error: 'scripts' directory not found!"
    print_info "Please ensure you are running this script from the main HyprGraphite directory."
    exit 1
fi

# Function to check if system is Arch-based
is_arch_based() {
    # Primary check: If pacman exists
    if command_exists pacman; then
        return 0
    fi
    
    # Check for Arch-based distros
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "arch" || "$ID" == "endeavouros" || "$ID" == "manjaro" || "$ID" == "garuda" || "$ID" == "artix" ]] || \
           [[ -n "$ID_LIKE" && "$ID_LIKE" == *"arch"* ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Detect distribution and set installation path
if is_arch_based; then
    print_success "Arch-based system detected! ✓"
    
    if ask_yes_no "Would you like to use the Arch-specific installer for better compatibility?" "y"; then
        print_status "Launching Arch Linux installation script..."
        
        SCRIPT_DIR="$(dirname "$0")/scripts"
        ARCH_SCRIPT="${SCRIPT_DIR}/arch_install.sh"
        
        if [ -f "$ARCH_SCRIPT" ]; then
            if [ ! -x "$ARCH_SCRIPT" ]; then
                print_status "Making Arch installation script executable..."
                chmod +x "$ARCH_SCRIPT"
            fi
            
            "$ARCH_SCRIPT"
            exit 0
        else
            print_error "Arch installation script not found at: $ARCH_SCRIPT"
            print_info "Continuing with generic installation..."
        fi
    fi
else
    print_warning "This script is designed for Arch-based systems."
    print_info "Support for other distributions may be limited due to package management differences."
    
    if ! ask_yes_no "Do you want to continue anyway? (Not recommended)" "n"; then
        print_completion_banner "Thanks for your interest in HyprGraphite!"
        print_info "Visit: https://github.com/os-guy/HyprGraphite"
        exit 0
    fi
    
    print_warning "Continuing with generic installation process..."
fi

#==================================================================
# Flatpak Setup
#==================================================================
print_section "Flatpak Setup"
print_info "Installing Flatpak for additional application support"

offer_flatpak_install

#==================================================================
# Theme Setup
#==================================================================
print_section "Theme Setup"
print_info "Installing and configuring themes for your desktop environment"

# Setup all themes using function from common_functions.sh
setup_theme

#==================================================================
# Configuration Setup
#==================================================================
print_section "Configuration Setup"
print_info "Setting up HyprGraphite configuration files"

# Offer config management function from common_functions.sh
offer_config_management

# Ask about copying the included config files
if ask_yes_no "Would you like to copy the included configuration files to your home directory?" "y"; then
    print_status "Copying configuration files..."
    
    CONFIG_SCRIPT="$(dirname "$0")/scripts/copy-configs.sh"
    
    if [ -f "$CONFIG_SCRIPT" ]; then
        if [ ! -x "$CONFIG_SCRIPT" ]; then
            print_status "Making config script executable..."
            chmod +x "$CONFIG_SCRIPT"
        fi
        
        "$CONFIG_SCRIPT"
    else
        print_error "Configuration script not found at: $CONFIG_SCRIPT"
    fi
fi

#==================================================================
# Additional Theme Configuration
#==================================================================
print_section "Additional Theme Configuration"
print_info "Fine-tuning theme settings for optimal appearance"

if ask_yes_no "Would you like to manually configure additional theme options?" "n"; then
    print_status "Launching the theme setup script..."
    
    THEME_SCRIPT="$(dirname "$0")/scripts/setup-themes.sh"
    
    if [ -f "$THEME_SCRIPT" ]; then
        if [ ! -x "$THEME_SCRIPT" ]; then
            print_status "Making theme setup script executable..."
            chmod +x "$THEME_SCRIPT"
        fi
        
        "$THEME_SCRIPT"
    else
        print_error "Theme setup script not found at: $THEME_SCRIPT"
    fi
else
    print_status "Skipping manual theme configuration. You can run it later with: ./scripts/setup-themes.sh"
fi

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

print_completion_banner "HyprGraphite installation completed successfully!"

print_status "Next steps:"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Log out and log back in to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Configure themes with ${BRIGHT_CYAN}'nwg-look'${RESET}"
echo -e "${BRIGHT_WHITE}  4. ${RESET}Configure Qt applications with ${BRIGHT_CYAN}'qt5ct'${RESET} and ${BRIGHT_CYAN}'kvantummanager'${RESET}"

# End of script, ensure we're back in the original directory
cd "$ORIGINAL_INSTALL_DIR" || {
    print_error "Failed to return to original install directory"
}

exit 0 