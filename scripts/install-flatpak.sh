#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure Flatpak"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs Flatpak, a cross-distribution application deployment"
    echo -e "    system that provides sandboxed applications."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}FEATURES${RESET}"
    echo -e "    - Automatic distribution detection"
    echo -e "    - Flathub repository setup"
    echo -e "    - Common Flatpak application suggestions"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    This script must be run as root to install system packages."
    echo
    exit 0
fi

# Define command_exists if not already defined
if ! declare -f command_exists >/dev/null; then
    # Check if a command exists
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }
fi

# ╭──────────────────────────────────────────────────────────╮
# │                  Flatpak Installation                    │
# │          Cross-Distribution Application Manager          │
# ╰──────────────────────────────────────────────────────────╯

#==================================================================
# Privilege Check
#==================================================================
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

#==================================================================
# Helper Functions
#==================================================================

# Function to retry flatpak installation if it fails
retry_flatpak_install() {
    case "$distro" in
        "arch"|"endeavouros"|"manjaro"|"garuda"|"arcolinux"|"artix"|"archcraft")
            print_status "Installing Flatpak for Arch-based distribution..."
            pacman -S --needed --noconfirm flatpak
            ;;
        "debian"|"ubuntu"|"pop"|"linuxmint"|"elementary"|"zorin"|"kali"|"parrot"|"deepin"|"mx"|"peppermint")
            print_status "Installing Flatpak for Debian-based distribution..."
            apt update
            apt install -y flatpak
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"alma")
            print_status "Installing Flatpak for Fedora/RHEL-based distribution..."
            dnf install -y flatpak
            ;;
        "opensuse"|"suse")
            print_status "Installing Flatpak for openSUSE..."
            zypper install -y flatpak
            ;;
        "void")
            print_status "Installing Flatpak for Void Linux..."
            xbps-install -Sy flatpak
            ;;
        "alpine")
            print_status "Installing Flatpak for Alpine Linux..."
            apk add flatpak
            ;;
        "gentoo")
            print_status "Installing Flatpak for Gentoo Linux..."
            emerge --ask=n sys-apps/flatpak
            ;;
        *)
            print_status "Distribution not explicitly recognized, trying to detect package manager..."
            if command_exists apt; then
                print_status "APT detected, assuming Debian-based..."
                apt update && apt install -y flatpak
            elif command_exists dnf; then
                print_status "DNF detected, assuming Fedora-based..."
                dnf install -y flatpak
            elif command_exists pacman; then
                print_status "Pacman detected, assuming Arch-based..."
                pacman -S --needed --noconfirm flatpak
            elif command_exists zypper; then
                print_status "Zypper detected, assuming openSUSE..."
                zypper install -y flatpak
            elif command_exists xbps-install; then
                print_status "XBPS detected, assuming Void Linux..."
                xbps-install -Sy flatpak
            elif command_exists apk; then
                print_status "APK detected, assuming Alpine Linux..."
                apk add flatpak
            elif command_exists emerge; then
                print_status "Portage detected, assuming Gentoo..."
                emerge --ask=n sys-apps/flatpak
            else
                print_error "No known package manager found."
                return 1
            fi
            ;;
    esac
}

# Function to retry adding Flathub repository if it fails
retry_flathub_add() {
    print_status "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [ $? -eq 0 ]; then
        print_success "Flathub repository added successfully."
    else
        print_error "Failed to add Flathub repository."
        return 1
    fi
}

#==================================================================
# Welcome Message
#==================================================================
echo
echo -e "${BRIGHT_CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}│${RESET}              ${BOLD}${BRIGHT_YELLOW}Flatpak Installation Setup${RESET}              ${BRIGHT_CYAN}│${RESET}"
echo -e "${BRIGHT_CYAN}├──────────────────────────────────────────────────────────┤${RESET}"
echo -e "${BRIGHT_CYAN}│${RESET}  ${BRIGHT_WHITE}Sandboxed application deployment across distributions${RESET}  ${BRIGHT_CYAN}│${RESET}"
echo -e "${BRIGHT_CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
echo

#==================================================================
# Distribution Detection
#==================================================================
print_section "1. Distribution Detection"
print_info "Identifying your Linux distribution for compatibility"

# Enhanced OS detection variables
distro=""
distro_version=""
distro_name=""

