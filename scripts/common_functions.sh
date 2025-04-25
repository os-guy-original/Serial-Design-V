#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Reset
RESET='\033[0m'

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Helper Functions                                        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

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

# Ask the user for a choice from a list of options
ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local selection
    
    echo -e "${CYAN}${BOLD}? ${RESET}${CYAN}${prompt}${RESET}"
    
    for i in "${!options[@]}"; do
        echo -e "  ${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}. ${options[$i]}"
    done
    
    echo -e -n "${CYAN}Enter selection [1-${#options[@]}]: ${RESET}"
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
        echo "${options[$((selection-1))]}"
        return 0
    else
        print_error "Invalid selection."
        return 1
    fi
}

# Function to handle errors with retry, cancel, and skip options
handle_error() {
    local error_message="$1"
    local retry_function="$2"
    local skip_message="${3:-Skipping this step.}"
    
    print_error "$error_message"
    
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}Options:${RESET}"
    echo -e "  ${BRIGHT_CYAN}1.${RESET} ${BRIGHT_WHITE}Retry${RESET} - Try the operation again"
    echo -e "  ${BRIGHT_CYAN}2.${RESET} ${BRIGHT_WHITE}Skip${RESET} - Skip this step and continue with installation"
    echo -e "  ${BRIGHT_CYAN}3.${RESET} ${BRIGHT_WHITE}Cancel${RESET} - Cancel the installation"
    
    echo
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Choose an option (1-3): ${RESET}"
    read -r choice
    
    case "$choice" in
        1)
            print_status "Retrying..."
            # Call the provided retry function
            $retry_function
            return $?
            ;;
        2)
            print_warning "$skip_message"
            return 2  # Special return code indicating skipped
            ;;
        3)
            print_error "Installation cancelled by user."
            exit 1
            ;;
        *)
            print_warning "Invalid choice. Assuming Skip."
            print_warning "$skip_message"
            return 2
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Nautilus Scripts
install_nautilus_scripts() {
    print_section "Nautilus Scripts Installation"
    
    if ! ask_yes_no "Would you like to install Nautilus Scripts for enhanced file manager functionality?" "y"; then
        print_status "Skipping Nautilus Scripts installation."
        return
    fi
    
    print_status "Installing Nautilus Scripts..."
    
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Clone the repository
        cd /tmp || {
            print_error "Failed to change to /tmp directory"
            return 1
        }
        
        rm -rf nautilus-scripts 2>/dev/null
        if ! git clone https://github.com/cfgnunes/nautilus-scripts.git; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Failed to clone repository. Retrying (attempt $retry_count of $max_retries)..."
                sleep 5
                continue
            else
                print_error "Failed to clone repository after $max_retries attempts."
                if ask_yes_no "Would you like to retry the installation?" "y"; then
                    retry_count=0
                    continue
                else
                    print_error "Nautilus Scripts installation failed. Please try again later."
                    return 1
                fi
            fi
        fi
        
        cd nautilus-scripts || {
            print_error "Failed to enter nautilus-scripts directory"
            return 1
        }
        
        # Make installation script executable
        print_status "Making installation script executable..."
        if ! chmod +x ./install.sh; then
            print_error "Failed to make installation script executable"
            return 1
        fi
        
        # Run the installation script
        print_status "Running installation script..."
        if ! ./install.sh; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Installation script failed. Retrying (attempt $retry_count of $max_retries)..."
                sleep 5
                continue
            else
                print_error "Installation script failed after $max_retries attempts."
                if ask_yes_no "Would you like to retry the installation?" "y"; then
                    retry_count=0
                    continue
                else
                    print_error "Nautilus Scripts installation failed. Please try again later."
                    return 1
                fi
            fi
        fi
        
        # Clean up
        cd - >/dev/null || true
        rm -rf /tmp/nautilus-scripts
        
        print_success "Nautilus Scripts have been installed successfully!"
        print_status "You can access these scripts by right-clicking on files/folders in Nautilus."
        return 0
    done
}

