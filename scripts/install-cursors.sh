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

# Function to detect OS type
detect_os() {
    # Add notice about Arch-only support
    print_status "⚠️  This script is designed for Arch-based systems only."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    else
        OS="unknown"
    fi
    
    # Return for Arch-based distros
    if [[ "$OS" == "arch" || "$OS" == "manjaro" || "$OS" == "endeavouros" || "$OS" == "garuda" ]] || grep -q "Arch" /etc/os-release 2>/dev/null; then
        DISTRO_TYPE="arch"
        return
    fi
    
    # For anything else, default to arch-based package management
    print_warning "Unsupported distribution detected. Using Arch-based package management."
    DISTRO_TYPE="arch"
}

# Function to install Graphite cursors via package manager
install_graphite_package() {
    print_section "Installing Graphite Cursors via Package Manager"
    
    # Check if theme is already installed
    if [ -d "/usr/share/icons/Graphite-dark-cursors" ] || [ -d "$HOME/.local/share/icons/Graphite-dark-cursors" ] || [ -d "$HOME/.icons/Graphite-dark-cursors" ]; then
        print_warning "Graphite cursor theme is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            print_status "Skipping cursor theme installation."
            return 0
        fi
        print_status "Reinstalling Graphite cursor theme..."
    fi
    
    # Define retry function for package installation
    install_graphite_retry() {
        install_graphite_package
    }
    
    case "$DISTRO_TYPE" in
        "arch")
            print_status "Installing from AUR: graphite-cursor-theme"
            
            # Check if AUR_HELPER is set from arch_install script
            if [ -n "$AUR_HELPER" ] && [ "$AUR_HELPER" != "pacman" ]; then
                print_status "Using $AUR_HELPER to install graphite-cursor-theme"
                
                # If running as root, we need to execute AUR helpers as the regular user
                if [ "$(id -u)" -eq 0 ]; then
                    print_warning "Running as root. AUR helpers require a regular user account."
                    
                    # Try to get the regular user who may have launched this script with sudo
                    REGULAR_USER=${SUDO_USER:-$USER}
                    
                    if [ -z "$REGULAR_USER" ] || [ "$REGULAR_USER" = "root" ]; then
                        print_error "Could not determine the regular user. Running as root with no SUDO_USER set."
                        print_status "Trying GitHub installation method instead..."
                        install_graphite_github
                        return $?
                    fi
                    
                    print_status "Attempting to run $AUR_HELPER as $REGULAR_USER..."
                    if su -c "cd ~ && $AUR_HELPER -S --noconfirm graphite-cursor-theme" "$REGULAR_USER"; then
                        print_success "Successfully installed graphite-cursor-theme using $AUR_HELPER"
                        return 0
                    else 
                        print_warning "Installation with $AUR_HELPER failed"
                        print_status "Trying GitHub installation method as fallback..."
                        install_graphite_github
                        return $?
                    fi
                else
                    # Regular execution as non-root
                    if $AUR_HELPER -S --noconfirm graphite-cursor-theme; then
                        print_success "Successfully installed graphite-cursor-theme using $AUR_HELPER"
                        return 0
                    else
                        print_warning "Installation with $AUR_HELPER failed"
                        print_status "Trying GitHub installation method as fallback..."
                        install_graphite_github
                        return $?
                    fi
                fi
            else
                # No AUR helper available, try GitHub installation
                print_status "No AUR helper available, using GitHub installation method..."
                install_graphite_github
                return $?
            fi
            ;;
            
        "fedora")
            print_status "Installing via DNF package manager"
            if command_exists dnf; then
                # For Fedora, we do need sudo since we're using the system package manager
                print_status "Installing Graphite cursor theme via DNF..."
                if sudo dnf install -y graphite-cursor-theme; then
                    print_success "Successfully installed graphite-cursor-theme via dnf"
                    return 0
                else
                    print_warning "Package not found in standard repositories."
                    print_status "Trying GitHub installation method as fallback..."
                    install_graphite_github
                    return $?
                fi
            else
                print_error "DNF not found. Cannot install packages."
                return $(handle_error "DNF not found. Cannot install packages." install_graphite_retry "Skipping Graphite cursor installation.")
            fi
            ;;
            
        *)
            print_warning "No package installation method available for this distribution."
            print_warning "Attempting to install directly from GitHub..."
            install_graphite_github
            return $?
            ;;
    esac
}

