#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │          HyprGraphite GTK Theme Installer                │
# │          Install GTK Theme for Activation                │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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

# Debug function to print paths and check if they exist
debug_path() {
    local path="$1"
    local description="$2"
    
    echo -e "${BRIGHT_BLACK}${DIM}DEBUG: Checking $description path: $path${RESET}"
    if [ -e "$path" ]; then
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✓ Path exists${RESET}"
    else
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✗ Path does not exist${RESET}"
    fi
}

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Distribution Detection                                  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Detect the distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
        OS_NAME=$PRETTY_NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        OS_VER=$(lsb_release -sr)
        OS_NAME=$(lsb_release -sd)
    else
        OS=$(uname -s)
        OS_VER=$(uname -r)
        OS_NAME="$OS $OS_VER"
    fi
    
    # Convert to lowercase for easier comparison
    OS=${OS,,}
    
    # Return for Arch-based distros
    if [[ "$OS" =~ ^(arch|endeavouros|manjaro|garuda)$ ]]; then
        DISTRO_TYPE="arch"
        return 0
    fi
    
    # Return for Debian-based distros
    if [[ "$OS" =~ ^(debian|ubuntu|pop|linuxmint|elementary)$ ]]; then
        DISTRO_TYPE="debian"
        return 0
    fi
    
    # Return for Fedora-based distros
    if [[ "$OS" =~ ^(fedora|centos|rhel)$ ]]; then
        DISTRO_TYPE="fedora"
        return 0
    fi
    
    # Unknown distro
    DISTRO_TYPE="unknown"
    return 1
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ GTK Theme Installation                                  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check and install dependencies
install_dependencies() {
    print_section "Installing Dependencies"
    
    # Check for required tools
    print_status "Checking GTK theme dependencies..."
    
    case "$DISTRO_TYPE" in
        "arch")
            if ! pacman -Q gnome-themes-extra gtk-engine-murrine sassc &>/dev/null; then
                print_status "Installing GTK theme dependencies..."
                sudo pacman -S --needed --noconfirm gnome-themes-extra gtk-engine-murrine sassc
            fi
            ;;
        "debian")
            if ! dpkg -l | grep -qE "gnome-themes-extra|gtk2-engines-murrine|sassc"; then
                print_status "Installing GTK theme dependencies..."
                sudo apt-get update
                sudo apt-get install -y gnome-themes-extra gtk2-engines-murrine sassc
            fi
            ;;
        "fedora")
            if ! rpm -q gnome-themes-extra gtk-murrine-engine sassc &>/dev/null; then
                print_status "Installing GTK theme dependencies..."
                sudo dnf install -y gnome-themes-extra gtk-murrine-engine sassc
            fi
            ;;
        *)
            print_error "Unsupported distribution for automatic dependency installation."
            print_status "Please install gnome-themes-extra, gtk-engine-murrine, and sassc manually."
            ;;
    esac
    
    # Check for git
    if ! command_exists git; then
        print_status "Installing git..."
        case "$DISTRO_TYPE" in
            "arch")
                sudo pacman -S --needed --noconfirm git
                ;;
            "debian")
                sudo apt-get update
                sudo apt-get install -y git
                ;;
            "fedora")
                sudo dnf install -y git
                ;;
            *)
                print_error "Unsupported distribution for automatic git installation."
                print_status "Please install git manually to continue."
                exit 1
                ;;
        esac
    fi
    
    print_success "Dependencies checked and installed!"
    return 0
}

# Install Graphite GTK theme
install_gtk_theme() {
    print_section "Installing Graphite GTK Theme"
    
    # Temporary directory for cloning the repository
    TMP_DIR="/tmp/graphite-gtk-theme"
    rm -rf "$TMP_DIR" 2>/dev/null
    mkdir -p "$TMP_DIR"
    
    # Clone the repository
    print_status "Cloning Graphite GTK Theme repository..."
    git clone https://github.com/vinceliuice/Graphite-gtk-theme.git "$TMP_DIR"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to clone the Graphite GTK Theme repository."
        return 1
    fi
    
    # Change to the repository directory
    cd "$TMP_DIR" || return 1
    
    # Make the install script executable
    chmod +x install.sh
    
    # Debug paths
    debug_path "/usr/share/themes/Graphite" "GTK theme directory (system)"
    debug_path "$HOME/.themes/Graphite" "GTK theme directory (user)"
    debug_path "/usr/local/share/themes/Graphite" "GTK theme directory (local)"
    
    # Install the theme
    print_status "Installing Graphite GTK Theme with rimless tweaks..."
    
    # Execute installation
    ./install.sh --tweaks rimless
    
    # Check if installation succeeded
    if [ $? -ne 0 ]; then
        print_error "Installation failed. Trying fallback installation method..."
        ./install.sh
        
        if [ $? -ne 0 ]; then
            print_error "Fallback installation also failed. Please check the repository."
            cd - >/dev/null || return 1
            rm -rf "$TMP_DIR"
            return 1
        else
            print_success "Fallback installation succeeded!"
        fi
    else
        print_success "Graphite GTK Theme installed successfully!"
    fi
    
    # Configure for Flatpak if available
    if command_exists flatpak; then
        print_status "Setting Graphite theme for Flatpak applications..."
        sudo flatpak override --env=GTK_THEME=Graphite-Dark
        print_success "Flatpak GTK theme configuration completed!"
    else
        print_warning "Flatpak is not installed. If you install Flatpak later, you may need to run this script again to configure the GTK theme for Flatpak applications."
    fi
    
    # Cleanup
    cd - >/dev/null || return 1
    print_status "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
    
    return 0
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Graphite GTK Theme Installer        ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install theme for later activation    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./scripts/install-gtk-theme.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script installs the Graphite GTK theme on your system."
    echo -e "  It will detect your distribution and install the necessary dependencies,"
    echo -e "  then clone and install the theme with standard options."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DEPENDENCIES:${RESET}"
    echo -e "  • gnome-themes-extra"
    echo -e "  • gtk-engine-murrine / gtk2-engines-murrine / gtk-murrine-engine"
    echo -e "  • sassc"
    echo -e "  • git"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}THEME SOURCE:${RESET}"
    echo -e "  The Graphite GTK theme is created by ${BRIGHT_CYAN}vinceliuice${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/vinceliuice/Graphite-gtk-theme${RESET}"
    
    exit 0
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
    print_help
fi

# Clear the screen
clear

# Print banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Graphite GTK Theme Installer        ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install theme for later activation    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Detect distribution
print_section "System Detection"
detect_distro
print_status "Detected: $OS_NAME (Type: $DISTRO_TYPE)"

# Install dependencies
install_dependencies

# Install Graphite GTK theme
install_gtk_theme

# Inform about theme activation
print_section "Next Steps"
print_status "The Graphite GTK theme has been installed successfully!"
print_status "To activate the theme, run:"
echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
print_status "And select the 'Activate Graphite GTK Theme' option."

print_success "Installation completed!"
press_enter
exit 0 