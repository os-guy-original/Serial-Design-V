#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

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
        "arch"|"endeavouros"|"manjaro"|"garuda")
            pacman -S --needed --noconfirm flatpak
            ;;
        "debian"|"ubuntu"|"pop"|"linuxmint")
            apt update
            apt install -y flatpak
            ;;
        "fedora")
            dnf install -y flatpak
            ;;
        *)
            if command_exists apt; then
                apt update && apt install -y flatpak
            elif command_exists dnf; then
                dnf install -y flatpak
            elif command_exists pacman; then
                pacman -S --needed --noconfirm flatpak
            else
                print_error "No known package manager found."
                return 1
            fi
            ;;
    esac
}

retry_flathub_add() {
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Detect the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
elif type lsb_release >/dev/null 2>&1; then
    distro=$(lsb_release -si)
else
    result=$(handle_error "Cannot detect OS." "exit 1" "Exiting installation.")
    exit 1
fi

print_status "Detected distribution: $distro"

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

print_success "Flatpak and Flathub repository have been installed successfully!"

# Function to install common Flatpak applications
install_common_flatpaks() {
    print_section "Installing Common Flatpak Applications"
    
    if ! command_exists flatpak; then
        print_error "Flatpak is not installed. Please install it first."
        return 1
    }
    
    # Install Firefox
    print_status "Installing Firefox..."
    if ! flatpak install -y flathub org.mozilla.firefox; then
        result=$(handle_error "Failed to install Firefox." "flatpak install -y flathub org.mozilla.firefox" "Skipping Firefox installation.")
        if [ $result -eq 2 ]; then
            print_warning "Firefox installation skipped."
        fi
    fi
    
    # Install Epiphany
    print_status "Installing Epiphany (GNOME Web)..."
    if ! flatpak install -y flathub org.gnome.Epiphany; then
        result=$(handle_error "Failed to install Epiphany." "flatpak install -y flathub org.gnome.Epiphany" "Skipping Epiphany installation.")
        if [ $result -eq 2 ]; then
            print_warning "Epiphany installation skipped."
        fi
    fi
    
    # Install Chrome
    print_status "Installing Google Chrome..."
    if ! flatpak install -y flathub com.google.Chrome; then
        result=$(handle_error "Failed to install Google Chrome." "flatpak install -y flathub com.google.Chrome" "Skipping Google Chrome installation.")
        if [ $result -eq 2 ]; then
            print_warning "Google Chrome installation skipped."
        fi
    fi
    
    # Install Ungoogled Chromium
    print_status "Installing Ungoogled Chromium..."
    if ! flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium; then
        result=$(handle_error "Failed to install Ungoogled Chromium." "flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium" "Skipping Ungoogled Chromium installation.")
        if [ $result -eq 2 ]; then
            print_warning "Ungoogled Chromium installation skipped."
        fi
    fi
    
    # Install Zen Browser
    print_status "Installing Zen Browser..."
    if ! flatpak install -y flathub app.zen_browser.zen; then
        result=$(handle_error "Failed to install Zen Browser." "flatpak install -y flathub app.zen_browser.zen" "Skipping Zen Browser installation.")
        if [ $result -eq 2 ]; then
            print_warning "Zen Browser installation skipped."
        fi
    fi
    
    print_success "Common Flatpak applications have been installed successfully!"
    return 0
}

# Function to configure Flatpak for Wayland
configure_flatpak_wayland() {
    print_section "Configuring Flatpak for Wayland"
    
    # Create the override directory if it doesn't exist
    mkdir -p ~/.local/share/flatpak/overrides
    
    # Configure global overrides for Wayland
    print_status "Configuring global Flatpak overrides for Wayland..."
    
    if ! cat > ~/.local/share/flatpak/overrides/global << EOF
[Context]
sockets=wayland;x11;pulseaudio;
EOF
    then
        result=$(handle_error "Failed to create Flatpak override file." "configure_flatpak_wayland" "Skipping Wayland configuration.")
        if [ $result -eq 2 ]; then
            print_warning "Wayland configuration skipped."
            return 1
        elif [ $result -ne 0 ]; then
            return $result
        fi
    fi
    
    print_success "Flatpak has been configured to use Wayland when possible!"
    return 0
}

# Ask if the user wants to install common Flatpak applications
if ask_yes_no "Would you like to install common Flatpak applications?" "y"; then
    install_common_flatpaks
fi

# Configure Flatpak for Wayland
if ask_yes_no "Would you like to configure Flatpak for better Wayland integration?" "y"; then
    configure_flatpak_wayland
fi

print_section "Installation Complete"
print_success "Flatpak has been set up successfully!"
echo -e "${BRIGHT_WHITE}You can now install and run Flatpak applications on your system.${RESET}"
echo -e "${BRIGHT_WHITE}To browse and install more applications, visit: ${BRIGHT_CYAN}https://flathub.org${RESET}"
echo

exit 0 