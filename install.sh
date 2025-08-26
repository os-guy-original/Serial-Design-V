#!/bin/bash

# Source common functions
source "$(dirname "$0")/scripts/utils/common_functions.sh"

# Store the original installation directory for reference
ORIGINAL_INSTALL_DIR="$(pwd)"

# Flag to track if Arch installation was already run
ARCH_INSTALL_DONE=false

# Default AUR helper if not set
if [ -z "$AUR_HELPER" ]; then
    # Run the AUR helper detector script
    print_status "Detecting AUR helpers..."
    AUR_DETECTOR_SCRIPT="$(dirname "$0")/scripts/system-setup/detect-aur-helper.sh"
    
    if [ -f "$AUR_DETECTOR_SCRIPT" ]; then
        if [ ! -x "$AUR_DETECTOR_SCRIPT" ]; then
            chmod +x "$AUR_DETECTOR_SCRIPT"
        fi
        
        # Run the detector script directly to show the UI, then capture its output
        source "$AUR_DETECTOR_SCRIPT"
    else
        print_error "AUR helper detector script not found at: $AUR_DETECTOR_SCRIPT"
        # Fallback to pacman if script not found
        export AUR_HELPER="pacman"
        print_warning "No AUR helper found, using pacman (limited functionality)"
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
    print_error "This script requires the pacman package manager. Serial Design V is ONLY compatible with Arch Linux and Arch-based distributions."
    print_info "This project CANNOT be installed on Debian, Ubuntu, Fedora or other non-Arch distributions."
    print_info "Please install this project on an Arch-based distribution like Arch Linux, EndeavourOS, Manjaro, etc."
    exit 1
else
    print_success "Arch Linux detected! ✓"
    
    #--------------------------------------------------------------
    # AUR Helper Setup
    #--------------------------------------------------------------
    print_section "AUR Helper Setup"
    print_status "Checking for AUR helpers..."

    if [ -z "$AUR_HELPER" ]; then
        AUR_DETECTOR_SCRIPT="$(dirname "$0")/scripts/system-setup/detect-aur-helper.sh"
        if [ -f "$AUR_DETECTOR_SCRIPT" ]; then
            [ ! -x "$AUR_DETECTOR_SCRIPT" ] && chmod +x "$AUR_DETECTOR_SCRIPT"
            # Source to capture AUR_HELPER variable interactively
            source "$AUR_DETECTOR_SCRIPT"
        else
            print_error "AUR helper detector script not found at: $AUR_DETECTOR_SCRIPT"
            export AUR_HELPER="pacman"
            print_warning "No AUR helper found, using pacman (limited functionality)"
        fi
    else
        print_status "Using predefined AUR helper: $AUR_HELPER"
    fi

    export AUR_HELPER

    #--------------------------------------------------------------
    # Chaotic-AUR Setup
    #--------------------------------------------------------------
    print_section "Chaotic-AUR Setup"
    print_info "Chaotic-AUR provides pre-built AUR packages, saving compile time"

    if ask_yes_no "Would you like to install the Chaotic-AUR repository (recommended for additional packages)?" "y"; then
        print_status "Installing Chaotic-AUR repository..."
        if ! find_and_execute_script "scripts/system-setup/install-chaotic-aur.sh" --sudo; then
            print_error "Failed to install Chaotic-AUR repository"
            print_warning "You can try installing it later with: sudo ./scripts/system-setup/install-chaotic-aur.sh"
        fi
    fi
fi

#==================================================================
# File Manager Installation
#==================================================================
print_section "File Manager Installation"
print_info "Installing a file manager"

if ! find_and_execute_script "scripts/app-install/install-file-manager.sh" "" "" "--install-only"; then
    print_error "Failed to run file manager installation script"
    print_warning "You can try installing a file manager later with: ./scripts/app-install/install-file-manager.sh"
else
    print_success "File manager installation completed successfully!"
    print_info "File manager will be configured after copying config files."
fi

# Offer file-manager scripts (previously called "Nautilus Scripts") from the top-level installer
if type install_nautilus_scripts >/dev/null 2>&1; then
    if ask_yes_no "Would you like to install the file-manager scripts (useful for Nautilus and other file managers)?" "y"; then
        install_nautilus_scripts || print_warning "File-manager scripts installation failed or was cancelled."
    else
        print_status "You can install the file-manager scripts later via the file manager installer script."
    fi
fi

