#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │               Configuration Manager Script               │
# ╰──────────────────────────────────────────────────────────╯

# Source colors and common functions
source "$(dirname "$0")/colors.sh"

# Check if script is run with root privileges
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Print welcome banner
echo
echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Configuration Manager                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Customize Your Desktop Experience      ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
echo

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

# Selection menu
selection_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selection
    
    echo -e "${BRIGHT_BLUE}${BOLD}$title${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..60})${RESET}"
    
    for i in "${!options[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${options[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#options[@]}]: ${RESET}"
    read -r selection
    
    # Validate input
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#options[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    return $((selection-1))
}

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
    
    # Get list of HyprGraphite related directories
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
        
        # Get list of HyprGraphite related directories
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
    
    # Get list of HyprGraphite related directories
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

# Copy HyprGraphite configuration
copy_config() {
    print_section "Copy HyprGraphite Configuration"
    
    # Get the project root directory
    local PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    print_status "Project root: $PROJECT_ROOT"
    
    if [ ! -d "$PROJECT_ROOT/.config" ]; then
        print_error "HyprGraphite .config directory not found at: $PROJECT_ROOT/.config"
        print_status "Current directory: $(pwd)"
        print_status "Listing project root contents:"
        ls -la "$PROJECT_ROOT" || true
        print_status "Please run this script from the HyprGraphite repository root."
        return 1
    fi
    
    # Create .config directory if it doesn't exist
    if [ ! -d "$HOME/.config" ]; then
        print_status "Creating .config directory in your home folder..."
        mkdir -p "$HOME/.config"
    fi
    
    if ask_yes_no "Copy HyprGraphite configuration to your home directory?" "y"; then
        print_status "Copying configuration files to ~/.config..."
        
        # Get list of directories in .config
        local source_dirs=()
        for dir in "$PROJECT_ROOT/.config"/*; do
            if [ -d "$dir" ]; then
                dir_name=$(basename "$dir")
                source_dirs+=("$dir_name")
            fi
        done
        
        if [ ${#source_dirs[@]} -eq 0 ]; then
            print_error "No configuration directories found in $PROJECT_ROOT/.config"
            print_status "Listing .config directory contents:"
            ls -la "$PROJECT_ROOT/.config" || true
            return 1
        fi
        
        # Ask for each directory
        for dir in "${source_dirs[@]}"; do
            if ask_yes_no "Copy $dir configuration?" "y"; then
                print_status "Copying $dir..."
                cp -r "$PROJECT_ROOT/.config/$dir" "$HOME/.config/"
                if [ $? -eq 0 ]; then
                    print_success "Successfully copied $dir configuration"
                else
                    print_error "Failed to copy $dir configuration"
                fi
            fi
        done
        
        print_success "Configuration files copied successfully!"
    else
        print_status "Copy operation cancelled."
    fi
    
    return 0
}

# Restore from backup
restore_backup() {
    print_section "Restore from Backup"
    
    # Find backup directories
    local backup_dirs=()
    for dir in "$HOME"/.config.hypr-backup.*; do
        if [ -d "$dir" ]; then
            backup_dirs+=("$dir")
        fi
    done
    
    if [ ${#backup_dirs[@]} -eq 0 ]; then
        print_error "No backup directories found."
        return 1
    fi
    
    # Sort backup directories (newest first)
    IFS=$'\n' sorted_backups=($(sort -r <<<"${backup_dirs[*]}"))
    unset IFS
    
    # Display menu of backups
    echo -e "${BRIGHT_BLUE}${BOLD}Available backups:${RESET}"
    for i in "${!sorted_backups[@]}"; do
        backup_date=$(echo "${sorted_backups[$i]}" | sed 's/.*\.hypr-backup\.\([0-9]\{14\}\)$/\1/')
        formatted_date=$(date -d "${backup_date:0:8} ${backup_date:8:2}:${backup_date:10:2}:${backup_date:12:2}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${sorted_backups[$i]} ${BRIGHT_BLACK}(${formatted_date})${RESET}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter backup number to restore [1-${#sorted_backups[@]}] or 0 to cancel: ${RESET}"
    read -r selection
    
    # Validate and process selection
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [ "$selection" -eq 0 ]; then
            print_status "Restore cancelled."
            return 0
        elif [ "$selection" -ge 1 ] && [ "$selection" -le "${#sorted_backups[@]}" ]; then
            selected_backup="${sorted_backups[$((selection-1))]}"
            
            # Get list of directories in the backup
            local backup_config_dirs=()
            for dir in "$selected_backup"/*; do
                if [ -d "$dir" ]; then
                    dir_name=$(basename "$dir")
                    backup_config_dirs+=("$dir_name")
                fi
            done
            
            if [ ${#backup_config_dirs[@]} -eq 0 ]; then
                print_error "Selected backup is empty."
                return 1
            fi
            
            print_status "Selected backup: $selected_backup"
            
            # Ask for confirmation and restore
            if ask_yes_no "Restore this backup?" "y"; then
                for dir in "${backup_config_dirs[@]}"; do
                    if ask_yes_no "Restore $dir configuration?" "y"; then
                        # Remove existing directory if it exists
                        if [ -d "$HOME/.config/$dir" ]; then
                            print_status "Removing existing $dir configuration..."
                            rm -rf "$HOME/.config/$dir"
                        fi
                        
                        # Copy from backup
                        print_status "Restoring $dir..."
                        cp -r "$selected_backup/$dir" "$HOME/.config/"
                    fi
                done
                
                print_success "Backup restoration complete!"
            else
                print_status "Restore cancelled."
            fi
        else
            print_error "Invalid selection."
            return 1
        fi
    else
        print_error "Invalid input. Please enter a number."
        return 1
    fi
    
    return 0
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Main Script                                             ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Main menu
while true; do
    print_section "Main Menu"
    options=(
        "List existing configuration"
        "Backup current configuration"
        "Clean existing configuration"
        "Copy HyprGraphite configuration"
        "Restore from backup"
        "Exit"
    )
    
    selection_menu "Select an action:" "${options[@]}"
    choice=$?
    
    case $choice in
        0) # List existing configuration
            list_config_directories
            ;;
        1) # Backup current configuration
            backup_config
            ;;
        2) # Clean existing configuration
            backup_config
            clean_config
            ;;
        3) # Copy HyprGraphite configuration
            copy_config
            ;;
        4) # Restore from backup
            restore_backup
            ;;
        5) # Exit
            echo
            print_success "Thank you for using HyprGraphite Configuration Manager!"
            exit 0
            ;;
        *)
            print_error "Invalid selection"
            ;;
    esac
    
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    clear
    
    # Print welcome banner again
    echo
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}         Configuration Manager                ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}     Customize Your Desktop Experience      ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
done 