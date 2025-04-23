#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               QT Theme Installer Script                  │
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
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            QT Theme Installer                 ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Sleek and Consistent QT/KDE Theme      ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

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
# ┃ QT Theme Installation                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check and install dependencies
install_dependencies() {
    print_section "Installing Dependencies"
    
    # Check for Kvantum
    if ! command_exists kvantummanager; then
        print_warning "Kvantum not found. It's recommended for the best QT theme experience."
        print_status "Installing Kvantum..."
        
        case "$DISTRO_TYPE" in
            "arch")
                sudo pacman -S --needed --noconfirm kvantum
                ;;
            "debian")
                sudo apt-get update
                sudo apt-get install -y qt5-style-kvantum qt5-style-kvantum-themes
                ;;
            "fedora")
                sudo dnf install -y kvantum
                ;;
            *)
                print_error "Unsupported distribution for automatic Kvantum installation."
                print_status "Please install Kvantum manually to get the best experience."
                ;;
        esac
    else
        print_success "Kvantum detected!"
    fi
    
    # Check for git and other required tools
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

# Install Graphite QT theme
install_qt_theme() {
    print_section "Installing Graphite QT Theme"
    
    # Define retry function for error handling
    retry_install_qt_theme() {
        install_qt_theme
    }
    
    # Always work from a fixed, reliable directory
    cd /tmp || {
        return $(handle_error "Failed to change to /tmp directory" retry_install_qt_theme "Skipping QT theme installation.")
    }
    
    # Temporary directory for cloning the repository
    TMP_DIR="/tmp/graphite-qt-theme"
    rm -rf "$TMP_DIR" 2>/dev/null
    mkdir -p "$TMP_DIR"
    
    # Clone the repository directly in /tmp without relying on CWD
    print_status "Cloning Graphite QT Theme repository..."
    if ! git clone --depth=1 https://github.com/vinceliuice/Graphite-kde-theme.git "$TMP_DIR"; then
        print_status "Trying alternative download method..."
        
        # Try direct download of zip file as backup
        if command_exists curl; then
            print_status "Downloading using curl..."
            if ! curl -L -o /tmp/graphite-kde-theme.zip https://github.com/vinceliuice/Graphite-kde-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_qt_theme "Skipping QT theme installation.")
            fi
        elif command_exists wget; then
            print_status "Downloading using wget..."
            if ! wget -O /tmp/graphite-kde-theme.zip https://github.com/vinceliuice/Graphite-kde-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_qt_theme "Skipping QT theme installation.")
            fi
        else
            return $(handle_error "Neither curl nor wget is available. Cannot download theme." retry_install_qt_theme "Skipping QT theme installation.")
        fi
        
        # Extract zip file
        print_status "Extracting theme files..."
        if ! unzip -q -o /tmp/graphite-kde-theme.zip -d /tmp; then
            return $(handle_error "Failed to extract theme zip file." retry_install_qt_theme "Skipping QT theme installation.")
        fi
        
        # Rename the extracted directory
        mv /tmp/Graphite-kde-theme-master "$TMP_DIR"
    fi
    
    # Debug paths
    debug_path "/usr/share/aurorae" "KDE Aurorae themes directory (system)"
    debug_path "$HOME/.local/share/aurorae" "KDE Aurorae themes directory (user)"
    debug_path "/usr/share/Kvantum" "Kvantum themes directory (system)"
    debug_path "$HOME/.config/Kvantum" "Kvantum themes directory (user)"
    
    # Make the install script executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Install the theme
    print_status "Installing Graphite QT Theme with standard options..."
    print_status "Theme Variant: default"
    print_status "Color Variant: dark"
    print_status "Rimless: Yes"
    print_status "Running install script from: $TMP_DIR"
    
    # Execute installation from the TMP_DIR
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to change to theme directory" retry_install_qt_theme "Skipping QT theme installation.")
    }
    
    # Run with standard options
    if ! ./install.sh -t default -c dark --rimless; then
        print_warning "Installation failed. Trying fallback installation method..."
        if ! ./install.sh; then
            cd /tmp || true
            rm -rf "$TMP_DIR"
            return $(handle_error "Fallback installation also failed. Please check the repository." retry_install_qt_theme "Skipping QT theme installation.")
        else
            print_success "Fallback installation succeeded!"
        fi
    else
        print_success "Graphite QT Theme installed successfully!"
    fi
    
    # Return to a safe directory
    cd /tmp || true
    
    # Cleanup without relying on return to original directory
    print_status "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
    
    return 0
}

