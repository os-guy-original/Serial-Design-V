#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Fedora Installation                     │
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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
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

# Function to install packages with dnf
install_packages() {
    local packages=("$@")
    
    print_status "Installing packages with DNF..."
    sudo dnf install -y "${packages[@]}"
    
    # Check if all packages were installed
    local failed_packages=()
    for pkg in "${packages[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            failed_packages+=("$pkg")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "The following packages could not be installed:"
        for pkg in "${failed_packages[@]}"; do
            echo "  - $pkg"
        done
        return 1
    else
        return 0
    fi
}

# Add RPM Fusion repositories
add_rpm_fusion() {
    print_status "Adding RPM Fusion repositories..."
    
    # Free repository
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        print_status "Installing RPM Fusion Free repository..."
        sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    else
        print_success "RPM Fusion Free repository already installed."
    fi
    
    # Non-free repository
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        print_status "Installing RPM Fusion Non-Free repository..."
        sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    else
        print_success "RPM Fusion Non-Free repository already installed."
    fi
    
    # Update repositories
    sudo dnf groupupdate core -y
}

# Install Hyprland from COPR
install_hyprland_copr() {
    print_section "Installing Hyprland (COPR Repository)"
    
    print_status "Adding Hyprland COPR repository..."
    sudo dnf copr enable solopasha/hyprland -y
    
    print_status "Installing Hyprland and required packages..."
    install_packages hyprland xdg-desktop-portal-hyprland
    
    if command_exists Hyprland; then
        print_success "Hyprland has been installed successfully from COPR!"
        return 0
    else
        print_error "Failed to install Hyprland from COPR!"
        return 1
    fi
}

# Configure Hyprland from source
configure_hyprland_from_source() {
    print_section "Building Hyprland from Source"
    
    # Install build dependencies
    print_status "Installing build dependencies..."
    install_packages cmake meson wget git gcc-c++ \
        wayland-devel libxkbcommon-devel libinput-devel mesa-libgbm-devel \
        libdrm-devel xcb-util-devel xcb-util-keysyms-devel \
        xcb-util-wm-devel libXext-devel cairo-devel pixman-devel \
        glslang-devel ninja-build wayland-protocols-devel \
        libseat-devel systemd-devel libdisplay-info-devel
    
    # Install wlroots
    print_status "Installing wlroots-devel..."
    install_packages wlroots-devel

    # Clone Hyprland
    print_status "Cloning Hyprland repository..."
    cd /tmp || exit
    rm -rf Hyprland 2>/dev/null
    git clone --recursive https://github.com/hyprwm/Hyprland
    cd Hyprland || exit
    
    # Build and install
    print_status "Building and installing Hyprland..."
    sudo mkdir -p /usr/share/wayland-sessions
    sudo make install
    
    cd - >/dev/null || exit
    
    if command_exists Hyprland; then
        print_success "Hyprland has been installed successfully from source!"
        return 0
    else
        print_error "Failed to install Hyprland from source!"
        return 1
    fi
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Setup & Checks                                          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Detect Fedora version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
    OS_NAME=$PRETTY_NAME
else
    print_error "Cannot detect OS version. Exiting..."
    exit 1
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}       HyprGraphite Installation Wizard       ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

print_section "System Check"
print_status "Detected: $OS_NAME ($OS $OS_VER)"

if [[ "$OS" != "fedora" ]]; then
    print_error "This script is designed for Fedora Linux."
    exit 1
fi

if [[ "$OS_VER" -lt 37 ]]; then
    print_warning "Fedora $OS_VER is older than recommended. Some features may not work correctly."
    print_warning "Consider upgrading to Fedora 37 or newer for the best experience."
    if ! ask_yes_no "Do you want to continue anyway?" "n"; then
        print_status "Installation cancelled."
        exit 0
    fi
fi

if ask_yes_no "Do you want to continue with the installation?" "y"; then
    print_success "Proceeding with installation..."
else
    print_status "Installation cancelled."
    exit 0
fi

# Update system packages
print_section "System Update"
print_status "Updating system packages..."
sudo dnf update -y

# Install essential packages
print_section "Installing Essential Packages"
print_status "Installing essential packages..."
install_packages wget git make cmake curl gnupg2 \
    dnf-plugins-core

# Add RPM Fusion repositories
add_rpm_fusion

