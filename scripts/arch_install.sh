#!/bin/bash

BASE_DIR="$(pwd)"

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │                 Serial Design V Installer                   │
# │         A Modern Hyprland Desktop Environment            │
# ╰──────────────────────────────────────────────────────────╯

#==================================================================
# Helper Functions
#==================================================================

install_aur_helper() {
    local helper_name="$1"
    print_status "Installing $helper_name from AUR..."
    
    # Create a temporary directory for building
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || {
        print_error "Failed to create temporary directory"
        return 1
    }
    
    # Clone the AUR package
    if ! git clone "https://aur.archlinux.org/${helper_name}.git"; then
        print_error "Failed to clone ${helper_name} repository"
        return 1
    fi
    
    # Enter the directory and build
    cd "${helper_name}" || {
        print_error "Failed to enter ${helper_name} directory"
        return 1
    }
    
    # Build and install
    if ! makepkg -si --noconfirm; then
        print_error "Failed to build and install ${helper_name}"
        return 1
    fi
    
    # Clean up
    cd / || true
    rm -rf "$tmp_dir"
    
    print_success "${helper_name} installed successfully"
    return 0
}

# Function to handle package conflicts and network issues
handle_package_installation() {
    local packages=("$@")
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        print_status "Attempting to install packages (attempt $((retry_count+1)) of $max_retries)..."
        
        if ! install_packages "${packages[@]}"; then
            retry_count=$((retry_count+1))
            
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Installation failed. This could be due to network issues or package conflicts."
                print_status "Checking network connectivity..."
                
                # Check network connectivity
                if ! ping -c 1 archlinux.org &>/dev/null; then
                    print_error "Network connectivity issue detected."
                    if ask_yes_no "Would you like to retry after waiting for network?" "y"; then
                        print_status "Waiting for 10 seconds before retrying..."
                        sleep 10
                        continue
                    fi
                else
                    print_status "Network seems to be working."
                    # Check for package conflicts
                    if ask_yes_no "Would you like to try installing packages one by one to identify conflicts?" "y"; then
                        print_status "Installing packages individually..."
                        local failed_packages=()
                        for pkg in "${packages[@]}"; do
                            print_status "Installing $pkg..."
                            if ! install_packages "$pkg"; then
                                print_warning "Failed to install $pkg. Skipping."
                                failed_packages+=("$pkg")
                            else
                                print_success "Successfully installed $pkg."
                            fi
                        done
                        
                        if [ ${#failed_packages[@]} -eq 0 ]; then
                            print_success "All packages were installed successfully!"
                            return 0
                        else
                            print_warning "Some packages could not be installed:"
                            for pkg in "${failed_packages[@]}"; do
                                echo "  - $pkg"
                            done
                            
                            if ask_yes_no "Continue with installation \(skipping failed packages\)?" "y"; then
                                print_warning "Continuing installation without failed packages."
                                return 0
                            else
                                print_error "Installation aborted by user."
                                return 1
                            fi
                        fi
                    else
                        # Try again with the whole group
                        print_status "Retrying complete package group..."
                        continue
                    fi
                fi
            else
                print_error "Failed to install packages after $max_retries attempts."
                if ! ask_yes_no "Continue with installation \(some features may not work\)?" "y"; then
                    print_error "Installation aborted by user."
                    return 1
                fi
                return 0
            fi
        else
            print_success "Packages installed successfully!"
            return 0
        fi
    done
    
    return 1
}

#==================================================================
# Pre-Installation Checks
#==================================================================

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    print_warning "Please run without sudo. The script will ask for privileges when needed."
    exit 1
fi

# Clear the screen for a fresh start
clear

# Print welcome banner
print_banner "Serial Design V - Arch Linux Installation" "A modern and feature-rich Hyprland desktop environment"

#==================================================================
# 1. AUR Helper Setup
#==================================================================
print_section "1. AUR Helper Setup"
print_status "Checking for AUR helpers..."

# If AUR_HELPER is not set, run the detector script
if [ -z "$AUR_HELPER" ]; then
    # Run the AUR helper detector script
    AUR_DETECTOR_SCRIPT="$(dirname "$0")/detect-aur-helper.sh"
    
    if [ -f "$AUR_DETECTOR_SCRIPT" ]; then
        if [ ! -x "$AUR_DETECTOR_SCRIPT" ]; then
            chmod +x "$AUR_DETECTOR_SCRIPT"
        fi
        
        # Run the detector script directly to show the UI
        source "$AUR_DETECTOR_SCRIPT"
    else
        print_error "AUR helper detector script not found at: $AUR_DETECTOR_SCRIPT"
        # Fallback to pacman if script not found
        export AUR_HELPER="pacman"
        print_warning "No AUR helper found, using pacman (limited functionality)"
    fi
else
    print_status "Using AUR helper: $AUR_HELPER"
fi

# Export AUR_HELPER for use in common_functions.sh
export AUR_HELPER
cd "$BASE_DIR"

#==================================================================
# 2. Chaotic-AUR Setup
#==================================================================
print_section "2. Chaotic-AUR Setup"
print_info "Chaotic-AUR provides pre-built AUR packages, saving compile time"

if ask_yes_no "Would you like to set up Chaotic-AUR? \(Recommended\)" "y"; then
    if [ -f "./scripts/install-chaotic-aur.sh" ] && [ -x "./scripts/install-chaotic-aur.sh" ]; then
        sudo ./scripts/install-chaotic-aur.sh
    else
        print_status "Making Chaotic-AUR installer executable..."
        chmod +x ./scripts/install-chaotic-aur.sh
        sudo ./scripts/install-chaotic-aur.sh
    fi
else
    print_status "Skipping Chaotic-AUR setup."
fi

#==================================================================
# 3. Flatpak Setup
#==================================================================
print_section "3. Flatpak Setup"
print_info "Flatpak provides sandboxed applications with dependencies included"

if ask_yes_no "Would you like to install Flatpak?" "y"; then
    if [ -f "./scripts/install-flatpak.sh" ] && [ -x "./scripts/install-flatpak.sh" ]; then
        sudo ./scripts/install-flatpak.sh
    else
        print_status "Making Flatpak installer executable..."
        chmod +x ./scripts/install-flatpak.sh
        sudo ./scripts/install-flatpak.sh
    fi
else
    print_status "Skipping Flatpak setup."
fi

#==================================================================
# 4. File Manager Setup
#==================================================================
print_section "4. File Manager Setup"
print_status "Setting up file manager..."

# List available file managers with descriptions
echo -e "\n${BRIGHT_WHITE}${BOLD}Available File Managers:${RESET}"
echo -e "  ${BRIGHT_WHITE}1.${RESET} Nautilus  - GNOME's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}2.${RESET} Nemo      - Cinnamon's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}3.${RESET} Thunar    - Xfce's file manager (GTK, lightweight)"
echo -e "  ${BRIGHT_WHITE}4.${RESET} PCManFM   - LXDE's file manager (GTK, very lightweight)"
echo -e "  ${BRIGHT_WHITE}5.${RESET} Dolphin   - KDE's file manager (Qt, feature-rich)"
echo -e "  ${BRIGHT_WHITE}6.${RESET} Caja      - MATE's file manager (GTK, feature-rich)"
echo -e "  ${BRIGHT_WHITE}7.${RESET} Krusader  - Twin-panel file manager (Qt, advanced features)"
echo -e "  ${BRIGHT_WHITE}8.${RESET} Thunar + PCManFM (lightweight options)"
echo -e "  ${BRIGHT_WHITE}9.${RESET} Nautilus + Nemo (feature-rich options)"
echo -e "  ${BRIGHT_WHITE}10.${RESET} All GUI file managers"
echo -e "  ${BRIGHT_WHITE}0.${RESET} None - Skip file manager installation"

echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select file manager(s) to install [0-10] (default: 3): ${RESET}"
read -r fm_choice

# Default to Thunar if no input
if [ -z "$fm_choice" ]; then
    fm_choice=3
fi

# Only install file manager dependencies if not skipping file manager installation
if [ "$fm_choice" != "0" ]; then
    print_status "Installing file manager dependencies..."
    # Install the common file manager dependencies from the package list
    install_packages_by_category "FILEMANAGER"
else
    print_status "Skipping file manager installation entirely."
fi

# Function to install specific file manager from the package list
install_file_manager() {
    local fm_name="$1"
    local packages=()
    
    # Read package list file
    local package_list_file="${BASE_DIR}/package-list.txt"
    
    if [ ! -f "$package_list_file" ]; then
        print_error "Package list file not found: $package_list_file"
        return 1
    fi
    
    # Debug
    print_status "Looking for $fm_name packages in $package_list_file"
    
    # Extract packages matching the category and containing the file manager name
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        # Check if line matches the FILEMANAGER category and contains the file manager name
        if [[ "$line" =~ ^\[FILEMANAGER\][[:space:]]+([^[:space:]#]+) ]]; then
            # Get the package name
            local pkg_name="${BASH_REMATCH[1]}"
            
            # Check if the package name or comment contains the file manager name
            if [[ "$pkg_name" == "$fm_name" || "$pkg_name" =~ ^"$fm_name"[-_] || "$line" =~ [[:space:]]"$fm_name"([[:space:]]|$) ]]; then
                # Make sure it's an actual package name, not a status message
                if [[ ! "$pkg_name" =~ ^(Found|Installing|No|packages|for|category|ℹ) ]]; then
                    packages+=("$pkg_name")
                fi
            fi
        fi
    done < "$package_list_file"
    
    # Check if any packages were found
    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages found for file manager: $fm_name"
        return 1
    fi
    
    # Install the packages
    print_status "Installing $fm_name file manager packages: ${packages[*]}"
    install_packages "${packages[@]}"
}

# Install selected file manager(s)
case "$fm_choice" in
    0)
        print_status "No file manager will be installed."
        ;;
    1)
        print_status "Installing Nautilus..."
        install_file_manager "nautilus"
        ;;
    2)
        print_status "Installing Nemo..."
        install_file_manager "nemo"
        ;;
    3)
        print_status "Installing Thunar..."
        install_file_manager "thunar"
        ;;
    4)
        print_status "Installing PCManFM..."
        install_file_manager "pcmanfm"
        ;;
    5)
        print_status "Installing Dolphin..."
        install_file_manager "dolphin"
        ;;
    6)
        print_status "Installing Caja..."
        install_file_manager "caja"
        ;;
    7)
        print_status "Installing Krusader..."
        install_file_manager "krusader"
        ;;
    8)
        print_status "Installing Thunar and PCManFM..."
        install_file_manager "thunar"
        install_file_manager "pcmanfm"
        ;;
    9)
        print_status "Installing Nautilus and Nemo..."
        install_file_manager "nautilus"
        install_file_manager "nemo"
        ;;
    10)
        print_status "Installing all GUI file managers..."
        install_file_manager "nautilus"
        install_file_manager "nemo"
        install_file_manager "thunar"
        install_file_manager "pcmanfm"
        install_file_manager "dolphin"
        install_file_manager "caja"
        install_file_manager "krusader"
        ;;
    *)
        print_warning "Invalid selection. Installing Thunar as default."
        install_file_manager "thunar"
        ;;
