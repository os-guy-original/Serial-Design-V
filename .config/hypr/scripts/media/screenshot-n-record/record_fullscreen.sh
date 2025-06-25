#!/bin/bash

# record_fullscreen.sh - Script for recording fullscreen

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound files
RECORD_START_SOUND="$SOUNDS_DIR/record-start.ogg"

# Make sure Videos directory exists
mkdir -p "$HOME/Videos"

# Check if wf-recorder is running
is_recording() {
    pgrep -x wf-recorder >/dev/null
}

# Recording function
record_fullscreen() {
    # Check if wf-recorder is installed
    if ! command -v wf-recorder &> /dev/null; then
        notify-send "Error" "wf-recorder is not installed"
        return 1
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
        return 0
    else
        notify-send "Error" "Failed to start recording"
        return 1
    fi
}

# Execute recording
record_fullscreen
exit $? 