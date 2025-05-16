#!/bin/bash

# Source common functions
source "$(dirname "$0")/scripts/common_functions.sh"

# Store the original installation directory for reference
ORIGINAL_INSTALL_DIR="$(pwd)"

# Flag to track if Arch installation was already run
ARCH_INSTALL_DONE=false

# Default AUR helper if not set
if [ -z "$AUR_HELPER" ]; then
    if command -v yay &>/dev/null; then
        export AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        export AUR_HELPER="paru"
    elif command -v trizen &>/dev/null; then
        export AUR_HELPER="trizen"
    elif command -v pikaur &>/dev/null; then
        export AUR_HELPER="pikaur"
    else
        export AUR_HELPER="pacman"
    fi
fi

#==================================================================
# Pre-Installation Checks
#==================================================================

# Print custom help info
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
    echo -e "  1. The installer will set up appropriate packages and dependencies"
    echo -e "  2. You will be prompted to install theme components"
    echo -e "  3. Configuration files will be managed and installed"
    echo -e "  4. Themes will be activated if desired"
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
    print_banner "Serial Design V Installation Wizard" "A Nice Hyprland Rice Install Helper"
    show_install_help
    exit 0
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
print_banner "Serial Design V Installation Wizard" "A Nice Hyprland Rice Install Helper"

#==================================================================
# Prerequisites Check
#==================================================================
print_section "Prerequisites Check"
print_info "Checking for required dependencies"

# Make sure the scripts directory is accessible
if [ ! -d "scripts" ]; then
    print_error "Error: 'scripts' directory not found!"
    print_info "Please ensure you are running this script from the main HyprGraphite directory."
    exit 1
fi

# Check for pacman package manager
if ! command_exists pacman; then
    print_warning "This script requires the pacman package manager."
    print_info "Support for other distributions may be limited due to package management differences."
    
    if ! ask_yes_no "Do you want to continue anyway? (Not recommended)" "n"; then
        print_completion_banner "Thanks for your interest in HyprGraphite!"
        print_info "Visit: https://github.com/os-guy/HyprGraphite"
        exit 0
    fi
    
    print_warning "Continuing with installation process without package management..."
else
    print_success "Package manager detected! ✓"
    
    # Ask about using Arch-specific installer if available
    if ask_yes_no "Would you like to use the Arch-specific installer for better compatibility?" "y"; then
        print_status "Launching Arch Linux installation script..."
        
        SCRIPT_DIR="$(dirname "$0")/scripts"
        ARCH_SCRIPT="${SCRIPT_DIR}/arch_install.sh"
        
        if [ -f "$ARCH_SCRIPT" ]; then
            if [ ! -x "$ARCH_SCRIPT" ]; then
                print_status "Making Arch installation script executable..."
                chmod +x "$ARCH_SCRIPT"
            fi
            
            # Run the Arch install script and continue with this script afterward
            "$ARCH_SCRIPT"
            ARCH_INSTALL_DONE=true
            
            # Make sure AUR_HELPER is exported after arch_install.sh is run
            if [ -z "$AUR_HELPER" ]; then
                print_warning "AUR helper not detected from arch_install.sh, using default"
                # Default AUR helper if not set
                if command -v yay &>/dev/null; then
                    export AUR_HELPER="yay"
                    print_status "Using detected AUR helper: yay"
                elif command -v paru &>/dev/null; then
                    export AUR_HELPER="paru"
                    print_status "Using detected AUR helper: paru"
                else
                    export AUR_HELPER="pacman"
                    print_status "No AUR helper found, using pacman (limited functionality)"
                fi
            else
                print_status "Using AUR helper from arch_install.sh: $AUR_HELPER"
            fi
            
            print_section "Continuing Installation after Arch Setup"
            print_info "Proceeding with theme and configuration setup"
        else
            print_error "Arch installation script not found at: $ARCH_SCRIPT"
            print_info "Continuing with generic installation..."
        fi
    fi
fi

#==================================================================
# Flatpak Setup
#==================================================================
# Only run this if Arch install was not performed
if [ "$ARCH_INSTALL_DONE" = false ]; then
    print_section "Flatpak Setup"
    print_info "Installing Flatpak for additional application support"
    
    offer_flatpak_install
fi

