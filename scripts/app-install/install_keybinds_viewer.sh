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

# Source common functions
# ╭──────────────────────────────────────────────────────────╮
# │            Hyprland Keybinds Viewer Installer            │
# │               (Part of Serial Design V Suite)               │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_warning "This script needs to be run as root to install to /usr/bin"
    print_status "Rerunning with sudo..."
    exec sudo "$0" "$@"
    exit $?
fi

print_section "Hyprland Keybinds Viewer Installation"
print_info "This script will build and install the keybinds viewer utility"

# Set the path to the Rust project
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)/show_keybinds"

# Check if the project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Could not find the show_keybinds directory at $PROJECT_DIR"
    exit 1
fi

# Navigate to the project directory
cd "$PROJECT_DIR" || {
    print_error "Failed to enter project directory"
    exit 1
}

# Function to install packages directly with pacman if AUR helper is not available
safe_install_packages() {
    local packages=("$@")
    
    # Check if AUR_HELPER is set and available
    if [ -n "$AUR_HELPER" ] && command -v "$AUR_HELPER" &>/dev/null && [ "$AUR_HELPER" != "pacman" ]; then
        print_status "Installing packages with $AUR_HELPER..."
        $AUR_HELPER -S --needed --noconfirm "${packages[@]}"
    else
        print_status "Using pacman to install packages..."
        pacman -S --needed --noconfirm "${packages[@]}"
    fi
}

# Ensure rust and cargo are installed
if ! command -v cargo &>/dev/null; then
    print_warning "Cargo is not installed."
    print_status "Installing Rust and Cargo..."
    safe_install_packages rust cargo
fi

# Install build dependencies
print_status "Installing build dependencies..."
safe_install_packages gtk4 pkg-config

# Build the project
print_status "Building the keybinds viewer..."
cargo build --release

# Check if build was successful
if [ $? -ne 0 ]; then
    print_error "Build failed. Please check the error messages above."
    exit 1
fi

# Install to /usr/bin
print_status "Installing to /usr/bin..."
install -Dm755 "target/release/hyprland-keybinds" "/usr/bin/hyprland-keybinds"

# Set proper permissions
chmod 755 "/usr/bin/hyprland-keybinds"

print_success_banner "Keybinds viewer installed successfully!"
print_info "You can now view your Hyprland keybinds by pressing Super+K" 
