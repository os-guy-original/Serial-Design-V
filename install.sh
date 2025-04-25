#!/bin/bash

# Source common functions
source "$(dirname "$0")/scripts/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Complete Desktop Setup                   │
# ╰──────────────────────────────────────────────────────────╯

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

# 6. Theme Setup
print_section "Theme Setup"
print_status "Checking installed themes..."

# Check and offer GTK theme
if check_gtk_theme_installed; then
    print_success "GTK theme 'Graphite-Dark' is already installed."
else
    print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    if ask_yes_no "Would you like to install the Graphite GTK theme now?" "y"; then
        # Get the script directory path for this script
        THEME_SCRIPT_DIR="$(dirname "$0")/scripts"
        "$THEME_SCRIPT_DIR/install-gtk-theme.sh"
    else
        print_status "Skipping GTK theme installation."
    fi
fi

# Check and offer QT theme
if check_qt_theme_installed; then
    print_success "QT theme 'Graphite-rimlessDark' is already installed."
else
    print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
    if ask_yes_no "Would you like to install the Graphite QT theme now?" "y"; then
        # Get the script directory path for this script
        THEME_SCRIPT_DIR="$(dirname "$0")/scripts"
        "$THEME_SCRIPT_DIR/install-qt-theme.sh"
    else
        print_status "Skipping QT theme installation."
    fi
fi

# Check and offer cursor theme
if check_cursor_theme_installed; then
    print_success "Cursor theme 'Bibata-Modern-Classic' is already installed."
else
    print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
    if ask_yes_no "Would you like to install the Bibata cursors now?" "y"; then
        # Get the script directory path for this script
        THEME_SCRIPT_DIR="$(dirname "$0")/scripts"
        "$THEME_SCRIPT_DIR/install-cursors.sh"
    else
        print_status "Skipping cursor installation."
    fi
fi

# Check and offer icon theme
if check_icon_theme_installed; then
    print_success "Fluent icon theme already installed."
else
    print_warning "Icon theme is not installed. Your system will use the default icon theme."
    if ask_yes_no "Would you like to install the Fluent icon theme now?" "y"; then
        # Get the script directory path for this script
        THEME_SCRIPT_DIR="$(dirname "$0")/scripts"
        "$THEME_SCRIPT_DIR/install-icon-theme.sh" "fluent" "Fluent-grey"
    else
        print_status "Skipping icon theme installation."
    fi
fi

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

# Automatically set up themes
auto_setup_themes

# Offer manual theme setup as an option
if ask_yes_no "Would you like to manually configure and activate additional theme options?" "n"; then
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
    print_status "Skipping manual theme activation. You can run it later with: ./scripts/setup-themes.sh"
fi

# Thank the user for installing
print_section "Installation Complete"
print_success "HyprGraphite has been installed on your system!"
echo -e "${BRIGHT_WHITE}You can now log out and select Hyprland at your login screen to start using HyprGraphite.${RESET}"
echo

# Show available scripts
show_available_scripts

exit 0 