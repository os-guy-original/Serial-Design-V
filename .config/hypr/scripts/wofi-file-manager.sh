#!/bin/bash

# Initialize variables
CURRENT_DIR="$HOME"
STYLE="$HOME/.config/wofi/style.css"

# Function to display directory contents
show_directory() {
    # Clear the screen and show the directory contents
    clear
    echo "Current Directory: $CURRENT_DIR"
    echo ""
    # List actions (at the top, with Pango markup for bold)
    echo "<b>Back</b>"
    echo "<b>Exit</b>"
    echo ""
    # List directory contents using ls (files and directories)
    ls -1 --group-directories-first "$CURRENT_DIR"
}

# Function to handle navigation
navigate() {
    while true; do
        show_directory

        # Prepare the list of options for wofi (with Pango markup for actions)
        OPTIONS="<b>Back</b>\n<b>Exit</b>\n$(ls -1 --group-directories-first "$CURRENT_DIR")"

        # Get user input using wofi (disable sorting to avoid prioritizing recently opened items)
        SELECTION=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Choose an action, directory, or file:" --no-sort --style="$STYLE" --allow-markup)

        # Handle actions
        case "$SELECTION" in
            "<b>Back</b>")
                # Go to the parent directory
                PARENT_DIR=$(dirname "$CURRENT_DIR")
                if [ "$PARENT_DIR" != "/" ]; then
                    CURRENT_DIR="$PARENT_DIR"
                fi
                ;;
            "<b>Exit</b>")
                echo "Exiting file manager."
                exit 0
                ;;
            *)
                # Handle file or directory selection
                SELECTION_PATH="$CURRENT_DIR/$SELECTION"
                if [ -d "$SELECTION_PATH" ]; then
                    # If it's a directory, navigate into it
                    CURRENT_DIR="$SELECTION_PATH"
                elif [ -f "$SELECTION_PATH" ]; then
                    # If it's a file, open its parent folder in Nautilus
                    nautilus "$(dirname "$SELECTION_PATH")" &
                else
                    echo "Invalid selection: $SELECTION_PATH"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Start navigation
navigate
