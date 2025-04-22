#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Flatpak Script                │
# │                  Modern Hyprland Setup                   │
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

# Function to install Flatpak based on distribution
install_flatpak() {
    local distro
    
    # Detect the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro=$ID
    elif type lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -si)
    else
        print_error "Cannot detect OS. Exiting..."
        exit 1
    fi
    
    # Convert to lowercase
    distro=$(echo "$distro" | tr '[:upper:]' '[:lower:]')
    
    print_status "Detected distribution: $distro"
    
    case "$distro" in
        "arch"|"endeavouros"|"manjaro"|"garuda")
            print_status "Installing Flatpak for Arch-based distribution..."
            sudo pacman -S --needed --noconfirm flatpak
            ;;
        "debian"|"ubuntu"|"pop"|"linuxmint"|"elementary")
            print_status "Installing Flatpak for Debian/Ubuntu-based distribution..."
            sudo apt update
            sudo apt install -y flatpak gnome-software-plugin-flatpak
            ;;
        "fedora")
            print_status "Installing Flatpak for Fedora..."
            sudo dnf install -y flatpak
            ;;
        *)
            print_error "Unsupported distribution: $distro"
            if ask_yes_no "Would you like to try installing Flatpak anyway?" "n"; then
                print_status "Attempting generic Flatpak installation. This may not work..."
                
                if command_exists apt; then
                    sudo apt update
                    sudo apt install -y flatpak
                elif command_exists dnf; then
                    sudo dnf install -y flatpak
                elif command_exists pacman; then
                    sudo pacman -S --needed --noconfirm flatpak
                else
                    print_error "No known package manager found. Please install Flatpak manually."
                    exit 1
                fi
            else
                print_status "Skipping Flatpak installation."
                exit 1
            fi
            ;;
    esac
    
    # Add the Flathub repository
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    print_success "Flatpak and Flathub repository have been installed successfully!"
}

# Function to install common Flatpak applications
install_common_flatpaks() {
    print_section "Installing Common Flatpak Applications"
    
    # Check if Flatpak is installed
    if ! command_exists flatpak; then
        print_error "Flatpak is not installed. Please install it first."
        exit 1
    fi
    
    # Install common applications
    local apps=(
        "org.mozilla.firefox"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
        "org.inkscape.Inkscape"
        "org.kde.kdenlive"
        "org.audacityteam.Audacity"
        "org.videolan.VLC"
        "com.spotify.Client"
        "com.discordapp.Discord"
        "com.valvesoftware.Steam"
    )
    
    # Ask which applications to install
    print_status "Select applications to install:"
    local selected_apps=()
    
    for app in "${apps[@]}"; do
        if ask_yes_no "Install $app?" "n"; then
            selected_apps+=("$app")
        fi
    done
    
    # Install selected applications
    if [ ${#selected_apps[@]} -gt 0 ]; then
        print_status "Installing selected Flatpak applications..."
        for app in "${selected_apps[@]}"; do
            print_status "Installing $app..."
            flatpak install -y flathub "$app"
            if [ $? -eq 0 ]; then
                print_success "$app installed successfully!"
            else
                print_error "Failed to install $app."
            fi
        done
    else
        print_status "No applications selected for installation."
    fi
}

# Function to configure Flatpak for Wayland
configure_flatpak_wayland() {
    print_section "Configuring Flatpak for Wayland"
    
    # Create the override directory if it doesn't exist
    mkdir -p ~/.local/share/flatpak/overrides
    
    # Configure global overrides for Wayland
    print_status "Configuring global Flatpak overrides for Wayland..."
    
    cat > ~/.local/share/flatpak/overrides/global << EOF
[Context]
sockets=wayland;x11;pulseaudio;
EOF
    
    print_success "Flatpak has been configured to use Wayland when possible!"
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Script                                             ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            Flatpak Installer                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./install-flatpak.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help${RESET}    Display this help message"
    echo
    exit 0
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            Flatpak Installer                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Main installation process
print_section "Flatpak Installation"

# Check if Flatpak is already installed
if command_exists flatpak; then
    print_success "Flatpak is already installed!"
    
    # Check if Flathub repository is added
    if flatpak remotes | grep -q "flathub"; then
        print_success "Flathub repository is already configured!"
    else
        print_status "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        print_success "Flathub repository has been added successfully!"
    fi
else
    print_status "Flatpak is not installed. Installing now..."
    install_flatpak
fi

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