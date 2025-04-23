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
        print_status "Configuring file manager..."
        "$(dirname "$0")/configure-file-manager.sh"
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
    print_status "Installing theme components..."
    
    # Use absolute paths to locate scripts
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    SCRIPT_DIR="$REPO_ROOT/scripts"
    
    # If scripts directory still not found, try backup methods
    if [ ! -d "$SCRIPT_DIR" ]; then
        print_warning "Cannot locate scripts directory using primary method."
        # Get the current script's path
        CURRENT_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
        SCRIPT_DIR=$(dirname "$CURRENT_SCRIPT_PATH")
        print_status "Trying alternate method: $SCRIPT_DIR"
    fi
    
    # Last resort - use PWD and manually construct path
    if [ ! -d "$SCRIPT_DIR" ]; then
        print_warning "Cannot locate scripts directory using alternate method."
        CURRENT_DIR=$(pwd)
        
        # Check if we're in HyprGraphite root
        if [ -d "$CURRENT_DIR/scripts" ]; then
            SCRIPT_DIR="$CURRENT_DIR/scripts"
        # Check if we're in scripts directory
        elif [ -d "$CURRENT_DIR" ] && [ $(basename "$CURRENT_DIR") = "scripts" ]; then
            SCRIPT_DIR="$CURRENT_DIR"
        # Last resort
        else
            print_warning "Using hard-coded path as last resort."
            SCRIPT_DIR="/home/sd-v/git-repos/HyprGraphite/scripts"
        fi
    fi
    
    print_status "Using scripts directory: $SCRIPT_DIR"
    
    # Detect system type for sudo usage
    if grep -q "ID=fedora" /etc/os-release 2>/dev/null; then
        USING_SUDO=""
    else
        USING_SUDO="sudo"
    fi
    
    # Install GTK theme
    print_status "Installing Graphite GTK theme..."
    GTK_THEME_SCRIPT="$SCRIPT_DIR/install-gtk-theme.sh"
    
    if [ -f "$GTK_THEME_SCRIPT" ]; then
        if [ ! -x "$GTK_THEME_SCRIPT" ]; then
            print_status "Making GTK theme installer executable..."
            chmod +x "$GTK_THEME_SCRIPT"
        fi
        
        if [ -n "$USING_SUDO" ]; then
            $USING_SUDO "$GTK_THEME_SCRIPT"
        else
            "$GTK_THEME_SCRIPT"
        fi
    else
        print_error "GTK theme installer not found at: $GTK_THEME_SCRIPT"
        print_status "Checking for theme installer script in alternative locations..."
        for alt_path in "./scripts/install-gtk-theme.sh" "/home/sd-v/git-repos/HyprGraphite/scripts/install-gtk-theme.sh" "./install-gtk-theme.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found theme installer at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
        if [ -n "$USING_SUDO" ]; then
                    $USING_SUDO "$alt_path"
        else
                    "$alt_path"
                fi
                break
        fi
        done
    fi
    
    # Install QT theme
    print_status "Installing Graphite QT theme for QT applications..."
    QT_THEME_SCRIPT="$SCRIPT_DIR/install-qt-theme.sh"
    
    if [ -f "$QT_THEME_SCRIPT" ]; then
        if [ ! -x "$QT_THEME_SCRIPT" ]; then
            print_status "Making QT theme installer executable..."
            chmod +x "$QT_THEME_SCRIPT"
        fi
        
        if [ -n "$USING_SUDO" ]; then
            $USING_SUDO "$QT_THEME_SCRIPT"
        else
            "$QT_THEME_SCRIPT"
        fi
    else
        print_error "QT theme installer not found at: $QT_THEME_SCRIPT"
        print_status "Checking for theme installer script in alternative locations..."
        for alt_path in "./scripts/install-qt-theme.sh" "/home/sd-v/git-repos/HyprGraphite/scripts/install-qt-theme.sh" "./install-qt-theme.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found theme installer at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
        if [ -n "$USING_SUDO" ]; then
                    $USING_SUDO "$alt_path"
        else
                    "$alt_path"
                fi
                break
        fi
        done
    fi
    
    # Install cursors
    print_status "Installing Bibata cursors..."
    CURSOR_SCRIPT="$SCRIPT_DIR/install-cursors.sh"
    
    if [ -f "$CURSOR_SCRIPT" ]; then
        if [ ! -x "$CURSOR_SCRIPT" ]; then
            print_status "Making cursor installer executable..."
            chmod +x "$CURSOR_SCRIPT"
        fi
        
        # Never use sudo for cursor installation
        print_status "Running cursor installation script directly (without sudo)..."
        "$CURSOR_SCRIPT"
        else
        print_error "Cursor installer not found at: $CURSOR_SCRIPT"
        print_status "Checking for cursor installer script in alternative locations..."
        for alt_path in "./scripts/install-cursors.sh" "/home/sd-v/git-repos/HyprGraphite/scripts/install-cursors.sh" "./install-cursors.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found cursor installer at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
                # Never use sudo for cursor installation
                print_status "Running cursor installation script directly (without sudo)..."
                "$alt_path"
                break
            fi
        done
    fi
    
    # Install icon theme
    print_status "Installing Fluent icon theme..."
    ICON_THEME_SCRIPT="$SCRIPT_DIR/install-icon-theme.sh"
    
    if [ -f "$ICON_THEME_SCRIPT" ]; then
        if [ ! -x "$ICON_THEME_SCRIPT" ]; then
            print_status "Making icon theme installer executable..."
            chmod +x "$ICON_THEME_SCRIPT"
        fi
        
        # Never use sudo for icon theme installation
        print_status "Running icon theme installation script directly (without sudo)..."
        "$ICON_THEME_SCRIPT"
    else
        print_error "Icon theme installer not found at: $ICON_THEME_SCRIPT"
        print_status "Checking for icon theme installer script in alternative locations..."
        for alt_path in "./scripts/install-icon-theme.sh" "/home/sd-v/git-repos/HyprGraphite/scripts/install-icon-theme.sh" "./install-icon-theme.sh"; do
            if [ -f "$alt_path" ]; then
                print_status "Found icon theme installer at: $alt_path"
                if [ ! -x "$alt_path" ]; then
                    chmod +x "$alt_path"
                fi
                
                # Never use sudo for icon theme installation
                print_status "Running icon theme installation script directly (without sudo)..."
                "$alt_path"
                break
            fi
        done
    fi
}

