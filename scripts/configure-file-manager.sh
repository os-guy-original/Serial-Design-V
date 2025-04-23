#!/bin/bash

# Source colors and common functions
source "$(dirname "$0")/colors.sh"

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
    if ! ask_yes_no "Would you like to configure your default file manager?" "y"; then
        print_status "Skipping file manager configuration."
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
    
    print_success "Default file manager has been set to $selected_manager"
}

# Main script
configure_file_manager 