# Function to install packages with retry logic
install_packages() {
    local packages=("$@")
    local max_retries=3
    local retry_count=0
    
    if [ -z "$AUR_HELPER" ]; then
        print_error "No AUR helper selected."
        exit 1
    fi
    
    while [ $retry_count -lt $max_retries ]; do
        case "$AUR_HELPER" in
            "yay")
                print_status "Installing packages with yay..."
                if yay -S --needed --noconfirm "${packages[@]}"; then
                    break
                fi
                ;;
            "paru")
                print_status "Installing packages with paru..."
                if paru -S --needed --noconfirm "${packages[@]}"; then
                    break
                fi
                ;;
            "pacman")
                print_status "Installing packages with pacman..."
                if sudo pacman -S --needed --noconfirm "${packages[@]}"; then
                    break
                fi
                ;;
            *)
                print_error "Unknown AUR helper: $AUR_HELPER"
                exit 1
                ;;
        esac
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_warning "Package installation failed due to network issues."
            print_status "Retrying installation (attempt $retry_count of $max_retries)..."
            sleep 5
        else
            print_error "Failed to install packages after $max_retries attempts."
            print_warning "This might be due to network issues or slow mirrors."
            if ask_yes_no "Would you like to retry the installation?" "y"; then
                retry_count=0
                print_status "Retrying installation..."
            else
                print_error "Package installation failed. Please try again later."
                exit 1
            fi
        fi
    done
    
    # Configure file manager after installation
    if [[ "${packages[*]}" =~ (nautilus|dolphin|nemo|thunar|pcmanfm) ]]; then
        print_status "File manager package(s) installed. Configuration will be done after copying config files."
        # Removed automatic configure-file-manager.sh call here
    fi
}

# Function to install Flatpak browsers
install_flatpak_browsers() {
    # Check for existing Flatpak browsers
    existing_flatpak_browsers=()
    if flatpak list | grep -q "org.mozilla.firefox"; then
        existing_flatpak_browsers+=("Firefox")
    fi
    if flatpak list | grep -q "com.google.Chrome"; then
        existing_flatpak_browsers+=("Google Chrome")
    fi
    if flatpak list | grep -q "io.github.ungoogled_software.ungoogled_chromium"; then
        existing_flatpak_browsers+=("UnGoogled Chromium")
    fi
    if flatpak list | grep -q "org.gnome.Epiphany"; then
        existing_flatpak_browsers+=("Epiphany")
    fi
    
    if [ ${#existing_flatpak_browsers[@]} -gt 0 ]; then
        print_warning "The following Flatpak browsers are already installed:"
        for browser in "${existing_flatpak_browsers[@]}"; do
            echo -e "  ${YELLOW}•${RESET} $browser"
        done
        if ! ask_yes_no "Do you want to continue with installation?" "y"; then
            print_status "Skipping browser installation."
            return
        fi
    fi
    
    # List available Flatpak browsers
    echo -e "\n${BRIGHT_WHITE}${BOLD}Available Flatpak Browsers:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} Zen Browser - A privacy-focused browser"
    echo -e "  ${BRIGHT_WHITE}2.${RESET} Firefox - Popular open-source browser"
    echo -e "  ${BRIGHT_WHITE}3.${RESET} Google Chrome - Google's web browser"
    echo -e "  ${BRIGHT_WHITE}4.${RESET} UnGoogled Chromium - Chromium without Google integration"
    echo -e "  ${BRIGHT_WHITE}5.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser numbers (comma-separated, e.g., 1,3,5): ${RESET}"
    read -r browser_choices
    
    if [[ -n "$browser_choices" ]]; then
        IFS=',' read -ra choices <<< "$browser_choices"
        
        for choice in "${choices[@]}"; do
            case "$choice" in
                1)
                    print_status "Installing Zen Browser..."
                    flatpak install -y flathub app.zen_browser.zen
                    ;;
                2)
                    print_status "Installing Firefox..."
                    flatpak install -y flathub org.mozilla.firefox
                    ;;
                3)
                    print_status "Installing Google Chrome..."
                    flatpak install -y flathub com.google.Chrome
                    ;;
                4)
                    print_status "Installing UnGoogled Chromium..."
                    flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium
                    ;;
                5)
                    print_status "Installing Epiphany..."
                    flatpak install -y flathub org.gnome.Epiphany
                    ;;
                *)
                    print_warning "Invalid selection: $choice. Skipping."
                    ;;
            esac
        done
    fi
}