#==================================================================
# Flatpak Setup
#==================================================================
print_section "Flatpak Setup"
print_info "Installing Flatpak for additional application support"

if ask_yes_no "Would you like to install Flatpak and set it up?" "y"; then
    print_status "Launching the Flatpak installer..."
    if ! find_and_execute_script "scripts/system-setup/install-flatpak.sh" --sudo; then
        print_error "Failed to run Flatpak installation script"
        print_warning "Skipping Flatpak installation. You can run it later with: sudo ./scripts/system-setup/install-flatpak.sh"
    fi
else
    print_status "Skipping Flatpak installation. You can run it later with: sudo ./scripts/system-setup/install-flatpak.sh"
fi

#==================================================================
# Core Dependencies Installation
#==================================================================
print_section "Core Dependencies Installation"

if ask_yes_no "Would you like to install core dependencies for Serial Design V?" "y"; then
    print_status "Launching core dependencies installer..."
    if ! find_and_execute_script "scripts/system-setup/install-core-deps.sh" --yes; then
        print_error "Failed to run core dependencies installation script"
        print_warning "You can attempt manual installation by running ./scripts/system-setup/install-core-deps.sh"
    fi
else
    print_status "Skipping core dependencies installation. You can run it later with: ./scripts/system-setup/install-core-deps.sh"
fi

#==================================================================
# Theme Setup
#==================================================================
print_section "Theme Setup"
print_info "Setting up visual themes for your desktop environment"

# Initialize GTK theme skip flag
GTK_THEME_SKIPPED=false
export GTK_THEME_SKIPPED

# GTK Theme Installation
print_section "GTK Theme Installation"

# Check if GTK theme is already installed
if check_gtk_theme_installed; then
    print_success "GTK theme 'adw-gtk3-dark' is already installed."
    if ask_yes_no "Would you like to reinstall it?" "n"; then
        print_status "Reinstalling GTK theme..."
    else
        print_status "Skipping GTK theme installation."
        GTK_THEME_SKIPPED=true
    fi
else
    print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
fi

# Install GTK theme if not skipped
if [ "$GTK_THEME_SKIPPED" = false ]; then
    if ask_yes_no "Would you like to install the GTK theme?" "y"; then
        print_status "Installing GTK theme..."
        
        if ! find_and_execute_script "scripts/theme-setup/install-gtk-theme.sh" "" "" "--install-only"; then
            print_error "Failed to install GTK theme"
            print_warning "You can try installing it later with: ./scripts/theme-setup/install-gtk-theme.sh"
            GTK_THEME_SKIPPED=true
        else
            print_success "GTK theme installed successfully!"
        fi
    else
        print_status "Skipping GTK theme installation. You can run it later with: ./scripts/theme-setup/install-gtk-theme.sh"
        GTK_THEME_SKIPPED=true
    fi
fi

# QT Theme Installation
print_section "QT Theme Installation"

QT_SKIPPED=false

if command -v flatpak &>/dev/null; then
    print_info "QT theme configuration for Flatpak applications"
    if ask_yes_no "Would you like to configure QT theme for Flatpak applications?" "y"; then
        print_status "Installing QT theme for Flatpak..."
        # Call the script directly instead of using find_and_execute_script
        SCRIPT_PATH="$(dirname "$0")/scripts/theme-setup/apply-flatpak-theme.sh"
        if [ -f "$SCRIPT_PATH" ]; then
            chmod +x "$SCRIPT_PATH"
            if ! "$SCRIPT_PATH" --only-qt; then
                print_error "Failed to run QT theme installation script"
                print_warning "Skipping QT theme installation."
                QT_SKIPPED=true
            fi
        else
            print_error "Could not find apply-flatpak-theme.sh script"
            print_warning "Skipping QT theme installation."
            QT_SKIPPED=true
        fi
    else
        print_status "Skipping QT theme installation. You can run it later with: ./scripts/theme-setup/apply-flatpak-theme.sh --only-qt"
        QT_SKIPPED=true
    fi
else
    print_warning "Flatpak is not installed. Skipping QT theme configuration."
    QT_SKIPPED=true
fi

# GTK Flatpak Theme Installation
print_section "GTK Flatpak Theme Installation"

GTK_FLATPAK_SKIPPED=false

