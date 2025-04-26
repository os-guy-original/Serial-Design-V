#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Define command_exists if not already defined
if ! declare -f command_exists >/dev/null; then
    # Check if a command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }
fi

# ╭──────────────────────────────────────────────────────────╮
# │               Flatpak Installation                      │
# │                  Package Manager Setup                  │
# ╰──────────────────────────────────────────────────────────╯

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

# Retry functions for error handling
retry_flatpak_install() {
    case "$distro" in
        "arch"|"endeavouros"|"manjaro"|"garuda"|"arcolinux"|"artix"|"archcraft")
            print_status "Installing Flatpak for Arch-based distribution..."
            pacman -S --needed --noconfirm flatpak
            ;;
        "debian"|"ubuntu"|"pop"|"linuxmint"|"elementary"|"zorin"|"kali"|"parrot"|"deepin"|"mx"|"peppermint")
            print_status "Installing Flatpak for Debian-based distribution..."
            apt update
            apt install -y flatpak
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"alma")
            print_status "Installing Flatpak for Fedora/RHEL-based distribution..."
            dnf install -y flatpak
            ;;
        "opensuse"|"suse")
            print_status "Installing Flatpak for openSUSE..."
            zypper install -y flatpak
            ;;
        "void")
            print_status "Installing Flatpak for Void Linux..."
            xbps-install -Sy flatpak
            ;;
        "alpine")
            print_status "Installing Flatpak for Alpine Linux..."
            apk add flatpak
            ;;
        "gentoo")
            print_status "Installing Flatpak for Gentoo Linux..."
            emerge --ask=n sys-apps/flatpak
            ;;
        *)
            print_status "Distribution not explicitly recognized, trying to detect package manager..."
            if command_exists apt; then
                print_status "APT detected, assuming Debian-based..."
                apt update && apt install -y flatpak
            elif command_exists dnf; then
                print_status "DNF detected, assuming Fedora-based..."
                dnf install -y flatpak
            elif command_exists pacman; then
                print_status "Pacman detected, assuming Arch-based..."
                pacman -S --needed --noconfirm flatpak
            elif command_exists zypper; then
                print_status "Zypper detected, assuming openSUSE..."
                zypper install -y flatpak
            elif command_exists xbps-install; then
                print_status "XBPS detected, assuming Void Linux..."
                xbps-install -Sy flatpak
            elif command_exists apk; then
                print_status "APK detected, assuming Alpine Linux..."
                apk add flatpak
            elif command_exists emerge; then
                print_status "Portage detected, assuming Gentoo..."
                emerge --ask=n sys-apps/flatpak
            else
                print_error "No known package manager found."
                return 1
            fi
            ;;
    esac
}

retry_flathub_add() {
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [ $? -eq 0 ]; then
        print_success "Flathub repository added successfully."
    else
        print_error "Failed to add Flathub repository."
        return 1
    fi
}

# Enhanced OS detection
distro=""
distro_version=""
distro_name=""

# First try /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro="${ID,,}" # Convert to lowercase
    distro_version="$VERSION_ID"
    distro_name="$NAME"
    
    # Handle specific distribution variants
    case "$distro" in
        # Handle Ubuntu-based distributions
        "ubuntu"|"ubuntu-budgie"|"kubuntu"|"xubuntu"|"lubuntu"|"ubuntu-mate"|"ubuntu-gnome")
            distro="ubuntu"
            ;;
        # Handle Debian-based distributions that don't set ID properly
        "linuxmint"|"elementary"|"pop"|"zorin"|"kali"|"parrot"|"deepin"|"mx"|"peppermint")
            # These already have their ID set correctly
            ;;
        # Handle Arch-based distributions
        "manjaro"|"endeavouros"|"garuda"|"arcolinux"|"artix"|"archcraft"|"archbang")
            # These already have their ID set correctly
            ;;
        # Handle special case for ID_LIKE
        *)
            # If ID isn't specific enough, check ID_LIKE for family
            if [ -n "$ID_LIKE" ]; then
                if [[ "$ID_LIKE" == *"arch"* ]]; then
                    print_status "Distribution '$distro' is Arch-based according to ID_LIKE"
                    distro="arch"
                elif [[ "$ID_LIKE" == *"debian"* ]]; then
                    print_status "Distribution '$distro' is Debian-based according to ID_LIKE"
                    distro="debian" 
                elif [[ "$ID_LIKE" == *"fedora"* ]]; then
                    print_status "Distribution '$distro' is Fedora-based according to ID_LIKE"
                    distro="fedora"
                elif [[ "$ID_LIKE" == *"ubuntu"* ]]; then
                    print_status "Distribution '$distro' is Ubuntu-based according to ID_LIKE"
                    distro="ubuntu"
                fi
            fi
            ;;
    esac
# If /etc/os-release doesn't exist, try lsb_release
elif command_exists lsb_release; then
    distro_raw=$(lsb_release -si)
    distro="${distro_raw,,}" # Convert to lowercase
    distro_version=$(lsb_release -sr)
    distro_name="$distro_raw $distro_version"
    
    # Map some common LSB names to our standard IDs
    case "$distro" in
        "archlinux")
            distro="arch"
            ;;
        "manjarolinux")
            distro="manjaro"
            ;;
        "debian"|"ubuntu")
            # Keep these as-is
            ;;
        "fedora")
            # Keep as-is
            ;;
    esac
