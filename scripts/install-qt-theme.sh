#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                   Qt Theme Installation                   │
# │         Modern and Consistent Styling for Qt Apps         │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure Qt/KDE themes"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs the Graphite Qt theme for KDE/Qt applications"
    echo -e "    and configures it system-wide using Kvantum."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}REQUIREMENTS${RESET}"
    echo -e "    - Kvantum theme engine"
    echo -e "    - Qt5/Qt6 configuration tools"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script must be run as root to properly configure system-wide settings."
    echo
    exit 0
fi

#==================================================================
# Privilege Check
#==================================================================
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

#==================================================================
# Welcome Message
#==================================================================
clear
print_banner "Qt Theme Installation" "Sleek and consistent themes for Qt/KDE applications"

#==================================================================
# System Detection
#==================================================================
print_section "1. System Detection"
print_info "Detecting your operating system for compatibility"

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
        print_success "Detected Arch-based distribution: $OS"
        return
    fi
    
    # For anything else, default to arch-based package management
    print_warning "Unsupported distribution detected. Using Arch-based package management."
    DISTRO_TYPE="arch"
}

# Run OS detection
detect_os

#==================================================================
# Dependencies Installation
#==================================================================
print_section "2. Dependencies"
print_info "Installing required packages for Qt theme support"

# Check and install dependencies
install_dependencies() {
    # Check for Kvantum
    if ! command_exists kvantummanager; then
        print_warning "Kvantum not found. It's recommended for the best Qt theme experience."
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
        print_success "Kvantum is already installed!"
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
        print_success "Git installed successfully!"
    else
        print_success "Git is already installed!"
    }
    
    return 0
}

# Run dependencies installation
install_dependencies

#==================================================================
# Theme Installation
#==================================================================
print_section "3. Qt Theme Installation"
print_info "Installing and configuring Graphite theme for Qt applications"

# Install Graphite Qt theme
install_qt_theme() {
    # Check if theme is already installed
    if [ -d "/usr/share/Kvantum/Graphite-rimlessDark" ] || [ -d "$HOME/.local/share/Kvantum/Graphite-rimlessDark" ] || [ -d "$HOME/.config/Kvantum/Graphite-rimlessDark" ]; then
        print_warning "Graphite Qt theme is already installed."
        if ! ask_yes_no "Do you want to reinstall it?" "n"; then
            print_status "Skipping Qt theme installation."
            return 0
        fi
        print_status "Reinstalling Graphite Qt theme..."
    fi
    
    # Define retry function for error handling
    retry_install_qt_theme() {
        install_qt_theme
    }
    
    # Always work from a fixed, reliable directory
    cd /tmp || {
        return $(handle_error "Failed to change to /tmp directory" retry_install_qt_theme "Skipping Qt theme installation.")
    }
    
    # Temporary directory for cloning the repository
    TMP_DIR="/tmp/graphite-qt-theme"
    rm -rf "$TMP_DIR" 2>/dev/null
    mkdir -p "$TMP_DIR"
    
    # Clone the repository directly in /tmp without relying on CWD
    print_status "Cloning Graphite Qt Theme repository..."
    if ! git clone --depth=1 https://github.com/vinceliuice/Graphite-kde-theme.git "$TMP_DIR"; then
        print_status "Trying alternative download method..."
        
        # Try direct download of zip file as backup
        if command_exists curl; then
            print_status "Downloading using curl..."
            if ! curl -L -o /tmp/graphite-kde-theme.zip https://github.com/vinceliuice/Graphite-kde-theme/archive/refs/heads/main.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_qt_theme "Skipping Qt theme installation.")
            fi
        elif command_exists wget; then
            print_status "Downloading using wget..."
            if ! wget -O /tmp/graphite-kde-theme.zip https://github.com/vinceliuice/Graphite-kde-theme/archive/refs/heads/main.zip; then
                return $(handle_error "Failed to download theme zip file." retry_install_qt_theme "Skipping Qt theme installation.")
            fi
        else
            return $(handle_error "Neither curl nor wget is available. Cannot download theme." retry_install_qt_theme "Skipping Qt theme installation.")
        fi
        
        # Extract zip file
        print_status "Extracting theme files..."
        if ! unzip -q -o /tmp/graphite-kde-theme.zip -d /tmp; then
            return $(handle_error "Failed to extract theme zip file." retry_install_qt_theme "Skipping Qt theme installation.")
        fi
        
        # Rename the extracted directory
        mv /tmp/Graphite-kde-theme-main "$TMP_DIR"
    fi
    
    # Execute installation from the TMP_DIR
    cd "$TMP_DIR" || {
        return $(handle_error "Failed to change to theme directory" retry_install_qt_theme "Skipping Qt theme installation.")
    }
    
    # Make the install script executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Install the theme with Kvantum support
    print_status "Installing Graphite KDE theme with Kvantum theme..."
    if ! ./install.sh -t rimless --color dark; then
        print_warning "Installation failed. Trying fallback installation method..."
        if ! ./install.sh; then
            cd /tmp || true
            rm -rf "$TMP_DIR"
            return $(handle_error "Fallback installation also failed. Please check the repository." retry_install_qt_theme "Skipping Qt theme installation.")
        else
            print_success "Fallback installation succeeded!"
        fi
    else
        print_success "Graphite Qt Theme installed successfully!"
    fi
    
    # Cleanup without relying on return to original directory
    print_status "Cleaning up temporary files..."
    cd / || true
    rm -rf "$TMP_DIR"
    
    return 0
}

