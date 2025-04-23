#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Cursor Installer Script                    │
# ╰──────────────────────────────────────────────────────────╯

# Source colors and common functions
source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/common_functions.sh"

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

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
}

# Function to detect distribution for package installation
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

# Function to install Bibata cursors via package manager
install_bibata_package() {
    print_section "Installing Bibata Cursors via Package Manager"
    
    # Define retry function for package installation
    install_bibata_retry() {
        install_bibata_package
    }
    
    case "$DISTRO_TYPE" in
        "arch")
            print_status "Installing from AUR: bibata-cursor-theme"
            
            # If running as root, we need to execute AUR helpers as the regular user
            if [ "$(id -u)" -eq 0 ]; then
                print_warning "Running as root. AUR helpers require a regular user account."
                
                # Try to get the regular user who may have launched this script with sudo
                REGULAR_USER=${SUDO_USER:-$USER}
                
                if [ -z "$REGULAR_USER" ] || [ "$REGULAR_USER" = "root" ]; then
                    print_error "Could not determine the regular user. Running as root with no SUDO_USER set."
                    print_status "Trying GitHub installation method instead..."
                    install_bibata_github
                    return $?
                fi
                
                print_status "Detected regular user: $REGULAR_USER"
                
            if command_exists paru; then
                    print_status "Using paru to install bibata-cursor-theme-bin"
                    print_status "Attempting to run paru as $REGULAR_USER..."
                    
                    if su -c "cd ~ && paru -S --noconfirm bibata-cursor-theme-bin" "$REGULAR_USER"; then
                        print_success "Successfully installed bibata-cursor-theme-bin using paru"
                        return 0
                    else
                        print_warning "Installing with paru failed, trying alternative method..."
                        print_status "Trying GitHub installation method as fallback..."
                        install_bibata_github
                        return $?
                    fi
            elif command_exists yay; then
                    print_status "Using yay to install bibata-cursor-theme-bin"
                    print_status "Attempting to run yay as $REGULAR_USER..."
                    
                    if su -c "cd ~ && yay -S --noconfirm bibata-cursor-theme-bin" "$REGULAR_USER"; then
                        print_success "Successfully installed bibata-cursor-theme-bin using yay"
                        return 0
                    else
                        print_warning "Installing with yay failed, trying alternative method..."
                        print_status "Trying GitHub installation method as fallback..."
                        install_bibata_github
                        return $?
                    fi
                else
                    print_warning "Neither paru nor yay found for AUR installation."
                    print_status "Trying GitHub installation method instead..."
                    install_bibata_github
                    return $?
                fi
            else
                # Regular execution as non-root
                if command_exists paru; then
                    print_status "Using paru to install bibata-cursor-theme-bin"
                    if paru -S --noconfirm bibata-cursor-theme-bin; then
                        print_success "Successfully installed bibata-cursor-theme-bin using paru"
                        return 0
                    else
                        print_warning "Installing with paru failed, trying alternative method..."
                        print_status "Trying GitHub installation method as fallback..."
                        install_bibata_github
                        return $?
                    fi
                elif command_exists yay; then
                    print_status "Using yay to install bibata-cursor-theme-bin"
                    if yay -S --noconfirm bibata-cursor-theme-bin; then
                        print_success "Successfully installed bibata-cursor-theme-bin using yay"
                        return 0
                    else
                        print_warning "Installing with yay failed, trying alternative method..."
                        print_status "Trying GitHub installation method as fallback..."
                        install_bibata_github
                        return $?
                    fi
                else
                    print_warning "Neither paru nor yay found for AUR installation."
                    print_status "Trying GitHub installation method instead..."
                    install_bibata_github
                    return $?
                fi
            fi
            ;;
            
        "fedora")
            print_status "Installing via DNF package manager"
            if command_exists dnf; then
                # For Fedora, we do need sudo since we're using the system package manager
                print_status "Installing Bibata cursor theme via DNF..."
                if sudo dnf install -y bibata-cursor-theme; then
                    print_success "Successfully installed bibata-cursor-theme via dnf"
                    return 0
                else
                    print_status "Standard repository installation failed. Trying copr repository..."
                    
                    # Fallback to copr repo
                    print_status "Enabling copr repository..."
                    if ! sudo dnf copr enable -y peterwu/rendezvous; then
                        return $(handle_error "Failed to enable copr repository." install_bibata_retry "Skipping Bibata cursor installation.")
                    fi
                    
                    print_status "Installing bibata-cursor-themes package..."
                    if sudo dnf install -y bibata-cursor-themes; then
                        print_success "Successfully installed bibata-cursor-themes via copr repository"
                        return 0
                    else
                        return $(handle_error "Failed to install bibata-cursor-themes via dnf." install_bibata_retry "Skipping Bibata cursor installation.")
                    fi
                fi
            else
                print_error "DNF not found. Cannot install packages."
                return $(handle_error "DNF not found. Cannot install packages." install_bibata_retry "Skipping Bibata cursor installation.")
            fi
            ;;
            
        *)
            print_warning "No package installation method available for this distribution."
            print_warning "Attempting to install directly from GitHub..."
            install_bibata_github
            return $?
            ;;
    esac
}

