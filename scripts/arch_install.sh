#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               HyprGraphite Installer Script              │
# │                  Modern Hyprland Setup                   │
# ╰──────────────────────────────────────────────────────────╯

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

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
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

# Install AUR helper
install_aur_helper() {
    local helper="$1"
    
    # Install git if not installed
    if ! command_exists git; then
        print_status "Installing git..."
        sudo pacman -S --needed --noconfirm git base-devel
    fi
    
    case "$helper" in
        "yay")
            print_status "Cloning and building yay..."
            cd /tmp || exit
            rm -rf yay 2>/dev/null
    git clone https://aur.archlinux.org/yay.git
            cd yay || exit
    makepkg -si --noconfirm
            cd - >/dev/null || exit
            
            if command_exists yay; then
                print_success "yay has been installed successfully!"
                return 0
            else
                print_error "Failed to install yay!"
                return 1
            fi
            ;;
        "paru")
            print_status "Cloning and building paru..."
            cd /tmp || exit
            rm -rf paru 2>/dev/null
            git clone https://aur.archlinux.org/paru.git
            cd paru || exit
            makepkg -si --noconfirm
            cd - >/dev/null || exit
            
            if command_exists paru; then
                print_success "paru has been installed successfully!"
                return 0
            else
                print_error "Failed to install paru!"
                return 1
            fi
            ;;
        *)
            print_error "Unknown AUR helper: $helper"
            return 1
            ;;
    esac
}

# Function to install packages
install_packages() {
    local packages=("$@")
    
    if [ -z "$AUR_HELPER" ]; then
        print_error "No AUR helper selected."
        exit 1
    fi
    
    case "$AUR_HELPER" in
        "yay")
            print_status "Installing packages with yay..."
            yay -S --needed --noconfirm "${packages[@]}"
            ;;
        "paru")
            print_status "Installing packages with paru..."
            paru -S --needed --noconfirm "${packages[@]}"
            ;;
        "pacman")
            print_status "Installing packages with pacman..."
            sudo pacman -S --needed --noconfirm "${packages[@]}"
            ;;
        *)
            print_error "Unknown AUR helper: $AUR_HELPER"
            exit 1
            ;;
    esac
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Setup & Checks                                          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}       HyprGraphite Installation Wizard       ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Modern Hyprland Desktop Environment     ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

print_section "System Check"
print_status "Checking for AUR helpers..."

# Detect available AUR helpers
AUR_HELPERS=()
if command_exists yay; then
    AUR_HELPERS+=("yay")
fi
if command_exists paru; then
    AUR_HELPERS+=("paru")
fi

# Set default AUR helper
AUR_HELPER=""

