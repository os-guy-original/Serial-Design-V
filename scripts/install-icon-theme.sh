#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Icon Theme Installer Script                │
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

# Function to debug paths
debug_path() {
    local path="$1"
    local description="$2"
    
    echo -e "${DIM}${BRIGHT_BLACK}Checking: $description${RESET}"
    echo -n "${DIM}${BRIGHT_BLACK}  Path: $path - "
    
    if [ -e "$path" ]; then
        echo -e "Exists${RESET}"
    else
        echo -e "Does not exist${RESET}"
    fi
}

# Function to detect distribution
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

# Install dependencies required for icon theme installation
install_dependencies() {
    print_section "Installing Dependencies"
    
    # Define retry function for dependency installation
    retry_install_dependencies() {
        install_dependencies
    }
    
    # Make sure git is installed for cloning the repository
    if ! command_exists git; then
        print_status "Installing git..."
        
        case "$DISTRO_TYPE" in
            "arch")
                sudo pacman -S --noconfirm git
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

# Function to install Fluent icon theme
install_icon_theme() {
    print_section "Installing Fluent Icon Theme"
    
    # Define retry function for error handling
    retry_install_icon_theme() {
        install_icon_theme
    }
    
    # Always work from a fixed, reliable directory
    cd /tmp || {
        return $(handle_error "Failed to change to /tmp directory" retry_install_icon_theme "Skipping icon theme installation.")
    }
    
    # Temporary directory for cloning the repository
    TMP_DIR="/tmp/fluent-icon-theme"
    rm -rf "$TMP_DIR" 2>/dev/null
    mkdir -p "$TMP_DIR"
    
    # Clone the repository
    print_status "Cloning Fluent Icon Theme repository..."
    if ! git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git "$TMP_DIR"; then
        print_status "Trying alternative download method..."
        
        # Try direct download of zip file as backup
        if command_exists curl; then
            print_status "Downloading using curl..."
            if ! curl -L -o /tmp/fluent-icon-theme.zip https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download icon theme zip file." retry_install_icon_theme "Skipping icon theme installation.")
            fi
        elif command_exists wget; then
            print_status "Downloading using wget..."
            if ! wget -O /tmp/fluent-icon-theme.zip https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip; then
                return $(handle_error "Failed to download icon theme zip file." retry_install_icon_theme "Skipping icon theme installation.")
            fi
        else
            return $(handle_error "Neither curl nor wget is available. Cannot download theme." retry_install_icon_theme "Skipping icon theme installation.")
        fi
        
        # Extract zip file
        print_status "Extracting icon theme files..."
        if ! unzip -q -o /tmp/fluent-icon-theme.zip -d /tmp; then
            return $(handle_error "Failed to extract icon theme zip file." retry_install_icon_theme "Skipping icon theme installation.")
        fi
        
        # Rename the extracted directory
        mv /tmp/Fluent-icon-theme-master "$TMP_DIR"
    fi
    
    # Debug paths
    debug_path "/usr/share/icons/Fluent" "Icon theme directory (system)"
    debug_path "$HOME/.local/share/icons/Fluent" "Icon theme directory (user)"
    
    # Make the install script executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Install the theme with all color variants
    print_status "Installing Fluent Icon Theme with all color variants..."
    print_status "Running install script from: $TMP_DIR"
    
    # Execute installation from the TMP_DIR
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to change to theme directory" retry_install_icon_theme "Skipping icon theme installation.")
    }
    
    # Run the install script with all variants
    if ! ./install.sh -a; then
        print_warning "Installation with all variants failed. Trying standard installation..."
        if ! ./install.sh; then
            cd /tmp || true
            rm -rf "$TMP_DIR"
            return $(handle_error "Standard installation also failed. Please check the repository." retry_install_icon_theme "Skipping icon theme installation.")
        else
            print_success "Standard installation succeeded!"
        fi
    else
        print_success "Fluent Icon Theme with all color variants installed successfully!"
    fi
    
    # Set Fluent-grey as the default icon theme for the current user
    print_status "Setting Fluent-grey as the default icon theme..."
    
    # Create the GTK3 settings directory if it doesn't exist
    mkdir -p "$HOME/.config/gtk-3.0"
    
    # Check if settings.ini exists, create it if not
    if [ ! -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        echo "[Settings]" > "$HOME/.config/gtk-3.0/settings.ini"
        echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-3.0/settings.ini"
    else
        # Update or add the icon theme setting
        if grep -q "gtk-icon-theme-name" "$HOME/.config/gtk-3.0/settings.ini"; then
            sed -i 's/gtk-icon-theme-name=.*/gtk-icon-theme-name=Fluent-grey/' "$HOME/.config/gtk-3.0/settings.ini"
        else
            echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-3.0/settings.ini"
        fi
    fi
    
    # Set for GTK4 as well
    mkdir -p "$HOME/.config/gtk-4.0"
    if [ ! -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
        echo "[Settings]" > "$HOME/.config/gtk-4.0/settings.ini"
        echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-4.0/settings.ini"
    else
        if grep -q "gtk-icon-theme-name" "$HOME/.config/gtk-4.0/settings.ini"; then
            sed -i 's/gtk-icon-theme-name=.*/gtk-icon-theme-name=Fluent-grey/' "$HOME/.config/gtk-4.0/settings.ini"
        else
            echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-4.0/settings.ini"
        fi
    fi
    
    # Configure for Flatpak if available
    if command_exists flatpak; then
        print_status "Setting Fluent-grey theme for Flatpak applications..."
        if ! flatpak override --user --env=GTK_ICON_THEME=Fluent-grey; then
            print_warning "Failed to set Flatpak icon theme. You may need to set it manually."
        else
            print_success "Flatpak icon theme configuration completed!"
        fi
    else
        print_warning "Flatpak is not installed. If you install Flatpak later, you may need to run this script again to configure the icon theme for Flatpak applications."
    fi
    
    # Cleanup
    print_status "Cleaning up temporary files..."
    cd /tmp || true
    rm -rf "$TMP_DIR"
    
    return 0
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Fluent Icon Theme Installer        ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install and set as default theme     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./scripts/install-icon-theme.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script installs the Fluent Icon theme on your system."
    echo -e "  It will detect your distribution and install the necessary dependencies,"
    echo -e "  then clone and install the theme with all color variants."
    echo -e "  The script sets Fluent-grey as the default icon theme."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DEPENDENCIES:${RESET}"
    echo -e "  • git"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}THEME SOURCE:${RESET}"
    echo -e "  The Fluent Icon theme is created by ${BRIGHT_CYAN}vinceliuice${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/vinceliuice/Fluent-icon-theme${RESET}"
    
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

# Install Fluent icon theme
install_icon_theme
result_code=$?

# Check result code - 2 means skipped
if [ $result_code -eq 0 ]; then
    # Success case - normal completion
    print_section "Next Steps"
    print_success "The Fluent Icon theme has been installed successfully!"
    print_status "Fluent-grey has been set as the default icon theme."
    print_status "You may need to log out and log back in to see the changes."
    print_success "Installation completed!"
elif [ $result_code -eq 2 ]; then
    # Skipped case
    print_section "Installation Skipped"
    print_warning "Icon theme installation was skipped by user request."
    print_status "You can run this script again later if you want to install the theme."
else
    # Error case
    print_section "Installation Failed"
    print_error "Failed to install the Fluent Icon theme."
    print_status "Please check the error messages above for more information."
fi

press_enter
exit $result_code 