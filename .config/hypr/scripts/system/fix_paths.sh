#!/bin/bash

# Script to move temporary and state files to cache directory
# This ensures all temporary files are stored in one place

# Set strict error handling
set -euo pipefail

# Define paths
HYPR_CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$HYPR_CONFIG_DIR/cache"

# Create cache subdirectories
mkdir -p "$CACHE_DIR/state"
mkdir -p "$CACHE_DIR/logs"
mkdir -p "$CACHE_DIR/temp"
mkdir -p "$CACHE_DIR/backups"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to move a file to cache directory and create a symbolic link
move_to_cache() {
    local source_file="$1"
    local cache_subdir="$2"
    local target_dir="$CACHE_DIR/$cache_subdir"
    
    # Check if the source file exists
    if [ -f "$source_file" ]; then
        local filename=$(basename "$source_file")
        local target_file="$target_dir/$filename"
        
        # If the file already exists in cache, just create the symlink
        if [ ! -f "$target_file" ]; then
            log_message "Moving $source_file to $target_file"
            mv "$source_file" "$target_file"
        else
            log_message "File $target_file already exists, removing original"
            rm -f "$source_file"
        fi
        
        # Create symbolic link
        log_message "Creating symbolic link from $target_file to $source_file"
        ln -sf "$target_file" "$source_file"
    fi
}

# Main execution starts here
log_message "Starting path fix script"

# Move state files to cache/state
move_to_cache "$HYPR_CONFIG_DIR/last_wallpaper" "state"
move_to_cache "$HYPR_CONFIG_DIR/.saved_wallpaper" "state"
move_to_cache "$HYPR_CONFIG_DIR/main_center_notify_pref" "state"
move_to_cache "$HYPR_CONFIG_DIR/keybinds_notify_pref" "state"

# Move temporary files to cache/temp
move_to_cache "$HYPR_CONFIG_DIR/.temp_performance_conf" "temp"
move_to_cache "$HYPR_CONFIG_DIR/.black_bg.png" "temp"

# Move backup files to cache/backups
move_to_cache "$HYPR_CONFIG_DIR/hyprland.conf.backup" "backups"

# Update any scripts that might still be using the old paths
log_message "Updating scripts to use cache directory paths..."

# Update any scripts that use mktemp to use the cache directory
log_message "Checking for scripts using mktemp..."
SCRIPTS_USING_MKTEMP=$(grep -l "mktemp" "$HYPR_CONFIG_DIR/scripts" --include="*.sh" -r 2>/dev/null || true)

if [ -n "$SCRIPTS_USING_MKTEMP" ]; then
    log_message "The following scripts use mktemp and may need manual review:"
    echo "$SCRIPTS_USING_MKTEMP" | while read -r script; do
        echo "  - $script"
    done
    log_message "Consider updating these scripts to use \$HOME/.config/hypr/cache/temp instead"
fi

log_message "Path fix completed successfully"

# Script to fix hardcoded paths in all scripts
# This script replaces absolute paths with $HOME

# Base directory
SCRIPTS_DIR="$HOME/.config/hypr/scripts"
COLORGEN_DIR="$HOME/.config/hypr/colorgen"

echo "Fixing hardcoded paths in scripts..."

# Function to fix paths in a file
fix_paths() {
    local file="$1"
    local filename=$(basename "$file")
    
    echo "Processing: $filename"
    
    # Replace hardcoded paths with $HOME
    sed -i "s|$HOME/.config/hypr|\$HOME/.config/hypr|g" "$file"
    
    # Fix source lines for sound_manager.sh
    sed -i 's|source "/\$HOME/.config/hypr/scripts/system/sound_manager.sh"|source "$HOME/.config/hypr/scripts/system/sound_manager.sh"|g' "$file"
    
    # Remove duplicate source lines
    if grep -q "source.*sound_manager.sh" "$file" && grep -c "source.*sound_manager.sh" "$file" -gt 1; then
        # Keep only the first source line
        awk '
            BEGIN { printed = 0 }
            /source.*sound_manager.sh/ {
                if (!printed) {
                    print; 
                    printed = 1;
                }
                next;
            }
            { print }
        ' "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
        echo "  Removed duplicate source lines"
    fi
}

# Find all shell scripts
SHELL_SCRIPTS=$(find "$SCRIPTS_DIR" "$COLORGEN_DIR" -name "*.sh" -type f)

# Process each script
for script in $SHELL_SCRIPTS; do
    fix_paths "$script"
done

echo "Path fixing complete!" 