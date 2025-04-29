#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │                 HyprGraphite Installer                   │
# │         A Modern Hyprland Desktop Environment            │
# ╰──────────────────────────────────────────────────────────╯

#==================================================================
# Helper Functions
#==================================================================

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

# Function to handle package conflicts and network issues
handle_package_installation() {
    local packages=("$@")
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        print_status "Attempting to install packages (attempt $((retry_count+1)) of $max_retries)..."
        
        if ! install_packages "${packages[@]}"; then
            retry_count=$((retry_count+1))
            
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Installation failed. This could be due to network issues or package conflicts."
                print_status "Checking network connectivity..."
                
                # Check network connectivity
                if ! ping -c 1 archlinux.org &>/dev/null; then
                    print_error "Network connectivity issue detected."
                    if ask_yes_no "Would you like to retry after waiting for network?" "y"; then
                        print_status "Waiting for 10 seconds before retrying..."
                        sleep 10
                        continue
                    fi
                else
                    print_status "Network seems to be working."
                    # Check for package conflicts
                    if ask_yes_no "Would you like to try installing packages one by one to identify conflicts?" "y"; then
                        print_status "Installing packages individually..."
                        local failed_packages=()
                        for pkg in "${packages[@]}"; do
                            print_status "Installing $pkg..."
                            if ! install_packages "$pkg"; then
                                print_warning "Failed to install $pkg. Skipping."
                                failed_packages+=("$pkg")
                            else
                                print_success "Successfully installed $pkg."
                            fi
                        done
                        
                        if [ ${#failed_packages[@]} -eq 0 ]; then
                            print_success "All packages were installed successfully!"
                            return 0
                        else
                            print_warning "Some packages could not be installed:"
                            for pkg in "${failed_packages[@]}"; do
                                echo "  - $pkg"
                            done
                            
                            if ask_yes_no "Continue with installation (skipping failed packages)?" "y"; then
                                print_warning "Continuing installation without failed packages."
                                return 0
                            else
                                print_error "Installation aborted by user."
                                return 1
                            fi
                        fi
                    else
                        # Try again with the whole group
                        print_status "Retrying complete package group..."
                        continue
                    fi
                fi
            else
                print_error "Failed to install packages after $max_retries attempts."
                if ! ask_yes_no "Continue with installation (some features may not work)?" "y"; then
                    print_error "Installation aborted by user."
                    return 1
                fi
                return 0
            fi
        else
            print_success "Packages installed successfully!"
            return 0
        fi
    done
    
    return 1
}

#==================================================================
# Pre-Installation Checks
#==================================================================

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    print_warning "Please run without sudo. The script will ask for privileges when needed."
    exit 1
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
print_banner "HyprGraphite - Arch Linux Installation" "A modern and feature-rich Hyprland desktop environment"

#==================================================================
# 1. AUR Helper Setup
#==================================================================
print_section "1. AUR Helper Setup"
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
    print_warning "No AUR helper detected."
    
    # Ask which AUR helper to install
    echo -e "\n${BRIGHT_WHITE}${BOLD}Available AUR Helpers:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} yay   - Yet Another Yogurt - AUR Helper in Go"
    echo -e "  ${BRIGHT_WHITE}2.${RESET} paru  - AUR helper written in Rust"
    echo -e "  ${BRIGHT_WHITE}3.${RESET} trizen - Lightweight AUR helper"
    echo -e "  ${BRIGHT_WHITE}4.${RESET} pikaur - AUR helper with minimal dependencies"
    echo -e "  ${BRIGHT_WHITE}5.${RESET} None  - Use pacman only (no AUR support)"
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select AUR helper to install [1-5] (default: 1): ${RESET}"
    read -r aur_choice
    
    # Default to yay if no input
    if [ -z "$aur_choice" ]; then
        aur_choice=1
    fi
    
    case "$aur_choice" in
        1)
            if install_aur_helper "yay"; then
                AUR_HELPER="yay"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        2)
            if install_aur_helper "paru"; then
                AUR_HELPER="paru"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        3)
            if install_aur_helper "trizen"; then
                AUR_HELPER="trizen"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        4)
            if install_aur_helper "pikaur"; then
                AUR_HELPER="pikaur"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        5|*)
            print_status "Skipping AUR helper installation."
            AUR_HELPER="pacman"
            ;;
    esac
