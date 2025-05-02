#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │            Hyprland Variable Viewer Installer            │
# │               (Part of HyprGraphite Suite)               │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_warning "This script needs to be run as root to install to /usr/bin"
    print_status "Rerunning with sudo..."
    exec sudo "$0" "$@"
    exit $?
fi

print_section "Hyprland Variable Viewer Installation"
print_info "This script will build and install the variable viewer utility"

# Set the path to the Rust project
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)/hyprland_var_viewer"

# Check if the project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Could not find the hyprland_var_viewer directory at $PROJECT_DIR"
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
print_status "Building the variable viewer..."
cargo build --release

# Check if build was successful
if [ $? -ne 0 ]; then
    print_error "Build failed. Please check the error messages above."
    exit 1
fi

# Install to /usr/bin
print_status "Installing to /usr/bin..."
install -Dm755 "target/release/hyprland-var-viewer" "/usr/bin/hyprland-var-viewer"

# Set proper permissions
chmod 755 "/usr/bin/hyprland-var-viewer"

print_success_banner "Variable viewer installed successfully!"
print_info "You can now view your Hyprland variables by pressing Super+Alt+V" 