# Function to install Graphite cursors directly from GitHub
install_graphite_github() {
    print_section "Installing Graphite Cursors from GitHub"
    
    # Check if theme is already installed
    if [ -d "/usr/share/icons/Graphite-dark-cursors" ] || [ -d "$HOME/.local/share/icons/Graphite-dark-cursors" ] || [ -d "$HOME/.icons/Graphite-dark-cursors" ]; then
        print_warning "Graphite cursor theme is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            print_status "Skipping cursor theme installation."
            return 0
        fi
        print_status "Reinstalling Graphite cursor theme..."
    fi
    
    # Define retry function for GitHub installation
    install_graphite_github_retry() {
        install_graphite_github
    }
    
    # Create temporary directory for downloaded files
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to create temporary directory." install_graphite_github_retry "Skipping Graphite cursor installation.")
    }
    
    print_status "Downloading Graphite cursor themes from GitHub..."
    
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
                return $(handle_error "curl and unzip are required but not installed." install_graphite_github_retry "Skipping Graphite cursor installation.")
            fi
            ;;
    esac
    
    # Download the Graphite cursor theme
    print_status "Downloading Graphite cursor theme..."
    if ! curl -L -o graphite-cursor-theme.zip https://github.com/vinceliuice/Graphite-cursor-theme/archive/refs/heads/main.zip; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to download Graphite cursor theme." install_graphite_github_retry "Skipping Graphite cursor installation.")
    fi
    
    # Extract theme
    print_status "Extracting theme..."
    if ! unzip -q graphite-cursor-theme.zip; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to extract Graphite cursor theme." install_graphite_github_retry "Skipping Graphite cursor installation.")
    fi
    
    # Navigate to the extracted directory
    cd Graphite-cursor-theme-main || {
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to navigate to extracted directory." install_graphite_github_retry "Skipping Graphite cursor installation.")
    }
    
    # Make the install script executable
    chmod +x install.sh
    
    # Install the theme
    print_status "Installing cursor theme..."
    if ! ./install.sh; then
        cd /tmp
        rm -rf "$TMP_DIR"
        return $(handle_error "Failed to install Graphite cursor theme." install_graphite_github_retry "Skipping Graphite cursor installation.")
    fi
    
    # Cleanup
    cd /tmp
    rm -rf "$TMP_DIR"
    
    print_success "Successfully installed Graphite cursor themes from GitHub!"
    return 0
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Graphite Cursor Installer          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
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
    echo -e "  This script installs the Graphite cursor theme on your system."
    echo -e "  It will automatically detect your distribution and use the appropriate method."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}INSTALLATION METHODS:${RESET}"
    echo -e "  • Package Manager: Uses AUR for Arch-based or package repositories for other systems"
    echo -e "  • GitHub Releases: Downloads the theme directly from GitHub"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SOURCE:${RESET}"
    echo -e "  The Graphite cursors are created by ${BRIGHT_CYAN}vinceliuice${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/vinceliuice/Graphite-cursor-theme${RESET}"
    
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
    if [ "$SUDO_USER" ]; then
        print_warning "This script is running with sudo. AUR helpers might need to be run as a regular user."
    else
        print_warning "This script is running as root. Some operations may require a regular user."
    fi
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            print_help
            ;;
        --package)
            PREFER_PACKAGE=true
            PREFER_GITHUB=false
            shift
            ;;
        --github)
            PREFER_PACKAGE=false
            PREFER_GITHUB=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            print_status "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Clear the screen
clear

# Welcome Message
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Graphite Cursor Installer          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}        For HyprGraphite installation       ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Detect the operating system
print_section "System Detection"
detect_os
print_status "Detected OS: $OS"
print_status "Using installation type: $DISTRO_TYPE"

# Install cursor theme based on preference
if $PREFER_PACKAGE && ! $PREFER_GITHUB; then
    # Try package manager first, fall back to GitHub if needed
    print_status "Attempting to install via package manager..."
    if ! install_graphite_package; then
        print_warning "Package manager installation failed or was skipped."
        
        if ask_yes_no "Would you like to try installing from GitHub instead?" "y"; then
            install_graphite_github
        else
            print_error "Cursor theme installation aborted."
            exit 1
        fi
    fi
elif $PREFER_GITHUB && ! $PREFER_PACKAGE; then
    # Try GitHub only
    print_status "Installing directly from GitHub as requested..."
    install_graphite_github
else
    # Default behavior - try package manager first
    print_status "Attempting to install via package manager..."
    if ! install_graphite_package; then
        print_warning "Package manager installation failed or was skipped."
        
        if ask_yes_no "Would you like to try installing from GitHub instead?" "y"; then
            install_graphite_github
        else
            print_error "Cursor theme installation aborted."
            exit 1
        fi
    fi
fi

# Success message
print_section "Installation Complete"
print_success "Graphite cursor theme has been installed successfully!"
print_status "To activate the theme, use the following command:"
echo -e "${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"

press_enter
exit 0 