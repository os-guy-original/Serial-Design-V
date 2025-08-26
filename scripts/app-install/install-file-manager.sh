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

# Process command line arguments
CONFIGURE_ONLY=false
INSTALL_ONLY=false
AUTO_INSTALL=""

# Add global var for storing selected file manager
SELECTED_MANAGER_FILE="$HOME/.config/serial-design-v/selected_file_manager"

# Check for specific flags in the arguments
for arg in "$@"; do
    case "$arg" in
        "--configure-only")
            CONFIGURE_ONLY=true
            ;;
        "--install-only")
            INSTALL_ONLY=true
            ;;
        "--auto="*)
            AUTO_INSTALL="${arg#--auto=}"
            ;;
        "-h" | "--help")
            print_generic_help "$(basename "$0")" "Install and configure file managers"
            echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
            echo -e "    This script helps you install and configure your preferred file manager."
            echo
            echo -e "${BRIGHT_WHITE}${BOLD}SUPPORTED FILE MANAGERS${RESET}"
            echo -e "    - Nautilus (GNOME Files)"
            echo -e "    - Dolphin (KDE)"
            echo -e "    - Thunar (XFCE)"
            echo -e "    - Nemo (Cinnamon)"
            echo -e "    - PCManFM (LXDE/LXQt)"
            echo -e "    - Caja (MATE)"
            echo -e "    - Krusader (Advanced twin-panel)"
            echo
            echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS${RESET}"
            echo -e "    --install-only     Install file manager without configuring as default"
            echo -e "    --configure-only   Configure existing file manager without installation"
            echo -e "    --auto=NAME        Automatically install and configure specified file manager"
            echo -e "                       (NAME can be: nautilus, dolphin, thunar, nemo, pcmanfm, caja, krusader)"
            echo
            echo -e "${BRIGHT_WHITE}${BOLD}EXAMPLES${RESET}"
            echo -e "    ./install-file-manager.sh             # Interactive mode"
            echo -e "    ./install-file-manager.sh --auto=thunar # Auto-install Thunar"
            echo
            exit 0
            ;;
    esac
done

# Function to install file manager packages
install_file_manager_packages() {
    local file_manager=$1
    local subcategory=""
    
    # Map file manager to subcategory
    case "$file_manager" in
        "nautilus")
            subcategory="NAUTILUS"
            ;;
        "dolphin")
            subcategory="DOLPHIN"
            ;;
        "thunar")
            subcategory="THUNAR"
            ;;
        "nemo")
            subcategory="NEMO"
            ;;
        "pcmanfm")
            subcategory="PCMANFM"
            ;;
        "caja")
            subcategory="CAJA"
            ;;
        "krusader")
            subcategory="ADVANCED"
            ;;
        *)
            print_warning "Unknown file manager: $file_manager"
            return 1
            ;;
    esac
    
    print_status "Installing packages for $file_manager..."
    
    # Install only the specific file manager packages using subcategory
    if ! install_packages_by_category "FILEMANAGER" false "$subcategory"; then
        print_warning "Failed to install packages for $file_manager"
        return 1
    fi
    
    print_success "Successfully installed packages for $file_manager"
    return 0
}