# Choose AUR Helper
if [ ${#AUR_HELPERS[@]} -gt 0 ]; then
    # Display detected AUR helpers
    echo -e "\n${BRIGHT_PURPLE}${BOLD}AUR Helpers Detected:${RESET}"
    for helper in "${AUR_HELPERS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} ${helper}"
    done
    
    # If we have multiple helpers, let the user choose
    if [ ${#AUR_HELPERS[@]} -gt 1 ]; then
        # Add the options for the user to choose
        options=("${AUR_HELPERS[@]}" "pacman (no AUR support)")
        
        AUR_HELPER=$(ask_choice "Choose your preferred AUR helper:" "${options[@]}")
        
        if [[ "$AUR_HELPER" == "pacman (no AUR support)" ]]; then
            AUR_HELPER="pacman"
        fi
    else
        # Only one helper detected, use it
        AUR_HELPER="${AUR_HELPERS[0]}"
        print_success "Detected and using ${AUR_HELPER} as the AUR helper."
    fi
else
    # No AUR helper detected, offer to install one
    print_warning "No AUR helper detected."
    
    # Ask if the user wants to install an AUR helper
    if ask_yes_no "Would you like to install an AUR helper?" "y"; then
        print_section "AUR Helper Installation"
        
        # Show AUR helper options
        echo -e "${BRIGHT_PURPLE}${BOLD}Available AUR Helpers:${RESET}"
        echo -e "  ${BRIGHT_WHITE}1.${RESET} yay - Yet Another Yogurt - A modern AUR helper"
        echo -e "  ${BRIGHT_WHITE}2.${RESET} paru - Feature-packed AUR helper with all the bells and whistles"
        echo
        
        # Ask the user to choose an AUR helper
        echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select an AUR helper to install [1-2]: ${RESET}"
        read -r helper_choice
        
        case "$helper_choice" in
            "1"|"")
                helper="yay"
                ;;
            "2")
                helper="paru"
                ;;
            *)
                print_error "Invalid choice. Defaulting to yay."
                helper="yay"
                ;;
        esac
        
        print_status "Installing ${helper}..."
        
        if install_aur_helper "$helper"; then
            AUR_HELPER="$helper"
        else
            print_warning "Falling back to pacman (no AUR support)"
            AUR_HELPER="pacman"
        fi
    else
        print_warning "Using pacman without AUR support. Some packages may not be available."
        AUR_HELPER="pacman"
    fi
fi

# Verify AUR helper is set
if [ -z "$AUR_HELPER" ]; then
    print_error "Failed to set AUR helper. Falling back to pacman."
    AUR_HELPER="pacman"
fi

# Add "Press Enter to continue" after AUR helper setup
print_success "AUR helper ${BRIGHT_GREEN}${BOLD}${AUR_HELPER}${RESET}${GREEN} will be used for installation.${RESET}"
press_enter

print_section "Installation Options"

# Install Hyprland and related packages
print_section "Core Components Installation"
print_status "Installing Hyprland and required packages..."

# Hyprland base packages
hyprland_packages=(
    "hyprland" 
    "waypaper-git" 
    "hyprpicker" 
    "wf-recorder" 
    "grim"
    "waybar-cava" 
    "power-profiles-daemon" 
    "swww" 
    "libcava"
    "pipewire" 
    "pipewire-pulse" 
    "wireplumber" 
    "swayosd"
    "brightnessctl" 
    "pamixer" 
    "jq" 
    "ttf-roboto" 
    "wofi"
    "pavucontrol" 
    "libinput" 
    "qt5-base" 
    "qt6-base"
    "qt5-wayland" 
    "qt6-wayland" 
    "xdg-desktop-portal-hyprland"
    "nautilus"
    "nemo"
    "wl-clipboard"
    "slurp"
)

# Install Hyprland packages
install_packages "${hyprland_packages[@]}"

# Launcher packages
print_section "Application Launcher Installation"
print_status "Installing launcher packages..."
launcher_packages=(
    "wofi" 
    "rofi-wayland" 
    "ttf-nerd-fonts-symbols" 
    "ttf-firacode-nerd"
)
install_packages "${launcher_packages[@]}"

# Notification packages
print_section "Notification System Installation"
print_status "Installing notification packages..."
notification_packages=(
    "swaync" 
    "wlogout" 
    "ttf-fira-sans" 
    "jq" 
    "mpv" 
    "yad"
    "dbus" 
    "networkmanager" 
    "network-manager-applet" 
    "bluez"
    "polkit" 
    "lib32-polkit" 
    "polkit-gnome"
)
install_packages "${notification_packages[@]}"

# Terminal packages
print_section "Terminal Emulator Installation"
print_status "Installing terminal packages..."
terminal_packages=(
    "kitty" 
    "foot" 
    "fish" 
    "zsh" 
    "bash"
)
install_packages "${terminal_packages[@]}"

# File manager packages
print_section "File Manager Installation"
print_status "Installing file manager packages..."
file_manager_packages=(
    "nautilus" 
    "nemo" 
    "thunar" 
    "gvfs" 
    "gvfs-mtp" 
    "tumbler"
)
install_packages "${file_manager_packages[@]}"

# Post-installation steps
print_section "Post-Installation Setup"

# Add user to required groups
print_status "Adding user to video and audio groups..."
sudo usermod -aG video,audio "$(whoami)"

# Enable services
print_status "Enabling services..."
systemctl --user enable --now swayosd.service

# Restart pipewire
print_status "Restarting pipewire services..."
systemctl --user restart pipewire wireplumber

# Copy config files
if ask_yes_no "Copy configuration files to your home directory?" "y"; then
    print_status "Copying configuration files to ~/.config..."
    
    # Check if .config exists, create if not
    if [ ! -d "$HOME/.config" ]; then
        mkdir -p "$HOME/.config"
    fi
    
    # Create backup of existing config
    print_status "Creating backup of existing config files..."
    BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Copy existing config files to backup
    for dir in .config/*; do
        if [ -d "$dir" ]; then
            cp -r "$dir" "$BACKUP_DIR/" 2>/dev/null
        fi
    done
    
    # Copy config files
    cp -r .config/* "$HOME/.config/"
    
    print_success "Configuration files copied successfully!"
    print_status "Backup of your previous configuration is available at: ${BACKUP_DIR}"
fi

# Final success message
print_section "Installation Complete!"
echo -e "${BRIGHT_GREEN}${BOLD}✨ HyprGraphite installation has been completed successfully! ✨${RESET}"
echo
echo -e "${YELLOW}${BOLD}Next Steps:${RESET}"
echo -e "${BRIGHT_WHITE}  1. ${RESET}Restart your system to ensure all changes take effect"
echo -e "${BRIGHT_WHITE}  2. ${RESET}Start Hyprland by running ${BRIGHT_CYAN}'Hyprland'${RESET} or selecting it from your display manager"
echo -e "${BRIGHT_WHITE}  3. ${RESET}Enjoy your new desktop environment!"
echo

# Goodbye message
echo -e "${BRIGHT_PURPLE}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_GREEN}Thank you for choosing HyprGraphite!${RESET}               ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_WHITE}Report any issues at:${RESET}                              ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}║${RESET}  ${BRIGHT_CYAN}https://github.com/os-guy/HyprGraphite/issues${RESET}       ${BRIGHT_PURPLE}${BOLD}║${RESET}"
echo -e "${BRIGHT_PURPLE}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

exit 0 