# Install Hyprland
if [[ "$OS_VER" -ge 37 ]]; then
    print_status "Fedora $OS_VER detected - proceeding with COPR installation..."
    install_hyprland_copr
else
    print_warning "Fedora $OS_VER detected - COPR installation may not be available."
    print_warning "Attempting to build from source instead..."
    if ask_yes_no "Do you want to build Hyprland from source?" "y"; then
        configure_hyprland_from_source
    else
        print_error "Installation cancelled - no installation method selected."
        exit 1
    fi
fi

# Install supporting packages
print_section "Installing Supporting Packages"

# Pipewire
print_status "Installing PipeWire audio system..."
install_packages pipewire pipewire-pulseaudio wireplumber \
    pipewire-alsa pipewire-libs pipewire-jack-audio-connection-kit

# Install terminal and shell
print_status "Installing terminal emulators and shells..."
install_packages kitty foot fish zsh

# Install fonts
print_status "Installing fonts..."
install_packages google-roboto-fonts fira-code-fonts \
    jetbrains-mono-fonts mozilla-fira-sans-fonts

# XDG Desktop Portal
print_status "Installing XDG Desktop Portal..."
install_packages xdg-desktop-portal xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome

# Install Wayland utilities
print_status "Installing Wayland utilities..."
install_packages waybar wofi rofi-wayland grim slurp \
    brightnessctl wl-clipboard pamixer \
    pavucontrol NetworkManager-tui blueman \
    polkit-kde-authentication-agent-1 qt5-qtwayland qt6-qtwayland

# Install file managers
print_status "Installing file managers..."
install_packages nautilus nemo thunar gvfs

# Install SwayOSD
print_status "Installing SwayOSD (for volume/brightness OSD)..."
sudo dnf copr enable erikreider/SwayOSD -y
install_packages SwayOSD

# Install SWWW (wallpaper daemon)
print_status "Installing SWWW..."
if ! command_exists cargo; then
    print_status "Installing Rust (required for SWWW)..."
    install_packages cargo rust
fi

cd /tmp || exit
rm -rf swww 2>/dev/null
git clone https://github.com/Horus645/swww.git
cd swww || exit
cargo build --release
sudo cp target/release/swww /usr/local/bin/
sudo cp target/release/swww-daemon /usr/local/bin/
sudo mkdir -p /usr/local/share/wayland-sessions/
cd - >/dev/null || exit

# Copy configuration files
print_section "Configuration Setup"
if ask_yes_no "Copy configuration files to your home directory?" "y"; then
    print_status "Copying configuration files to ~/.config..."
    
    # Check if .config exists, create if not
    if [ ! -d "$HOME/.config" ]; then
        mkdir -p "$HOME/.config"
    fi
    
    # Create backup of existing config
    print_status "Creating backup of existing config files..."
    BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Copy existing config files to backup
    for dir in .config/*; do
        if [ -d "$dir" ]; then
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null
        fi
    done
    
    # Copy config files
    cp -r .config/* "$HOME/.config/"
    
    print_success "Configuration files copied successfully!"
    print_status "Backup of your previous configuration is available at: ${BACKUP_DIR}"
fi

# Post-installation steps
print_section "Post-Installation Setup"

# Add user to required groups
print_status "Adding user to required groups..."
sudo usermod -aG video,audio "$(whoami)"

# Set up Hyprland session file
print_status "Setting up Hyprland session file..."
sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << EOF
[Desktop Entry]
Name=Hyprland
Comment=A modern wayland compositor
Exec=Hyprland
Type=Application
EOF

# Enable swayosd service
print_status "Setting up SwayOSD service..."
systemctl --user enable --now swayosd.service

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Select Hyprland from your display manager or run ${BRIGHT_CYAN}'Hyprland'${RESET}"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Enjoy your new desktop environment!"
echo
echo -e "${BRIGHT_YELLOW}${BOLD}Note:${RESET} Hyprland on Fedora is experimental. If you encounter issues,"
echo -e "      please report them at the HyprGraphite GitHub repository."
echo

# Goodbye message
echo -e "${BRIGHT_PURPLE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_GREEN}Thank you for choosing HyprGraphite!${RESET}               ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_WHITE}Report any issues at:${RESET}                              ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_CYAN}https://github.com/os-guy/HyprGraphite/issues${RESET}       ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

exit 0 