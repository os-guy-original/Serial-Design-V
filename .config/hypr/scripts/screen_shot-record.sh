#!/bin/bash

# Wofi style configuration
WOFI_STYLE="$HOME/.config/wofi/style.css"

# Check if wf-recorder is running
is_recording() {
    pgrep -x wf-recorder >/dev/null
}

# Main menu
main_menu() {
    if is_recording; then
        echo -e "Screenshot\nRecording Options" | wofi --dmenu --prompt "Choose action:" --style "$WOFI_STYLE"
    else
        echo -e "Screenshot\nRecord" | wofi --dmenu --prompt "Choose action:" --style "$WOFI_STYLE"
    fi
}

# Screenshot submenu
screenshot_submenu() {
    echo -e "Fullscreen\nArea\n<span weight='bold'>Go Back</span>" | wofi --dmenu --prompt "Screenshot:" --style "$WOFI_STYLE" --allow-markup
}

# Record submenu
record_submenu() {
    if is_recording; then
        echo -e "Stop Recording\nFullscreen\nArea\n<span weight='bold'>Go Back</span>" | wofi --dmenu --prompt "Recording Options:" --style "$WOFI_STYLE" --allow-markup
    else
        echo -e "Fullscreen\nArea\n<span weight='bold'>Go Back</span>" | wofi --dmenu --prompt "Record:" --style "$WOFI_STYLE" --allow-markup
    fi
}

# Unified selection function
get_geometry() {
    slurp "$@"
}

# Screenshot functions
capture_fullscreen() {
    grim - | wl-copy
    notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
}

capture_area() {
    geometry=$(get_geometry)
    grim -g "$geometry" - | wl-copy
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
}

# Recording functions
record_fullscreen() {
    wf-recorder -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    notify-send "Recording Started" "Fullscreen recording"
}

record_area() {
    wf-recorder -g "$(slurp)" -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
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
                "<span weight='bold'>Go Back</span>") continue ;;
            esac
            ;;
        Record|"Recording Options")
            sub_choice=$(record_submenu)
            case "$sub_choice" in
                "Stop Recording") stop_recording ;;
                Fullscreen)       record_fullscreen ;;
                Area)             record_area ;;
                "<span weight='bold'>Go Back</span>") continue ;;
            esac
            ;;
        *) exit 0 ;; # Exit the script if no valid option is selected
    esac
done
