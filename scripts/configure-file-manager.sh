#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Configure your default file manager"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script helps you set up your preferred file manager"
    echo -e "    as the default for opening folders and directories."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SUPPORTED FILE MANAGERS${RESET}"
    echo -e "    - Nautilus (GNOME Files)"
    echo -e "    - Dolphin (KDE)"
    echo -e "    - Thunar (XFCE)"
    echo -e "    - Nemo (Cinnamon)"
    echo -e "    - PCManFM (LXDE/LXQt)"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    The script will only show file managers that are installed on your system."
    echo -e "    It will also update Hyprland keybindings if you're using Hyprland."
    echo
    exit 0
fi

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
        
        # Use sed to replace the file manager line in keybinds.conf
        # The pattern matches the line that starts with "bind = $mainMod, E, exec, " followed by any file manager
        local new_command="bind = \$mainMod, E, exec, $file_manager $command_args"
        if sed -i "s|bind = \$mainMod, E, exec, .*|$new_command|" "$keybinds_file"; then
            print_success "Updated Hyprland keybinds to use $file_manager"
        else
            print_warning "Failed to update Hyprland keybinds automatically"
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
    
    if [ ${#file_managers[@]} -eq 0 ]; then
        print_warning "No file managers found. Skipping configuration."
        return
    fi
    
    # Ask if user wants to configure file manager
    print_warning "If you skip this step, the default file manager will be Nautilus (Files)."
    if ! ask_yes_no "Would you like to configure your default file manager?" "y"; then
        print_status "Using Nautilus as the default file manager."
        # Set Nautilus as the default file manager in XDG
        xdg-mime default "nautilus.desktop" inode/directory
        xdg-mime default "nautilus.desktop" application/x-directory
        xdg-mime default "nautilus.desktop" application/x-directory-share
        return
    fi
    
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
    
    local selected_manager="${file_managers[$((choice-1))]}"
    
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
    
    echo
    print_status "You can change this setting at any time by running this script again."
    echo -e "  ${BRIGHT_CYAN}./configure-file-manager.sh${RESET}"
    
    exit 0
}

# Main script
configure_file_manager 