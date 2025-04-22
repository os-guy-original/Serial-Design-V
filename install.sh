#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Modern Hyprland Setup                   │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Reset
RESET='\033[0m'

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bright Colors
BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_PURPLE='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Helper Functions                                        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Print a section header
print_section() {
    echo -e "\n${BRIGHT_BLUE}${BOLD}⟪ $1 ⟫${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

# Print a status message
print_status() {
    echo -e "${YELLOW}${BOLD}ℹ ${RESET}${YELLOW}$1${RESET}"
}

# Print a success message
print_success() {
    echo -e "${GREEN}${BOLD}✓ ${RESET}${GREEN}$1${RESET}"
}

# Print an error message
print_error() {
    echo -e "${RED}${BOLD}✗ ${RESET}${RED}$1${RESET}"
}

# Print a warning message
print_warning() {
    echo -e "${BRIGHT_YELLOW}${BOLD}⚠ ${RESET}${BRIGHT_YELLOW}$1${RESET}"
}

# Ask the user for a yes/no answer
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [ "$default" = "y" ]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}${prompt}${RESET}"
    read -r response
    
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

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
    echo -e "  ${CYAN}• scripts/debian_install.sh${RESET} - Debian/Ubuntu specific installation"
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
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
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
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            HyprGraphite Installer            ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
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

case "$OS" in
    "arch"|"endeavouros"|"manjaro"|"garuda")
        print_success "Arch-based system detected! ${GREEN}${BOLD}✓${RESET}"
        print_status "Launching Arch Linux installation script..."
        
        # Check if arch_install.sh exists and is executable
        if [ -f "./scripts/arch_install.sh" ] && [ -x "./scripts/arch_install.sh" ]; then
            ./scripts/arch_install.sh
        else
            print_status "Making Arch installation script executable..."
            chmod +x ./scripts/arch_install.sh
            ./scripts/arch_install.sh
        fi
        
        # Offer Flatpak installation first
        print_warning "Installing Flatpak first is recommended since theme installers will also set Flatpak themes!"
        offer_flatpak_install
        
        # Offer individual theme components
        offer_gtk_theme
        
        offer_qt_theme
        
        offer_cursor_install
        
        # Offer config management
        offer_config_management
        
        # Finally offer theme setup/activation
        offer_theme_setup
        ;;
    "debian"|"ubuntu"|"pop"|"linuxmint"|"elementary")
        print_success "Debian/Ubuntu-based system detected! ${GREEN}${BOLD}✓${RESET}"
        print_status "Launching Debian installation script..."
        
        # Check if debian_install.sh exists and is executable
        if [ -f "./scripts/debian_install.sh" ] && [ -x "./scripts/debian_install.sh" ]; then
            ./scripts/debian_install.sh
        else
            print_status "Making Debian installation script executable..."
            chmod +x ./scripts/debian_install.sh
            ./scripts/debian_install.sh
        fi
        
        # Offer Flatpak installation first
        print_warning "Installing Flatpak first is recommended since theme installers will also set Flatpak themes!"
        offer_flatpak_install
        
        # Offer individual theme components
        offer_gtk_theme
        
        offer_qt_theme
        
        offer_cursor_install
        
        # Offer config management
        offer_config_management
        
        # Finally offer theme setup/activation
        offer_theme_setup
        ;;
    "fedora")
        print_success "Fedora detected! ${GREEN}${BOLD}✓${RESET}"
        print_status "Launching Fedora installation script..."
        
        # Check if fedora_install.sh exists and is executable
        if [ -f "./scripts/fedora_install.sh" ] && [ -x "./scripts/fedora_install.sh" ]; then
            ./scripts/fedora_install.sh
        else
            print_status "Making Fedora installation script executable..."
            chmod +x ./scripts/fedora_install.sh
            ./scripts/fedora_install.sh
        fi
        
        # Offer Flatpak installation first
        print_warning "Installing Flatpak first is recommended since theme installers will also set Flatpak themes!"
        offer_flatpak_install
        
        # Offer individual theme components
        offer_gtk_theme
        
        offer_qt_theme
        
        offer_cursor_install
        
        # Offer config management
        offer_config_management
        
        # Finally offer theme setup/activation
        offer_theme_setup
        ;;
    *)
        print_error "Unsupported distribution: $OS"
        echo
        echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}HyprGraphite is primarily designed for Arch Linux, Debian/Ubuntu, and Fedora."
        echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}If you're feeling adventurous, you can try manual installation following the README."
        
        echo
        echo -e "${BRIGHT_PURPLE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_GREEN}Want to contribute support for your distro?${RESET}      ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_CYAN}https://github.com/os-guy/HyprGraphite${RESET}           ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
        exit 1
        ;;
esac

# Thank the user for installing
print_section "Installation Complete"
print_success "HyprGraphite has been installed on your system!"
echo -e "${BRIGHT_WHITE}You can now log out and select Hyprland at your login screen to start using HyprGraphite.${RESET}"
echo

# Show available scripts
show_available_scripts

exit 0 