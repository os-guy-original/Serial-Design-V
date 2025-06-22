#!/bin/bash

# Script to update other scripts to use cache directory for temporary files
# This ensures all temporary files are stored in one place

# Set strict error handling
set -euo pipefail

# Define paths
HYPR_CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$HYPR_CONFIG_DIR/cache"
TEMP_DIR="$CACHE_DIR/temp"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to update mktemp usage in a script
update_mktemp_usage() {
    local script_file="$1"
    local script_name=$(basename "$script_file")
    local backup_file="${script_file}.bak"
    
    log_message "Processing $script_name..."
    
    # Create backup
    cp "$script_file" "$backup_file"
    
    # Replace mktemp with TEMP_DIR-based alternative
    sed -i 's|TEMP_\([A-Za-z0-9_]*\)=\$(mktemp)|TEMP_\1="$HOME/.config/hypr/cache/temp/\1_$(date +%s)"|g' "$script_file"
    sed -i 's|TEMP_\([A-Za-z0-9_]*\)=$(mktemp)|TEMP_\1="$HOME/.config/hypr/cache/temp/\1_$(date +%s)"|g' "$script_file"
    sed -i 's|tmp_\([A-Za-z0-9_]*\)=$(mktemp)|tmp_\1="$HOME/.config/hypr/cache/temp/\1_$(date +%s)"|g' "$script_file"
    sed -i 's|local tmp_\([A-Za-z0-9_]*\)=$(mktemp)|local tmp_\1="$HOME/.config/hypr/cache/temp/\1_$(date +%s)"|g' "$script_file"
    
    # Replace direct /tmp references
    sed -i 's|/tmp/\([A-Za-z0-9_]*\)\.log|$HOME/.config/hypr/cache/logs/\1.log|g' "$script_file"
    sed -i 's|/tmp/\([A-Za-z0-9_]*\)_debug\.log|$HOME/.config/hypr/cache/logs/\1_debug.log|g' "$script_file"
    
    # Check if any changes were made
    if diff -q "$script_file" "$backup_file" >/dev/null; then
        log_message "No changes needed for $script_name"
        rm "$backup_file"
    else
        log_message "Updated $script_name to use cache directory for temporary files"
        log_message "Backup saved as $backup_file"
    fi
}

# Function to update swaync script to use cache directory
update_swaync_script() {
    local script_file="$HYPR_CONFIG_DIR/colorgen/configs/swaync.sh"
    
    if [ -f "$script_file" ]; then
        log_message "Updating SwayNC script to use cache directory..."
        sed -i 's|TEMP_STYLE="/tmp/swaync_style.css"|TEMP_STYLE="$HOME/.config/hypr/cache/temp/swaync_style.css"|g' "$script_file"
        log_message "SwayNC script updated"
    fi
}

# Function to update material_extract script to use cache directory
update_material_extract_script() {
    local script_file="$HYPR_CONFIG_DIR/colorgen/material_extract.sh"
    
    if [ -f "$script_file" ]; then
        log_message "Updating material_extract.sh to use cache directory..."
        sed -i 's|rm -f /tmp/done_color_application|rm -f "$HOME/.config/hypr/cache/temp/done_color_application"|g' "$script_file"
        sed -i 's|echo "$(date +%s)" > /tmp/done_color_application|echo "$(date +%s)" > "$HOME/.config/hypr/cache/temp/done_color_application"|g' "$script_file"
        sed -i 's|echo "Created finish indicator file: /tmp/done_color_application"|echo "Created finish indicator file: $HOME/.config/hypr/cache/temp/done_color_application"|g' "$script_file"
        log_message "material_extract.sh updated"
    fi
}

# Function to update loading_overlay script to use cache directory
update_loading_overlay_script() {
    local script_file="$HYPR_CONFIG_DIR/scripts/system/loading_overlay.sh"
    
    if [ -f "$script_file" ]; then
        log_message "Updating loading_overlay.sh to use cache directory..."
        sed -i 's|TEMP_CONFIG=$(mktemp)|TEMP_CONFIG="$HOME/.config/hypr/cache/temp/loading_overlay_config_$(date +%s)"|g' "$script_file"
        sed -i 's|TEMP_CSS=$(mktemp)|TEMP_CSS="$HOME/.config/hypr/cache/temp/loading_overlay_css_$(date +%s)"|g' "$script_file"
        log_message "loading_overlay.sh updated"
    fi
}

# Main execution starts here
log_message "Starting script to fix temporary file paths"

# Update specific scripts that we know use temporary files
update_swaync_script
update_material_extract_script
update_loading_overlay_script

# Find and update all scripts that use mktemp
log_message "Searching for scripts that use mktemp..."
SCRIPTS_USING_MKTEMP=$(grep -l "mktemp" "$HYPR_CONFIG_DIR/scripts" --include="*.sh" -r 2>/dev/null || true)

if [ -n "$SCRIPTS_USING_MKTEMP" ]; then
    log_message "Found scripts using mktemp, updating them..."
    echo "$SCRIPTS_USING_MKTEMP" | while read -r script; do
        update_mktemp_usage "$script"
    done
else
    log_message "No scripts found using mktemp"
fi

# Find and update all scripts that use /tmp directly
log_message "Searching for scripts that use /tmp directly..."
SCRIPTS_USING_TMP=$(grep -l "/tmp/" "$HYPR_CONFIG_DIR/scripts" --include="*.sh" -r 2>/dev/null || true)

if [ -n "$SCRIPTS_USING_TMP" ]; then
    log_message "Found scripts using /tmp directly, updating them..."
    echo "$SCRIPTS_USING_TMP" | while read -r script; do
        # Skip if it's a socket path which we can't change
        if ! grep -q "/tmp/hypr/.*socket" "$script"; then
            update_mktemp_usage "$script"
        fi
    done
else
    log_message "No scripts found using /tmp directly"
fi

log_message "Temporary file path fixes completed successfully" 