esac

print_success "File manager setup complete!"

# Ask for Nautilus scripts only if file managers are being installed
if [ "$fm_choice" != "0" ]; then
    # Only ask about nautilus scripts if nautilus is being installed or if option 10 (all) was selected
    if [ "$fm_choice" = "1" ] || [ "$fm_choice" = "9" ] || [ "$fm_choice" = "10" ]; then
        if ask_yes_no "Would you like to install file manager scripts \(nautilus-scripts\)?" "y"; then
            install_nautilus_scripts
        fi
    fi
fi

#==================================================================
# 5. Core Dependencies Installation
#==================================================================
print_section "5. Core Dependencies Installation"
print_info "These packages are essential for Serial Design V to function properly"

if ask_yes_no "Would you like to install core dependencies for Serial Design V?" "y"; then
    # Install necessary system packages
    print_status "Installing core system dependencies..."
    install_packages_by_category "SYSTEM"
    
    # Install Hyprland and related packages
    print_status "Installing Hyprland and related packages..."
    install_packages_by_category "HYPRLAND"
    
    # Install network and bluetooth packages
    print_status "Installing network and bluetooth packages..."
    install_packages_by_category "NETWORK"
    
    # Install fonts
    print_status "Installing fonts..."
    install_packages_by_category "FONT"
    
    # Install utilities
    print_status "Installing utilities..."
    install_packages_by_category "UTILITY"
    
    # Install development packages
    print_status "Installing development packages..."
    install_packages_by_category "DEV"
    
    # Print success
    print_success_banner "Core dependencies installed successfully!"
    
    # Install keybinds viewer
    print_section "6.5. Keybinds Viewer Installation"
    print_info "Installing the Hyprland keybinds viewer utility"
    
    if ask_yes_no "Would you like to install the keybinds viewer? \(Super+K to launch\)" "y"; then
        # Ensure the script is executable
        chmod +x ./scripts/install_keybinds_viewer.sh
        
        # Export AUR_HELPER for the script
        export AUR_HELPER
        
        print_status "Installing Hyprland keybinds viewer..."
        if ! sudo -E ./scripts/install_keybinds_viewer.sh; then
            print_error "Failed to install keybinds viewer"
            if ask_yes_no "Would you like to continue with the installation?" "y"; then
                print_warning "Continuing without keybinds viewer"
            else
                print_error "Installation aborted by user."
                exit 1
            fi
        else
            print_success "Keybinds viewer installation complete!"
        fi
    else
        print_status "Skipping keybinds viewer installation."
    fi
    
    # Install variable viewer
    print_section "6.6. Variable Viewer Installation"
    print_info "Installing the Hyprland variable viewer utility"
    
    if ask_yes_no "Would you like to install the variable viewer? \(Super+Alt+V to launch\)" "y"; then
        # Ensure the script is executable
        chmod +x ./scripts/install_var_viewer.sh
        
        # Export AUR_HELPER for the script
        export AUR_HELPER
        
        print_status "Installing Hyprland variable viewer..."
        if ! sudo -E ./scripts/install_var_viewer.sh; then
            print_error "Failed to install variable viewer"
            if ask_yes_no "Would you like to continue with the installation?" "y"; then
                print_warning "Continuing without variable viewer"
            else
                print_error "Installation aborted by user."
                exit 1
            fi
        else
            print_success "Variable viewer installation complete!"
        fi
    else
            print_status "Skipping variable viewer installation."
