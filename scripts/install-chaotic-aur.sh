#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               Chaotic-AUR Installation                  │
# │                  Arch Linux Repository                  │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

print_section "Chaotic-AUR Setup"
print_status "Setting up Chaotic-AUR repository..."

# Retry functions for error handling
retry_keyring() {
    print_status "Retrying keyring installation..."
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
}

retry_mirrorlist() {
    print_status "Retrying mirrorlist installation..."
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
}

retry_pacman_update() {
    print_status "Retrying system update..."
    pacman -Syu
}

# Retrieve and sign the primary key
print_status "Retrieving and signing Chaotic-AUR key..."
if ! pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com; then
    result=$(handle_error "Failed to retrieve Chaotic-AUR key." retry_keyring "Skipping key retrieval.")
    if [ $result -eq 2 ]; then
        print_warning "Key retrieval skipped. Repository setup may be incomplete."
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

if ! pacman-key --lsign-key 3056513887B78AEB; then
    result=$(handle_error "Failed to sign Chaotic-AUR key." retry_keyring "Skipping key signing.")
    if [ $result -eq 2 ]; then
        print_warning "Key signing skipped. Repository setup may be incomplete."
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

# Install keyring and mirrorlist
print_status "Installing Chaotic-AUR keyring and mirrorlist..."
if ! pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'; then
    result=$(handle_error "Failed to install Chaotic-AUR keyring." retry_mirrorlist "Skipping keyring installation.")
    if [ $result -eq 2 ]; then
        print_warning "Keyring installation skipped. Repository setup may be incomplete."
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

if ! pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
    result=$(handle_error "Failed to install Chaotic-AUR mirrorlist." retry_mirrorlist "Skipping mirrorlist installation.")
    if [ $result -eq 2 ]; then
        print_warning "Mirrorlist installation skipped. Repository setup may be incomplete."
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

# Add repository to pacman.conf
print_status "Adding Chaotic-AUR to pacman.conf..."
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf > /dev/null
    print_success "Chaotic-AUR repository added to pacman.conf"
else
    print_warning "Chaotic-AUR repository already exists in pacman.conf"
fi

# Update system
print_status "Updating system and syncing repositories..."
if ! pacman -Syu --noconfirm; then
    result=$(handle_error "Failed to update system." retry_pacman_update "Skipping system update.")
    if [ $result -eq 2 ]; then
        print_warning "System update skipped. You may need to run 'sudo pacman -Syu' manually."
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

print_section "Installation Complete"
print_success "Chaotic-AUR has been successfully installed and configured!"
print_status "You can now install packages from Chaotic-AUR using pacman."
print_status "Example: pacman -S package-name"

exit 0 