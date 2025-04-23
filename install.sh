#!/bin/bash

# Source common functions
source "$(dirname "$0")/scripts/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Complete Desktop Setup                   │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Helper Functions                                        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Function to offer theme setup
offer_theme_setup() {
    echo
    print_section "Theme Activation"
    
    if ask_yes_no "Would you like to configure and activate the installed themes?" "y"; then
        print_status "Launching the theme setup script..."
        
        # Check if setup-themes.sh exists and is executable
        if [ -f "./scripts/setup-themes.sh" ] && [ -x "./scripts/setup-themes.sh" ]; then
            ./scripts/setup-themes.sh
        else
            print_status "Making theme setup script executable..."
            chmod +x ./scripts/setup-themes.sh
            ./scripts/setup-themes.sh
        fi
    else
        print_status "Skipping theme activation. You can run it later with: ./scripts/setup-themes.sh"
    fi
}

# Function to offer config management
offer_config_management() {
    echo
    print_section "Configuration Management"
    
    if ask_yes_no "Would you like to manage your configuration files?" "y"; then
        print_status "Launching the configuration management script..."
        
        # Check if manage-config.sh exists and is executable
        if [ -f "./scripts/manage-config.sh" ] && [ -x "./scripts/manage-config.sh" ]; then
            ./scripts/manage-config.sh
        else
            print_status "Making configuration management script executable..."
            chmod +x ./scripts/manage-config.sh
            ./scripts/manage-config.sh
        fi
    else
        print_status "Skipping configuration management. You can run it later with: ./scripts/manage-config.sh"
    fi
}

# Function to show all available scripts
show_available_scripts() {
    echo
    print_section "Available Scripts"
    
    echo -e "${BRIGHT_WHITE}${BOLD}HyprGraphite comes with several utility scripts:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Core Installation:${RESET}"
    echo -e "  ${CYAN}• install.sh${RESET} - Main installation script (current)"
    echo -e "  ${CYAN}• scripts/arch_install.sh${RESET} - Arch Linux specific installation"
    echo -e "  ${CYAN}• scripts/fedora_install.sh${RESET} - Fedora specific installation"
    echo -e "  ${CYAN}• scripts/install-flatpak.sh${RESET} - Install and configure Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Components:${RESET}"
    echo -e "  ${CYAN}• scripts/install-gtk-theme.sh${RESET} - Install Graphite GTK theme"
    echo -e "  ${CYAN}• scripts/install-qt-theme.sh${RESET} - Install Graphite Qt/KDE theme"
    echo -e "  ${CYAN}• scripts/install-cursors.sh${RESET} - Install Bibata cursors"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Activation:${RESET}"
    echo -e "  ${CYAN}• scripts/setup-themes.sh${RESET} - Configure and activate installed themes"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Configuration:${RESET}"
    echo -e "  ${CYAN}• scripts/manage-config.sh${RESET} - Manage HyprGraphite configuration files"
    echo
    echo -e "${BRIGHT_WHITE}Run any script with: ${BRIGHT_CYAN}chmod +x <script-path> && ./<script-path>${RESET}"
}

# Function to offer GTK theme installation
offer_gtk_theme() {
    echo
    print_section "GTK Theme Installation"
    
    if ask_yes_no "Would you like to install the Graphite GTK theme separately?" "n"; then
        print_status "Launching the GTK theme installer..."
        
        # Check if install-gtk-theme.sh exists and is executable
        if [ -f "./scripts/install-gtk-theme.sh" ] && [ -x "./scripts/install-gtk-theme.sh" ]; then
            ./scripts/install-gtk-theme.sh
        else
            print_status "Making GTK theme installer executable..."
            chmod +x ./scripts/install-gtk-theme.sh
            ./scripts/install-gtk-theme.sh
        fi
    else
        print_status "Skipping GTK theme installation. You can run it later with: ./scripts/install-gtk-theme.sh"
    fi
}

# Function to offer QT theme installation
offer_qt_theme() {
    echo
    print_section "QT Theme Installation"
    
    if ask_yes_no "Would you like to install the Graphite QT/KDE theme separately?" "n"; then
        print_status "Launching the QT theme installer..."
        
        # Check if install-qt-theme.sh exists and is executable
        if [ -f "./scripts/install-qt-theme.sh" ] && [ -x "./scripts/install-qt-theme.sh" ]; then
            ./scripts/install-qt-theme.sh
        else
            print_status "Making QT theme installer executable..."
            chmod +x ./scripts/install-qt-theme.sh
            ./scripts/install-qt-theme.sh
        fi
    else
        print_status "Skipping QT theme installation. You can run it later with: ./scripts/install-qt-theme.sh"
    fi
}

