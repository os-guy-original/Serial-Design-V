#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               Fedora Installation                      │
# │                  Package Manager Setup                  │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}│${RESET} ${BOLD}${BRIGHT_YELLOW}HyprGraphite - Fedora Installation${RESET} ${BRIGHT_CYAN}│${RESET}"
echo -e "${BRIGHT_CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
echo

# 1. RPM Fusion Setup
print_section "RPM Fusion Setup"
print_status "Adding RPM Fusion free and non-free repositories..."

dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update system
print_status "Updating system..."
dnf update -y

# 2. Flatpak Setup
print_section "Flatpak Setup"
print_status "Installing Flatpak and Flathub repository..."

dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# 3. Core Dependencies
print_section "Installing Core Dependencies"
print_status "Installing Hyprland and its dependencies..."

dnf install -y \
    hyprland \
    waybar \
    rofi \
    kitty \
    swaybg \
    swaylock \
    wofi \
    wl-clipboard \
    grim \
    slurp \
    mako \
    polkit-gnome \
    gtk3 \
    qt5-qtwayland \
    qt6-qtwayland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    xdg-user-dirs \
    xdg-utils

# 4. File Manager Setup
print_section "File Manager Setup"
print_status "Installing file manager packages..."

dnf install -y \
    nautilus \
    nemo \
    thunar \
    gvfs \
    gvfs-mtp \
    tumbler

# Ask user if they want to install Nautilus scripts
if ask_yes_no "Would you like to install Nautilus scripts (right-click menu extensions)?" "y"; then
    print_status "Installing Nautilus scripts..."
    git clone https://github.com/cfgnunes/nautilus-scripts.git /tmp/nautilus-scripts
    cd /tmp/nautilus-scripts && chmod +x install.sh && ./install.sh
    rm -rf /tmp/nautilus-scripts
    print_success "Nautilus scripts installed successfully."
else
    print_status "Skipping Nautilus scripts installation."
fi

# 5. Browser Setup
print_section "Browser Setup"

if ask_yes_no "Would you like to install web browsers?" "y"; then
    # Ask for package manager choice
    echo -e "${BRIGHT_WHITE}${BOLD}Choose package manager for browser installation:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} DNF Packages (System packages)"
    echo -e "  ${BRIGHT_WHITE}2.${RESET} Flatpak packages"
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice (1 or 2): ${RESET}"
    read -r pkg_manager_choice
    
    case "$pkg_manager_choice" in
        1)
            # List available browsers
            echo -e "\n${BRIGHT_WHITE}${BOLD}Available Browsers:${RESET}"
            echo -e "  ${BRIGHT_WHITE}1.${RESET} Zen Browser - A privacy-focused browser"
            echo -e "  ${BRIGHT_WHITE}2.${RESET} Firefox - Popular open-source browser"
            echo -e "  ${BRIGHT_WHITE}3.${RESET} Google Chrome - Google's web browser"
            echo -e "  ${BRIGHT_WHITE}4.${RESET} UnGoogled Chromium - Chromium without Google integration"
            echo -e "  ${BRIGHT_WHITE}5.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
            
            echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser number (e.g., 1): ${RESET}"
            read -r browser_choice
            
            case "$browser_choice" in
                1)
                    print_status "Installing Zen Browser..."
                    # Add COPR repository for Zen Browser
                    dnf copr enable sneexy/zen-browser -y
                    dnf install -y zen-browser
                    ;;
                2)
                    print_status "Installing Firefox..."
                    dnf install -y firefox
                    ;;
                3)
                    print_status "Installing Google Chrome..."
                    # Install required repositories
                    dnf install -y fedora-workstation-repositories
                    # Enable Google Chrome repo
                    dnf config-manager --set-enabled google-chrome
                    # Install Chrome
                    dnf install -y google-chrome-stable
                    ;;
                4)
                    print_status "Installing UnGoogled Chromium..."
                    # Add COPR repository for UnGoogled Chromium
                    dnf copr enable wojnilowicz/ungoogled-chromium -y
                    dnf install -y ungoogled-chromium
                    ;;
                5)
                    print_status "Installing Epiphany..."
                    dnf install -y epiphany
                    ;;
                *)
                    print_warning "Invalid selection. Skipping browser installation."
                    ;;
            esac
            ;;
        2)
            # List available Flatpak browsers
            echo -e "\n${BRIGHT_WHITE}${BOLD}Available Flatpak Browsers:${RESET}"
            echo -e "  ${BRIGHT_WHITE}1.${RESET} Zen Browser - A privacy-focused browser"
            echo -e "  ${BRIGHT_WHITE}2.${RESET} Firefox - Popular open-source browser"
            echo -e "  ${BRIGHT_WHITE}3.${RESET} Google Chrome - Google's web browser"
            echo -e "  ${BRIGHT_WHITE}4.${RESET} UnGoogled Chromium - Chromium without Google integration"
            echo -e "  ${BRIGHT_WHITE}5.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
            
            echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser number (e.g., 1): ${RESET}"
            read -r browser_choice
            
            case "$browser_choice" in
                1)
                    print_status "Installing Zen Browser..."
                    flatpak install -y flathub app.zen_browser.zen
                    ;;
                2)
                    print_status "Installing Firefox..."
                    flatpak install -y flathub org.mozilla.firefox
                    ;;
                3)
                    print_status "Installing Google Chrome..."
                    flatpak install -y flathub com.google.Chrome
                    ;;
                4)
                    print_status "Installing UnGoogled Chromium..."
                    flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium
                    ;;
                5)
                    print_status "Installing Epiphany..."
                    flatpak install -y flathub org.gnome.Epiphany
                    ;;
                *)
                    print_warning "Invalid selection. Skipping browser installation."
                    ;;
            esac
            ;;
        *)
            print_warning "Invalid choice. Skipping browser installation."
            ;;
    esac
else
    print_status "Skipping browser installation."
fi

# 6. Theme Setup
setup_theme

# 7. Configuration Setup
setup_configuration

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Enjoy your new desktop environment!"
echo

exit 0 