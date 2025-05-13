#!/bin/bash

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

# Unified selection function
get_geometry() {
    slurp "$@"
}

# Screenshot functions
capture_fullscreen() {
    sleep 1.5  # Add a 1.5-second delay
    grim - | wl-copy
    notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
}

capture_area() {
    geometry=$(get_geometry)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return
    fi
    grim -g "$geometry" - | wl-copy
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
}

# Recording functions
record_fullscreen() {
    wf-recorder -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    notify-send "Recording Started" "Fullscreen recording"
}

record_area() {
    geometry=$(slurp)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return
    fi
    wf-recorder -g "$geometry" -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    notify-send "Recording Started" "Area recording"
}

stop_recording() {
    pkill -INT wf-recorder
    notify-send "Recording Stopped" "Recording saved to ~/Videos/"
}

# Main execution loop
while true; do
    main_choice=$(main_menu)

    case "$main_choice" in
        Screenshot)
            sub_choice=$(screenshot_submenu)
            case "$sub_choice" in
                Fullscreen) capture_fullscreen ;;
                Area)       capture_area ;;
                "Go Back") continue ;;
            esac
            ;;
        Record|"Recording Options")
            sub_choice=$(record_submenu)
            case "$sub_choice" in
                "Stop Recording") stop_recording ;;
                Fullscreen)       record_fullscreen ;;
                Area)             record_area ;;
                "Go Back") continue ;;
            esac
            ;;
        *) exit 0 ;; # Exit the script if no valid option is selected
    esac
done
