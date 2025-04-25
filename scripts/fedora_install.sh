#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Modern Hyprland Setup                   │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    print_warning "Please run without sudo. The script will ask for privileges when needed."
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

# 1. Core Dependencies (Bağımlılıklar / Gereklilikler)
print_section "Installing Core Dependencies"

# Enable RPM Fusion repositories
if ! grep -q "rpmfusion-free" "/etc/yum.repos.d/"*; then
    print_status "Enabling RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
else
    print_success "RPM Fusion repositories are already enabled."
fi

# Add COPR repositories for Hyprland and dependencies
print_status "Adding COPR repositories for Hyprland..."
sudo dnf copr enable -y solopasha/hyprland

# Update system
print_status "Updating system packages. This may take a while..."
sudo dnf update -y

# Install Hyprland
print_status "Installing Hyprland and its dependencies..."
sudo dnf install -y \
    hyprland \
    waybar \
    kitty \
    rofi-wayland \
    swaylock \
    swww \
    fish \
    grim \
    slurp \
    mako \
    nwg-look \
    polkit-gnome \
    gtk3 \
    brightnessctl \
    qt5ct \
    qt6ct \
    kvantum \
    qt5-qtwayland \
    qt6-qtwayland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    xdg-user-dirs \
    xdg-utils \
    wl-clipboard \
    swayosd \
    power-profiles-daemon

# 2. Flatpak Setup
print_section "Flatpak Setup"
if ! command_exists flatpak; then
    print_status "Installing Flatpak..."
    sudo dnf install -y flatpak
    
    # Add Flathub repository
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Enable Flatpak system integration
    print_status "Enabling Flatpak system integration..."
    systemctl --user enable --now flatpak-session-helper.service
else
    print_success "Flatpak is already installed."
fi

# 3. File Manager Setup (Paket kurulumu)
print_section "File Manager Setup"
print_status "Installing file manager packages..."

sudo dnf install -y \
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

# 4. Browser Setup
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
            echo -e "  ${BRIGHT_WHITE}1.${RESET} Firefox - Popular open-source browser"
            echo -e "  ${BRIGHT_WHITE}2.${RESET} Google Chrome - Google's web browser"
            echo -e "  ${BRIGHT_WHITE}3.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
            echo -e "  ${BRIGHT_WHITE}4.${RESET} LibreWolf - Privacy-focused Firefox fork"
            echo -e "  ${BRIGHT_WHITE}5.${RESET} Zen Browser - A privacy-focused browser"
            
            echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser number (e.g., 1): ${RESET}"
            read -r browser_choice
            
            case "$browser_choice" in
                1)
                    print_status "Installing Firefox..."
                    sudo dnf install -y firefox
                    ;;
                2)
                    print_status "Installing Google Chrome..."
                    # Download and install Google Chrome
                    print_status "Downloading Google Chrome..."
                    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O /tmp/chrome.rpm
                    sudo dnf install -y /tmp/chrome.rpm
                    rm -f /tmp/chrome.rpm
                    ;;
                3)
                    print_status "Installing Epiphany..."
                    sudo dnf install -y epiphany
                    ;;
                4)
                    print_status "Installing LibreWolf..."
                    print_status "Adding LibreWolf repository..."
                    curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo tee /etc/yum.repos.d/librewolf.repo
                    sudo dnf install -y librewolf
                    ;;
                5)
                    print_status "Installing Zen Browser..."
                    print_status "Adding Zen Browser repository..."
                    sudo dnf copr enable -y sneexy/zen-browser
                    sudo dnf install -y zen-browser
                    ;;
                *)
                    print_warning "Invalid selection. Skipping browser installation."
                    ;;
            esac
            ;;
        2)
            # List available Flatpak browsers
            echo -e "\n${BRIGHT_WHITE}${BOLD}Available Flatpak Browsers:${RESET}"
            echo -e "  ${BRIGHT_WHITE}1.${RESET} Firefox - Popular open-source browser"
            echo -e "  ${BRIGHT_WHITE}2.${RESET} Google Chrome - Google's web browser"
            echo -e "  ${BRIGHT_WHITE}3.${RESET} Chromium - Open-source browser project"
            echo -e "  ${BRIGHT_WHITE}4.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
            echo -e "  ${BRIGHT_WHITE}5.${RESET} LibreWolf - Privacy-focused Firefox fork"
            echo -e "  ${BRIGHT_WHITE}6.${RESET} Zen Browser - A privacy-focused browser"
            
            echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser number (e.g., 1): ${RESET}"
            read -r browser_choice
            
            case "$browser_choice" in
                1)
                    print_status "Installing Firefox..."
                    flatpak install -y flathub org.mozilla.firefox
                    ;;
                2)
                    print_status "Installing Google Chrome..."
                    flatpak install -y flathub com.google.Chrome
                    ;;
                3)
                    print_status "Installing Chromium..."
                    flatpak install -y flathub org.chromium.Chromium
                    ;;
                4)
                    print_status "Installing Epiphany..."
                    flatpak install -y flathub org.gnome.Epiphany
                    ;;
                5)
                    print_status "Installing LibreWolf..."
                    flatpak install -y flathub io.gitlab.librewolf-community
                    ;;
                6)
                    print_status "Installing Zen Browser..."
                    flatpak install -y flathub app.zen_browser.zen
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

