#!/bin/bash

# Function to set default file manager
set_default_file_manager() {
    local file_manager="$1"
    
    # Check if the file manager exists
    if ! command -v "$file_manager" &> /dev/null; then
        echo "Error: File manager '$file_manager' not found"
        return 1
    fi
    
    # Set default file manager using xdg-mime
    xdg-mime default "$file_manager.desktop" inode/directory
    
    # Set default file manager for other common file types
    xdg-mime default "$file_manager.desktop" application/x-directory
    xdg-mime default "$file_manager.desktop" application/x-directory-share
    
    echo "Default file manager set to: $file_manager"
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_manager>"
    echo "Example: $0 nautilus"
    exit 1
fi

set_default_file_manager "$1" 