fi

# Export AUR_HELPER for use in common_functions.sh
export AUR_HELPER

#==================================================================
# 2. Chaotic-AUR Setup
#==================================================================
print_section "2. Chaotic-AUR Setup"
print_info "Chaotic-AUR provides pre-built AUR packages, saving compile time"

if ask_yes_no "Would you like to set up Chaotic-AUR? (Recommended)" "y"; then
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

#==================================================================
# 3. Flatpak Setup
#==================================================================
print_section "3. Flatpak Setup"
print_info "Flatpak provides sandboxed applications with dependencies included"

if ask_yes_no "Would you like to install Flatpak?" "y"; then
    if [ -f "./scripts/install-flatpak.sh" ] && [ -x "./scripts/install-flatpak.sh" ]; then
        sudo ./scripts/install-flatpak.sh
    else
        print_status "Making Flatpak installer executable..."
        chmod +x ./scripts/install-flatpak.sh
        sudo ./scripts/install-flatpak.sh
    fi
else
    print_status "Skipping Flatpak setup."
fi

#==================================================================
# 4. File Manager Setup
#==================================================================
print_section "4. File Manager Setup"
print_status "Setting up file manager..."

# List available file managers with descriptions
echo -e "\n${BRIGHT_WHITE}${BOLD}Available File Managers:${RESET}"
echo -e "  ${BRIGHT_WHITE}1.${RESET} Nautilus  - GNOME's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}2.${RESET} Nemo      - Cinnamon's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}3.${RESET} Thunar    - Xfce's file manager (GTK, lightweight)"
echo -e "  ${BRIGHT_WHITE}4.${RESET} PCManFM   - LXDE's file manager (GTK, very lightweight)"
echo -e "  ${BRIGHT_WHITE}5.${RESET} Dolphin   - KDE's file manager (Qt, feature-rich)"
echo -e "  ${BRIGHT_WHITE}6.${RESET} Caja      - MATE's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}7.${RESET} Krusader  - Twin-panel file manager (Qt, advanced features)"
echo -e "  ${BRIGHT_WHITE}8.${RESET} Thunar + PCManFM (lightweight options)"
echo -e "  ${BRIGHT_WHITE}9.${RESET} Nautilus + Nemo (feature-rich options)"
echo -e "  ${BRIGHT_WHITE}10.${RESET} All GUI file managers"
echo -e "  ${BRIGHT_WHITE}0.${RESET} None - Skip file manager installation"

echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select file manager(s) to install [0-10] (default: 3): ${RESET}"
read -r fm_choice

# Default to Thunar if no input
if [ -z "$fm_choice" ]; then
    fm_choice=3
fi

# Always install these common dependencies for file managers
print_status "Installing file manager dependencies..."
install_packages \
    gvfs \
    gvfs-mtp \
    tumbler