# Function to update Hyprland keybinds file with the selected file manager
update_hyprland_keybinds() {
    local file_manager=$1
    local keybinds_file="$HOME/.config/hypr/configs/keybinds.conf"
    
    # Create config directory if it doesn't exist
    mkdir -p "$HOME/.config/hypr/configs"
    
    # Define the appropriate arguments for each file manager
    local command_args=""
    case "$file_manager" in
        "nautilus")
            command_args="--new-window"
            ;;
        "dolphin")
            command_args="--new-window"
            ;;
        "thunar")
            command_args=""  # Thunar opens a new window by default
            ;;
        "nemo")
            command_args=""  # Nemo opens a new window by default
            ;;
        "pcmanfm")
            command_args=""  # PCManFM opens a new window by default
            ;;
        *)
            command_args=""  # Default to no arguments for other file managers
            ;;
    esac
    
    if [ -f "$keybinds_file" ]; then
        print_status "Updating Hyprland keybinds with the selected file manager..."
        
        # Look for the line after the "## File Manager" comment and replace it
        # This approach is more reliable as it uses the comment as an anchor
        local line_number=$(grep -n "## File Manager" "$keybinds_file" | cut -d':' -f1)
        
        if [ -n "$line_number" ]; then
            # Get the next line after the comment (which should be the keybinding line)
            local next_line=$((line_number + 1))
            local new_command="bind = \$mainMod, E, exec, $file_manager $command_args"
            
            # Use sed to replace that specific line
            if sed -i "${next_line}s|.*|$new_command|" "$keybinds_file"; then
                print_success "Updated Hyprland keybinds to use $file_manager"
            else
                print_warning "Failed to update Hyprland keybinds automatically"
                print_status "You can manually edit $keybinds_file to set $file_manager as your default file manager"
            fi
        else
            print_warning "Could not find '## File Manager' comment in keybinds file"
            print_status "You can manually edit $keybinds_file to set $file_manager as your default file manager"
        fi
    else
        print_warning "Hyprland keybinds file not found at $keybinds_file"
        print_status "The file will be created when you first run Hyprland"
        print_status "After that, you can manually set $file_manager as your default file manager"
    fi
}

