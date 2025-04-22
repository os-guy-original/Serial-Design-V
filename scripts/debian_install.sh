#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                Debian/Ubuntu Installation                │
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

# Function to install packages with apt
install_packages() {
    local packages=("$@")
    
    print_status "Installing packages with apt..."
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
    
    # Check if all packages were installed
    local failed_packages=()
    for pkg in "${packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
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

# Function to add a PPA repository
add_ppa() {
    local ppa="$1"
    
    if ! command_exists add-apt-repository; then
        print_status "Installing software-properties-common..."
        sudo apt-get update
        sudo apt-get install -y software-properties-common
    fi
    
    print_status "Adding PPA: $ppa"
    sudo add-apt-repository -y "$ppa"
    sudo apt-get update
}

# Configure Hyprland from source
configure_hyprland_from_source() {
    print_section "Building Hyprland from Source"
    
    # Install build dependencies
    print_status "Installing build dependencies..."
    install_packages build-essential cmake meson wget git \
    libwayland-dev libxkbcommon-dev libinput-dev libgbm-dev \
    libxcb-dri3-dev libxcb-present-dev libxcb-composite0-dev \
    libxcb-render-util0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
    libxcb-xinput-dev libxcb-xkb-dev libxcb-image0-dev \
    libxcb-cursor-dev libseat-dev libudev-dev libsystemd-dev \
    libdisplay-info-dev libdrm-dev wlroots-dev libfreetype-dev \
    libfontconfig-dev libpixman-1-dev hwdata libxcb-res0-dev

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
        print_success "Hyprland has been installed successfully!"
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

# Detect Ubuntu/Debian version
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
print_warning "Hyprland on Debian/Ubuntu is experimental and may not be fully stable."
print_warning "This script will install Hyprland from source, which may take some time."

if ask_yes_no "Do you want to continue with the installation?" "y"; then
    print_success "Proceeding with installation..."
else
    print_status "Installation cancelled."
    exit 0
fi

# Update system packages
print_section "System Update"
print_status "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential packages
print_section "Installing Essential Packages"
print_status "Installing essential packages..."
install_packages wget git build-essential cmake curl gnupg lsb-release \
    software-properties-common apt-transport-https ca-certificates

# Install Hyprland and dependencies
configure_hyprland_from_source

# Install supporting packages
print_section "Installing Supporting Packages"

# Pipewire
print_status "Installing PipeWire audio system..."
install_packages pipewire pipewire-pulse wireplumber \
    libspa-0.2-bluetooth pipewire-audio-client-libraries

# Install terminal and shell
print_status "Installing terminal emulators and shells..."
install_packages kitty foot fish zsh

# Install fonts
print_status "Installing fonts..."
install_packages fonts-roboto fonts-firacode fonts-noto-color-emoji fonts-font-awesome

# XDG Desktop Portal
print_status "Installing XDG Desktop Portal..."
install_packages xdg-desktop-portal xdg-desktop-portal-gtk

# Install other Wayland utilities
print_status "Installing Wayland utilities..."
install_packages waybar wofi brightnessctl \
    pavucontrol network-manager-gnome bluez \
    polkit-kde-agent-1 qt5-wayland qt6-wayland

# Build and install additional tools
print_section "Building Additional Tools"

# Install grim (screenshot utility)
print_status "Installing grim..."
install_packages libwayland-dev libcairo2-dev libjpeg-dev
cd /tmp || exit
rm -rf grim 2>/dev/null
git clone https://github.com/emersion/grim.git
cd grim || exit
meson setup build
ninja -C build
sudo ninja -C build install
cd - >/dev/null || exit

# Install slurp (area selection)
print_status "Installing slurp..."
cd /tmp || exit
rm -rf slurp 2>/dev/null
git clone https://github.com/emersion/slurp.git
cd slurp || exit
meson setup build
ninja -C build
sudo ninja -C build install
cd - >/dev/null || exit

# Install wlr-randr (screen configuration)
print_status "Installing wlr-randr..."
cd /tmp || exit
rm -rf wlr-randr 2>/dev/null
git clone https://github.com/emersion/wlr-randr.git
cd wlr-randr || exit
meson setup build
ninja -C build
sudo ninja -C build install
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

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Select Hyprland from your display manager or run ${BRIGHT_CYAN}'Hyprland'${RESET}"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Enjoy your new desktop environment!"
echo
echo -e "${BRIGHT_YELLOW}${BOLD}Note:${RESET} Hyprland on Debian/Ubuntu is experimental. If you encounter issues,"
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