# Install selected file manager(s)
case "$fm_choice" in
    0)
        print_status "Skipping file manager installation."
        ;;
    1)
        print_status "Installing Nautilus..."
        install_packages nautilus
        ;;
    2)
        print_status "Installing Nemo..."
        install_packages nemo nemo-fileroller
        ;;
    3)
        print_status "Installing Thunar..."
        install_packages thunar thunar-archive-plugin thunar-media-tags-plugin
        ;;
    4)
        print_status "Installing PCManFM..."
        install_packages pcmanfm
        ;;
    5)
        print_status "Installing Dolphin..."
        install_packages dolphin dolphin-plugins kde-cli-tools
        ;;
    6)
        print_status "Installing Caja..."
        install_packages caja caja-audio-video-properties caja-extensions-common caja-image-converter caja-open-terminal caja-sendto caja-share caja-wallpaper caja-xattr-tags
        ;;
    7)
        print_status "Installing Krusader..."
        install_packages krusader krename
        ;;
    8)
        print_status "Installing Thunar and PCManFM..."
        install_packages thunar thunar-archive-plugin pcmanfm
        ;;
    9)
        print_status "Installing Nautilus and Nemo..."
        install_packages nautilus nemo nemo-fileroller
        ;;
    10)
        print_status "Installing all GUI file managers..."
        install_packages \
            nautilus \
            nemo \
            nemo-fileroller \
            thunar \
            thunar-archive-plugin \
            thunar-media-tags-plugin \
            pcmanfm \
            dolphin \
            caja \
            caja-audio-video-properties \
            caja-extensions-common \
            caja-image-converter \
            caja-open-terminal \
            caja-sendto \
            caja-share \
            caja-wallpaper \
            caja-xattr-tags \
            krusader
        ;;
    *)
        print_warning "Invalid selection. Installing Thunar as default."
        install_packages thunar thunar-archive-plugin
        ;;
esac

print_success "File manager setup complete!"

# Ask for Nautilus scripts
if ask_yes_no "Would you like to install file manager scripts (nautilus-scripts)?" "y"; then
    install_nautilus_scripts
fi

#==================================================================
# 5. Core Dependencies Installation
#==================================================================
print_section "5. Core Dependencies Installation"
print_info "These packages are essential for HyprGraphite to function properly"

