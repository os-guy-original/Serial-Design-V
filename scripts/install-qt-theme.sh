#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                  QT Theme Installation                    │
# │            Flatpak QT/KDE Theme Configuration             │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Function to print generic help message
print_generic_help() {
    local script_name="$1"
    local description="$2"
    
    echo -e "${BRIGHT_CYAN}${BOLD}╭────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                                        ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}                 Serial Design V Help                 ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}          $description          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                                        ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰────────────────────────────────────────────────────────────╯${RESET}"
}

# Process command line arguments 
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure QT themes for Flatpak"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script configures QT/KDE themes for Flatpak applications"
    echo -e "    by installing Kvantum and QGnomePlatform runtimes."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE${RESET}"
    echo -e "    $(basename "$0")"
    echo
    exit 0
fi

#==================================================================
# Welcome Message
#==================================================================

# Clear the screen
clear
print_banner "QT Theme Installation" "Flatpak QT/KDE Theme Configuration"

#==================================================================
# QT Theme Installation
#==================================================================
print_section "QT Theme Installation"

print_warning "!! IT MAY NOT WORK !!"

# Use center_text for better formatting
echo -e "${BRIGHT_WHITE}$(center_text "The QT/KDE Theme is handled by Kvantum. We'll just copy the Kvantum theme, copy the qt5ct and qt6ct configs, done!")${RESET}"
echo -e "${BRIGHT_WHITE}$(center_text "So, this script will only activate the QT/KDE theme for flatpak apps.")${RESET}"
echo

# Check if flatpak is installed
if ! command -v flatpak &>/dev/null; then
    print_error "Flatpak is not installed. Please install Flatpak first."
    exit 1
fi

# Install Kvantum runtime for Flatpak
print_status "Installing Kvantum runtime for Flatpak..."
if flatpak install -y flathub runtime/org.kde.KStyle.Kvantum/x86_64/6.6 runtime/org.kde.KStyle.Kvantum/x86_64/5.15-23.08; then
    print_success "Kvantum runtime installed successfully!"
else
    print_error "Failed to install Kvantum runtime."
fi

# Install QGnomePlatform runtime for Flatpak
print_status "Installing QGnomePlatform runtime for Flatpak..."
if flatpak install -y runtime/org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-23.08 runtime/org.kde.PlatformTheme.QGnomePlatform/x86_64/6.6; then
    print_success "QGnomePlatform runtime installed successfully!"
else
    print_error "Failed to install QGnomePlatform runtime."
fi

# Configure Flatpak to use Kvantum and qt5ct
print_status "Configuring Flatpak to use Kvantum and qt5ct..."
if sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum --env=QT_QPA_PLATFORMTHEME=qt5ct --filesystem=xdg-config/Kvantum:ro --filesystem=~/.config/qt5ct --filesystem=~/.config/qt6ct; then
    print_success "Flatpak QT theme configuration completed successfully!"
else
    print_error "Failed to configure Flatpak QT theme."
fi

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

# Print final success message
echo
print_success_banner "QT theme for Flatpak has been successfully configured!"
print_info "The theme will be applied to Flatpak QT applications." 