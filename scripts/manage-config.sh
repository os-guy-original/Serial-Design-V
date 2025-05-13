#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Configuration Manager Script               │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Print welcome banner
print_banner "Configuration Manager" "Customize Your Desktop Experience"

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Configuration Management Functions                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# List existing configuration directories
list_config_directories() {
    print_section "Existing Configuration Directories"
    
    if [ ! -d "$HOME/.config" ]; then
        print_status "No .config directory found in your home directory."
        return
    fi
    
    # Get list of Serial Design V related directories
    local hypr_dirs=(
        "hypr"
        "waybar"
        "wofi"
        "kitty"
        "foot"
        "swaylock"
        "rofi"
        "swaync"
    )
    
    local existing_dirs=()
    for dir in "${hypr_dirs[@]}"; do
        if [ -d "$HOME/.config/$dir" ]; then
            existing_dirs+=("$dir")
            echo -e "${BRIGHT_WHITE}${BOLD}•${RESET} $dir"
        fi
    done
    
    # Check for other Wayland WM directories
    for dir in "$HOME/.config/"*; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            if [[ "$dir_name" =~ ^(sway|river|wlroots|weston)$ ]]; then
                if [[ ! " ${existing_dirs[*]} " =~ " ${dir_name} " ]]; then
                    existing_dirs+=("$dir_name")
                    echo -e "${BRIGHT_YELLOW}${BOLD}•${RESET} $dir_name ${BRIGHT_YELLOW}(other Wayland WM)${RESET}"
                fi
            fi
        fi
    done
    
    if [ ${#existing_dirs[@]} -eq 0 ]; then
        print_status "No Hyprland or other Wayland compositor configurations found."
    fi
}

# Create a backup of existing configuration
backup_config() {
    print_section "Backup Configuration"
    
    if [ ! -d "$HOME/.config" ]; then
        print_status "No .config directory found to backup."
        return 0
    fi
    
    # Create a timestamped backup directory
    BACKUP_DIR="$HOME/.config.hypr-backup.$(date +%Y%m%d%H%M%S)"
    
    if ask_yes_no "Create a backup of your current configuration?" "y"; then
        print_status "Creating backup at $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        
        # Get list of Serial Design V related directories
        local hypr_dirs=(
            "hypr"
            "waybar"
            "wofi"
            "kitty"
            "foot"
            "swaylock"
            "rofi"
            "swaync"
        )
        
        # Copy each directory if it exists
        for dir in "${hypr_dirs[@]}"; do
            if [ -d "$HOME/.config/$dir" ]; then
                print_status "Backing up $dir..."
                cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
            fi
        done
        
        print_success "Backup created at: $BACKUP_DIR"
        return 0
    else
        print_status "Backup skipped."
        return 1
    fi
}

# Clean existing configuration
clean_config() {
    print_section "Clean Configuration"
    
    if [ ! -d "$HOME/.config" ]; then
        print_status "No .config directory found to clean."
        return 0
    fi
    
    # Get list of Serial Design V related directories
    local hypr_dirs=(
        "hypr"
        "waybar"
        "wofi"
        "kitty"
        "foot"
        "swaylock"
        "rofi"
        "swaync"
    )
    
    local to_remove=()
    
    # Check each directory if it exists
    for dir in "${hypr_dirs[@]}"; do
        if [ -d "$HOME/.config/$dir" ]; then
            if ask_yes_no "Remove existing $dir configuration?" "n"; then
                to_remove+=("$dir")
            fi
        fi
    done
    
    # Remove selected directories
    if [ ${#to_remove[@]} -gt 0 ]; then
        print_status "Removing selected configuration directories..."
        for dir in "${to_remove[@]}"; do
            print_status "Removing $dir..."
            rm -rf "$HOME/.config/$dir"
        done
        print_success "Cleanup complete!"
    else
        print_status "No directories selected for removal."
    fi
    
    return 0
}

# Copy Serial Design V configuration
install_configs() {
    print_section "Install Serial Design V Configurations"
    
    local SCRIPT_DIR="$(dirname "$0")"
    
    # Check if copy-configs.sh exists and is executable
    if [ -f "${SCRIPT_DIR}/copy-configs.sh" ]; then
        if [ ! -x "${SCRIPT_DIR}/copy-configs.sh" ]; then
            print_status "Making copy-configs.sh executable..."
            chmod +x "${SCRIPT_DIR}/copy-configs.sh"
        fi
        
        print_status "Running copy-configs.sh to install configurations..."
        "${SCRIPT_DIR}/copy-configs.sh"
        
        if [ $? -eq 0 ]; then
            # Set permissions
            chown -R "$USER_NAME" "$CONFIG_DIR"
            
            # Completion message
            print_success_banner "Serial Design V configurations installed successfully!"
            print_status "You can now customize them to your liking."
            echo
            print_warning "Remember to log out and log back in for all changes to take effect."
        else
            print_error "Failed to install Serial Design V configurations."
            return 1
        fi
    else
        print_error "copy-configs.sh not found. Cannot install configurations."
        return 1
    fi
    
    return 0
}

# Edit configuration files
edit_configs() {
    print_section "Edit Configuration Files"
    
    # Get list of Serial Design V related directories
    local hypr_dirs=(
        "hypr"
        "waybar"
        "wofi"
        "kitty"
        "foot"
        "swaylock"
        "rofi"
        "swaync"
    )
    
    # Filter to only existing directories
    local existing_dirs=()
    for dir in "${hypr_dirs[@]}"; do
        if [ -d "$HOME/.config/$dir" ]; then
            existing_dirs+=("$dir")
        fi
    done
    
    if [ ${#existing_dirs[@]} -eq 0 ]; then
        print_error "No Serial Design V configuration directories found."
        return 1
    fi
    
    # Create selection menu for directories
    print_status "Select a configuration directory to edit:"
    for i in "${!existing_dirs[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${existing_dirs[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#existing_dirs[@]}]: ${RESET}"
    read -r dir_selection
    
    # Validate input
    if [[ ! "$dir_selection" =~ ^[0-9]+$ ]] || [ "$dir_selection" -lt 1 ] || [ "$dir_selection" -gt "${#existing_dirs[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_dir="${existing_dirs[$((dir_selection-1))]}"
    print_status "Selected: $selected_dir"
    
    # List files in the selected directory
    local config_files=()
    for file in "$HOME/.config/$selected_dir/"*; do
        if [ -f "$file" ]; then
            config_files+=("$(basename "$file")")
        fi
    done
    
    if [ ${#config_files[@]} -eq 0 ]; then
        print_error "No configuration files found in $selected_dir."
        return 1
    fi
    
    # Create selection menu for files
    print_status "Select a file to edit:"
    for i in "${!config_files[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${config_files[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#config_files[@]}]: ${RESET}"
    read -r file_selection
    
    # Validate input
    if [[ ! "$file_selection" =~ ^[0-9]+$ ]] || [ "$file_selection" -lt 1 ] || [ "$file_selection" -gt "${#config_files[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_file="${config_files[$((file_selection-1))]}"
    print_status "Selected: $selected_file"
    
    # Determine editor
    local editor="${EDITOR:-nano}"
    if ! command -v "$editor" &> /dev/null; then
        if command -v nano &> /dev/null; then
            editor="nano"
        elif command -v vim &> /dev/null; then
            editor="vim"
        elif command -v vi &> /dev/null; then
            editor="vi"
        else
            print_error "No suitable text editor found (tried: $EDITOR, nano, vim, vi)."
            return 1
        fi
    fi
    
    # Open file in editor
    print_status "Opening $selected_file in $editor..."
    $editor "$HOME/.config/$selected_dir/$selected_file"
    
    print_success "File edited successfully."
    return 0
}

# Restart Hyprland components
restart_components() {
    print_section "Restart Hyprland Components"
    
    local components=(
        "Hyprland (restart entire session)"
        "waybar"
        "swaync"
        "wallpaper"
    )
    
    # Create selection menu for components
    print_status "Select a component to restart:"
    for i in "${!components[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${components[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#components[@]}]: ${RESET}"
    read -r component_selection
    
    # Validate input
    if [[ ! "$component_selection" =~ ^[0-9]+$ ]] || [ "$component_selection" -lt 1 ] || [ "$component_selection" -gt "${#components[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    # Execute based on selection
    case $component_selection in
        1)
            print_status "Restarting Hyprland..."
            if ask_yes_no "This will close your session. Continue?" "n"; then
                hyprctl dispatch exit
            else
                print_status "Restart cancelled."
            fi
            ;;
        2)
            print_status "Restarting waybar..."
            killall waybar
            waybar &
            print_success "waybar restarted."
            ;;
        3)
            print_status "Restarting swaync..."
            killall swaync
            swaync &
            print_success "swaync restarted."
            ;;
        4)
            print_status "Reloading wallpaper..."
            if [ -f "$HOME/.config/hypr/scripts/wallpaper.sh" ]; then
                "$HOME/.config/hypr/scripts/wallpaper.sh"
                print_success "Wallpaper reloaded."
            else
                print_error "Wallpaper script not found."
            fi
            ;;
    esac
    
    return 0
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Menu                                               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Main menu function
main_menu() {
    while true; do
        print_section "Serial Design V Configuration Manager"
        
        echo -e "${BRIGHT_WHITE}${BOLD}1)${RESET} List existing configuration directories"
        echo -e "${BRIGHT_WHITE}${BOLD}2)${RESET} Backup current configuration"
        echo -e "${BRIGHT_WHITE}${BOLD}3)${RESET} Clean existing configuration"
        echo -e "${BRIGHT_WHITE}${BOLD}4)${RESET} Install Serial Design V configuration"
        echo -e "${BRIGHT_WHITE}${BOLD}5)${RESET} Edit configuration files"
        echo -e "${BRIGHT_WHITE}${BOLD}6)${RESET} Restart Hyprland components"
        echo -e "${BRIGHT_WHITE}${BOLD}7)${RESET} Setup themes"
        echo -e "${BRIGHT_WHITE}${BOLD}0)${RESET} Exit"
        
        echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [0-7]: ${RESET}"
        read -r menu_selection
        
        case $menu_selection in
            1)
                list_config_directories
                ;;
            2)
                backup_config
                ;;
            3)
                clean_config
                ;;
            4)
                install_configs
                ;;
            5)
                edit_configs
                ;;
            6)
                restart_components
                ;;
            7)
                # Run setup-themes.sh
                local SCRIPT_DIR="$(dirname "$0")"
                if [ -f "${SCRIPT_DIR}/setup-themes.sh" ]; then
                    if [ ! -x "${SCRIPT_DIR}/setup-themes.sh" ]; then
                        print_status "Making setup-themes.sh executable..."
                        chmod +x "${SCRIPT_DIR}/setup-themes.sh"
                    fi
                    
                    print_status "Running setup-themes.sh..."
                    "${SCRIPT_DIR}/setup-themes.sh"
                else
                    print_error "setup-themes.sh not found. Cannot setup themes."
                fi
                ;;
            0)
                print_status "Exiting configuration manager..."
                exit 0
                ;;
            *)
                print_error "Invalid selection. Please enter a number between 0 and 7."
                ;;
        esac
        
        # Pause before showing menu again
        echo
        read -n 1 -s -r -p "Press any key to continue..."
        echo
    done
}