if ask_yes_no "Would you like to install core dependencies for HyprGraphite?" "y"; then
    # Install necessary system packages
    print_status "Installing core system dependencies..."
    system_packages=(
        base-devel           # Essential development tools
        udisks2              # USB Devices
        udev                 # Device Management
        util-linux           # Base Linux Utils
        findutils            # Finding Stuff
        sysstat              # System Status
        grep                 # Extracting Stuff From Text
        sed                  # Text editing with commands
        bash                 # BASH GO BRRRRRRRRRRR!!!!
        alsa-utils           # ALSA Utils
        bc                   
        xdg-utils            # XDG Utilities
        libnotify            # Notifications
        git                  # Version control system
        rust                 # Rust programming language
        cargo                # Rust package manager
        mpv                  # Playing sounds
        gtk4                 # GTK4 toolkit for applications
        wget                 # Network downloader
        curl                 # Command line tool for transferring data
        unzip                # Extract zip archives
        btop                 # System Resource Manager
        python-pip           # Python package manager
        python-setuptools    # Tools for Python packages
        python-wheel         # Built-package format for Python
        xdg-desktop-portal   # Desktop integration portals
        xdg-desktop-portal-gtk # GTK implementation
        xdg-desktop-portal-hyprland # Hyprland implementation
        xdg-desktop-portal-wlr # wlroots implementation
        xdg-user-dirs        # User directories management
        xdg-utils            # Desktop integration tools
        polkit               # Authorization framework
        gnome-keyring        # Password manager
        libsecret            # Secret storage library
        noto-fonts           # Noto Sans font family
        noto-fonts-cjk       # Noto CJK fonts
        noto-fonts-emoji     # Noto emoji fonts
        noto-fonts-extra     # Extra Noto fonts
        ttf-fira-sans        # Fira Sans font used by Waybar
        ttf-jetbrains-mono   # JetBrains Mono font used in kitty
        ttf-jetbrains-mono-nerd # JetBrains Mono Nerd Font with icon support
        ttf-material-design-icons # Material Design Icons for Waybar
    )
    handle_package_installation "${system_packages[@]}"
    
    # Install Hyprland and related packages
    print_status "Installing Hyprland and related packages..."
    hyprland_packages=(
        hyprland             # Hyprland compositor
        polkit               # Auth
        polkit-gnome         # GUI Auth
        hyprpaper            # Wallpaper
        waybar-cava          # Status bar with audio visualization
        wofi                 # Application launcher
        wlogout              # Logout menu
        swayidle             # Idle management daemon
        swaybg               # Wallpaper
        swaylock             # Screen locker
        swayosd              # On-screen display
        swaync               # Notification daemon
        gammastep            # Color temperature adjustment
        wl-clipboard         # Clipboard utilities
        wf-recorder          # Screen Recorder
        brightnessctl        # Brightness control utility
        pamixer              # PulseAudio command line mixer
        playerctl            # Media player controller
        network-manager-applet # Network management tray applet
        blueman              # Bluetooth manager
        bluez                # Bluetooth stack
        bluez-utils          # Bluetooth utilities
        grim                 # Screenshot utility
        slurp                # Region selection
        hyprpicker           # Color picker
    )
    handle_package_installation "${hyprland_packages[@]}"
    
    # Install additional utilities
    print_status "Installing additional utilities..."
    utility_packages=(
        kitty                # GPU-accelerated terminal emulator
        foot                 # FOOT Terminal Emulator
        fish                 # User-friendly shell
        fisher               # Plugin manager for Fish
        nwg-look             # Theme manager
        qt5ct                # Qt5 configuration tool
        qt6ct                # Qt6 configuration tool
        kvantum              # SVG-based theme engine for Qt
        kvantum-qt5          # Kvantum for Qt5
        pavucontrol          # PulseAudio volume control
        gvfs                 # Virtual filesystem implementation
    )
    handle_package_installation "${utility_packages[@]}"
    
    # Print success
    print_success_banner "Core dependencies installed successfully!"
    
    # Install keybinds viewer
    print_section "6.5. Keybinds Viewer Installation"
    print_info "Installing the Hyprland keybinds viewer utility"
    
    if ask_yes_no "Would you like to install the keybinds viewer? (Super+K to launch)" "y"; then
        # Ensure the script is executable
        chmod +x ./scripts/install_keybinds_viewer.sh
        
        # Export AUR_HELPER for the script
        export AUR_HELPER
        
        print_status "Installing Hyprland keybinds viewer..."
        if ! sudo -E ./scripts/install_keybinds_viewer.sh; then
            print_error "Failed to install keybinds viewer"
            if ask_yes_no "Would you like to continue with the installation?" "y"; then
                print_warning "Continuing without keybinds viewer"
            else
                print_error "Installation aborted by user."
                exit 1
            fi
        else
            print_success "Keybinds viewer installation complete!"
        fi
    else
        print_status "Skipping keybinds viewer installation."
    fi
    
    print_status "Now let's continue with HyprGraphite customization..."
    echo
    press_enter
else
    print_status "Skipping core dependencies installation."
fi

#==================================================================
# 6. Theme Setup
#==================================================================
print_section "6. Theme Setup"
print_info "Setting up visual themes for your desktop environment"

setup_theme

#==================================================================
# 7. Configuration Setup
#==================================================================
print_section "7. Configuration Setup"
print_info "Setting up configuration files for HyprGraphite"

setup_configuration

#==================================================================
# 8. Installation Complete
#==================================================================
print_section "Installation Complete!"

print_completion_banner "HyprGraphite installed successfully!"

echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Use ${BRIGHT_CYAN}'nwg-look'${RESET} to customize your default theme settings"
echo -e "${BRIGHT_WHITE}  4. ${RESET}Configure Qt applications with ${BRIGHT_CYAN}'qt5ct'${RESET} and ${BRIGHT_CYAN}'kvantummanager'${RESET}"
echo -e "${BRIGHT_WHITE}  5. ${RESET}Enjoy your new modern desktop environment!"
echo

exit 0
