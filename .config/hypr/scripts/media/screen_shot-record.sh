#!/bin/bash

# screen_shot-record.sh - Updated to use individual scripts

# Define the scripts directory
SCRIPTS_DIR="$HOME/.config/hypr/scripts/media/screenshot-n-record"

# Rofi style configuration
ROFI_STYLE="-theme $HOME/.config/rofi/theme.rasi"

# Check if wf-recorder is running
is_recording() {
    pgrep -x wf-recorder >/dev/null
}

# Main menu
main_menu() {
    if is_recording; then
        echo -e "Screenshot\nRecording Options" | rofi -dmenu -p "Choose action:" $ROFI_STYLE
    else
        echo -e "Screenshot\nRecord" | rofi -dmenu -p "Choose action:" $ROFI_STYLE
    fi
}

# Screenshot submenu
screenshot_submenu() {
    echo -e "Fullscreen\nArea\nGo Back" | rofi -dmenu -p "Screenshot:" $ROFI_STYLE -markup-rows
}

# Record submenu
record_submenu() {
    if is_recording; then
        echo -e "Stop Recording\nFullscreen\nArea\nGo Back" | rofi -dmenu -p "Recording Options:" $ROFI_STYLE -markup-rows
    else
        echo -e "Fullscreen\nArea\nGo Back" | rofi -dmenu -p "Record:" $ROFI_STYLE -markup-rows
    fi
}

# Main execution loop
while true; do
    main_choice=$(main_menu)

    case "$main_choice" in
        Screenshot)
            sub_choice=$(screenshot_submenu)
            case "$sub_choice" in
                Fullscreen) "$SCRIPTS_DIR/screenshot_fullscreen.sh" ;;
                Area)       "$SCRIPTS_DIR/screenshot_area.sh" ;;
                "Go Back") continue ;;
                *) exit 0 ;;
            esac
            ;;
        Record|"Recording Options")
            sub_choice=$(record_submenu)
            case "$sub_choice" in
                "Stop Recording") "$SCRIPTS_DIR/stop_recording.sh" ;;
                Fullscreen)       "$SCRIPTS_DIR/record_fullscreen.sh" ;;
                Area)             "$SCRIPTS_DIR/record_area.sh" ;;
                "Go Back") continue ;;
                *) exit 0 ;;
            esac
            ;;
        *) exit 0 ;; # Exit the script if no valid option is selected
    esac
    
    # Exit after performing an action
    exit 0
done