fi

#==================================================================
# 6.7. Main Center Installation
#==================================================================
print_section "6.7. Main Center Installation"
print_info "Installing the Main Center utility"

if ask_yes_no "Would you like to install the Main Center utility?" "y"; then
    # Ensure the script is executable
    chmod +x ./scripts/install_main_center.sh
    
    # Export AUR_HELPER for the script
    export AUR_HELPER
    
    print_status "Installing Main Center..."
    if ! sudo -E ./scripts/install_main_center.sh; then
        print_error "Failed to install Main Center"
        if ask_yes_no "Would you like to continue with the installation?" "y"; then
            print_warning "Continuing without Main Center"
        else
            print_error "Installation aborted by user."
            exit 1
        fi
    else
        print_success "Main Center installation complete!"
        # Set variable to inform main install script
        export MAIN_CENTER_INSTALLED=true
    fi
else
    print_status "Skipping Main Center installation."
    export MAIN_CENTER_INSTALLED=false
fi

print_status "Now let's continue with Serial Design V customization..."
echo
press_enter
else
    print_status "Skipping core dependencies installation."
fi

#==================================================================
# Arch-specific Installation Completed
#==================================================================
print_section "Arch-specific Installation Completed"
print_info "Core dependencies and Arch-specific setup have been completed successfully."
print_info "Returning to the main installer for theme and configuration setup..."

# Simply exit with success and let the parent install.sh script continue
exit 0
