#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# ╭──────────────────────────────────────────────────────────╮
# │               Configuration Copy Script                 │
# │                  Copy Project Configs                   │
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
        print_status "Listing .config directory contents:"
        ls -la "$PROJECT_ROOT/.config" 2>&1
        
        print_status "Copying configuration files..."
        
        # Try to copy each directory individually for better error handling
        for config_dir in "$PROJECT_ROOT/.config"/*; do
            if [ -d "$config_dir" ]; then
                dir_name=$(basename "$config_dir")
                print_status "Copying $dir_name configuration..."
                cp -rv "$config_dir" ~/.config/ 2>&1 || {
                    print_error "Failed to copy $dir_name configuration"
                }
            fi
        done
        
        print_success "Configuration files have been copied successfully!"
    else
        print_warning "No .config directory found in project root: $PROJECT_ROOT"
        print_status "Listing project root contents:"
        ls -la "$PROJECT_ROOT"
        
        # Try an alternative method to find the .config directory
        print_status "Searching for .config directory in the repository..."
        config_dir=$(find "$PROJECT_ROOT" -type d -name ".config" -print -quit 2>/dev/null)
        
        if [ -n "$config_dir" ] && [ -d "$config_dir" ]; then
            print_status "Found .config directory at: $config_dir"
            print_status "Listing .config directory contents:"
            ls -la "$config_dir" 2>&1
            
            print_status "Copying configuration files..."
            
            # Try to copy each directory individually
            for dir in "$config_dir"/*; do
                if [ -d "$dir" ]; then
                    dir_name=$(basename "$dir")
                    print_status "Copying $dir_name configuration..."
                    cp -rv "$dir" ~/.config/ 2>&1 || {
                        print_error "Failed to copy $dir_name configuration"
                    }
                fi
            done
            
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
            
            print_status "Skipping configuration copy. You can copy them manually later."
        fi
    fi
}

# Main execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo "Copies configuration files from the project to the user's home directory."
    exit 0
fi

copy_configs

# Always exit successfully since this is optional
exit 0 