# Configure QT theme for Flatpak
configure_flatpak_qt() {
    print_section "Configuring QT Theme for Flatpak"
    
    # Check if flatpak is installed
    if ! command_exists flatpak; then
        print_warning "Flatpak is not installed. Skipping Flatpak QT theme configuration."
        return 1
    fi
    
    print_status "Configuring Flatpak to use the system QT theme..."
    
    # Create the override directory if it doesn't exist
    mkdir -p ~/.local/share/flatpak/overrides
    
    # Check if global override file exists
    if [ -f ~/.local/share/flatpak/overrides/global ]; then
        # Backup existing file
        cp ~/.local/share/flatpak/overrides/global ~/.local/share/flatpak/overrides/global.bak
        print_status "Backed up existing Flatpak overrides to ~/.local/share/flatpak/overrides/global.bak"
        
        # Check if the file already has [Environment] section
        if grep -q "\[Environment\]" ~/.local/share/flatpak/overrides/global; then
            # Append to existing Environment section if QT_STYLE_OVERRIDE is not set
            if ! grep -q "QT_STYLE_OVERRIDE" ~/.local/share/flatpak/overrides/global; then
                sed -i '/\[Environment\]/a QT_STYLE_OVERRIDE=kvantum' ~/.local/share/flatpak/overrides/global
            fi
        else
            # Add Environment section if it doesn't exist
            echo -e "\n[Environment]\nQT_STYLE_OVERRIDE=kvantum" >> ~/.local/share/flatpak/overrides/global
        fi
    else
        # Create new global override file
        cat > ~/.local/share/flatpak/overrides/global << EOF
[Context]
sockets=wayland;x11;pulseaudio;

[Environment]
QT_STYLE_OVERRIDE=kvantum
EOF
    fi
    
    print_success "Flatpak Qt theme configuration completed!"
    return 0
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Graphite QT Theme Installer        ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install theme for later activation    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./scripts/install-qt-theme.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script installs the Graphite QT/KDE theme on your system."
    echo -e "  It will detect your distribution and install the necessary dependencies,"
    echo -e "  then clone and install the theme with standard options."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DEPENDENCIES:${RESET}"
    echo -e "  • Kvantum (recommended for best QT theme experience)"
    echo -e "  • git"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}THEME SOURCE:${RESET}"
    echo -e "  The Graphite QT/KDE theme is created by ${BRIGHT_CYAN}vinceliuice${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/vinceliuice/Graphite-kde-theme${RESET}"
    
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

# Install Graphite QT theme
install_qt_theme
result_code=$?

# Check the result code - 2 means skipped
if [ $result_code -eq 0 ]; then
    # Success case - normal completion
    # Configure QT theme for Flatpak
    configure_flatpak_qt
    
    # Inform about theme activation
    print_section "Next Steps"
    print_success "The Graphite QT theme has been installed successfully!"
    print_status "Qt theme has been configured for Flatpak applications (if Flatpak is installed)."
    print_status "To activate the theme, run:"
    echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
    print_status "And select the 'Activate Graphite QT/KDE Theme' option."
    print_success "Installation completed!"
elif [ $result_code -eq 2 ]; then
    # Skipped case
    print_section "Installation Skipped"
    print_warning "QT theme installation was skipped by user request."
    print_status "You can run this script again later if you want to install the theme."
else
    # Error case
    print_section "Installation Failed"
    print_error "Failed to install the Graphite QT theme."
    print_status "Please check the error messages above for more information."
fi

press_enter
exit $result_code 