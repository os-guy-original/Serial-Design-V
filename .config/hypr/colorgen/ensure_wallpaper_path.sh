#!/bin/bash

# ============================================================================
# Ensure Wallpaper Path Consistency
# 
# This script ensures that the wallpaper path is consistent across all scripts
# by creating symbolic links if needed.
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/hypr"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
CACHE_DIR="$CONFIG_DIR/cache"
STATE_DIR="$CACHE_DIR/state"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$COLORGEN_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$STATE_DIR"

# Define wallpaper paths
MATERIAL_EXTRACT_WALLPAPER="$STATE_DIR/last_wallpaper"
HYPR_WALLPAPER="$CONFIG_DIR/last_wallpaper"

# Function to ensure a symbolic link exists
ensure_symlink() {
    local source=$1
    local target=$2
    
    # If the target already exists as a symlink, check if it points to the source
    if [ -L "$target" ]; then
        local current_link=$(readlink -f "$target")
        if [ "$current_link" = "$(readlink -f "$source")" ]; then
            echo "Symlink already exists and is correct: $target -> $source"
            return 0
        else
            echo "Symlink exists but points to wrong location: $target -> $current_link"
            echo "Removing old symlink..."
            rm -f "$target"
        fi
    elif [ -e "$target" ]; then
        # If the target exists as a regular file, back it up
        echo "Target exists as a regular file: $target"
        echo "Backing up to $target.bak..."
        mv "$target" "$target.bak"
    fi
    
    # Create the symlink
    echo "Creating symlink: $target -> $source"
    ln -sf "$source" "$target"
}

# Check if material_extract's wallpaper file exists
if [ -f "$MATERIAL_EXTRACT_WALLPAPER" ]; then
    # Create a symlink from hypr's wallpaper file to material_extract's
    ensure_symlink "$MATERIAL_EXTRACT_WALLPAPER" "$HYPR_WALLPAPER"
elif [ -f "$HYPR_WALLPAPER" ]; then
    # Create a symlink from material_extract's wallpaper file to hypr's
    ensure_symlink "$HYPR_WALLPAPER" "$MATERIAL_EXTRACT_WALLPAPER"
else
    echo "No wallpaper file found at either location."
    echo "A symlink will be created when a wallpaper is set."
fi

echo "Wallpaper path consistency ensured."
exit 0 