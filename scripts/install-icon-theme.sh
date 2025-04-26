#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                  Icon Theme Installation                  │
# │           Beautiful Icons for Desktop Environments        │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install icon themes for desktop environments"
    echo -e "${BRIGHT_WHITE}${BOLD}THEME OPTIONS${RESET}"
    echo -e "    ${BRIGHT_CYAN}fluent${RESET}"
    echo -e "        Install Fluent icon theme"
    echo
    echo -e "    ${BRIGHT_CYAN}tela${RESET}"
    echo -e "        Install Tela icon theme"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}FLUENT VARIANTS${RESET}"
    echo -e "    Fluent-blue, Fluent-green, Fluent-grey, Fluent-orange,"
    echo -e "    Fluent-pink, Fluent-purple, Fluent-red, Fluent-yellow"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}EXAMPLE${RESET}"
    echo -e "    $(basename "$0") fluent Fluent-grey"
    echo -e "        Installs the Fluent icon theme with the grey variant"
    echo
    exit 0
fi

# Get icon theme type from command line argument
# Default is "fluent" if no argument is provided
ICON_TYPE="${1:-fluent}"
FLUENT_VARIANT="${2:-Fluent-grey}"

#==================================================================
# Welcome Message
#==================================================================
clear
print_banner "Icon Theme Installation" "Beautiful and consistent icons for your applications"

#==================================================================
# Helper Functions
#==================================================================

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#==================================================================
# Dependencies Installation
#==================================================================
print_section "1. Dependencies"
print_info "Installing required packages for icon theme installation"

# Install dependencies required for icon theme installation
install_dependencies() {
    # Make sure git is installed for cloning the repository
    if ! command_exists git; then
        print_status "Installing git..."
        
        # Try to install git using available package managers
        if command_exists pacman; then
            sudo pacman -S --noconfirm git
        elif command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y git
        elif command_exists dnf; then
            sudo dnf install -y git
        elif command_exists zypper; then
            sudo zypper install -y git
        else
            print_error "Couldn't find a supported package manager to install git."
            print_status "Please install git manually to continue."
            return 1
        fi
        
        if command_exists git; then
            print_success "Git installed successfully!"
        else
            print_error "Failed to install git."
            return 1
        fi
    else
        print_success "Git is already installed."
    fi
    
    return 0
}

# Install dependencies for icon theme installation
install_dependencies || exit 1

#==================================================================
# Theme Installation
#==================================================================
print_section "2. Icon Theme Installation"
print_info "Installing ${FLUENT_VARIANT} icon theme"

# Function to install Fluent icon theme
install_fluent_icon_theme() {
    # Check if theme is already installed
    if [ -d "/usr/share/icons/$FLUENT_VARIANT" ] || [ -d "$HOME/.local/share/icons/$FLUENT_VARIANT" ] || [ -d "$HOME/.icons/$FLUENT_VARIANT" ]; then
        print_warning "Fluent icon theme ($FLUENT_VARIANT) is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            print_status "Skipping icon theme installation."
            return 0
        fi
        print_status "Reinstalling Fluent icon theme..."
    fi
    
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

# Install the Fluent icon theme
install_fluent_icon_theme

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

print_success_banner "Fluent icon theme ($FLUENT_VARIANT) has been installed successfully!"
print_status "You can change icon themes using these tools:"
echo -e "  ${BRIGHT_CYAN}- nwg-look ${RESET}(recommended)"
echo -e "  ${BRIGHT_CYAN}- lxappearance${RESET}"
echo -e "  ${BRIGHT_CYAN}- gnome-tweaks${RESET} (if using GNOME)"

# Exit with success
exit 0 