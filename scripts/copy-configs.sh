#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Copy Serial Design V configuration files to your system"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script copies the Serial Design V configuration files to your"
    echo -e "    ~/.config directory, creating backups of any existing configurations."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}CONFIGURATIONS COPIED${RESET}"
    echo -e "    - Hyprland (hypr)"
    echo -e "    - Waybar"
    echo -e "    - Wofi"
    echo -e "    - Kitty terminal"
    echo -e "    - SwayNC, SwayLock"
    echo -e "    - GTK themes"
    echo -e "    - And more..."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES${RESET}"
    echo -e "    Running this script will make backups of your existing configurations"
    echo -e "    before overwriting them."
    echo
    exit 0
fi

# ╭──────────────────────────────────────────────────────────╮
# │               Configuration Copy Script                  │
# │                  Copy Project Configs                    │
# ╰──────────────────────────────────────────────────────────╯

# Get the absolute path of the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Function to copy configuration files
copy_configs() {
    print_section "Copying Configuration Files"
    
    # Debug output
    print_status "Script location: $(readlink -f "$0")"
    print_status "Project root determined as: $PROJECT_ROOT"
    print_status "Current working directory: $(pwd)"
    
    # Create necessary directories
    print_status "Creating configuration directories..."
    mkdir -p ~/.config
    
    # Ensure ~/.config has the right permissions
    if [ ! -w "$HOME/.config" ]; then
        print_error "Cannot write to ~/.config directory. Please ensure you have the right permissions."
        print_info "You might need to run: chmod u+w ~/.config"
        if ask_yes_no "Would you like to try to fix the permissions on your ~/.config directory?" "y"; then
            chmod u+w "$HOME/.config" && print_success "Fixed permissions on ~/.config" || print_error "Failed to fix permissions. Please fix manually."
        fi
    fi
    
    # Define possible locations for the .config directory
    CONFIG_PATHS=(
        "$PROJECT_ROOT/.config"
        "./.config"
        "../.config"
        "$(dirname "$0")/../.config"
    )
    
    # Find the first valid .config path
    CONFIG_DIR=""
    for path in "${CONFIG_PATHS[@]}"; do
        if [ -d "$path" ]; then
            CONFIG_DIR="$path"
            print_status "Found configuration directory at: $CONFIG_DIR"
            break
        fi
    done
    
    # If no path was found, search for it
    if [ -z "$CONFIG_DIR" ]; then
        print_status "Searching for .config directory in the repository..."
        CONFIG_DIR=$(find "$PROJECT_ROOT" -type d -name ".config" -print -quit 2>/dev/null)
        
        if [ -n "$CONFIG_DIR" ] && [ -d "$CONFIG_DIR" ]; then
            print_status "Found .config directory at: $CONFIG_DIR"
        else
            print_error "Could not find .config directory in the repository"
            return 1
        fi
    fi
    
    # List the directories to be copied
    print_status "Configuration directories found:"
    ls -la "$CONFIG_DIR" | grep "^d" | awk '{print $9}' | grep -v "^\."
    
    # Get list of directories to copy
    CONFIG_DIRS=(
        "hypr"
        "waybar"
        "Kvantum"
        "kitty"
        "rofi"
        "dunst"
        "gtk-3.0"
        "gtk-4.0"
        "fish"
        "swaync"
    )
    
    # Copy each directory if it exists
    for dir in "${CONFIG_DIRS[@]}"; do
        if [ -d "$CONFIG_DIR/$dir" ]; then
            print_status "Copying $dir configuration..."
            
            # Create backup if the directory already exists
            if [ -d "$HOME/.config/$dir" ]; then
                backup_dir="$HOME/.config/$dir.bak.$(date +%Y%m%d%H%M%S)"
                print_status "Creating backup of existing $dir configuration to $backup_dir"
                mv "$HOME/.config/$dir" "$backup_dir"
            fi
            
            # Copy the configuration
            cp -r "$CONFIG_DIR/$dir" "$HOME/.config/" || {
                print_error "Failed to copy $dir configuration"
            }
        else
            print_status "Directory $dir not found in $CONFIG_DIR, skipping..."
        fi
    done
    
    # Set proper permissions for scripts
    find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \;
    
    print_success "Configuration files have been copied successfully!"
    
    # Additional setup steps
    print_status "Performing additional setup steps..."
    
    # Make scripts executable
    if [ -d "$HOME/.config/hypr/scripts" ]; then
        print_status "Making Hyprland scripts executable..."
        chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
    fi
    
    # Set up wallpaper
    if [ -f "$HOME/.config/hypr/scripts/wallpaper.sh" ]; then
        print_status "Setting up wallpaper..."
        "$HOME/.config/hypr/scripts/wallpaper.sh" 2>/dev/null || true
    fi
    
    # Create common directories if they don't exist
    print_status "Creating common user directories..."
    mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Downloads" "$HOME/Documents" "$HOME/Music" "$HOME/Videos" 2>/dev/null || true
    
    # Update XDG user directories if command exists
    if command_exists xdg-user-dirs-update; then
        print_status "Updating XDG user directories..."
        xdg-user-dirs-update 2>/dev/null || true
    fi
    
    # Ensure Fish shell configuration is properly set up
    if [ -d "$HOME/.config/fish" ]; then
        print_status "Setting up Fish shell configuration..."
        
        # Create required directories
        mkdir -p "$HOME/.config/fish/conf.d" "$HOME/.config/fish/functions"
        
        # Fix permissions
        chmod 700 "$HOME/.config/fish"
        chmod -R 700 "$HOME/.config/fish/conf.d" "$HOME/.config/fish/functions"
        
        # Fix ownership
        chown -R "$(whoami):$(id -gn)" "$HOME/.config/fish" 2>/dev/null || true
        
        print_success "Fish shell configuration set up successfully!"
    fi
    
    return 0
}