if command -v flatpak &>/dev/null; then
    print_info "GTK theme configuration for Flatpak applications"
    if ask_yes_no "Would you like to configure GTK theme for Flatpak applications?" "y"; then
        print_status "Setting up GTK theme for Flatpak..."
        # Call the script directly
        SCRIPT_PATH="$(dirname "$0")/scripts/theme-setup/apply-flatpak-theme.sh"
        if [ -f "$SCRIPT_PATH" ]; then
            chmod +x "$SCRIPT_PATH"
            if ! "$SCRIPT_PATH" --only-gtk; then
                print_error "Failed to run GTK theme installation script"
                print_warning "Skipping GTK Flatpak theme installation."
                GTK_FLATPAK_SKIPPED=true
            fi
        else
            print_error "Could not find apply-flatpak-theme.sh script"
            print_warning "Skipping GTK Flatpak theme installation."
            GTK_FLATPAK_SKIPPED=true
        fi
    else
        print_status "Skipping GTK Flatpak theme installation. You can run it later with: ./scripts/theme-setup/apply-flatpak-theme.sh --only-gtk"
        GTK_FLATPAK_SKIPPED=true
    fi
else
    print_warning "Flatpak is not installed. Skipping GTK Flatpak theme configuration."
    GTK_FLATPAK_SKIPPED=true
fi

# Cursor Theme Installation
print_section "Cursor Installation"

CURSOR_REINSTALL=false
if check_cursor_theme_installed; then
    print_success "Cursor theme 'Graphite-dark-cursors' is already installed."
    if ask_yes_no "Would you like to reinstall it?" "n"; then
        print_status "Reinstalling cursor theme..."
        CURSOR_REINSTALL=true
    else
        print_status "Skipping cursor theme installation."
    fi
else
    print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
fi

if $CURSOR_REINSTALL || ! check_cursor_theme_installed; then
    print_status "Installing Graphite cursors..."
    if ! find_and_execute_script "scripts/theme-setup/install-cursors.sh"; then
        print_error "Failed to run cursor installation script"
        print_warning "You can try installing manually with: yay -S graphite-cursor-theme"
    fi
else
    print_status "Skipping cursor installation. You can run it later with: ./scripts/theme-setup/install-cursors.sh"
fi

# Icon Theme Installation
print_section "Icon Theme Installation"

ICON_SKIPPED=false

if check_icon_theme_installed; then
    print_success "Fluent icon theme already installed."
    if ! ask_yes_no "Would you like to reinstall it?" "n"; then
        print_status "Skipping icon theme installation."
        ICON_SKIPPED=true
    else
        print_status "Reinstalling icon theme..."
    fi
else
    print_warning "Icon theme is not installed. Your system will use the default icon theme."
fi

# Install fluent icon theme if not skipped
if [ "$ICON_SKIPPED" != "true" ]; then
    if ask_yes_no "Would you like to install the Fluent icon theme?" "y"; then
        print_status "Installing Fluent icon theme..."
        if ! find_and_execute_script "scripts/theme-setup/install-icon-theme.sh"; then
            print_error "Failed to run icon theme installation script"
            print_warning "Skipping icon theme installation."
        fi
    else
        print_status "Skipping icon theme installation. You can run it later with: ./scripts/theme-setup/install-icon-theme.sh"
    fi
fi

#==================================================================
# Evolve-Core Installation
#==================================================================
print_section "Evolve-Core Theme Manager"
print_info "Installing Evolve-Core Theme Manager Utility"

# Debug information
print_status "Current AUR helper: $AUR_HELPER"

if ask_yes_no "Would you like to install Evolve-Core theme manager utility?" "y"; then
    print_status "Launching Evolve-Core installer..."
    export AUR_HELPER
    print_status "Using AUR helper for Evolve-Core: $AUR_HELPER"
    if find_and_execute_script "scripts/app-install/install-evolve-core.sh"; then
        EVOLVE_INSTALLED=true
    else
        print_error "Failed to run Evolve-Core installation script"
        EVOLVE_INSTALLED=false
    fi
else
    print_status "Skipping Evolve-Core installation. You can run it later with: ./scripts/app-install/install-evolve-core.sh"
    EVOLVE_INSTALLED=false
fi

#==================================================================
# Configuration Setup
#==================================================================
print_section "Configuration Setup"
print_info "Setting up configuration files for Serial Design V"

# Configuration setup
print_status "Running configuration scripts..."

# Execute configuration copy script
if ! find_and_execute_script "scripts/config/copy-configs.sh" "" "" "--skip-prompt"; then
    print_error "Failed to run configuration copy script"
    print_warning "You will need to copy configuration files manually."
fi