# Function to setup configuration files
setup_configuration() {
    print_section "Configuration Setup"
    print_status "Running configuration script..."
    
    # Use absolute paths to locate scripts
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    SCRIPT_DIR="$REPO_ROOT/scripts"
    
    # If scripts directory still not found, try backup methods
    if [ ! -d "$SCRIPT_DIR" ]; then
        print_warning "Cannot locate scripts directory using primary method."
        # Get the current script's path
        CURRENT_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
        SCRIPT_DIR=$(dirname "$CURRENT_SCRIPT_PATH")
        print_status "Trying alternate method: $SCRIPT_DIR"
    fi
    
    # Last resort - use PWD and manually construct path
    if [ ! -d "$SCRIPT_DIR" ]; then
        print_warning "Cannot locate scripts directory using alternate method."
        CURRENT_DIR=$(pwd)
        
        # Check if we're in HyprGraphite root
        if [ -d "$CURRENT_DIR/scripts" ]; then
            SCRIPT_DIR="$CURRENT_DIR/scripts"
        # Check if we're in scripts directory
        elif [ -d "$CURRENT_DIR" ] && [ $(basename "$CURRENT_DIR") = "scripts" ]; then
            SCRIPT_DIR="$CURRENT_DIR"
        # Last resort
        else
            print_warning "Using hard-coded path as last resort."
            SCRIPT_DIR="/home/sd-v/git-repos/HyprGraphite/scripts"
        fi
    fi
    
    print_status "Using scripts directory: $SCRIPT_DIR"
    CONFIG_SCRIPT="$SCRIPT_DIR/copy-configs.sh"
    
    if [ -f "$CONFIG_SCRIPT" ]; then
        if [ ! -x "$CONFIG_SCRIPT" ]; then
            print_status "Making configuration script executable..."
            chmod +x "$CONFIG_SCRIPT"
        fi
        
        "$CONFIG_SCRIPT"
    else
        print_error "Configuration script not found at: $CONFIG_SCRIPT"
        print_status "Checking for configuration script in alternative locations..."
        for alt_path in "./scripts/copy-configs.sh" "/home/sd-v/git-repos/HyprGraphite/scripts/copy-configs.sh" "./copy-configs.sh"; do
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
} 