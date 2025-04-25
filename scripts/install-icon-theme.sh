#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Icon Theme Installer Script                │
# ╰──────────────────────────────────────────────────────────╯

# Source colors and common functions
source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/common_functions.sh"

# Get icon theme type from command line argument
# Default is "fluent" if no argument is provided
ICON_TYPE="${1:-fluent}"
FLUENT_VARIANT="${2:-Fluent-grey}"

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}           Icon Theme Installer               ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}    Beautiful Icons for your Desktop      ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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
install_fluent_icon_theme() {
    print_section "Installing Fluent Icon Theme"
    
    # Always work from a fixed, reliable directory
    cd /tmp || {
        print_error "Failed to change to /tmp directory"
        return 1
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
                print_error "Failed to download icon theme zip file."
                return 1
            fi
        elif command_exists wget; then
            print_status "Downloading using wget..."
            if ! wget -O /tmp/fluent-icon-theme.zip https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/heads/master.zip; then
                print_error "Failed to download icon theme zip file."
                return 1
            fi
        else
            print_error "Neither curl nor wget is available. Cannot download theme."
            return 1
        fi
        
        # Extract zip file
        print_status "Extracting icon theme files..."
        if ! unzip -q -o /tmp/fluent-icon-theme.zip -d /tmp; then
            print_error "Failed to extract icon theme zip file."
            return 1
        fi
        
        # Rename the extracted directory
        mv /tmp/Fluent-icon-theme-master "$TMP_DIR"
    fi
    
    # Make the install script executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Extract the color variant from FLUENT_VARIANT
    # Fluent-grey should use -g option
    THEME_VARIANT=""
    
    if [[ "$FLUENT_VARIANT" == *"grey"* ]]; then
        THEME_VARIANT="-g"
        print_status "Installing grey variant of Fluent theme..."
    elif [[ "$FLUENT_VARIANT" == *"dark"* ]]; then
        THEME_VARIANT="-d"
        print_status "Installing dark variant of Fluent theme..."
    elif [[ "$FLUENT_VARIANT" == *"light"* ]]; then
        THEME_VARIANT="-l"
        print_status "Installing light variant of Fluent theme..."
    else
        print_status "Installing standard variant of Fluent theme..."
    fi
    
    # Execute the installation script with the appropriate options
    cd "$TMP_DIR" || {
        print_error "Failed to change directory to $TMP_DIR"
        return 1
    }
    
    print_status "Running Fluent icon theme installer with options: $THEME_VARIANT"
    ./install.sh $THEME_VARIANT
    
    # Check if the installation was successful
    if [ $? -eq 0 ]; then
        print_success "Fluent icon theme installed successfully!"
    else
        print_error "Failed to install Fluent icon theme."
        return 1
    fi
    
    # Clean up the temporary directory
    cd / || true
    rm -rf "$TMP_DIR"
    
    return 0
}

# Main script execution
print_section "Fluent Icon Theme Installation"
print_status "Starting installation of $FLUENT_VARIANT icon theme..."

# Detect the Linux distribution
detect_distro
print_status "Detected distribution: $DISTRO_TYPE"

# Install dependencies for icon theme installation
install_dependencies

# Install the Fluent icon theme
install_fluent_icon_theme

print_section "Installation Complete"

# Final message
echo -e "${BRIGHT_GREEN}${BOLD}Fluent icon theme ($FLUENT_VARIANT) has been installed successfully.${RESET}"
echo -e "${BRIGHT_WHITE}The theme will be available in your system settings.${RESET}"
echo

exit 0 