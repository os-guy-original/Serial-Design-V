#!/bin/bash

# Simple script to exit performance mode
MODE_FILE="$HOME/.config/hypr/.performance_mode"
TOGGLE_SCRIPT="$HOME/.config/hypr/scripts/toggle_performance_mode.sh"

if [ -f "$MODE_FILE" ]; then
    notify-send -t 1000 "Mode" "Exiting performance mode..."
    "$TOGGLE_SCRIPT"
else
    notify-send -t 1000 "Mode" "Not in performance mode"
fi
