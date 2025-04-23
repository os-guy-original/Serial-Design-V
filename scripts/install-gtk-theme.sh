#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               GTK Theme Installer Script                 │
# ╰──────────────────────────────────────────────────────────╯

# Source colors and common functions
source "$(dirname "$0")/colors.sh"

# Check if script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            GTK Theme Installer               ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Elegant and Modern GTK Theme          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

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
    
    # Define retry function for error handling
    retry_install_gtk_theme() {
        install_gtk_theme
    }
    
    # Always work from a fixed, reliable directory
    cd /tmp || {
        return $(handle_error "Failed to change to /tmp directory" retry_install_gtk_theme "Skipping GTK theme installation.")
    }
    
    # Temporary directory for cloning the repository
    TMP_DIR="/tmp/graphite-gtk-theme"
    rm -rf "$TMP_DIR" 2>/dev/null
    mkdir -p "$TMP_DIR"
    
    # Clone the repository directly in /tmp without relying on CWD
    print_status "Cloning Graphite GTK Theme repository..."
    if ! git clone --depth=1 https://github.com/vinceliuice/Graphite-gtk-theme.git "$TMP_DIR"; then
        print_status "Trying alternative download method..."
        
        # Try direct download of zip file as backup
        if command_exists curl; then
            print_status "Downloading using curl..."
            if ! curl -L -o /tmp/graphite-theme.zip https://github.com/vinceliuice/Graphite-gtk-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_gtk_theme "Skipping GTK theme installation.")
            fi
        elif command_exists wget; then
            print_status "Downloading using wget..."
            if ! wget -O /tmp/graphite-theme.zip https://github.com/vinceliuice/Graphite-gtk-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_gtk_theme "Skipping GTK theme installation.")
            fi
        else
            return $(handle_error "Neither curl nor wget is available. Cannot download theme." retry_install_gtk_theme "Skipping GTK theme installation.")
        fi
        
        # Extract zip file
        print_status "Extracting theme files..."
        if ! unzip -q -o /tmp/graphite-theme.zip -d /tmp; then
            return $(handle_error "Failed to extract theme zip file." retry_install_gtk_theme "Skipping GTK theme installation.")
        fi
        
        # Rename the extracted directory
        mv /tmp/Graphite-gtk-theme-master "$TMP_DIR"
    fi
    
    # Debug paths
    debug_path "/usr/share/themes/Graphite" "GTK theme directory (system)"
    debug_path "$HOME/.themes/Graphite" "GTK theme directory (user)"
    debug_path "/usr/local/share/themes/Graphite" "GTK theme directory (local)"
    
    # Make the install script executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Install the theme
    print_status "Installing Graphite GTK Theme with rimless tweaks and libadwaita support..."
    print_status "Running install script from: $TMP_DIR"
    
    # Execute installation from the TMP_DIR
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to change to theme directory" retry_install_gtk_theme "Skipping GTK theme installation.")
    }
    
    # Run with standard options
    if ! ./install.sh --tweaks rimless -l; then
        print_warning "Installation failed. Trying fallback installation method..."
        if ! ./install.sh -l; then
            cd /tmp || true
            rm -rf "$TMP_DIR"
            return $(handle_error "Fallback installation also failed. Please check the repository." retry_install_gtk_theme "Skipping GTK theme installation.")
        else
            print_success "Fallback installation succeeded!"
        fi
    else
        print_success "Graphite GTK Theme installed successfully!"
    fi
    
    # Configure for Flatpak if available
    cd /tmp || true
    if command_exists flatpak; then
        print_status "Setting Graphite theme for Flatpak applications..."
        if ! sudo flatpak override --env=GTK_THEME=Graphite-Dark; then
            print_warning "Failed to set Flatpak GTK theme. You may need to set it manually."
        else
        print_success "Flatpak GTK theme configuration completed!"
        fi
    else
        print_warning "Flatpak is not installed. If you install Flatpak later, you may need to run this script again to configure the GTK theme for Flatpak applications."
    fi
    
    # Cleanup without relying on return to original directory
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

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_help
fi

# Clear the screen
clear

# Detect distribution
print_section "System Detection"
detect_distro
print_status "Detected: $OS_NAME (Type: $DISTRO_TYPE)"

# Install dependencies
install_dependencies

# Install Graphite GTK theme
install_gtk_theme
result_code=$?

# Check result code - 2 means skipped
if [ $result_code -eq 0 ]; then
    # Success case - normal completion
print_section "Next Steps"
    print_success "The Graphite GTK theme has been installed successfully!"
print_status "GTK4/libadwaita support is enabled, modern applications will use the theme."
print_status "To activate the theme, run:"
echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
print_status "And select the 'Activate Graphite GTK Theme' option."
print_success "Installation completed!"
elif [ $result_code -eq 2 ]; then
    # Skipped case
    print_section "Installation Skipped"
    print_warning "GTK theme installation was skipped by user request."
    print_status "You can run this script again later if you want to install the theme."
else
    # Error case
    print_section "Installation Failed"
    print_error "Failed to install the Graphite GTK theme."
    print_status "Please check the error messages above for more information."
fi

press_enter
exit $result_code 