#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │          HyprGraphite Cursor Installer                  │
# │          Install Bibata Cursors for Activation          │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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

# Function to select cursor variant
select_cursor_variant() {
    print_section "Select Bibata Cursor Variant"
    
    echo -e "${BRIGHT_WHITE}${BOLD}Available Variants:${RESET}"
    echo -e "  ${BRIGHT_CYAN}1.${RESET} ${BRIGHT_WHITE}Bibata-Modern-Classic${RESET} - Modern cursors with classic sharp edges"
    echo -e "  ${BRIGHT_CYAN}2.${RESET} ${BRIGHT_WHITE}Bibata-Modern-Ice${RESET} - Modern white cursors"
    echo -e "  ${BRIGHT_CYAN}3.${RESET} ${BRIGHT_WHITE}Bibata-Original-Classic${RESET} - Original cursors with classic sharp edges"
    echo -e "  ${BRIGHT_CYAN}4.${RESET} ${BRIGHT_WHITE}Bibata-Original-Ice${RESET} - Original white cursors"
    
    echo
    
    while true; do
        echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-4]: ${RESET}"
        read -r choice
        
        case "$choice" in
            1)
                echo "Bibata-Modern-Classic"
                return
                ;;
            2)
                echo "Bibata-Modern-Ice"
                return
                ;;
            3)
                echo "Bibata-Original-Classic"
                return
                ;;
            4)
                echo "Bibata-Original-Ice"
                return
                ;;
            *)
                print_error "Invalid choice. Please select a number between 1 and 4."
                ;;
        esac
    done
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

# Function to install Bibata cursors using package managers
install_via_package_manager() {
    print_section "Installing Bibata Cursor via Package Manager"
    
    case "$DISTRO_TYPE" in
        "arch")
            if command_exists paru; then
                print_status "Installing Bibata cursor theme using paru..."
                paru -S --needed --noconfirm bibata-cursor-theme-bin
            elif command_exists yay; then
                print_status "Installing Bibata cursor theme using yay..."
                yay -S --needed --noconfirm bibata-cursor-theme-bin
            else
                print_warning "No AUR helper found (paru/yay). Falling back to manual installation."
                return 1
            fi
            ;;
        "fedora")
            print_status "Enabling copr repository for Bibata cursors..."
            sudo dnf copr enable -y peterwu/rendezvous
            print_status "Installing Bibata cursor themes..."
            sudo dnf install -y bibata-cursor-themes
            ;;
        *)
            print_warning "No package manager installation method available for $DISTRO_TYPE. Falling back to manual installation."
            return 1
            ;;
    esac
    
    # Check if installation was successful
    if [ $? -eq 0 ]; then
        print_success "Bibata cursor theme installed successfully via package manager!"
        return 0
    else
        print_error "Failed to install via package manager. Falling back to manual installation."
        return 1
    fi
}