# Handle command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTION]"
    echo "Manage Serial Design V configuration."
    echo
    echo "Options:"
    echo "  --list, -l        List existing configuration directories"
    echo "  --backup, -b      Backup current configuration"
    echo "  --clean, -c       Clean existing configuration"
    echo "  --install, -i     Install Serial Design V configuration"
    echo "  --edit, -e        Edit configuration files"
    echo "  --restart, -r     Restart Hyprland components"
    echo "  --themes, -t      Setup themes"
    echo "  --help, -h        Display this help message"
    echo
    echo "Without arguments, the script will show an interactive menu."
    exit 0
fi

# Execute based on command line arguments
case $1 in
    --list|-l)
        list_config_directories
        ;;
    --backup|-b)
        backup_config
        ;;
    --clean|-c)
        clean_config
        ;;
    --install|-i)
        install_configs
        ;;
    --edit|-e)
        edit_configs
        ;;
    --restart|-r)
        restart_components
        ;;
    --themes|-t)
        # Run setup-themes.sh
        SCRIPT_DIR="$(dirname "$0")"
        if [ -f "${SCRIPT_DIR}/setup-themes.sh" ]; then
            if [ ! -x "${SCRIPT_DIR}/setup-themes.sh" ]; then
                print_status "Making setup-themes.sh executable..."
                chmod +x "${SCRIPT_DIR}/setup-themes.sh"
            fi
            
            print_status "Running setup-themes.sh..."
            "${SCRIPT_DIR}/setup-themes.sh"
        else
            print_error "setup-themes.sh not found. Cannot setup themes."
        fi
        ;;
    "")
        # No arguments provided, show interactive menu
        main_menu
        ;;
    *)
        print_error "Invalid option: $1"
        echo "Use --help for usage information."
        exit 1
        ;;
esac

exit 0 