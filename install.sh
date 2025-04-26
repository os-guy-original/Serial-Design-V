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

# Print important notice about supported systems
print_section "System Requirements"
echo -e "${BRIGHT_RED}${BOLD}⚠️ IMPORTANT: ${RESET}${RED}This script is designed for Arch-based systems only.${RESET}"
echo -e "${RED}Other distributions are not supported due to package management issues.${RESET}"
echo

# Detect the distro
print_section "System Detection"
print_status "Detecting your operating system..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
    OS_LIKE=$ID_LIKE
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

# Function to check if system is Arch-based
is_arch_based() {
    # Primary check: If pacman or yay exists and works, it's probably Arch
    if command -v pacman >/dev/null 2>&1; then
        # Check if pacman can be used to query packages
        if pacman -Qi base >/dev/null 2>&1 || pacman -Qi filesystem >/dev/null 2>&1; then
            return 0
        fi
    fi

    # Check for yay (popular AUR helper)
    if command -v yay >/dev/null 2>&1; then
        return 0
    fi
    
    # Fallback to ID check for specific distributions
    if [[ "$OS" == "arch" || "$OS" == "endeavouros" || "$OS" == "manjaro" || "$OS" == "garuda" || "$OS" == "artix" || "$OS" == "archman" || "$OS" == "arcolinux" ]]; then
        return 0
    fi
    
    # Last resort: Check ID_LIKE for "arch" as substring
    [[ -n "$OS_LIKE" && "$OS_LIKE" == *"arch"* ]] && return 0
    
    return 1
}

# Ask user if they want to use the OS-specific installer
if is_arch_based; then
    print_success "Arch-based system detected! ${GREEN}${BOLD}✓${RESET}"
    print_status "Detected distribution: $OS"
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
else
    print_error "This script is designed for Arch-based systems only."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}HyprGraphite is designed exclusively for Arch Linux and its derivatives."
    echo -e "${BRIGHT_WHITE}${BOLD}ℹ ${RESET}Support for other distributions has been removed due to package management complexity."
    
    if ask_yes_no "Do you want to force continue anyway? (Not recommended)" "n"; then
        print_warning "Continuing with installation despite unsupported system..."
    else
        echo
        echo -e "${BRIGHT_PURPLE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_GREEN}Thanks for your interest in HyprGraphite!${RESET}        ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_CYAN}https://github.com/os-guy/HyprGraphite${RESET}           ${BRIGHT_PURPLE}${BOLD}║${RESET}"
        echo -e "${BRIGHT_PURPLE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
        exit 1
    fi
fi

# If user chose not to use OS-specific installer, continue with generic installation
print_status "Continuing with generic installation process..."

# Offer Flatpak installation first
print_warning "Installing Flatpak first is recommended since theme installers will also set Flatpak themes!"
offer_flatpak_install

# 6. Theme Setup
print_section "Theme Setup"
print_status "Checking installed themes..."

# Set up themes directory path
THEME_SCRIPT_DIR="$(dirname "$0")/scripts"

# Always offer GTK theme installation
print_status "GTK Theme Installation"
if check_gtk_theme_installed; then
    print_success "GTK theme 'Graphite-Dark' is already installed."
    if ask_yes_no "Would you like to reinstall the GTK theme anyway?" "n"; then
        "$THEME_SCRIPT_DIR/install-gtk-theme.sh"
    else
        print_status "Skipping GTK theme installation."
    fi
else
    print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    if ask_yes_no "Would you like to install the Graphite GTK theme now?" "y"; then
        "$THEME_SCRIPT_DIR/install-gtk-theme.sh"
    else
        print_status "Skipping GTK theme installation."
    fi
fi

# Always offer QT theme installation
print_status "QT Theme Installation"
if check_qt_theme_installed; then
    print_success "QT theme 'Graphite-rimlessDark' is already installed."
    if ask_yes_no "Would you like to reinstall the QT theme anyway?" "n"; then
        "$THEME_SCRIPT_DIR/install-qt-theme.sh"
    else
        print_status "Skipping QT theme installation."
    fi
else
    print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
    if ask_yes_no "Would you like to install the Graphite QT theme now?" "y"; then
        "$THEME_SCRIPT_DIR/install-qt-theme.sh"
    else
        print_status "Skipping QT theme installation."
    fi
fi

# Always offer cursor theme installation
print_status "Cursor Theme Installation"
if check_cursor_theme_installed; then
    print_success "Cursor theme 'Bibata-Modern-Classic' is already installed."
    if ask_yes_no "Would you like to reinstall the cursor theme anyway?" "n"; then
        "$THEME_SCRIPT_DIR/install-cursors.sh"
    else
        print_status "Skipping cursor theme installation."
    fi
else
    print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
    if ask_yes_no "Would you like to install the Bibata cursors now?" "y"; then
        "$THEME_SCRIPT_DIR/install-cursors.sh"
    else
        print_status "Skipping cursor installation."
    fi
fi

# Always offer icon theme installation
print_status "Icon Theme Installation"
if check_icon_theme_installed; then
    print_success "Fluent icon theme already installed."
    if ask_yes_no "Would you like to reinstall the icon theme anyway?" "n"; then
        "$THEME_SCRIPT_DIR/install-icon-theme.sh" "fluent" "Fluent-grey"
    else
        print_status "Skipping icon theme installation."
    fi
else
    print_warning "Icon theme is not installed. Your system will use the default icon theme."
    if ask_yes_no "Would you like to install the Fluent icon theme now?" "y"; then
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