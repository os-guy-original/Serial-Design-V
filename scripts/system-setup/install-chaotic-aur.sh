#!/bin/bash

# Source common functions
# Check if common_functions.sh exists in the utils directory
if [ -f "$(dirname "$0")/../utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../utils/common_functions.sh"
# Check if common_functions.sh exists in the scripts/utils directory
elif [ -f "$(dirname "$0")/../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../scripts/utils/common_functions.sh"
# Check if it exists in the parent directory's scripts/utils directory
elif [ -f "$(dirname "$0")/../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../scripts/utils/common_functions.sh"
# As a last resort, try the scripts/utils directory relative to current directory
elif [ -f "scripts/utils/common_functions.sh" ]; then
    source "scripts/utils/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    echo "Looked in: $(dirname "$0")/../utils/, $(dirname "$0")/../../scripts/utils/, $(dirname "$0")/../../../scripts/utils/, scripts/utils/"
    exit 1
fi

# ╭──────────────────────────────────────────────────────────╮
# │$(center_text "Chaotic-AUR Repository" 54)│
# │$(center_text "Pre-built AUR Packages for Arch Linux" 54)│
# ╰──────────────────────────────────────────────────────────╯

# Remove the problematic code
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Set up the Chaotic-AUR repository for Arch Linux"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs and configures the Chaotic-AUR repository,"
    echo -e "    which provides pre-built AUR packages for Arch Linux."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}REQUIREMENTS${RESET}"
    echo -e "    - Arch Linux or Arch-based distribution"
    echo -e "    - Root privileges (script must be run with sudo)"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script must be run as root to properly configure pacman."
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
fi

#==================================================================
# Privilege Check
#==================================================================
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

#==================================================================
# Welcome Message
#==================================================================
clear
print_banner "Chaotic-AUR Repository Setup" "Access thousands of pre-built AUR packages for Arch Linux"

#==================================================================
# Prerequisites Check
#==================================================================
print_section "1. System Prerequisites"
print_info "Verifying required tools are available"

# Check if pacman-key is available
if ! command -v pacman-key > /dev/null; then
    print_error "pacman-key not found. This script is designed for Arch Linux."
    exit 1
fi

print_status "Installing required keyring packages..."

# Make sure the core packages are installed
pacman -Sy --noconfirm --needed ca-certificates curl base-devel

#==================================================================
# Key Installation
#==================================================================
print_section "2. Repository Keys"
print_info "Adding cryptographic keys for secure package verification"

# Step 1: Add the Chaotic-AUR key
print_status "Adding the Chaotic-AUR key to pacman keyring..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB

#==================================================================
# Package Installation
#==================================================================
print_section "3. Repository Setup"
print_info "Installing necessary packages for the repository"

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

#==================================================================
# Configuration
#==================================================================
print_section "4. System Configuration"
print_info "Updating system configuration files"

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

#==================================================================
# Completion
#==================================================================
print_section "Installation Complete!"

# Use only one success banner, removing the duplicate
print_success_banner "Chaotic-AUR repository has been successfully set up!"

print_status "You can now install packages from Chaotic-AUR using pacman or your AUR helper."
print_status "For example: sudo pacman -S package-name"

# Make sure we return to the original directory
cd "$SCRIPT_DIR/.." || {
    print_warning "Failed to return to original directory"
}

exit 0 