# Function to offer cursor installation
offer_cursor_install() {
    echo
    print_section "Cursor Installation"
    
    if ask_yes_no "Would you like to install the Bibata cursors separately?" "n"; then
        print_status "Launching the cursor installer..."
        
        # Check if install-cursors.sh exists and is executable
        if [ -f "./scripts/install-cursors.sh" ] && [ -x "./scripts/install-cursors.sh" ]; then
            ./scripts/install-cursors.sh
        else
            print_status "Making cursor installer executable..."
            chmod +x ./scripts/install-cursors.sh
            ./scripts/install-cursors.sh
        fi
    else
        print_status "Skipping cursor installation. You can run it later with: ./scripts/install-cursors.sh"
    fi
}

# Function to offer Flatpak installation
offer_flatpak_install() {
    echo
    print_section "Flatpak Installation"
    
    if ask_yes_no "Would you like to install Flatpak and set it up?" "y"; then
        print_status "Launching the Flatpak installer..."
        
        # Check if install-flatpak.sh exists and is executable
        if [ -f "./scripts/install-flatpak.sh" ] && [ -x "./scripts/install-flatpak.sh" ]; then
            ./scripts/install-flatpak.sh
        else
            print_status "Making Flatpak installer executable..."
            chmod +x ./scripts/install-flatpak.sh
            ./scripts/install-flatpak.sh
        fi
    else
        print_status "Skipping Flatpak installation. You can run it later with: ./scripts/install-flatpak.sh"
    fi
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            HyprGraphite Help                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     A Nice Hyprland Rice Install Helper     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./install.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help${RESET}    Display this help message"
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
    
    exit 0
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Installation Logic                                ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_help
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         HyprGraphite Installation Wizard         ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}       A Nice Hyprland Rice Install Helper       ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Detect the distro
print_section "System Detection"
print_status "Detecting your operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)
else
    print_error "Cannot detect OS. Exiting..."
    exit 1
fi

print_success "Detected: $OS $OS_VER"

# Make sure the scripts directory is accessible
if [ ! -d "scripts" ]; then
    print_error "Error: 'scripts' directory not found!"
    print_status "Please ensure you are running this script from the main HyprGraphite directory."
    exit 1
fi

# Ask user if they want to use the OS-specific installer
case "$OS" in
    "arch"|"endeavouros"|"manjaro"|"garuda")
        print_success "Arch-based system detected! ${GREEN}${BOLD}✓${RESET}"
        if ask_yes_no "Would you like to use the Arch-specific installer for better compatibility?" "y"; then
            print_status "Launching Arch Linux installation script..."
            if [ -f "./scripts/arch_install.sh" ] && [ -x "./scripts/arch_install.sh" ]; then
                ./scripts/arch_install.sh
                exit 0
            else
                print_status "Making Arch installation script executable..."
                chmod +x ./scripts/arch_install.sh
                ./scripts/arch_install.sh
                exit 0
            fi
        fi
        ;;
    "fedora")
        print_success "Fedora detected! ${GREEN}${BOLD}✓${RESET}"
        if ask_yes_no "Would you like to use the Fedora-specific installer for better compatibility?" "y"; then
            print_status "Launching Fedora installation script..."
            if [ -f "./scripts/fedora_install.sh" ] && [ -x "./scripts/fedora_install.sh" ]; then
                ./scripts/fedora_install.sh
                exit 0
            else
                print_status "Making Fedora installation script executable..."
                chmod +x ./scripts/fedora_install.sh
                ./scripts/fedora_install.sh
                exit 0
            fi
        fi
        ;;
    *)
        print_error "Unsupported distribution: $OS"
        echo
        echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}HyprGraphite is primarily designed for Arch Linux and Fedora."
        echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}If you're feeling adventurous, you can try manual installation following the README."
        
        echo
        echo -e "${BRIGHT_PURPLE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_GREEN}Want to contribute support for your distro?${RESET}      ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_CYAN}https://github.com/os-guy/HyprGraphite${RESET}           ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
        exit 1
        ;;
esac

# If user chose not to use OS-specific installer, continue with generic installation
print_status "Continuing with generic installation process..."

# Offer Flatpak installation first
print_warning "Installing Flatpak first is recommended since theme installers will also set Flatpak themes!"
offer_flatpak_install

# Offer individual theme components
offer_gtk_theme

offer_qt_theme

offer_cursor_install

# Offer config management
offer_config_management

# Directly offer to copy configs
if ask_yes_no "Would you like to directly copy the included configuration files to your home directory?" "y"; then
    print_status "Copying configuration files..."
    if [ -f "./scripts/copy-configs.sh" ] && [ -x "./scripts/copy-configs.sh" ]; then
        ./scripts/copy-configs.sh
    else
        print_status "Making config copy script executable..."
        chmod +x ./scripts/copy-configs.sh
        ./scripts/copy-configs.sh
    fi
fi

# Finally offer theme setup/activation
offer_theme_setup

# Thank the user for installing
print_section "Installation Complete"
print_success "HyprGraphite has been installed on your system!"
echo -e "${BRIGHT_WHITE}You can now log out and select Hyprland at your login screen to start using HyprGraphite.${RESET}"
echo

# Show available scripts
show_available_scripts

exit 0 