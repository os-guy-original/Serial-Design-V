#!/bin/bash

# Source common functions
# Check if common_functions.sh exists in the utils directory
if [ -f "$(dirname "$0")/../utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../utils/common_functions.sh"
# Check if common_functions.sh exists in the scripts/utils directory
elif [ -f "$(dirname "$0")/../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../scripts/utils/common_functions.sh"
# Check if it exists in the parent directory's scripts/utils directory
elif [ -f "$(dirname "$0")/../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../scripts/utils/common_functions.sh"
# As a last resort, try the scripts/utils directory relative to current directory
elif [ -f "scripts/utils/common_functions.sh" ]; then
    source "scripts/utils/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    echo "Looked in: $(dirname "$0")/../utils/, $(dirname "$0")/../../scripts/utils/, $(dirname "$0")/../../../scripts/utils/, scripts/utils/"
    exit 1
fi

# Source common functions
# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install and configure Flatpak"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs Flatpak, a cross-distribution application deployment"
    echo -e "    system that provides sandboxed applications."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}FEATURES${RESET}"
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
# Welcome Message
#==================================================================
echo
print_banner "Flatpak Installation Setup" "Sandboxed application deployment for Arch Linux"
echo

#==================================================================
# Flatpak Installation
#==================================================================
print_section "1. Flatpak Installation"
print_info "Installing Flatpak package manager"

# Check if Flatpak is already installed
if command_exists flatpak && flatpak --version &>/dev/null; then
    print_success "Flatpak is already installed on your system."
    flatpak_version=$(flatpak --version)
    print_status "Flatpak version: $flatpak_version"
else
    print_status "Installing Flatpak using pacman..."
    
    # Install Flatpak using pacman
    if pacman -S --needed --noconfirm flatpak; then
        print_success "Flatpak installed successfully."
    else
        print_error "Failed to install Flatpak. Please check your system."
        exit 1
    fi
fi

#==================================================================
# Flathub Repository Setup
#==================================================================
print_section "2. Flathub Repository Setup"
print_info "Ensuring Flathub repository is configured"

# Check if Flathub is already added
if flatpak remotes | grep -q "flathub"; then
    print_success "Flathub repository is already configured."
else
    print_status "Adding Flathub repository..."
    
    # Try to add Flathub repository with better error handling
    for attempt in {1..3}; do
        print_status "Attempt $attempt to add Flathub repository..."
        
        # Make sure flatpak service is running
        systemctl is-active --quiet flatpak > /dev/null 2>&1 || systemctl start flatpak > /dev/null 2>&1
        
        if flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
            print_success "Flathub repository added successfully (user-level)."
            break
        elif flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
            print_success "Flathub repository added successfully (system-level)."
            break
        else
            if [ $attempt -eq 3 ]; then
                print_error "Failed to add Flathub repository after multiple attempts."
                print_status "You can add it manually with: flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
                
                if ask_yes_no "Would you like to continue with the script anyway?" "y"; then
                    print_status "Continuing with script execution..."
                else
                    print_error "Exiting script due to Flathub repository setup failure."
                    exit 1
                fi
            else
                print_warning "Failed to add Flathub repository. Retrying in 3 seconds..."
                sleep 3
            fi
        fi
    done
fi

#==================================================================
# System Integration
#==================================================================
print_section "3. System Integration"
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

#==================================================================
# Basic Flatpak Applications
#==================================================================
print_section "4. Useful Flatpak Applications"
print_info "Recommended applications available via Flatpak"

# First ask if the user wants to skip all application installations
if ask_yes_no "Would you like to skip all application installations?" "y"; then
    print_status "Skipping all application installations."
else
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