# Function to install Bibata cursors directly from GitHub
install_bibata_github() {
    print_section "Installing Bibata Cursors from GitHub"
    
    # Define retry function for GitHub installation
    install_bibata_github_retry() {
        install_bibata_github
    }
    
    # Create temporary directory for downloaded files
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to create temporary directory." install_bibata_github_retry "Skipping Bibata cursor installation.")
    }
    
    print_status "Downloading Bibata cursor themes from GitHub..."
    
    # Install necessary tools
    print_status "Installing necessary tools..."
    case "$DISTRO_TYPE" in
        "arch")
            if ! command_exists curl unzip; then
                sudo pacman -S --needed --noconfirm curl unzip
            fi
            ;;
        "debian")
            if ! command_exists curl unzip; then
                sudo apt-get update
                sudo apt-get install -y curl unzip
            fi
            ;;
        "fedora")
            if ! command_exists curl unzip; then
                sudo dnf install -y curl unzip
            fi
            ;;
        *)
            if ! command_exists curl unzip; then
                return $(handle_error "curl and unzip are required but not installed." install_bibata_github_retry "Skipping Bibata cursor installation.")
            fi
            ;;
    esac
    
    # Download all cursor variants
    print_status "Downloading Modern variant..."
    if ! curl -L -o modern.tar.gz https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern.tar.gz; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to download Modern variant." install_bibata_github_retry "Skipping Bibata cursor installation.")
    fi
    
    print_status "Downloading Original variant..."
    if ! curl -L -o original.tar.gz https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Original.tar.gz; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to download Original variant." install_bibata_github_retry "Skipping Bibata cursor installation.")
    fi
    
    # Ensure directories exist
    sudo mkdir -p /usr/share/icons
    mkdir -p ~/.icons
    
    # Extract and install all variants
    print_status "Installing Modern variant..."
    if ! tar -xzf modern.tar.gz; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to extract Modern variant." install_bibata_github_retry "Skipping Bibata cursor installation.")
    fi
    
    print_status "Installing Original variant..."
    if ! tar -xzf original.tar.gz; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to extract Original variant." install_bibata_github_retry "Skipping Bibata cursor installation.")
    fi
    
    # Move extracted themes to system location
    print_status "Installing cursors system-wide..."
    for theme_dir in Bibata-*; do
        if [ -d "$theme_dir" ]; then
            if ! sudo cp -r "$theme_dir" /usr/share/icons/; then
                cd /tmp
                rm -rf "$TMP_DIR"
                return $(handle_error "Failed to install $theme_dir system-wide." install_bibata_github_retry "Skipping Bibata cursor installation.")
            fi
            print_success "Installed $theme_dir system-wide"
        fi
    done
    
    # Cleanup
    cd /tmp
    rm -rf "$TMP_DIR"
    
    print_success "Successfully installed Bibata cursor themes from GitHub!"
    return 0
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}          Bibata Cursor Installer           ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install cursors for later activation   ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./scripts/install-cursors.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo -e "  ${CYAN}--package${RESET}     Prefer package manager installation"
    echo -e "  ${CYAN}--github${RESET}      Prefer GitHub releases installation"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script installs all variants of the Bibata cursor theme on your system."
    echo -e "  It will automatically detect your distribution and use the appropriate method."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}INSTALLATION METHODS:${RESET}"
    echo -e "  • Package Manager: Uses AUR for Arch-based or COPR for Fedora-based systems"
    echo -e "  • GitHub Releases: Downloads all variants directly from GitHub"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SOURCE:${RESET}"
    echo -e "  The Bibata cursors are created by ${BRIGHT_CYAN}ful1e5${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/ful1e5/Bibata_Cursor${RESET}"
    
    exit 0
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Script                                             ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Initialize variables
PREFER_PACKAGE=true
PREFER_GITHUB=false

# Check if script is run with root privileges - but only warn, don't exit
# This allows it to be called from other installer scripts that might be running as root
if [ "$(id -u)" -eq 0 ]; then
    print_warning "This script is running as root. For Arch-based systems, AUR helpers will be run as the regular user."
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            print_help
            ;;
        --package)
            PREFER_PACKAGE=true
            PREFER_GITHUB=false
            ;;
        --github)
            PREFER_PACKAGE=false
            PREFER_GITHUB=true
            ;;
        *)
            print_error "Unknown option: $1"
    print_help
            ;;
    esac
    shift
done

