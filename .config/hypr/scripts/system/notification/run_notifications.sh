#!/bin/bash

# Script to run all notification-related scripts in parallel
# This allows for a single entry point for all notification services

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Set the directory where notification scripts are located
SCRIPTS_DIR="$HOME/.config/hypr/scripts/system/notification"
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"

# Ensure the sounds directory exists
mkdir -p "$SOUNDS_BASE_DIR/default"

# Check if notification scripts are already running
RUNNING_SCRIPTS=$(pgrep -f "window_monitor.sh|usb_monitor.sh|charger_monitor.sh|tools_notify.sh" | wc -l)

if [ $RUNNING_SCRIPTS -gt 0 ]; then
    echo "Notification services are already running."
    exit 0
fi

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Print the sound folder path
echo "Notification services using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Ensure sound theme directory exists
mkdir -p "$SOUNDS_DIR"

# Required sound files
SOUND_FILES=(
    "notification.ogg"
    "device-added.ogg"
    "device-removed.ogg"
    "login.ogg"
    "logout.ogg"
    "charging.ogg"
    "toggle_performance.ogg"
)

# Function to start a script in the background
run_script() {
    local script="$1"
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "Starting $script"
        bash "$script" &
    else
        echo "Warning: Cannot execute $script (file not found or not executable)"
        return 1
    fi
}

echo "=== Starting notification services ==="

# List of scripts to run
SCRIPTS=(
    "usb_monitor.sh"
    "charger_monitor.sh"
    "tools_notify.sh"
    "window_monitor.sh"
)

# Start all scripts
SUCCESS=0
for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="$SCRIPTS_DIR/$script"
    if run_script "$SCRIPT_PATH"; then
        SUCCESS=$((SUCCESS + 1))
    fi
done

if [ $SUCCESS -eq 0 ]; then
    echo "Error: No notification services could be started."
    exit 1
else
    echo "=== $SUCCESS notification services running ==="
fi

echo "Press Ctrl+C to stop all notification services"

# Keep the script running to maintain the child processes
# but allow it to be terminated with Ctrl+C
trap "echo 'Stopping notification services...'; pkill -P $$; exit 0" INT TERM
wait 