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
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs the Fluent-grey icon theme for desktop environments"
    echo -e "    and configures it system-wide."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE${RESET}"
    echo -e "    $(basename "$0")"
    echo
    exit 0
fi

# Use fixed values instead of command line arguments
ICON_TYPE="fluent"
FLUENT_VARIANT="Fluent-grey"

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
print_info "Installing Fluent Icon Theme"

# Function to install Fluent icon theme
install_fluent_icon_theme() {
    # Check if theme is already installed
    if [ -d "/usr/share/icons/Fluent-grey" ] || [ -d "$HOME/.local/share/icons/Fluent-grey" ] || [ -d "$HOME/.icons/Fluent-grey" ]; then
        print_warning "Fluent-grey icon theme is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            print_status "Skipping icon theme installation."
            return 0
        fi
        print_status "Reinstalling Fluent-grey icon theme..."
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
    
    # Execute the installation script with the appropriate options
    cd "$TMP_DIR" || {
        print_error "Failed to change directory to $TMP_DIR"
        return 1
    }
    
    print_status "Running Fluent icon theme installer..."
    ./install.sh -a
    
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
# Apply Icon Theme
#==================================================================
print_section "3. Applying Icon Theme"
print_info "Ensuring the icon theme is properly applied"

# Apply to GTK settings
if [ -d "$HOME/.config/gtk-3.0" ] || mkdir -p "$HOME/.config/gtk-3.0"; then
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        # Update existing setting
        if grep -q "gtk-icon-theme-name" "$HOME/.config/gtk-3.0/settings.ini"; then
            sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=Fluent-grey/g" "$HOME/.config/gtk-3.0/settings.ini"
        else
            # Add setting if it doesn't exist
            echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-3.0/settings.ini"
        fi
    fi
fi

# Apply to GTK4 settings
if [ -d "$HOME/.config/gtk-4.0" ] || mkdir -p "$HOME/.config/gtk-4.0"; then
    if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
        # Update existing setting
        if grep -q "gtk-icon-theme-name" "$HOME/.config/gtk-4.0/settings.ini"; then
            sed -i "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=Fluent-grey/g" "$HOME/.config/gtk-4.0/settings.ini"
        else
            # Add setting if it doesn't exist
            echo "gtk-icon-theme-name=Fluent-grey" >> "$HOME/.config/gtk-4.0/settings.ini"
        fi
    fi
fi

# Apply to Qt settings if qt5ct is installed
if [ -d "$HOME/.config/qt5ct" ]; then
    if [ -f "$HOME/.config/qt5ct/qt5ct.conf" ]; then
        if grep -q "icon_theme=" "$HOME/.config/qt5ct/qt5ct.conf"; then
            sed -i "s/icon_theme=.*/icon_theme=Fluent-grey/g" "$HOME/.config/qt5ct/qt5ct.conf"
        fi
    fi
fi

# Try to update the theme immediately if possible
if command_exists gsettings; then
    gsettings set org.gnome.desktop.interface icon-theme "Fluent-grey" 2>/dev/null || true
fi

print_success "Icon theme applied to configuration files"
print_status "You may need to log out and log back in for all changes to take effect"

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

print_success_banner "Fluent-grey icon theme has been installed successfully!"
print_status "You can change icon themes using these tools:"
echo -e "  ${BRIGHT_CYAN}- nwg-look ${RESET}(recommended)"
echo -e "  ${BRIGHT_CYAN}- lxappearance${RESET}"
echo -e "  ${BRIGHT_CYAN}- gnome-tweaks${RESET} (if using GNOME)"

# Exit with success
exit 0 