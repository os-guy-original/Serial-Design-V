#!/bin/bash

# screen_shot-record.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Rofi style configuration
ROFI_STYLE="-theme $HOME/.config/rofi/theme.rasi"

# Define sound files
SCREENSHOT_SOUND="$SOUNDS_DIR/screenshot.ogg"
RECORD_START_SOUND="$SOUNDS_DIR/record-start.ogg"
RECORD_STOP_SOUND="$SOUNDS_DIR/record-stop.ogg"

# Make sure Videos directory exists
mkdir -p "$HOME/Videos"

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
    
    # Play screenshot sound
    play_sound "$SCREENSHOT_SOUND"
    
    notify-send "Screenshot Copied" "Fullscreen screenshot copied to clipboard"
}

capture_area() {
    geometry=$(get_geometry)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return
    fi
    grim -g "$geometry" - | wl-copy
    
    # Play screenshot sound
    play_sound "$SCREENSHOT_SOUND"
    
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
}

# Recording functions
record_fullscreen() {
    # Check if wf-recorder is installed
    if ! command -v wf-recorder &> /dev/null; then
        notify-send "Error" "wf-recorder is not installed"
        return
    fi
    
    # Create output filename
    local output_file="$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    
    # Play record start sound
    play_sound "$RECORD_START_SOUND"
    
    # Run wf-recorder in background
    wf-recorder -f "$output_file" &
    
    # Wait a moment to ensure recording starts
    sleep 1
    
    # Check if recording started successfully
    if is_recording; then
        notify-send "Recording Started" "Fullscreen recording"
    else
        notify-send "Error" "Failed to start recording"
    fi
}

record_area() {
    # Check if wf-recorder is installed
    if ! command -v wf-recorder &> /dev/null; then
        notify-send "Error" "wf-recorder is not installed"
        return
    fi
    
    geometry=$(slurp)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return
    fi
    
    # Create output filename
    local output_file="$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    
    # Play record start sound
    play_sound "$RECORD_START_SOUND"
    
    # Run wf-recorder in background
    wf-recorder -g "$geometry" -f "$output_file" &
    
    # Wait a moment to ensure recording starts
    sleep 1
    
    # Check if recording started successfully
    if is_recording; then
        notify-send "Recording Started" "Area recording"
    else
        notify-send "Error" "Failed to start recording"
    fi
}

stop_recording() {
    if is_recording; then
        pkill -INT wf-recorder
        
        # Play record stop sound
        play_sound "$RECORD_STOP_SOUND"
        
        notify-send "Recording Stopped" "Recording saved to ~/Videos/"
    else
        notify-send "Error" "No active recording to stop"
    fi
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
                *) exit 0 ;;
            esac
            ;;
        Record|"Recording Options")
            sub_choice=$(record_submenu)
            case "$sub_choice" in
                "Stop Recording") stop_recording ;;
                Fullscreen)       record_fullscreen ;;
                Area)             record_area ;;
                "Go Back") continue ;;
                *) exit 0 ;;
            esac
            ;;
        *) exit 0 ;; # Exit the script if no valid option is selected
    esac
    
    # Exit after performing an action
    exit 0
done