#==================================================================
# Theme Setup
#==================================================================
print_section "Theme Setup"
print_info "Setting up visual themes for your desktop environment"

# Setup all themes using function from common_functions.sh
setup_theme

#==================================================================
# Evolve-Core Installation
#==================================================================
print_section "Evolve-Core Theme Manager"
print_info "Installing Evolve-Core Theme Manager Utility"

# Debug information
print_status "Current AUR helper: $AUR_HELPER"

if ask_yes_no "Would you like to install Evolve-Core theme manager utility?" "y"; then
    print_status "Launching Evolve-Core installer..."
    
    EVOLVE_SCRIPT="$(dirname "$0")/scripts/install-evolve-core.sh"
    
    if [ -f "$EVOLVE_SCRIPT" ]; then
        if [ ! -x "$EVOLVE_SCRIPT" ]; then
            print_status "Making Evolve-Core installer executable..."
            chmod +x "$EVOLVE_SCRIPT"
        fi
        
        # Make sure AUR_HELPER is exported
        export AUR_HELPER
        print_status "Using AUR helper for Evolve-Core: $AUR_HELPER"
        
        # Run with exported AUR_HELPER
        "$EVOLVE_SCRIPT"
        EVOLVE_INSTALLED=true
    else
        print_error "Evolve-Core installer script not found at: $EVOLVE_SCRIPT"
        EVOLVE_INSTALLED=false
    fi
else
    print_status "Skipping Evolve-Core installation. You can run it later with: ./scripts/install-evolve-core.sh"
    EVOLVE_INSTALLED=false
fi

#==================================================================
# Configuration Setup
#==================================================================
print_section "Configuration Setup"
print_info "Setting up configuration files for Serial Design V"

# Setup configuration files directly using common_functions.sh method
setup_configuration

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

print_completion_banner "Serial Design V installed successfully!"

echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Use ${BRIGHT_CYAN}'nwg-look'${RESET} to customize your default theme settings"
echo -e "${BRIGHT_WHITE}  4. ${RESET}Enjoy your new modern desktop environment!"

if [ "$EVOLVE_INSTALLED" = true ]; then
    echo -e "${BRIGHT_WHITE}  5. ${RESET}Use Evolve-Core from your Desktop to manage GTK themes if needed"
fi

if [ "$MAIN_CENTER_INSTALLED" = true ]; then
    echo -e "${BRIGHT_WHITE}  6. ${RESET}Access the Main Center by running ${BRIGHT_CYAN}'main-center'${RESET}"
fi

echo

# End of script, ensure we're back in the original directory
cd "$ORIGINAL_INSTALL_DIR" || {
    print_error "Failed to return to original install directory"
}

exit 0

show_available_scripts() {
    echo
    print_section "Available Scripts"
    
    echo -e "${BRIGHT_WHITE}${BOLD}Serial Design V comes with several utility scripts:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Core Installation:${RESET}"
    echo -e "  ${CYAN}• install.sh${RESET} - Main installation script (current)"
    echo -e "  ${CYAN}• scripts/arch_install.sh${RESET} - Arch Linux specific installation"
    echo -e "  ${CYAN}• scripts/install-flatpak.sh${RESET} - Install and configure Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Components:${RESET}"
    echo -e "  ${CYAN}• scripts/install-gtk-theme.sh${RESET} - Install serial-design-V GTK theme"
    echo -e "  ${CYAN}• scripts/install-cursors.sh${RESET} - Install Bibata cursors"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Activation:${RESET}"
    echo -e "  ${CYAN}• scripts/setup-themes.sh${RESET} - Configure and activate installed themes"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Configuration:${RESET}"
    echo -e "  ${CYAN}• scripts/manage-config.sh${RESET} - Manage Serial Design V configuration files"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Utilities:${RESET}"
    echo -e "  ${CYAN}• scripts/install_var_viewer.sh${RESET} - Install Hyprland settings utility"
    echo -e "  ${CYAN}• scripts/install_keybinds_viewer.sh${RESET} - Install Hyprland keybinds viewer"
    echo -e "  ${CYAN}• scripts/install_main_center.sh${RESET} - Install Main Center utility"
    echo
    echo -e "${BRIGHT_WHITE}Run any script with: ${BRIGHT_CYAN}chmod +x <script-path> && ./<script-path>${RESET}"
} 