# First try /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro="${ID,,}" # Convert to lowercase
    distro_version="$VERSION_ID"
    distro_name="$NAME"
    
    # Handle specific distribution variants
    case "$distro" in
        # Handle Ubuntu-based distributions
        "ubuntu"|"ubuntu-budgie"|"kubuntu"|"xubuntu"|"lubuntu"|"ubuntu-mate"|"ubuntu-gnome")
            distro="ubuntu"
            ;;
        # Handle Debian-based distributions that don't set ID properly
        "linuxmint"|"elementary"|"pop"|"zorin"|"kali"|"parrot"|"deepin"|"mx"|"peppermint")
            # These already have their ID set correctly
            ;;
        # Handle Arch-based distributions
        "manjaro"|"endeavouros"|"garuda"|"arcolinux"|"artix"|"archcraft"|"archbang")
            # These already have their ID set correctly
            ;;
        # Handle special case for ID_LIKE
        *)
            # If ID isn't specific enough, check ID_LIKE for family
            if [ -n "$ID_LIKE" ]; then
                if [[ "$ID_LIKE" == *"arch"* ]]; then
                    print_status "Distribution '$distro' is Arch-based according to ID_LIKE"
                    distro="arch"
                elif [[ "$ID_LIKE" == *"debian"* ]]; then
                    print_status "Distribution '$distro' is Debian-based according to ID_LIKE"
                    distro="debian" 
                elif [[ "$ID_LIKE" == *"fedora"* ]]; then
                    print_status "Distribution '$distro' is Fedora-based according to ID_LIKE"
                    distro="fedora"
                elif [[ "$ID_LIKE" == *"ubuntu"* ]]; then
                    print_status "Distribution '$distro' is Ubuntu-based according to ID_LIKE"
                    distro="ubuntu"
                fi
            fi
            ;;
    esac
# If /etc/os-release doesn't exist, try lsb_release
elif command_exists lsb_release; then
    distro_raw=$(lsb_release -si)
    distro="${distro_raw,,}" # Convert to lowercase
    distro_version=$(lsb_release -sr)
    distro_name="$distro_raw $distro_version"
    
    # Map some common LSB names to our standard IDs
    case "$distro" in
        "archlinux")
            distro="arch"
            ;;
        "manjarolinux")
            distro="manjaro"
            ;;
        "debian"|"ubuntu")
            # Keep these as-is
            ;;
        "fedora")
            # Keep as-is
            ;;
    esac
# Try /etc/issue as a last resort
elif [ -f /etc/issue ]; then
    issue=$(cat /etc/issue)
    issue_lower="${issue,,}" # Convert to lowercase
    
    if [[ "$issue_lower" == *"arch"* ]]; then
        distro="arch"
    elif [[ "$issue_lower" == *"debian"* ]]; then
        distro="debian"
    elif [[ "$issue_lower" == *"ubuntu"* ]]; then
        distro="ubuntu"
    elif [[ "$issue_lower" == *"fedora"* ]]; then
        distro="fedora"
    elif [[ "$issue_lower" == *"manjaro"* ]]; then
        distro="manjaro"
    fi
    
    # Try to extract version from issue
    if [[ "$issue" =~ [0-9]+\.[0-9]+ ]]; then
        distro_version="${BASH_REMATCH[0]}"
    fi
    
    distro_name="$issue"
else
    # Last resort: check for common package managers
    if command_exists pacman; then
        distro="arch"
        distro_name="Arch-based"
    elif command_exists apt; then
        distro="debian"
        distro_name="Debian-based"
    elif command_exists dnf; then
        distro="fedora"
        distro_name="Fedora-based"
    elif command_exists yum; then
        distro="fedora"
        distro_name="Red Hat-based"
    else
        print_error "Cannot detect OS. Please install Flatpak manually for your distribution."
        exit 1
    fi
fi

# If we still don't have a distro, report error
if [ -z "$distro" ]; then
    print_error "Cannot detect OS distribution."
    exit 1
fi

print_success "Detected distribution: $distro_name (ID: $distro, Version: $distro_version)"

#==================================================================
# Flatpak Installation Check
#==================================================================
print_section "2. Flatpak Availability"
print_info "Checking if Flatpak is already installed"

# Check if Flatpak is already installed
if command_exists flatpak; then
    print_success "Flatpak is already installed on your system."
    flatpak_version=$(flatpak --version)
    print_status "Flatpak version: $flatpak_version"
else
    print_status "Flatpak is not installed. Installing now..."
    
    # Try to install Flatpak
    if retry_flatpak_install; then
        print_success "Flatpak installed successfully."
    else
        print_error "Failed to install Flatpak. Please install it manually."
                exit 1
    fi
fi

#==================================================================
# Flathub Repository Setup
#==================================================================
print_section "3. Flathub Repository Setup"
print_info "Ensuring Flathub repository is configured"

# Check if Flathub is already added
if flatpak remotes | grep -q "flathub"; then
    print_success "Flathub repository is already configured."
else
    print_status "Flathub repository not found. Adding now..."
    
    # Try to add Flathub repository
    if retry_flathub_add; then
        print_success "Flathub repository added successfully."
    else
        print_error "Failed to add Flathub repository. Please add it manually."
        print_status "You can add it with: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
        exit 1
    fi
fi