# Run Qt theme installation
install_qt_theme

#==================================================================
# User Configuration
#==================================================================
print_section "4. System Configuration"
print_info "Setting up Qt theme configuration for all users"

configure_qt_theme() {
    print_status "Configuring Qt5/Qt6 settings for all users..."
    
    # Find all user home directories
    for user_home in /home/*; do
        # Skip if not a directory
        [ ! -d "$user_home" ] && continue
        
        username=$(basename "$user_home")
        
        # Skip system users
        if [ "$username" == "lost+found" ] || id -u "$username" &>/dev/null && [ "$(id -u "$username")" -lt 1000 ]; then
            continue
        fi
        
        print_status "Setting up Qt configuration for user: $username"
        
        # Create Qt configuration directories if they don't exist
        sudo -u "$username" mkdir -p "$user_home/.config"
        
        # Configure Qt5ct settings
        sudo -u "$username" mkdir -p "$user_home/.config/qt5ct"
        
        # Create qt5ct.conf file
        cat > "$user_home/.config/qt5ct/qt5ct.conf" << EOL
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=false
icon_theme=Fluent-dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x14\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x14\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[PaletteEditor]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\xe1\0\0\0\xb9\0\0\x3}\0\0\x2\xd3\0\0\0\xe1\0\0\0\xd5\0\0\x3}\0\0\x2\xd3\0\0\0\0\0\0\0\0\a\x80\0\0\0\xe1\0\0\0\xd5\0\0\x3}\0\0\x2\xd3)

[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\x14\0\0\x3\xb3\0\0\x4\x1b\0\0\0\0\0\0\0\x14\0\0\x2\xde\0\0\x2\xfa\0\0\0\0\x2\0\0\0\a\x80\0\0\0\0\0\0\0\x14\0\0\x3\xb3\0\0\x4\x1b)
EOL
        chown "$username:$username" "$user_home/.config/qt5ct/qt5ct.conf"
        
        # Configure Qt6ct settings if Qt6 is installed
        if command_exists qt6ct || [ -d "/usr/share/qt6ct" ]; then
            sudo -u "$username" mkdir -p "$user_home/.config/qt6ct"
            
            # Create qt6ct.conf file
            cat > "$user_home/.config/qt6ct/qt6ct.conf" << EOL
[Appearance]
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
custom_palette=false
icon_theme=Fluent-dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x14\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x14\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@&\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOL
            chown "$username:$username" "$user_home/.config/qt6ct/qt6ct.conf"
        fi
        
        # Configure Kvantum settings
        sudo -u "$username" mkdir -p "$user_home/.config/Kvantum"
        
        # Create kvantum.kvconfig file
        cat > "$user_home/.config/Kvantum/kvantum.kvconfig" << EOL
[General]
theme=Graphite-rimlessDark
EOL
        chown "$username:$username" "$user_home/.config/Kvantum/kvantum.kvconfig"
        
        print_success "Qt theme configurations set for user: $username"
    done
    
    # Set up environment variables for all users
    print_status "Configuring system-wide environment variables for Qt theme..."
    
    # Create the environment file
    cat > /etc/environment.d/99-qt-style.conf << EOL
# Use Kvantum and Qt styling
QT_STYLE_OVERRIDE=kvantum-dark
QT_QPA_PLATFORMTHEME=qt5ct
EOL
    
    print_success "System-wide Qt environment variables configured!"
    
    return 0
}

# Configure Qt theme for all users
configure_qt_theme

#==================================================================
# Installation Complete
#==================================================================
print_section "Installation Complete!"

# Print a friendly completion message
print_completion_banner "Qt Theme Installation Complete"

# Print success message
print_success_banner "Graphite Qt theme has been installed and configured!"

print_status "To customize your Qt application appearance:"
echo -e "  ${BRIGHT_CYAN}- kvantummanager${RESET} (for detailed Kvantum theme settings)"
echo -e "  ${BRIGHT_CYAN}- qt5ct${RESET} (for Qt5 applications) "
echo -e "  ${BRIGHT_CYAN}- qt6ct${RESET} (for Qt6 applications, if installed)"
print_status "You may need to log out and log back in for all changes to take effect."

exit 0 