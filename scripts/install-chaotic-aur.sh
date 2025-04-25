#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Chaotic-AUR Setup Script                   │
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

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

print_section "Chaotic-AUR Repository Setup"
print_status "Setting up the Chaotic-AUR repository for Arch Linux..."

# Check if pacman-key is available
if ! command -v pacman-key > /dev/null; then
    print_error "pacman-key not found. This script is designed for Arch Linux."
    exit 1
fi

print_status "Installing required keyring packages..."

# Make sure the core packages are installed
pacman -Sy --noconfirm --needed ca-certificates curl base-devel

# Step 1: Add the Chaotic-AUR key
print_status "Adding the Chaotic-AUR key to pacman keyring..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB

# Step 2: Install chaotic-keyring and chaotic-mirrorlist directly from URL
print_status "Installing Chaotic-AUR keyring and mirrorlist..."
print_status "Installing chaotic-keyring..."
if ! pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'; then
    print_error "Failed to install chaotic-keyring package"
    exit 1
fi

print_status "Installing chaotic-mirrorlist..."
if ! pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
    print_error "Failed to install chaotic-mirrorlist package"
    exit 1
fi

# Step 3: Add the repository to pacman.conf
print_status "Adding Chaotic-AUR to pacman.conf..."

# Check if the repository is already in pacman.conf
if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    print_warning "Chaotic-AUR repository already exists in pacman.conf"
else
    # Append the repository configuration to pacman.conf
    cat >> /etc/pacman.conf << EOL

# Chaotic-AUR Repository
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOL
    print_success "Chaotic-AUR repository added to pacman.conf"
fi

# Update package database
print_status "Updating package database..."
pacman -Sy

print_success "Chaotic-AUR repository has been successfully set up!"
print_status "You now have access to thousands of pre-built AUR packages."
print_status "To install packages from Chaotic-AUR, use pacman as usual:"
echo -e "  ${BRIGHT_CYAN}sudo pacman -S package-name${RESET}"

exit 0 