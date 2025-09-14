#!/bin/bash

# This script is intended to be run on login to restore hyprland.conf to its normal state.

CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache"
CHANGETONORMAL_FILE="$CACHE_DIR/changetonormal"

if [ -f "$CHANGETONORMAL_FILE" ]; then
    while IFS= read -r line; do
        if [[ "$line" == del* ]]; then
            file_to_delete=$(echo "$line" | cut -d' ' -f2-)
            rm -f "$file_to_delete"
        else
            IFS=';' read -r file_path search_pattern replacement_string <<< "$line"
            sed -i "s|$search_pattern|$replacement_string|g" "$file_path"
        fi
    done < "$CHANGETONORMAL_FILE"
    
    # Clear the file after applying changes
    > "$CHANGETONORMAL_FILE"
fi