# 5. Theme Setup (Tema Kurulumu)
print_section "Theme Setup"

# Check for GTK theme
if check_gtk_theme_installed "Graphite-Dark"; then
    print_success "GTK Theme 'Graphite-Dark' is installed."
else
    print_warning "GTK Theme 'Graphite-Dark' is not installed."
    if ask_yes_no "Would you like to install the GTK theme?" "y"; then
        install_gtk_theme
    else
        print_status "Skipping GTK theme installation."
    fi
fi

# Check for QT theme
if check_qt_theme_installed "Graphite-rimlessDark"; then
    print_success "QT Theme 'Graphite-rimlessDark' is installed."
else
    print_warning "QT Theme 'Graphite-rimlessDark' is not installed."
    if ask_yes_no "Would you like to install the QT theme?" "y"; then
        install_qt_theme
    else
        print_status "Skipping QT theme installation."
    fi
fi

# Check for cursor theme
if check_cursor_theme_installed "Bibata-Modern-Classic"; then
    print_success "Cursor Theme 'Bibata-Modern-Classic' is installed."
else
    print_warning "Cursor Theme 'Bibata-Modern-Classic' is not installed."
    if ask_yes_no "Would you like to install the cursor theme?" "y"; then
        install_cursor_theme
    else
        print_status "Skipping cursor theme installation."
    fi
fi

# Check for icon theme
if check_icon_theme_installed "Fluent"; then
    print_success "Fluent icon theme is installed."
else
    print_warning "Fluent icon theme is not installed."
    print_status "Installing Fluent icon theme..."
    
    # Create temporary directory and clone the repo
    print_status "Cloning Fluent icon theme repository..."
    cd /tmp || {
        print_error "Failed to change to /tmp directory"
    }
    
    # Remove any existing directory
    rm -rf /tmp/fluent-icon-theme 2>/dev/null
    
    # Clone the repository
    if ! git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icon-theme; then
        print_error "Failed to clone Fluent icon theme repository."
        print_warning "You will need to install the icon theme manually later."
    else
        # Make the install script executable
        chmod +x /tmp/fluent-icon-theme/install.sh
        
        # Install the icon theme (grey variant)
        print_status "Installing Fluent icon theme (grey variant)..."
        cd /tmp/fluent-icon-theme || {
            print_error "Failed to change directory to /tmp/fluent-icon-theme"
        }
        
        # Run the installer with grey variant
        ./install.sh -g
        
        # Check if installation was successful
        if [ $? -eq 0 ]; then
            print_success "Fluent icon theme installed successfully!"
        else
            print_error "Failed to install Fluent icon theme."
        fi
        
        # Clean up
        cd - > /dev/null || true
        rm -rf /tmp/fluent-icon-theme
    fi
fi

# 6. Configuration Setup (Kopyalama vb. ve Varsayılan klasör seçimi)
print_section "Configuration Setup"
setup_configuration

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}You can use nwg-look tool to customize your default theme settings"
echo -e "${BRIGHT_WHITE}  4. ${RESET}Configure Qt applications with ${BRIGHT_CYAN}'qt5ct'${RESET} and ${BRIGHT_CYAN}'kvantummanager'${RESET}"
echo -e "${BRIGHT_WHITE}  5. ${RESET}Enjoy your new desktop environment!"
echo

exit 0 
