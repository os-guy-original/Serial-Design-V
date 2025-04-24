#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Modern Hyprland Setup                   │
# ╰──────────────────────────────────────────────────────────╯

# Helper function to install AUR helpers
install_aur_helper() {
    local helper_name="$1"
    print_status "Installing $helper_name from AUR..."
    
    # Create a temporary directory for building
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || {
        print_error "Failed to create temporary directory"
        return 1
    }
    
    # Clone the AUR package
    if ! git clone "https://aur.archlinux.org/${helper_name}.git"; then
        print_error "Failed to clone ${helper_name} repository"
        return 1
    fi
    
    # Enter the directory and build
    cd "${helper_name}" || {
        print_error "Failed to enter ${helper_name} directory"
        return 1
    }
    
    # Build and install
    if ! makepkg -si --noconfirm; then
        print_error "Failed to build and install ${helper_name}"
        return 1
    fi
    
    # Clean up
    cd / || true
    rm -rf "$tmp_dir"
    
    print_success "${helper_name} installed successfully"
    return 0
}

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
echo -e "${BRIGHT_CYAN}│${RESET} ${BOLD}${BRIGHT_YELLOW}HyprGraphite - Arch Installation${RESET} ${BRIGHT_CYAN}│${RESET}"
echo -e "${BRIGHT_CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
echo

# 1. AUR Helper Setup
print_section "AUR Helper Setup"
print_status "Checking for AUR helpers..."

# Detect available AUR helpers
AUR_HELPERS=()
if command_exists yay; then
    AUR_HELPERS+=("yay")
fi
if command_exists paru; then
    AUR_HELPERS+=("paru")
fi

# Set default AUR helper
export AUR_HELPER=""

# Choose AUR Helper
if [ ${#AUR_HELPERS[@]} -gt 0 ]; then
    # Display detected AUR helpers
    echo -e "\n${BRIGHT_PURPLE}${BOLD}AUR Helpers Detected:${RESET}"
    for helper in "${AUR_HELPERS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} ${helper}"
    done
    
    # If we have multiple helpers, let the user choose
    if [ ${#AUR_HELPERS[@]} -gt 1 ]; then
        # Add the options for the user to choose
        options=("${AUR_HELPERS[@]}" "pacman (no AUR support)")
        
        AUR_HELPER=$(ask_choice "Choose your preferred AUR helper:" "${options[@]}")
        
        if [[ "$AUR_HELPER" == "pacman (no AUR support)" ]]; then
            AUR_HELPER="pacman"
        fi
    else
        # Only one helper detected, use it
        AUR_HELPER="${AUR_HELPERS[0]}"
        print_success "Detected and using ${AUR_HELPER} as the AUR helper."
    fi
else
    # No AUR helper detected, install one
    print_warning "No AUR helper detected. Installing yay..."
    
    if install_aur_helper "yay"; then
        AUR_HELPER="yay"
    else
        print_warning "Falling back to pacman (no AUR support)"
        AUR_HELPER="pacman"
    fi
fi

# Export AUR_HELPER for use in common_functions.sh
export AUR_HELPER

# 2. Chaotic-AUR Setup
print_section "Chaotic-AUR Setup"
if ask_yes_no "Would you like to set up Chaotic-AUR? (Recommended for pre-built AUR packages)" "y"; then
    if [ -f "./scripts/install-chaotic-aur.sh" ] && [ -x "./scripts/install-chaotic-aur.sh" ]; then
        sudo ./scripts/install-chaotic-aur.sh
    else
        print_status "Making Chaotic-AUR installer executable..."
        chmod +x ./scripts/install-chaotic-aur.sh
        sudo ./scripts/install-chaotic-aur.sh
    fi
else
    print_status "Skipping Chaotic-AUR setup."
fi

# 3. Flatpak Setup
print_section "Flatpak Setup"
if ! command_exists flatpak; then
    print_status "Installing Flatpak..."
    install_packages flatpak
    
    # Add Flathub repository
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Enable Flatpak system integration
    print_status "Enabling Flatpak system integration..."
    systemctl --user enable --now flatpak-session-helper.service
else
    print_success "Flatpak is already installed."
fi

# 4. Core Dependencies
print_section "Installing Core Dependencies"
print_status "Installing Hyprland and its dependencies..."

# Define Hyprland packages in correct order
hyprland_packages=(
    "hyprutils"
    "hyprlang"
    "hyprcursor"
    "hyprgraphics"
    "hyprwayland-scanner"
    "hyprland"
)

for pkg in "${hyprland_packages[@]}"; do
    print_status "Installing $pkg..."
    install_packages "$pkg"
done

# Install additional dependencies
print_status "Installing additional dependencies..."
install_packages \
    waybar-cava \
    nwg-look \
    fisher \
    swayosd \
    power-profiles-daemon \
    libcava \
    swww \
    rofi-wayland \
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
    brigtnessctl \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    xdg-user-dirs \
    xdg-utils

# 5. Browser Setup
print_section "Browser Setup"

if ask_yes_no "Would you like to install web browsers?" "y"; then
    # Ask for package manager choice
    echo -e "${BRIGHT_WHITE}${BOLD}Choose package manager for browser installation:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} Pacman Packages (System packages)"
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
                    $AUR_HELPER -S --noconfirm zen-browser
                    ;;
                2)
                    print_status "Installing Firefox..."
                    sudo pacman -S --noconfirm firefox
                    ;;
                3)
                    print_status "Installing Google Chrome..."
                    $AUR_HELPER -S --noconfirm google-chrome
                    ;;
                4)
                    print_status "Installing UnGoogled Chromium..."
                    $AUR_HELPER -S --noconfirm ungoogled-chromium
                    ;;
                5)
                    print_status "Installing Epiphany..."
                    sudo pacman -S --noconfirm epiphany
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

# 4. File Manager Setup
print_section "File Manager Setup"
print_status "Installing file manager packages..."

install_packages \
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
echo -e "${BRIGHT_WHITE}  3. ${RESET}You can use nwg-look tool to customize your default theme settings"

echo -e "${BRIGHT_WHITE}  4. ${RESET}Enjoy your new desktop environment!"
echo

exit 0 