# Try /etc/issue as a last resort
elif [ -f /etc/issue ]; then
    issue=$(cat /etc/issue)
    issue_lower="${issue,,}" # Convert to lowercase
    
    if [[ "$issue_lower" == *"arch"* ]]; then
        distro="arch"
    elif [[ "$issue_lower" == *"debian"* ]]; then
        distro="debian"
    elif [[ "$issue_lower" == *"ubuntu"* ]]; then
        distro="ubuntu"
    elif [[ "$issue_lower" == *"fedora"* ]]; then
        distro="fedora"
    elif [[ "$issue_lower" == *"manjaro"* ]]; then
        distro="manjaro"
    fi
    
    # Try to extract version from issue
    if [[ "$issue" =~ [0-9]+\.[0-9]+ ]]; then
        distro_version="${BASH_REMATCH[0]}"
    fi
    
    distro_name="$issue"
else
    # Last resort: check for common package managers
    if command_exists pacman; then
        distro="arch"
        distro_name="Arch-based"
    elif command_exists apt; then
        distro="debian"
        distro_name="Debian-based"
    elif command_exists dnf; then
        distro="fedora"
        distro_name="Fedora-based"
    elif command_exists yum; then
        distro="fedora"
        distro_name="Red Hat-based"
    else
        print_error "Cannot detect OS. Please install Flatpak manually for your distribution."
        exit 1
    fi
fi

# If we still don't have a distro, report error
if [ -z "$distro" ]; then
    print_error "Cannot detect OS distribution."
    exit 1
fi

print_status "Detected distribution: $distro_name (ID: $distro, Version: $distro_version)"

# Check if Flatpak is already installed
if command_exists flatpak; then
    print_success "Flatpak is already installed!"
    print_status "Checking Flathub repository..."
    
    # Check if Flathub repository is already added
    if flatpak remotes | grep -q "flathub"; then
        print_success "Flathub repository is already configured."
        exit 0
    else
        print_status "Adding Flathub repository..."
        if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
            result=$(handle_error "Failed to add Flathub repository." retry_flathub_add "Skipping Flathub repository addition.")
            if [ $result -eq 2 ]; then
                print_warning "Flathub repository addition skipped. You may need to add it manually with:"
                print_status "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
                exit 1
            elif [ $result -ne 0 ]; then
                exit $result
            fi
        fi
        
        print_success "Flathub repository added successfully!"
        exit 0
    fi
fi

# Install Flatpak based on distribution
case "$distro" in
    "arch"|"endeavouros"|"manjaro"|"garuda")
        print_status "Installing Flatpak for Arch-based distribution..."
        if ! pacman -S --needed --noconfirm flatpak; then
            result=$(handle_error "Failed to install Flatpak." retry_flatpak_install "Skipping Flatpak installation.")
            if [ $result -eq 2 ]; then
                print_warning "Flatpak installation skipped. You may need to install it manually."
                exit 0
            elif [ $result -ne 0 ]; then
                exit $result
            fi
        fi
        ;;
    "debian"|"ubuntu"|"pop"|"linuxmint")
        print_status "Installing Flatpak for Debian/Ubuntu-based distribution..."
        if ! apt update; then
            result=$(handle_error "Failed to update package repositories." retry_flatpak_install "Skipping Flatpak installation.")
            if [ $result -eq 2 ]; then
                print_warning "Flatpak installation skipped. You may need to install it manually."
                exit 0
            elif [ $result -ne 0 ]; then
                exit $result
            fi
        fi
        if ! apt install -y flatpak; then
            result=$(handle_error "Failed to install Flatpak." retry_flatpak_install "Skipping Flatpak installation.")
            if [ $result -eq 2 ]; then
                print_warning "Flatpak installation skipped. You may need to install it manually."
                exit 0
            elif [ $result -ne 0 ]; then
                exit $result
            fi
        fi
        ;;
    "fedora")
        print_status "Installing Flatpak for Fedora..."
        if ! dnf install -y flatpak; then
            result=$(handle_error "Failed to install Flatpak." retry_flatpak_install "Skipping Flatpak installation.")
            if [ $result -eq 2 ]; then
                print_warning "Flatpak installation skipped. You may need to install it manually."
                exit 0
            elif [ $result -ne 0 ]; then
                exit $result
            fi
        fi
        ;;
    *)
        print_error "Unsupported distribution: $distro"
        if ask_yes_no "Would you like to try installing Flatpak anyway?" "n"; then
            print_status "Attempting generic Flatpak installation. This may not work..."
            if ! retry_flatpak_install; then
                result=$(handle_error "Failed to install Flatpak." retry_flatpak_install "Skipping Flatpak installation.")
                if [ $result -eq 2 ]; then
                    print_warning "Flatpak installation skipped. You may need to install it manually."
                    exit 0
                elif [ $result -ne 0 ]; then
                    exit $result
                fi
            fi
        else
            print_status "Skipping Flatpak installation."
            exit 0
        fi
        ;;
esac

# Add Flathub repository
print_status "Adding Flathub repository..."
if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    result=$(handle_error "Failed to add Flathub repository." retry_flathub_add "Skipping Flathub repository addition.")
    if [ $result -eq 2 ]; then
        print_warning "Flathub repository addition skipped. You may need to add it manually with:"
        print_status "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    elif [ $result -ne 0 ]; then
        exit $result
    fi
fi

print_section "Flatpak Installation Complete"
print_success "Flatpak and Flathub repository have been installed successfully!"
print_status "You can install Flatpak applications using:"
echo -e "  ${BRIGHT_CYAN}flatpak install flathub <app-id>${RESET}"
print_status "You can search for available applications using:"
echo -e "  ${BRIGHT_CYAN}flatpak search <query>${RESET}"

exit 0