# Function to check for missing dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    # List of essential Hyprland components
    local essential_deps=(
        "hyprland"
        "waybar"
        "wofi"
        "kitty"
    )
    
    # Check each essential dependency
    local missing_deps=()
    for dep in "${essential_deps[@]}"; do
        if ! command_exists "$dep"; then
            print_warning "$dep not found"
            missing_deps+=("$dep")
        else
            print_success "$dep is installed"
        fi
    done
    
    # Warn about missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Some essential dependencies are missing. Serial Design V may not work correctly."
        print_status "Missing dependencies: ${missing_deps[*]}"
        
        if ask_yes_no "Would you like to see installation instructions?" "y"; then
            print_status "Please install the missing dependencies with your package manager."
            print_status "For Arch-based systems: sudo pacman -S hyprland waybar wofi kitty"
            print_status "For Debian/Ubuntu-based systems: Follow Hyprland installation guide at https://hyprland.org/"
        fi
    else
        print_success "All essential dependencies are installed."
    fi
}

# Main execution
if [ "$1" = "--check-deps" ]; then
    check_dependencies
    exit 0
fi

# Check dependencies before copying
check_dependencies

# If there are missing dependencies, ask before proceeding
if ! command_exists "hyprland" || ! command_exists "waybar"; then
    if ! ask_yes_no "Some essential dependencies are missing. Continue anyway?" "n"; then
        print_status "Configuration copy aborted."
        exit 1
    fi
fi

# Copy configurations
copy_configs

if [ $? -eq 0 ]; then
    print_section "Installation Complete!"
    
    # Final success message
    print_success_banner "Serial Design V configurations have been set up successfully!"
    
    print_status "You can now log out and log back in to start using your new desktop environment."
    print_status "Remember to check the configuration files at ~/.config/ to customize your setup."
    
    exit 0
else
    print_error "Failed to set up Serial Design V configurations."
    exit 1
fi 