# Clear the screen
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            Cursor Installer                   ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Beautiful and Smooth Cursor Theme        ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Detect distribution
print_section "System Detection"
detect_distro
print_status "Detected: $OS_NAME (Type: $DISTRO_TYPE)"

# Installation method selection
print_section "Installation Method"

# Installation strategy based on user preference and distribution
installation_success=false
installation_skipped=false

if [ "$PREFER_PACKAGE" = true ] && ([ "$DISTRO_TYPE" = "arch" ] || [ "$DISTRO_TYPE" = "fedora" ]); then
    print_status "Using package manager installation..."
    install_bibata_package
    result_code=$?
    
    if [ $result_code -eq 0 ]; then
        installation_success=true
    elif [ $result_code -eq 2 ]; then
        # Special code 2 means skipped
        installation_skipped=true
        print_warning "Package installation was skipped by user."
        
        # Ask if user wants to try GitHub installation instead
        if ask_yes_no "Would you like to try installing directly from GitHub instead?" "y"; then
            print_status "Trying GitHub installation method..."
            install_bibata_github
            result_code=$?
            
            if [ $result_code -eq 0 ]; then
                installation_success=true
                installation_skipped=false
            elif [ $result_code -eq 2 ]; then
                installation_skipped=true
            fi
        fi
    else
        print_error "Package installation failed."
        
        # Try GitHub installation as fallback
        if ask_yes_no "Would you like to try installing directly from GitHub instead?" "y"; then
            print_status "Trying GitHub installation method..."
            install_bibata_github
            result_code=$?
            
            if [ $result_code -eq 0 ]; then
                installation_success=true
            elif [ $result_code -eq 2 ]; then
                installation_skipped=true
            fi
        fi
    fi
elif [ "$PREFER_GITHUB" = true ] || [ "$DISTRO_TYPE" != "arch" ] && [ "$DISTRO_TYPE" != "fedora" ]; then
    print_status "Using direct installation from GitHub..."
    install_bibata_github
    result_code=$?
    
    if [ $result_code -eq 0 ]; then
        installation_success=true
    elif [ $result_code -eq 2 ]; then
        installation_skipped=true
        print_warning "GitHub installation was skipped by user."
    else
        print_error "GitHub installation failed."
    fi
else
    print_error "No installation method selected or available for your distribution."
    installation_skipped=true
fi

# Check if installation was successful
if [ "$installation_success" = true ]; then
    print_section "Installation Complete"
    print_success "Bibata cursor themes have been successfully installed!"
    
    print_section "Usage Instructions"
    print_status "For X11/Wayland systems:"
    echo -e "  All cursor themes are installed in ${BRIGHT_CYAN}/usr/share/icons/${RESET}"
    
    print_status "To activate via command line:"
    echo -e "  For GTK: ${BRIGHT_CYAN}gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'${RESET}"
    echo -e "  For Hyprland/Sway: Add ${BRIGHT_CYAN}seat seat0 xcursor_theme Bibata-Modern-Classic 24${RESET} to your config"
    
    print_status "To activate using our theme script:"
        echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
        
        print_success "Installation completed!"
        press_enter
        exit 0
elif [ "$installation_skipped" = true ]; then
    print_section "Installation Skipped"
    print_warning "Bibata cursor theme installation was skipped."
    print_status "You can install it manually later using:"
    
    case "$DISTRO_TYPE" in
        "arch")
            echo -e "  For Arch: ${BRIGHT_CYAN}paru -S bibata-cursor-theme-bin${RESET} or ${BRIGHT_CYAN}yay -S bibata-cursor-theme-bin${RESET}"
            ;;
        "fedora")
            echo -e "  For Fedora: ${BRIGHT_CYAN}sudo dnf copr enable peterwu/rendezvous && sudo dnf install bibata-cursor-themes${RESET}"
            ;;
        *)
            echo -e "  Visit: ${BRIGHT_CYAN}https://github.com/ful1e5/Bibata_Cursor${RESET}"
            ;;
    esac
    
    press_enter
    exit 0
else
    print_section "Installation Failed"
    print_error "Failed to install Bibata cursor themes via package manager."
    print_status "Please try installing manually with your package manager:"
    
    case "$DISTRO_TYPE" in
        "arch")
            echo -e "  For Arch: ${BRIGHT_CYAN}paru -S bibata-cursor-theme-bin${RESET} or ${BRIGHT_CYAN}yay -S bibata-cursor-theme-bin${RESET}"
            ;;
        "fedora")
            echo -e "  For Fedora: ${BRIGHT_CYAN}sudo dnf copr enable peterwu/rendezvous && sudo dnf install bibata-cursor-themes${RESET}"
            ;;
        *)
            echo -e "  Your distribution is not directly supported."
            ;;
    esac
    
    echo -e "  You can also visit: ${BRIGHT_CYAN}https://github.com/ful1e5/Bibata_Cursor${RESET}"
    
    exit 1
fi 