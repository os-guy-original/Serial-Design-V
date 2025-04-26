#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Copy HyprGraphite configuration files to your system"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script copies the HyprGraphite configuration files to your"
    echo -e "    ~/.config directory, creating backups of any existing configurations."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}CONFIGURATIONS COPIED${RESET}"
    echo -e "    - Hyprland (hypr)"
    echo -e "    - Waybar"
    echo -e "    - Wofi"
    echo -e "    - Kitty terminal"
    echo -e "    - SwayNC, SwayLock"
    echo -e "    - GTK and Qt themes"
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
    
    # More verbose checking for .config directory
    print_status "Checking for .config directory..."
    print_status "Looking in: $PROJECT_ROOT/.config"
    
    # Also try the direct relative path if the absolute path doesn't work
    if [ ! -d "$PROJECT_ROOT/.config" ] && [ -d "./.config" ]; then
        print_status "Using relative path for .config directory"
        PROJECT_ROOT="."
    fi
    
    if [ -d "$PROJECT_ROOT/.config" ]; then
        print_status "Found configuration files in $PROJECT_ROOT/.config"
        # List the directories to be copied
        print_status "Configuration directories to be copied:"
        ls -la "$PROJECT_ROOT/.config" | grep "^d" | awk '{print $9}' | grep -v "^\."
        
        print_status "Copying configuration files..."
        
        # Get list of directories to copy
        CONFIG_DIRS=(
            "hypr"
            "waybar"
            "wofi"
            "kitty"
            "foot"
            "swaylock"
            "rofi"
            "swaync"
            "dunst"
            "gtk-3.0"
            "gtk-4.0"
            "qt5ct"
            "qt6ct"
            "xfce4"
            "Kvantum"
        )
        
        # Copy each directory if it exists
        for dir in "${CONFIG_DIRS[@]}"; do
            if [ -d "$PROJECT_ROOT/.config/$dir" ]; then
                print_status "Copying $dir configuration..."
                
                # Create backup if the directory already exists
                if [ -d "$HOME/.config/$dir" ]; then
                    backup_dir="$HOME/.config/$dir.bak.$(date +%Y%m%d%H%M%S)"
                    print_status "Creating backup of existing $dir configuration to $backup_dir"
                    mv "$HOME/.config/$dir" "$backup_dir"
                fi
                
                # Copy the configuration
                cp -r "$PROJECT_ROOT/.config/$dir" "$HOME/.config/" || {
                    print_error "Failed to copy $dir configuration"
                }
            fi
        done
        
        # Set proper permissions for scripts
        find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \;
        
        print_success "Configuration files have been copied successfully!"
    else
        print_warning "No .config directory found in project root: $PROJECT_ROOT"
        print_status "Checking project root contents..."
        ls -la "$PROJECT_ROOT"
        
        # Try an alternative method to find the .config directory
        print_status "Searching for .config directory in the repository..."
        config_dir=$(find "$PROJECT_ROOT" -type d -name ".config" -print -quit 2>/dev/null)
        
        if [ -n "$config_dir" ] && [ -d "$config_dir" ]; then
            print_status "Found .config directory at: $config_dir"
            print_status "Configuration directories found:"
            ls -la "$config_dir" | grep "^d" | awk '{print $9}' | grep -v "^\."
            
            print_status "Copying configuration files..."
            
            # Get list of directories to copy
            CONFIG_DIRS=(
                "hypr"
                "waybar"
                "wofi"
                "kitty"
                "foot"
                "swaylock"
                "rofi"
                "swaync"
                "dunst"
                "gtk-3.0"
                "gtk-4.0"
                "qt5ct"
                "qt6ct"
                "xfce4"
                "Kvantum"
            )
            
            # Copy each directory if it exists
            for dir in "${CONFIG_DIRS[@]}"; do
                if [ -d "$config_dir/$dir" ]; then
                    print_status "Copying $dir configuration..."
                    
                    # Create backup if the directory already exists
                    if [ -d "$HOME/.config/$dir" ]; then
                        backup_dir="$HOME/.config/$dir.bak.$(date +%Y%m%d%H%M%S)"
                        print_status "Creating backup of existing $dir configuration to $backup_dir"
                        mv "$HOME/.config/$dir" "$backup_dir"
                    fi
                    
                    # Copy the configuration
                    cp -r "$config_dir/$dir" "$HOME/.config/" || {
                        print_error "Failed to copy $dir configuration"
                    }
                fi
            done
            
            # Set proper permissions for scripts
            find "$HOME/.config" -type f -name "*.sh" -exec chmod +x {} \;
            
            print_success "Configuration files have been copied successfully!"
        else
            # Try a last resort method with ls-files
            if [ -d "$PROJECT_ROOT/.git" ]; then
                print_status "Checking if .config might be hidden by git:"
                config_files=$(cd "$PROJECT_ROOT" && git ls-files | grep -i "^\.config/")
                
                if [ -n "$config_files" ]; then
                    print_status "Found .config files in git, but couldn't access the directory directly."
                    print_status "This might be because the .config directory is hidden or has special permissions."
                    print_status "Please try copying the files manually."
                    print_status "Files found: $config_files"
                else
                    print_status "No .config files found in git tracking."
                fi
            fi
            
            print_error "Failed to find configuration files to copy."
            print_warning "You will need to set up your configuration manually."
            return 1
        fi
    fi
    
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
        print_warning "Some essential dependencies are missing. HyprGraphite may not work correctly."
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
    print_success_banner "HyprGraphite configurations have been set up successfully!"
    
    print_status "You can now log out and log back in to start using your new desktop environment."
    print_status "Remember to check the configuration files at ~/.config/ to customize your setup."
    
    exit 0
else
    print_error "Failed to set up HyprGraphite configurations."
    exit 1
fi 