# Function to download and install Bibata cursors manually
install_bibata_manually() {
    local variant="$1"
    local tmp_dir="/tmp/bibata_cursor_install"
    local release_url="https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest"
    
    print_section "Manual Installation of Bibata Cursor Theme"
    
    # Create temporary directory
    print_status "Preparing temporary directory..."
    rm -rf "$tmp_dir" 2>/dev/null
    mkdir -p "$tmp_dir"
    
    # Check for curl or wget
    if command_exists curl; then
        print_status "Using curl to download data..."
        download_cmd="curl -L"
        json_cmd="curl -s"
    elif command_exists wget; then
        print_status "Using wget to download data..."
        download_cmd="wget -O -"
        json_cmd="wget -q -O -"
    else
        print_error "Neither curl nor wget found! Please install one of them and try again."
        return 1
    fi
    
    # Get latest release data
    print_status "Fetching latest release information..."
    
    # Parse the JSON to find the correct asset URL
    if command_exists jq; then
        print_status "Using jq to parse JSON data..."
        release_data=$(${json_cmd} "$release_url")
        asset_url=$(echo "$release_data" | jq -r '.assets[] | select(.name | contains("'$variant'")) | .browser_download_url')
    else
        print_status "jq not found, using grep and cut for basic parsing..."
        release_data=$(${json_cmd} "$release_url")
        # This is a very basic parsing and might not work in all cases
        asset_url=$(echo "$release_data" | grep -o "browser_download_url.*$variant.*tar.gz" | cut -d'"' -f4)
    fi
    
    if [ -z "$asset_url" ]; then
        print_error "Failed to find download URL for $variant!"
        print_status "Trying fixed URL pattern..."
        
        # Try to get tag name
        if command_exists jq; then
            tag_name=$(echo "$release_data" | jq -r '.tag_name')
        else
            tag_name=$(echo "$release_data" | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4)
        fi
        
        if [ -n "$tag_name" ]; then
            asset_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/$tag_name/$variant.tar.gz"
            print_status "Using URL: $asset_url"
        else
            print_error "Could not determine the latest version tag. Falling back to bibata.live website."
            print_status "Please visit https://bibata.live to download the latest version manually."
            return 1
        fi
    fi
    
    # Download the cursor theme
    print_status "Downloading $variant cursor theme..."
    ${download_cmd} "$asset_url" > "$tmp_dir/$variant.tar.gz"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to download the cursor theme!"
        print_status "Please visit https://bibata.live to download the latest version manually."
        return 1
    fi
    
    # Extract the archive
    print_status "Extracting cursor theme..."
    tar -xzf "$tmp_dir/$variant.tar.gz" -C "$tmp_dir"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to extract the cursor theme!"
        return 1
    fi
    
    # Create icons directory if it doesn't exist
    print_status "Setting up directories..."
    mkdir -p "$HOME/.local/share/icons"
    
    # Copy the cursor theme
    print_status "Installing cursor theme to user directory..."
    cp -r "$tmp_dir/$variant" "$HOME/.local/share/icons/"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to copy the cursor theme to icons directory!"
        return 1
    fi
    
    # Clean up
    print_status "Cleaning up temporary files..."
    rm -rf "$tmp_dir"
    
    print_success "Bibata cursor theme ($variant) has been installed successfully!"
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
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script installs the Bibata cursor theme on your system."
    echo -e "  It will first try to use your distribution's package manager,"
    echo -e "  and if that fails, it will download and install the theme manually."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}AVAILABLE CURSOR VARIANTS:${RESET}"
    echo -e "  • Bibata-Modern-Classic"
    echo -e "  • Bibata-Modern-Ice"
    echo -e "  • Bibata-Original-Classic"
    echo -e "  • Bibata-Original-Ice"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SOURCE:${RESET}"
    echo -e "  The Bibata cursors are created by ${BRIGHT_CYAN}ful1e5${RESET}"
    echo -e "  Source: ${BRIGHT_CYAN}https://github.com/ful1e5/Bibata_Cursor${RESET}"
    
    exit 0
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Script                                             ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_help
fi

# Clear the screen
clear

# Print banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}          Bibata Cursor Installer           ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}      Install cursors for later activation   ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

# Detect distribution
print_section "System Detection"
detect_distro
print_status "Detected: $OS_NAME (Type: $DISTRO_TYPE)"

# Ask user to select cursor variant
cursor_variant=$(select_cursor_variant)
print_success "Selected cursor variant: $cursor_variant"

# Try to install via package manager first
print_section "Installation Method"
if [ "$DISTRO_TYPE" = "arch" ] || [ "$DISTRO_TYPE" = "fedora" ]; then
    if ask_yes_no "Do you want to try installing via package manager first?" "y"; then
        if install_via_package_manager; then
            # Package manager installation successful
            print_section "Next Steps"
            print_status "The Bibata cursor theme has been installed successfully!"
            print_status "To activate the theme, run:"
            echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
            print_status "And select the 'Activate Bibata Cursors' option."
            
            print_success "Installation completed!"
            press_enter
            exit 0
        fi
    else
        print_status "Skipping package manager installation."
    fi
else
    print_status "No package manager installation method available for your distribution."
fi

# Manual installation
if ask_yes_no "Do you want to install the cursor theme manually?" "y"; then
    if install_bibata_manually "$cursor_variant"; then
        # Manual installation successful
        print_section "Next Steps"
        print_status "The Bibata cursor theme has been installed successfully!"
        print_status "To activate the theme, run:"
        echo -e "  ${BRIGHT_CYAN}./scripts/setup-themes.sh${RESET}"
        print_status "And select the 'Activate Bibata Cursors' option."
        
        print_success "Installation completed!"
        press_enter
        exit 0
    else
        print_error "Manual installation failed."
        print_status "Please try visiting https://bibata.live to download and install manually."
        exit 1
    fi
else
    print_status "Installation cancelled."
    exit 0
fi 