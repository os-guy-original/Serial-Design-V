#!/bin/bash

# stop_recording.sh - Script for stopping active recordings

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define sound files
RECORD_STOP_SOUND="$SOUNDS_DIR/record-stop.ogg"

# Check if wf-recorder is running
is_recording() {
    pgrep -x wf-recorder >/dev/null
}

# Stop recording function
stop_recording() {
    if is_recording; then
        pkill -INT wf-recorder
        
        # Play record stop sound
        play_sound "$RECORD_STOP_SOUND"
        
        notify-send "Recording Stopped" "Recording saved to ~/Videos/"
        return 0
    else
        notify-send "Error" "No active recording to stop"
        return 1
    fi
}

# Execute stop recording
stop_recording
exit $? 