# Execute file manager installation script
if ! find_and_execute_script "scripts/app-install/install-file-manager.sh" --silent "" "--configure-only"; then
    print_error "Failed to run file manager configuration script"
    print_warning "You will need to configure your file manager manually."
fi

# Execute GTK theme configuration script
if ! find_and_execute_script "scripts/theme-setup/install-gtk-theme.sh" --silent "" "--configure-only"; then
    print_error "Failed to run GTK theme configuration script"
    print_warning "You will need to configure your GTK theme manually."
fi

#==================================================================
# Additional Theme Configuration
#==================================================================
print_section "Additional Theme Configuration"
print_info "Fine-tuning theme settings for optimal appearance"

if ask_yes_no "Would you like to manually configure additional theme options?" "n"; then
    print_status "Launching the theme setup script..."
    
    # Execute theme setup script
    if ! find_and_execute_script "scripts/theme-setup/setup-themes.sh"; then
        print_error "Failed to run theme setup script"
    fi
else
    print_status "Skipping manual theme configuration. You can run it later with: ./scripts/theme-setup/setup-themes.sh"
fi

#==================================================================
# Custom Packages Installation
#==================================================================
print_section "Custom Packages Installation"
print_info "Checking for custom packages to install"

# Execute custom packages installation script
if ! find_and_execute_script "scripts/app-install/install-custom-packages.sh"; then
    print_warning "Could not run custom packages installation script"
fi

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

# Check if user skipped GTK theme installation, if so, set it silently to adw-gtk3-dark
if [ "$GTK_THEME_SKIPPED" = true ]; then
    # Run the script to set the default GTK theme silently
    find_and_execute_script "scripts/theme-setup/set-to-default-gtk.sh" --silent
fi

print_completion_banner "Serial Design V installed successfully!"

echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Use ${BRIGHT_CYAN}'nwg-look'${RESET} to customize your default theme settings"
echo -e "${BRIGHT_WHITE}  4. ${RESET}You should set the theme in WINE to ${BRIGHT_CYAN}'No Theme'${RESET} for using color generation in WINE"
echo -e "${BRIGHT_WHITE}  5. ${RESET}Enjoy your new modern desktop environment!"

if [ "$EVOLVE_INSTALLED" = true ]; then
    echo -e "${BRIGHT_WHITE}  6. ${RESET}Use Evolve-Core from your Desktop to manage GTK themes if needed"
fi

if [ "$MAIN_CENTER_INSTALLED" = true ]; then
    echo -e "${BRIGHT_WHITE}  7. ${RESET}Access the Main Center by running ${BRIGHT_CYAN}'main-center'${RESET}"
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
    echo -e "  ${CYAN}• scripts/system-setup/install-chaotic-aur.sh${RESET} - Arch Linux specific installation"
    echo -e "  ${CYAN}• scripts/system-setup/install-flatpak.sh${RESET} - Install and configure Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Components:${RESET}"
    echo -e "  ${CYAN}• scripts/theme-setup/install-gtk-theme.sh${RESET} - Install serial-design-V GTK theme"
    echo -e "  ${CYAN}• scripts/theme-setup/install-cursors.sh${RESET} - Install Bibata cursors"
    echo -e "  ${CYAN}• scripts/theme-setup/install-icon-theme.sh${RESET} - Install icon theme"
    echo -e "  ${CYAN}• scripts/theme-setup/apply-flatpak-theme.sh${RESET} - Install QT theme for Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Activation:${RESET}"
    echo -e "  ${CYAN}• scripts/theme-setup/setup-themes.sh${RESET} - Configure and activate installed themes"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Configuration:${RESET}"
    echo -e "  ${CYAN}• scripts/config/manage-config.sh${RESET} - Manage Serial Design V configuration files"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Utilities:${RESET}"
    echo -e "  ${CYAN}• scripts/app-install/install_var_viewer.sh${RESET} - Install Hyprland settings utility"
    echo -e "  ${CYAN}• scripts/app-install/install_keybinds_viewer.sh${RESET} - Install Hyprland keybinds viewer"
    echo -e "  ${CYAN}• scripts/app-install/install_main_center.sh${RESET} - Install Main Center utility"
    echo -e "  ${CYAN}• scripts/app-install/install-custom-packages.sh${RESET} - Install custom packages marked with [CUSTOM] in package-list.txt"
    echo
    echo -e "${BRIGHT_WHITE}Run any script with: ${BRIGHT_CYAN}chmod +x <script-path> && ./<script-path>${RESET}"
} 