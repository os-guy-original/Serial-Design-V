#!/bin/bash

# Comprehensive script to fix all path references in the Hyprland configuration
# This script will:
# 1. Check all scripts for references to old paths
# 2. Update any remaining path references

# Exit on any error
set -e

# Define paths
CONFIG_DIR="$HOME/.config/hypr"

# Timestamp for logging
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

echo "[$(timestamp)] Starting path fixing process"

# Function to update paths in a file
update_paths_in_file() {
    local file="$1"
    local old_path="$2"
    local new_path="$3"
    
    if [ -f "$file" ]; then
        if grep -q "$old_path" "$file"; then
            echo "[$(timestamp)] Updating paths in $file"
            sed -i "s|$old_path|$new_path|g" "$file"
        fi
    fi
}

# Fix any remaining references to media-management
echo "[$(timestamp)] Fixing media-management paths"
find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/media/media-management" | while read -r file; do
    update_paths_in_file "$file" "scripts/media/media-management" "scripts/media/media-management"
done

# Fix any remaining references to performance
echo "[$(timestamp)] Fixing performance paths"
find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/system/performance" | while read -r file; do
    update_paths_in_file "$file" "scripts/system/performance" "scripts/system/performance"
done

# Fix any remaining references to notification
echo "[$(timestamp)] Fixing notification paths"
find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/system/notification" | while read -r file; do
    update_paths_in_file "$file" "scripts/system/notification" "scripts/system/notification"
done

# Fix paths for UI scripts
echo "[$(timestamp)] Fixing UI script paths"
UI_SCRIPTS=("wallpaper_picker.sh" "launch_swww.sh" "set_first_wallpaper.sh" "rofi-file-manager.sh" "rofi-list-windows.sh" "screenshot_area.sh" "screenshot_fullscreen.sh")
for script in "${UI_SCRIPTS[@]}"; do
    find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/$script" | while read -r file; do
        update_paths_in_file "$file" "scripts/$script" "scripts/ui/$script"
    done
done

# Fix paths for media scripts
echo "[$(timestamp)] Fixing media script paths"
MEDIA_SCRIPTS=("volume-control.sh" "mute-audio.sh" "play_test_sound.sh" "screen_shot-record.sh")
for script in "${MEDIA_SCRIPTS[@]}"; do
    find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/$script" | while read -r file; do
        update_paths_in_file "$file" "scripts/$script" "scripts/media/$script"
    done
done

# Fix paths for system scripts
echo "[$(timestamp)] Fixing system script paths"
SYSTEM_SCRIPTS=("login.sh" "logout.sh" "loading_overlay.sh" "fix_colors.sh" "set-default-file-manager.sh")
for script in "${SYSTEM_SCRIPTS[@]}"; do
    find "$CONFIG_DIR" -type f -name "*.sh" -o -name "*.conf" | xargs grep -l "scripts/$script" | while read -r file; do
        update_paths_in_file "$file" "scripts/$script" "scripts/system/$script"
    done
done

echo "[$(timestamp)] Path fixing completed!"
echo "You may need to restart Hyprland for all changes to take effect." 