# Function to configure default file manager
configure_file_manager() {
    local selected_manager=$1  # Optional parameter for auto-configuration
    
    print_section "File Manager Configuration"
    
    # List available file managers
    local file_managers=()
    if command -v nautilus &>/dev/null; then
        file_managers+=("nautilus")
    fi
    if command -v dolphin &>/dev/null; then
        file_managers+=("dolphin")
    fi
    if command -v nemo &>/dev/null; then
        file_managers+=("nemo")
    fi
    if command -v thunar &>/dev/null; then
        file_managers+=("thunar")
    fi
    if command -v pcmanfm &>/dev/null; then
        file_managers+=("pcmanfm")
    fi
    if command -v caja &>/dev/null; then
        file_managers+=("caja")
    fi
    if command -v krusader &>/dev/null; then
        file_managers+=("krusader")
    fi
    
    if [ ${#file_managers[@]} -eq 0 ]; then
        print_warning "No file managers found. You need to install a file manager first."
        return 1
    fi
    
    # If no specific file manager is provided, ask the user to select one
    if [ -z "$selected_manager" ]; then
        # Show available file managers
        echo -e "\n${BRIGHT_WHITE}${BOLD}Available file managers:${RESET}"
        for i in "${!file_managers[@]}"; do
            echo -e "  ${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}. ${file_managers[$i]}"
        done
        
        # Get user choice
        local choice
        while true; do
            echo -e -n "${CYAN}Enter selection [1-${#file_managers[@]}]: ${RESET}"
            read -r choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#file_managers[@]}" ]; then
                break
            else
                print_error "Invalid selection. Please try again."
            fi
        done
        
        selected_manager="${file_managers[$((choice-1))]}"
    else
        # Verify that the specified manager is installed
        local manager_found=false
        for fm in "${file_managers[@]}"; do
            if [ "$fm" = "$selected_manager" ]; then
                manager_found=true
                break
            fi
        done
        
        if [ "$manager_found" = false ]; then
            print_error "The specified file manager '$selected_manager' is not installed."
            return 1
        fi
    fi
    
    # Set default file manager
    print_status "Setting default file manager to $selected_manager..."
    
    # Set default file manager using xdg-mime
    xdg-mime default "$selected_manager.desktop" inode/directory
    xdg-mime default "$selected_manager.desktop" application/x-directory
    xdg-mime default "$selected_manager.desktop" application/x-directory-share
    
    # Update Hyprland keybinds
    update_hyprland_keybinds "$selected_manager"
    
    # Final success message
    print_section "File Manager Configuration Complete"
    print_success_banner "Default file manager has been set to $selected_manager"
    print_status "Your Hyprland configuration has been updated to use $selected_manager for file operations."
    
    return 0
}

# Main function
main() {
    clear
    print_banner "File Manager Installation & Configuration" "Install and configure your preferred file manager"
    
    # If configure-only was requested without an explicit --auto option, try to
    # reuse the file manager that was chosen during the earlier installation
    # phase. This prevents the user from being prompted a second time.
    if [ "$CONFIGURE_ONLY" = true ] && [ -z "$AUTO_INSTALL" ] && [ -f "$SELECTED_MANAGER_FILE" ]; then
        AUTO_INSTALL="$(cat "$SELECTED_MANAGER_FILE" 2>/dev/null)"
        if [ -n "$AUTO_INSTALL" ]; then
            print_status "Re-using previously selected file manager: $AUTO_INSTALL"
        fi
    fi
    
    if [ "$CONFIGURE_ONLY" = true ]; then
        # Only configure existing file manager
        configure_file_manager "$AUTO_INSTALL"
        exit $?
    fi
    
    # If auto-install is specified, install that file manager
    if [ -n "$AUTO_INSTALL" ]; then
        print_status "Auto-installing file manager: $AUTO_INSTALL"
        if ! install_file_manager_packages "$AUTO_INSTALL"; then
            print_error "Failed to install $AUTO_INSTALL"
            exit 1
        fi

        # Remember the selection for later configuration steps
        mkdir -p "$(dirname "$SELECTED_MANAGER_FILE")"
        echo "$AUTO_INSTALL" > "$SELECTED_MANAGER_FILE" 2>/dev/null || true

        # Only configure if explicitly requested
        if [ "$INSTALL_ONLY" = false ]; then
                print_warning "File manager installed but not configured."
                print_info "To configure the file manager, run this script with --configure-only after copying configs."
            fi
            # Offer to install Nautilus scripts (works for multiple file managers)
            if [ "$INSTALL_ONLY" = false ]; then
                if type install_nautilus_scripts >/dev/null 2>&1; then
                    install_nautilus_scripts
                fi
            fi
        exit 0
    fi
    
    # Interactive mode
    print_section "File Manager Selection"
    print_info "Choose a file manager to install"
    
    # Define available file managers
    local available_managers=("nautilus" "dolphin" "nemo" "thunar" "pcmanfm" "caja" "krusader" "all" "none")
    local manager_names=(
        "Nautilus (GNOME Files)" 
        "Dolphin (KDE)" 
        "Nemo (Cinnamon)" 
        "Thunar (XFCE)" 
        "PCManFM (LXDE)" 
        "Caja (MATE)"
        "Krusader (Advanced twin-panel)"
        "All file managers"
        "None (skip installation)"
    )
    
    echo -e "\n${BRIGHT_WHITE}${BOLD}Available file managers to install:${RESET}"
    for i in "${!available_managers[@]}"; do
        echo -e "  ${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}. ${manager_names[$i]}"
    done
    
    # Get user choice
    local choice
    while true; do
        echo -e -n "${CYAN}Enter selection [1-${#available_managers[@]}]: ${RESET}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_managers[@]}" ]; then
            break
        else
            print_error "Invalid selection. Please try again."
        fi
    done
    
    local selected_option="${available_managers[$((choice-1))]}"
    
    # Handle the selected option
    if [ "$selected_option" = "none" ]; then
        print_status "Skipping file manager installation."
        exit 0
    elif [ "$selected_option" = "all" ]; then
        print_status "Installing all file managers..."
        for fm in "${available_managers[@]}"; do
            if [ "$fm" != "all" ] && [ "$fm" != "none" ]; then
                install_file_manager_packages "$fm"
            fi
        done
    else
        # Install the selected file manager
        if ! install_file_manager_packages "$selected_option"; then
            print_error "Failed to install $selected_option"
            exit 1
        fi

        # Remember the selection for later configuration steps
        if [ -n "$selected_option" ]; then
            mkdir -p "$(dirname "$SELECTED_MANAGER_FILE")"
            echo "$selected_option" > "$SELECTED_MANAGER_FILE" 2>/dev/null || true
        fi
    fi
    
    # Only configure if explicitly requested
    if [ "$INSTALL_ONLY" = false ]; then
        print_warning "File manager installed but not configured."
        print_info "To configure the file manager, run this script with --configure-only after copying configs."
    fi
}

# Run the main function
main 