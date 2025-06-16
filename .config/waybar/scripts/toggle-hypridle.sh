#!/bin/bash

# Script to toggle hypridle (keep desktop awake)
# This script will kill hypridle to prevent screen from sleeping/locking
# and restart it when toggled again

HYPRIDLE_STATUS_FILE="/tmp/hypridle_disabled"

# If no arguments are passed, this is a status check
if [ "$#" -eq 0 ]; then
    if [ -f "$HYPRIDLE_STATUS_FILE" ]; then
        # Hypridle is disabled (keep awake mode)
        echo '{"text": "󰅶", "tooltip": "Screen timeout disabled (keep awake)", "class": "disabled", "percentage": 100}'
    else
        # Hypridle is enabled (normal mode)
        echo '{"text": "󰒳", "tooltip": "Screen timeout enabled", "class": "enabled", "percentage": 0}'
    fi
    exit 0
fi

# If any argument is passed, toggle the state
if [ -f "$HYPRIDLE_STATUS_FILE" ]; then
    # Re-enable hypridle by starting it
    rm -f "$HYPRIDLE_STATUS_FILE"
    pkill -x hypridle || true
    hypridle &
else
    # Disable hypridle by killing it
    pkill -x hypridle || true
    touch "$HYPRIDLE_STATUS_FILE"
fi

# Output current status after toggle
if [ -f "$HYPRIDLE_STATUS_FILE" ]; then
    echo '{"text": "󰅶", "tooltip": "Screen timeout disabled (keep awake)", "class": "disabled", "percentage": 100}'
else
    echo '{"text": "󰒳", "tooltip": "Screen timeout enabled", "class": "enabled", "percentage": 0}'
fi 