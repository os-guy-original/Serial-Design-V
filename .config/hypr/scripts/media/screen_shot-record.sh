#!/bin/bash

# Rofi style configuration
ROFI_STYLE="-theme $HOME/.config/rofi/theme.rasi"

# Sound file paths
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    fi
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
fi

# Define sound files
SCREENSHOT_SOUND="$SOUNDS_DIR/screenshot.ogg"
RECORD_START_SOUND="$SOUNDS_DIR/record-start.ogg"
RECORD_STOP_SOUND="$SOUNDS_DIR/record-stop.ogg"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal "$sound_file" &
        else
            echo "Error: mpv is not installed. Please install mpv to play sounds." >&2
        fi
    fi
}

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
    # Play record start sound
    play_sound "$RECORD_START_SOUND"
    
    wf-recorder -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    notify-send "Recording Started" "Fullscreen recording"
}

record_area() {
    geometry=$(slurp)
    # Check if user canceled the selection
    if [ -z "$geometry" ]; then
        return
    fi
    
    # Play record start sound
    play_sound "$RECORD_START_SOUND"
    
    wf-recorder -g "$geometry" -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
    notify-send "Recording Started" "Area recording"
}

stop_recording() {
    pkill -INT wf-recorder
    
    # Play record stop sound
    play_sound "$RECORD_STOP_SOUND"
    
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
