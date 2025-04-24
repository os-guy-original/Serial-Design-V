#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               SwayOSD Setup Script                       │
# ╰──────────────────────────────────────────────────────────╯

# Source colors and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/colors.sh" ]; then
    source "$SCRIPT_DIR/colors.sh"
fi
if [ -f "$SCRIPT_DIR/common_functions.sh" ]; then
    source "$SCRIPT_DIR/common_functions.sh"
fi

# Define colors and functions if not already defined
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
fi

print_section "SwayOSD Installation"
print_status "Building and installing SwayOSD from source..."

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
    OS_NAME=$PRETTY_NAME
else
    print_error "Could not detect operating system!"
    exit 1
fi

# Install dependencies based on distribution
print_status "Installing dependencies for SwayOSD..."

case "$OS" in
    "fedora")
        # Check if we're root, otherwise use sudo
        if [ "$(id -u)" -eq 0 ]; then
            dnf install -y \
                git \
                meson \
                ninja-build \
                gcc \
                rust \
                rust-std-static \
                cargo \
                gtk4-devel \
                libinput-devel \
                pulseaudio-libs-devel \
                libpulse-devel \
                dbus-devel
        else
            sudo dnf install -y \
                git \
                meson \
                ninja-build \
                gcc \
                rust \
                rust-std-static \
                cargo \
                gtk4-devel \
                libinput-devel \
                pulseaudio-libs-devel \
                libpulse-devel \
                dbus-devel
        fi
        ;;
    *)
        print_error "This script is designed for Fedora systems."
        print_warning "For Arch Linux, SwayOSD can be installed via the AUR."
        exit 1
        ;;
esac

# Create temporary directory for building
TMP_DIR=$(mktemp -d)
print_status "Building in temporary directory: $TMP_DIR"

# Clone the repository
print_status "Cloning SwayOSD repository..."
git clone --depth=1 https://github.com/ErikReider/SwayOSD.git "$TMP_DIR"

# Build and install
print_status "Setting up build environment..."
cd "$TMP_DIR" || {
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
    print_success "SwayOSD installed successfully!"
    
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
rm -rf "$TMP_DIR"

exit 0 