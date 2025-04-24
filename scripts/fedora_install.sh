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

# Add RPMSphere repository for xcur2png
print_status "Adding RPMSphere repository for additional packages..."
dnf install -y https://github.com/negativo17/rpmsphere-release/blob/main/rpmsphere-release-$(rpm -E %fedora)-1.noarch.rpm?raw=true

# Add Fisher COPR repository
print_status "Adding COPR repository for Fisher (fish shell package manager)..."
dnf copr enable -y bdperkin/fisher

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
    power-profiles-daemon \
    cava \
    swww \
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
    brightnessctl \
    gtk3 \
    qt5-qtwayland \
    qt6-qtwayland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    xdg-user-dirs \
    xdg-utils

# 4. Install Fisher (fish shell package manager)
print_section "Fisher Setup"
print_status "Installing Fisher package manager for fish shell..."
dnf install -y fisher fish

# 5. Install nwg-look (GTK settings editor for Wayland)
print_section "nwg-look Setup"
print_status "Installing dependencies for nwg-look..."
dnf install -y golang gtk3 gtk3-devel xcur2png git

print_status "Building and installing nwg-look from source..."
TMP_DIR="/tmp/nwg-look"
rm -rf "$TMP_DIR" 2>/dev/null
mkdir -p "$TMP_DIR"

# Clone the repository
if ! git clone --depth=1 https://github.com/nwg-piotr/nwg-look.git "$TMP_DIR"; then
    print_error "Failed to clone nwg-look repository. Please check your internet connection."
else
    # Build and install
    cd "$TMP_DIR" || {
        print_error "Failed to change directory to $TMP_DIR"
    }
    
    if make; then
        if make install; then
            print_success "Successfully installed nwg-look"
        else
            print_error "Failed to install nwg-look"
        fi
    else
        print_error "Failed to build nwg-look"
    fi
    
    # Clean up
    cd - > /dev/null || true
    rm -rf "$TMP_DIR"
fi

# 6. Install SwayOSD (On-screen display for volume, brightness, etc.)
print_section "SwayOSD Setup"
print_status "SwayOSD is not available in the main Fedora repositories, installing from source..."

# Check if our installation script exists and is executable
if [ -f "./scripts/install-swayosd.sh" ] && [ -x "./scripts/install-swayosd.sh" ]; then
    ./scripts/install-swayosd.sh
else
    print_status "Making SwayOSD installer executable..."
    chmod +x ./scripts/install-swayosd.sh
    ./scripts/install-swayosd.sh
fi

# 7. File Manager Setup
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

# 8. Browser Setup
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

# 9. Theme Setup
setup_theme

# 10. Configuration Setup
setup_configuration

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Use ${BRIGHT_CYAN}'nwg-look'${RESET} to configure GTK themes in Wayland"
echo -e "${BRIGHT_WHITE}  4. ${RESET}Enjoy your new desktop environment!"
echo

exit 0 
