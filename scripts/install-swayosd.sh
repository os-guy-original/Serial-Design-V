#!/bin/bash
# THIS SCRIPT IS CURRENTLY NOT USED
# ╭──────────────────────────────────────────────────────────╮
# │                   SwayOSD Installation                   │
# │           On-Screen Display Service for Wayland          │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/common_functions.sh" ]; then
    source "$SCRIPT_DIR/common_functions.sh"
fi

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install SwayOSD for Wayland"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs SwayOSD, which provides on-screen display"
    echo -e "    notifications for volume, brightness, and other controls in Wayland."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}REQUIREMENTS${RESET}"
    echo -e "    - Arch Linux or Arch-based distribution"
    echo -e "    - Wayland compositor (Hyprland, Sway, etc.)"
    echo -e "    - Base development tools"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script will build SwayOSD from source."
    echo
    exit 0
fi

#==================================================================
# Fallback Definitions (if source files not found)
#==================================================================
if [ -z "$RESET" ]; then
    # Reset
    RESET='\033[0m'
    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    # Text formatting
    BOLD='\033[1m'
    DIM='\033[2m'
    
    # Bright colors
    BRIGHT_RED='\033[0;91m'
    BRIGHT_GREEN='\033[0;92m'
    BRIGHT_YELLOW='\033[0;93m'
    BRIGHT_BLUE='\033[0;94m'
    BRIGHT_PURPLE='\033[0;95m'
    BRIGHT_CYAN='\033[0;96m'
    BRIGHT_WHITE='\033[0;97m'
    
    # Function definitions
    print_section() {
        echo -e "\n${BRIGHT_BLUE}${BOLD}⟪ $1 ⟫${RESET}"
        echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"
    }
    
    print_status() {
        echo -e "${YELLOW}${BOLD}ℹ ${RESET}${YELLOW}$1${RESET}"
    }
    
    print_success() {
        echo -e "${GREEN}${BOLD}✓ ${RESET}${GREEN}$1${RESET}"
    }
    
    print_error() {
        echo -e "${RED}${BOLD}✗ ${RESET}${RED}$1${RESET}"
    }
    
    print_warning() {
        echo -e "${BRIGHT_YELLOW}${BOLD}⚠ ${RESET}${BRIGHT_YELLOW}$1${RESET}"
    }
    
    print_info() {
        echo -e "${BRIGHT_WHITE}${ITALIC}$1${RESET}"
    }
    
    # Add success banner function
    print_success_banner() {
        local message="${1:-Installation completed successfully!}"
        
        echo
        echo -e "${BRIGHT_GREEN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
        echo -e "${BRIGHT_GREEN}${BOLD}│${RESET}   ${BRIGHT_GREEN}${BOLD}✨ ${message} ✨${RESET}   ${BRIGHT_GREEN}${BOLD}│${RESET}"
        echo -e "${BRIGHT_GREEN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
        echo
    }
fi

#==================================================================
# Welcome Message
#==================================================================
clear
print_banner "SwayOSD Installation" "On-Screen Display notifications for volume and brightness"

#==================================================================
# Dependencies Installation
#==================================================================
print_section "1. Dependencies Installation"
print_info "Installing required packages for building SwayOSD"

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Try to use package list first
    if declare -f install_packages_by_category >/dev/null; then
        print_status "Using package list to install dependencies..."
        if install_packages_by_category "SWAYOSD"; then
            print_success "Dependencies installed successfully from package list."
            return 0
        else
            print_warning "Failed to install dependencies from package list, falling back to direct installation."
        fi
    fi
    
    # Fallback to direct installation
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm base-devel git gtk3 meson ninja wayland wayland-protocols libsystemd libpulse || {
            print_error "Failed to install dependencies."
            exit 1
        }
    else
        print_error "This script requires pacman package manager."
        exit 1
    fi
}

# Create temporary directory for building
print_status "Creating temporary build directory..."

# Call the install_dependencies function
install_dependencies

temp_dir=$(mktemp -d)
cd "$temp_dir" || {
    print_error "Failed to create temporary directory."
    exit 1
}

# Clone the repository
print_status "Cloning SwayOSD repository..."
git clone --depth=1 https://github.com/ErikReider/SwayOSD.git "$temp_dir"

# Build and install
print_status "Setting up build environment..."
cd "$temp_dir" || {
    print_error "Failed to change to build directory"
    exit 1
}

# Setup build directory with meson
print_status "Running meson setup..."
if ! meson setup build --prefix /usr; then
    print_error "Meson setup failed"
    exit 1
fi

# Build with ninja
print_status "Building with ninja..."
if ! ninja -C build; then
    print_error "Build failed"
    exit 1
fi

# Install with meson
print_status "Installing SwayOSD..."
if [ "$(id -u)" -eq 0 ]; then
    meson install -C build
else
    sudo meson install -C build
fi

# Check if installation was successful
if command -v swayosd-server >/dev/null 2>&1; then
    print_success_banner "SwayOSD installed successfully!"
    
    # Enable systemd service for libinput backend
    print_status "Enabling swayosd-libinput-backend.service..."
    if [ "$(id -u)" -eq 0 ]; then
        systemctl enable swayosd-libinput-backend.service
    else
        sudo systemctl enable swayosd-libinput-backend.service
    fi
    
    print_status "You can start the SwayOSD server with 'swayosd-server'"
    print_status "For help and command options, run 'swayosd-client --help'"
else
    print_error "SwayOSD installation might have failed."
    print_warning "Try installing manually following instructions at: https://github.com/ErikReider/SwayOSD"
fi

# Cleanup
print_status "Cleaning up..."
cd - > /dev/null || true
rm -rf "$temp_dir"

exit 0 