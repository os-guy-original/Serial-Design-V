#!/bin/bash

# Configuration
HOME_DIR="$HOME"
STYLE="-theme $HOME/.config/rofi/theme.rasi"

# Build the list of options
build_options() {
    local dirs=("$HOME" "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music")
    local actions=("Open Terminal Here" "Create New File" "Create New Directory")
    
    # Add actions with markup
    for action in "${actions[@]}"; do
        echo "$action"
    done
    
    # Add common directories
    for dir in "${dirs[@]}"; do
        echo "$(basename "$dir") ($(realpath --relative-to="$HOME" "$dir"))"
    done
    
    # Add recently accessed directories from history if available
    if [ -f "$HOME/.config/rofi-file-manager-history" ]; then
        cat "$HOME/.config/rofi-file-manager-history"
    fi
}

# Prepare the list of options for rofi
OPTIONS=$(build_options)

# Get user input using rofi (disable sorting to avoid prioritizing recently opened items)
SELECTION=$(echo -e "$OPTIONS" | rofi -dmenu -p "Choose an action, directory, or file:" -no-sort $STYLE -markup-rows)

# Exit if nothing was selected
if [ -z "$SELECTION" ]; then
    exit 0
fi

# Handle selection
case "$SELECTION" in
    "Open Terminal Here")
        # Open terminal in current directory
        kitty --working-directory="$PWD" &
        ;;
    "Create New File")
        # Prompt for filename
        FILENAME=$(rofi -dmenu -p "Enter filename:" $STYLE)
        if [ -n "$FILENAME" ]; then
            touch "$FILENAME"
        fi
        ;;
    "Create New Directory")
        # Prompt for directory name
        DIRNAME=$(rofi -dmenu -p "Enter directory name:" $STYLE)
        if [ -n "$DIRNAME" ]; then
            mkdir -p "$DIRNAME"
        fi
        ;;
    *)
        # Extract the path from the selection
        if [[ "$SELECTION" =~ \((.*)\)$ ]]; then
            # Get the relative path from the format "Name (path)"
            REL_PATH="${BASH_REMATCH[1]}"
            TARGET_PATH="$HOME/$REL_PATH"
            
            # Open the directory in the file manager
            xdg-open "$TARGET_PATH" &
            
            # Save to history file (maximum 5 entries)
            echo "$SELECTION" >> "$HOME/.config/rofi-file-manager-history"
            tail -n 5 "$HOME/.config/rofi-file-manager-history" > "$HOME/.config/rofi-file-manager-history.tmp"
            mv "$HOME/.config/rofi-file-manager-history.tmp" "$HOME/.config/rofi-file-manager-history"
        fi
        ;;
esac