# Function to setup theme files with system-specific handling
setup_theme() {
    print_section "Theme Setup"
    print_status "Checking theme installations and offering components if needed..."
    
    # Check and offer GTK theme
    if check_gtk_theme_installed; then
        print_success "GTK theme 'Graphite-Dark' is already installed."
    else
        print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
        offer_gtk_theme
    fi
    
    # Check and offer QT theme
    if check_qt_theme_installed; then
        print_success "QT theme 'Graphite-rimlessDark' is already installed."
    else
        print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
        offer_qt_theme
    fi
    
    # Check and offer cursor theme
    if check_cursor_theme_installed; then
        print_success "Cursor theme 'Bibata-Modern-Classic' is already installed."
    else
        print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
        offer_cursor_install
    fi
    
    # Check and offer icon theme
    if check_icon_theme_installed; then
        print_success "Fluent icon theme already installed."
    else
        print_warning "Icon theme is not installed. Your system will use the default icon theme."
        offer_icon_theme_install
    fi
}

# Function to setup configuration files
setup_configuration() {
    print_section "Configuration Setup"
    print_status "Running configuration script..."
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    print_status "Using scripts directory: $SCRIPTS_PREFIX"
    CONFIG_SCRIPT="${SCRIPTS_PREFIX}copy-configs.sh"
    
    if [ -f "$CONFIG_SCRIPT" ]; then
        if [ ! -x "$CONFIG_SCRIPT" ]; then
            print_status "Making configuration script executable..."
            chmod +x "$CONFIG_SCRIPT"
        fi
        
        "$CONFIG_SCRIPT"
    else
        print_error "Configuration script not found at: $CONFIG_SCRIPT"
        print_status "Checking for configuration script in alternative locations..."
        for alt_path in "./copy-configs.sh" "../scripts/copy-configs.sh" "scripts/copy-configs.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found configuration script at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
                "$alt_path"
                break
            fi
        done
    fi
    
    # Also run file manager configuration
    FILE_MANAGER_CONFIG="${SCRIPTS_PREFIX}configure-file-manager.sh"
    
    if [ -f "$FILE_MANAGER_CONFIG" ]; then
        if [ ! -x "$FILE_MANAGER_CONFIG" ]; then
            print_status "Making file manager configuration script executable..."
            chmod +x "$FILE_MANAGER_CONFIG"
        fi
        
        "$FILE_MANAGER_CONFIG"
    else
        print_error "File manager configuration script not found at: $FILE_MANAGER_CONFIG"
        print_status "Checking for file manager configuration script in alternative locations..."
        for alt_path in "./configure-file-manager.sh" "../scripts/configure-file-manager.sh" "scripts/configure-file-manager.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found file manager configuration script at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
                "$alt_path"
                break
            fi
        done
    fi
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Installation Helper Functions                           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Function to offer theme setup
offer_theme_setup() {
    echo
    print_section "Advanced Theme Configuration"
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to manually configure additional theme settings?" "n"; then
        print_status "Launching the theme setup script..."
        
        # Check if setup-themes.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}setup-themes.sh" ] && [ -x "${SCRIPTS_PREFIX}setup-themes.sh" ]; then
            ${SCRIPTS_PREFIX}setup-themes.sh
        else
            print_status "Making theme setup script executable..."
            chmod +x ${SCRIPTS_PREFIX}setup-themes.sh
            ${SCRIPTS_PREFIX}setup-themes.sh
        fi
    else
        print_status "Skipping advanced theme configuration. You can run it later with: ./scripts/setup-themes.sh"
    fi
}

# Function to offer config management
offer_config_management() {
    echo
    print_section "Configuration Management"
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to manage your configuration files?" "y"; then
        print_status "Launching the configuration management script..."
        
        # Check if manage-config.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}manage-config.sh" ] && [ -x "${SCRIPTS_PREFIX}manage-config.sh" ]; then
            ${SCRIPTS_PREFIX}manage-config.sh
        else
            print_status "Making configuration management script executable..."
            chmod +x ${SCRIPTS_PREFIX}manage-config.sh
            ${SCRIPTS_PREFIX}manage-config.sh
        fi
    else
        print_status "Skipping configuration management. You can run it later with: ./scripts/manage-config.sh"
    fi
}

# Function to show all available scripts
show_available_scripts() {
    echo
    print_section "Available Scripts"
    
    echo -e "${BRIGHT_WHITE}${BOLD}HyprGraphite comes with several utility scripts:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Core Installation:${RESET}"
    echo -e "  ${CYAN}• install.sh${RESET} - Main installation script (current)"
    echo -e "  ${CYAN}• scripts/arch_install.sh${RESET} - Arch Linux specific installation"
    echo -e "  ${CYAN}• scripts/fedora_install.sh${RESET} - Fedora specific installation"
    echo -e "  ${CYAN}• scripts/install-flatpak.sh${RESET} - Install and configure Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Components:${RESET}"
    echo -e "  ${CYAN}• scripts/install-gtk-theme.sh${RESET} - Install Graphite GTK theme"
    echo -e "  ${CYAN}• scripts/install-qt-theme.sh${RESET} - Install Graphite Qt/KDE theme"
    echo -e "  ${CYAN}• scripts/install-cursors.sh${RESET} - Install Bibata cursors"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Activation:${RESET}"
    echo -e "  ${CYAN}• scripts/setup-themes.sh${RESET} - Configure and activate installed themes"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Configuration:${RESET}"
    echo -e "  ${CYAN}• scripts/manage-config.sh${RESET} - Manage HyprGraphite configuration files"
    echo
    echo -e "${BRIGHT_WHITE}Run any script with: ${BRIGHT_CYAN}chmod +x <script-path> && ./<script-path>${RESET}"
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Theme Installation Check Functions                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Function to check if GTK theme is installed
check_gtk_theme_installed() {
    local theme_name="Graphite-Dark"
    local gtk_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking GTK theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in /usr/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in $HOME/.local/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    if [ -d "$HOME/.themes/$theme_name" ]; then
        print_status "Found GTK theme in $HOME/.themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in /usr/local/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # Also check for general Graphite theme
    if [ -d "/usr/share/themes/Graphite" ] || [ -d "$HOME/.local/share/themes/Graphite" ] || [ -d "$HOME/.themes/Graphite" ]; then
        print_status "Found general Graphite GTK theme"
        gtk_theme_found=true
    fi
    
    # Check GTK configuration
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-theme-name=Graphite\|gtk-theme-name=Graphite-Dark" "$HOME/.config/gtk-3.0/settings.ini"; then
        print_status "Found Graphite theme configured in GTK3 settings"
        gtk_theme_found=true
    fi
    
    if [ -f "$HOME/.config/gtk-4.0/settings.ini" ] && grep -q "gtk-theme-name=Graphite\|gtk-theme-name=Graphite-Dark" "$HOME/.config/gtk-4.0/settings.ini"; then
        print_status "Found Graphite theme configured in GTK4 settings"
        gtk_theme_found=true
    fi
    
    if $gtk_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if QT theme is installed
check_qt_theme_installed() {
    local theme_name="Graphite-rimlessDark"
    local qt_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking QT theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in /usr/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in $HOME/.local/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    if [ -d "$HOME/.config/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in $HOME/.config/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in /usr/local/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # Also check for Graphite-Dark as an alternative
    if [ -d "/usr/share/Kvantum/Graphite-Dark" ] || [ -d "$HOME/.local/share/Kvantum/Graphite-Dark" ] || [ -d "$HOME/.config/Kvantum/Graphite-Dark" ]; then
        print_status "Found alternative QT theme (Graphite-Dark)"
        qt_theme_found=true
    fi
    
    # Check for general Graphite Kvantum theme
    if [ -d "/usr/share/Kvantum/Graphite" ] || [ -d "$HOME/.local/share/Kvantum/Graphite" ] || [ -d "$HOME/.config/Kvantum/Graphite" ]; then
        print_status "Found general Graphite QT theme"
        qt_theme_found=true
    fi
    
    # Check if Kvantum config mentions the theme
    if [ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ] && grep -q "theme=Graphite\|theme=Graphite-Dark\|theme=Graphite-rimlessDark" "$HOME/.config/Kvantum/kvantum.kvconfig"; then
        print_status "Found Graphite theme configured in Kvantum settings"
        qt_theme_found=true
    fi
    
    if $qt_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if cursor theme is installed
check_cursor_theme_installed() {
    local theme_name="Bibata-Modern-Classic"
    local cursor_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking cursor theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in /usr/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in $HOME/.local/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    if [ -d "$HOME/.icons/$theme_name" ]; then
        print_status "Found cursor theme in $HOME/.icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in /usr/local/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # Check for different Bibata variants
    local bibata_variants=("Bibata-Modern-Ice" "Bibata-Original-Classic" "Bibata-Original-Ice")
    for variant in "${bibata_variants[@]}"; do
        if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ]; then
            print_status "Found alternative Bibata cursor variant: $variant"
            cursor_theme_found=true
        fi
    done
    
    # Check configuration
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-cursor-theme-name=Bibata" "$HOME/.config/gtk-3.0/settings.ini"; then
        print_status "Found Bibata configured in GTK3 settings"
        cursor_theme_found=true
    fi
    
    if [ -f "$HOME/.icons/default/index.theme" ] && grep -q "Inherits=Bibata" "$HOME/.icons/default/index.theme"; then
        print_status "Found Bibata configured in default cursor theme"
        cursor_theme_found=true
    fi
    
    if $cursor_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if icon theme is installed
check_icon_theme_installed() {
    local theme_name="Fluent-grey"
    local icon_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking icon theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/icons/$theme_name" ]; then
        print_status "Found icon theme in /usr/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/icons/$theme_name" ]; then
        print_status "Found icon theme in $HOME/.local/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    if [ -d "$HOME/.icons/$theme_name" ]; then
        print_status "Found icon theme in $HOME/.icons/$theme_name"
        icon_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/icons/$theme_name" ]; then
        print_status "Found icon theme in /usr/local/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    # Check for Fluent icon themes
    local fluent_variants=("Fluent" "Fluent-dark" "Fluent-light" "Fluent-teal" "Fluent-teal-dark" "Fluent-purple" "Fluent-purple-dark" "Fluent-pink" "Fluent-pink-dark" "Fluent-orange" "Fluent-orange-dark" "Fluent-green" "Fluent-green-dark" "Fluent-cyan" "Fluent-cyan-dark" "Fluent-yellow" "Fluent-yellow-dark" "Fluent-red" "Fluent-red-dark")
    for variant in "${fluent_variants[@]}"; do
        if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ]; then
            print_status "Found Fluent icon theme variant: $variant"
            icon_theme_found=true
        fi
    done
    
    # Check configuration
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-icon-theme-name=Fluent" "$HOME/.config/gtk-3.0/settings.ini"; then
        print_status "Found Fluent theme configured in GTK3 settings"
        icon_theme_found=true
    fi
    
    if $icon_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to offer GTK theme installation
offer_gtk_theme() {
    echo
    print_section "GTK Theme Installation"
    
    if check_gtk_theme_installed; then
        print_success "GTK theme 'Graphite-Dark' is already installed."
        return
    else
        print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    fi
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to install the Graphite GTK theme?" "y"; then
        print_status "Launching the GTK theme installer..."
        
        # Check if install-gtk-theme.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}install-gtk-theme.sh" ] && [ -x "${SCRIPTS_PREFIX}install-gtk-theme.sh" ]; then
            ${SCRIPTS_PREFIX}install-gtk-theme.sh
        else
            print_status "Making GTK theme installer executable..."
            chmod +x ${SCRIPTS_PREFIX}install-gtk-theme.sh
            ${SCRIPTS_PREFIX}install-gtk-theme.sh
        fi
    else
        print_status "Skipping GTK theme installation. You can run it later with: ./scripts/install-gtk-theme.sh"
    fi
}

# Function to offer QT theme installation
offer_qt_theme() {
    echo
    print_section "QT Theme Installation"
    
    if check_qt_theme_installed; then
        print_success "QT theme 'Graphite-rimlessDark' is already installed."
        return
    else
        print_warning "QT theme is not installed. Your QT applications will not match your GTK theme."
    fi
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to install the Graphite QT/KDE theme?" "y"; then
        print_status "Launching the QT theme installer..."
        
        # Check if install-qt-theme.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}install-qt-theme.sh" ] && [ -x "${SCRIPTS_PREFIX}install-qt-theme.sh" ]; then
            ${SCRIPTS_PREFIX}install-qt-theme.sh
        else
            print_status "Making QT theme installer executable..."
            chmod +x ${SCRIPTS_PREFIX}install-qt-theme.sh
            ${SCRIPTS_PREFIX}install-qt-theme.sh
        fi
    else
        print_status "Skipping QT theme installation. You can run it later with: ./scripts/install-qt-theme.sh"
    fi
}

# Function to offer cursor installation
offer_cursor_install() {
    echo
    print_section "Cursor Installation"
    
    if check_cursor_theme_installed; then
        print_success "Cursor theme 'Bibata-Modern-Classic' is already installed."
        return
    else
        print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
    fi
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to install the Bibata cursors?" "y"; then
        print_status "Launching the cursor installer..."
        
        # Check if install-cursors.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}install-cursors.sh" ] && [ -x "${SCRIPTS_PREFIX}install-cursors.sh" ]; then
            ${SCRIPTS_PREFIX}install-cursors.sh
        else
            print_status "Making cursor installer executable..."
            chmod +x ${SCRIPTS_PREFIX}install-cursors.sh
            ${SCRIPTS_PREFIX}install-cursors.sh
        fi
    else
        print_status "Skipping cursor installation. You can run it later with: ./scripts/install-cursors.sh"
    fi
}

# Function to offer icon theme installation
offer_icon_theme_install() {
    echo
    print_section "Icon Theme Installation"
    
    if check_icon_theme_installed; then
        print_success "Fluent icon theme already installed."
        return
    else
        print_warning "Icon theme is not installed. Your system will use the default icon theme."
    fi
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    # Set the default variant - no user choice
    FLUENT_VARIANT="Fluent-grey"
    
    # Ask if user wants to install the icon theme
    if ask_yes_no "Would you like to install the $FLUENT_VARIANT icon theme?" "y"; then
        print_status "Installing $FLUENT_VARIANT icon theme..."
        
        # Check if install-icon-theme.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}install-icon-theme.sh" ] && [ -x "${SCRIPTS_PREFIX}install-icon-theme.sh" ]; then
            ${SCRIPTS_PREFIX}install-icon-theme.sh "fluent" "$FLUENT_VARIANT"
        else
            print_status "Making icon theme installer executable..."
            chmod +x ${SCRIPTS_PREFIX}install-icon-theme.sh
            ${SCRIPTS_PREFIX}install-icon-theme.sh "fluent" "$FLUENT_VARIANT"
        fi
    else
        print_status "Skipping icon theme installation. You can run it later with: ${SCRIPTS_PREFIX}install-icon-theme.sh fluent Fluent-grey"
    fi
}

# Function to offer Flatpak installation
offer_flatpak_install() {
    echo
    print_section "Flatpak Installation"
    
    # Determine if being run from a script in the scripts directory
    CURRENT_DIR=$(pwd)
    SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
    
    # Check where we're running from to use the correct path
    if [ "$SCRIPT_NAME" = "common_functions.sh" ] || [ "$(basename "$CURRENT_DIR")" = "scripts" ]; then
        # Running from scripts directory
        SCRIPTS_PREFIX="./"
    else
        # Running from main directory
        SCRIPTS_PREFIX="./scripts/"
    fi
    
    if ask_yes_no "Would you like to install Flatpak and set it up?" "y"; then
        print_status "Launching the Flatpak installer..."
        
        # Check if install-flatpak.sh exists and is executable
        if [ -f "${SCRIPTS_PREFIX}install-flatpak.sh" ] && [ -x "${SCRIPTS_PREFIX}install-flatpak.sh" ]; then
            ${SCRIPTS_PREFIX}install-flatpak.sh
        else
            print_status "Making Flatpak installer executable..."
            chmod +x ${SCRIPTS_PREFIX}install-flatpak.sh
            ${SCRIPTS_PREFIX}install-flatpak.sh
        fi
    else
        print_status "Skipping Flatpak installation. You can run it later with: ./scripts/install-flatpak.sh"
    fi
}

# Function to automatically set up themes
auto_setup_themes() {
    print_section "Automatic Theme Activation"
    print_status "Automatically applying themes..."
    
    # Detect icon theme first
    ICON_THEME="Fluent-grey"  # Default
    
    # Check for Fluent variants - if Fluent-grey bulunamadıysa diğer Fluent varyantlarına geçiş yapılsın
    if [ ! -d "/usr/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.local/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.icons/$ICON_THEME" ]; then
        local fluent_variants=("Fluent-dark" "Fluent" "Fluent-light")
        for variant in "${fluent_variants[@]}"; do
            if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ]; then
                print_status "Fluent-grey not found, using alternative Fluent variant: $variant"
                ICON_THEME="$variant"
                break
            fi
        done
    fi
    
    # Configure GTK theme
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # Set GTK3 theme
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    # Set GTK4 theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    print_success "Themes have been automatically applied!"
    print_status "You can still manually configure themes with: ./scripts/setup-themes.sh"
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}            HyprGraphite Help                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     A Nice Hyprland Rice Install Helper     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./install.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help${RESET}    Display this help message"
    echo
    
    # Show available scripts
    show_available_scripts
    
    # Show installation options
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}INSTALLATION PROCESS:${RESET}"
    echo -e "  1. The installer will auto-detect your Linux distribution"
    echo -e "  2. It will run the appropriate installation script for your distribution"
    echo -e "  3. You will be prompted to install theme components"
    echo -e "  4. Configuration files will be managed and installed"
    echo -e "  5. Themes will be activated if desired"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTE:${RESET}"
    echo -e "  You can run any of the scripts individually as needed"
    echo -e "  All scripts have good defaults for a quick installation"
} 