#==================================================================
# System Integration
#==================================================================
print_section "4. System Integration"
print_info "Setting up Flatpak system integration"

# Check for common integration issues
if [ ! -f "/etc/profile.d/flatpak.sh" ]; then
    print_status "Creating Flatpak environment profile script..."
    
    # Create environment script for Flatpak
    cat > /tmp/flatpak.sh << 'EOF'
# Flatpak environment variables
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
EOF
    
    # Install the environment script
    if ! mv /tmp/flatpak.sh /etc/profile.d/flatpak.sh; then
        print_error "Failed to create Flatpak environment script. Please add this manually:"
        print_status "export XDG_DATA_DIRS=\"\$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:\$HOME/.local/share/flatpak/exports/share\""
    else
        chmod 644 /etc/profile.d/flatpak.sh
        print_success "Created Flatpak environment script."
    fi
else
    print_success "Flatpak environment script already exists."
fi

# Install portals if needed
print_status "Checking for XDG desktop portal..."
if ! flatpak info org.freedesktop.Platform &>/dev/null; then
    print_status "Installing XDG desktop portal..."
    flatpak install -y flathub org.freedesktop.Platform
fi

#==================================================================
# Basic Flatpak Applications
#==================================================================
print_section "5. Useful Flatpak Applications"
print_info "Recommended applications available via Flatpak"

# Function to offer application installation
offer_flatpak_app() {
    local app_id="$1"
    local app_name="$2"
    local app_desc="$3"
    
    echo -e "\n${BRIGHT_WHITE}${BOLD}$app_name${RESET} - $app_desc"
    
    if flatpak info "$app_id" &>/dev/null; then
        print_success "$app_name is already installed."
        return 0
    fi
    
    if ask_yes_no "Would you like to install $app_name?" "y"; then
        print_status "Installing $app_name..."
        if flatpak install -y flathub "$app_id"; then
            print_success "$app_name installed successfully."
        else
            print_error "Failed to install $app_name."
        fi
    else
        print_status "Skipping $app_name installation."
    fi
}

# Offer essential applications
offer_flatpak_app "org.mozilla.firefox" "Firefox" "Web browser from Mozilla"
offer_flatpak_app "org.libreoffice.LibreOffice" "LibreOffice" "Office suite"
offer_flatpak_app "org.gimp.GIMP" "GIMP" "Image editor"
offer_flatpak_app "org.inkscape.Inkscape" "Inkscape" "Vector graphics editor"
offer_flatpak_app "org.kde.okular" "Okular" "Document viewer"
offer_flatpak_app "com.github.tchx84.Flatseal" "Flatseal" "Manage Flatpak permissions"

# Ask about more apps
if ask_yes_no "Would you like to see more recommended applications?" "n"; then
    offer_flatpak_app "com.spotify.Client" "Spotify" "Music streaming service"
    offer_flatpak_app "com.discordapp.Discord" "Discord" "Voice, video and text chat"
    offer_flatpak_app "org.telegram.desktop" "Telegram" "Messaging app"
    offer_flatpak_app "org.videolan.VLC" "VLC" "Media player"
    offer_flatpak_app "org.kde.krita" "Krita" "Digital painting"
    offer_flatpak_app "io.github.shiftey.Desktop" "GitHub Desktop" "GitHub desktop client"
    offer_flatpak_app "com.obsproject.Studio" "OBS Studio" "Streaming and recording"
    offer_flatpak_app "net.cozic.joplin_desktop" "Joplin" "Note-taking app"
fi

#==================================================================
# Completion
#==================================================================
print_section "Flatpak Installation Complete"
print_status "Flatpak setup complete."
echo

print_success_banner "Flatpak has been successfully set up on your system!"

echo
echo -e "${BRIGHT_WHITE}${BOLD}Next steps:${RESET}"
echo -e "  ${BRIGHT_WHITE}•${RESET} Install applications using ${BRIGHT_CYAN}flatpak install <app_id>${RESET}"
echo -e "  ${BRIGHT_WHITE}•${RESET} Update Flatpak applications with ${BRIGHT_CYAN}flatpak update${RESET}"
echo -e "  ${BRIGHT_WHITE}•${RESET} Launch applications from your app menu or with ${BRIGHT_CYAN}flatpak run <app_id>${RESET}"
echo
echo -e "${BRIGHT_WHITE}${BOLD}Example applications to try:${RESET}"
echo -e "  ${BRIGHT_CYAN}flatpak install flathub org.mozilla.firefox${RESET} - Firefox browser"
echo -e "  ${BRIGHT_CYAN}flatpak install flathub org.libreoffice.LibreOffice${RESET} - Office suite"
echo -e "  ${BRIGHT_CYAN}flatpak install flathub org.gimp.GIMP${RESET} - Image editor"
echo

# Exit with success
exit 0