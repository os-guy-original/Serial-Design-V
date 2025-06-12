#!/bin/bash

# Script to fix path references in Waybar configuration files
# This script will:
# 1. Update paths in config.jsonc
# 2. Update paths in performance-mode.jsonc

# Exit on any error
set -e

# Define paths
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
CONFIG_FILE="$WAYBAR_CONFIG_DIR/config.jsonc"
PERFORMANCE_CONFIG_FILE="$WAYBAR_CONFIG_DIR/performance-mode.jsonc"

# Timestamp for logging
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

echo "[$(timestamp)] Starting Waybar path fixing process"

# Function to update paths in a file
update_paths_in_file() {
    local file="$1"
    local old_path="$2"
    local new_path="$3"
    
    if [ -f "$file" ]; then
        if grep -q "$old_path" "$file"; then
            echo "[$(timestamp)] Updating $old_path to $new_path in $file"
            sed -i "s|$old_path|$new_path|g" "$file"
        fi
    fi
}

# Fix paths in main config file
echo "[$(timestamp)] Fixing paths in $CONFIG_FILE"
update_paths_in_file "$CONFIG_FILE" "scripts/logout.sh" "scripts/system/logout.sh"
update_paths_in_file "$CONFIG_FILE" "scripts/screen_shot-record.sh" "scripts/media/screen_shot-record.sh"

# Fix paths in performance mode config file
echo "[$(timestamp)] Fixing paths in $PERFORMANCE_CONFIG_FILE"
update_paths_in_file "$PERFORMANCE_CONFIG_FILE" "scripts/performance/toggle_performance_mode.sh" "scripts/system/performance/toggle_performance_mode.sh"
update_paths_in_file "$PERFORMANCE_CONFIG_FILE" "scripts/logout.sh" "scripts/system/logout.sh"
update_paths_in_file "$PERFORMANCE_CONFIG_FILE" "scripts/screen_shot-record.sh" "scripts/media/screen_shot-record.sh"

echo "[$(timestamp)] Waybar path fixing completed!"
echo "You may need to restart Waybar for changes to take effect." 