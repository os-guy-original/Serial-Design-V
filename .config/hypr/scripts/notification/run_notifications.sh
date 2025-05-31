#!/bin/bash

# Script to run all notification-related scripts in parallel
# This allows for a single entry point for all notification services

# Set the directory where notification scripts are located
SCRIPTS_DIR="$HOME/.config/hypr/scripts/notification"
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Ensure the sounds directory exists
mkdir -p "$SOUNDS_BASE_DIR/default"

# Check if notification scripts are already running
RUNNING_SCRIPTS=$(pgrep -f "window_monitor.sh|usb_monitor.sh|charger_monitor.sh|tools_notify.sh" | wc -l)

if [ $RUNNING_SCRIPTS -gt 0 ]; then
    echo "Notification services are already running."
    exit 0
fi

# Determine which sound theme to use
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        DEFAULT_SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        DEFAULT_SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
        # Update to default if the theme doesn't exist
        echo "default" > "$DEFAULT_SOUND_FILE"
    fi
else
    DEFAULT_SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    echo "default" > "$DEFAULT_SOUND_FILE"
fi

# Print the sound folder path
echo "Notification services using sound theme: $SOUND_THEME, path: $DEFAULT_SOUNDS_DIR"

# Ensure sound theme directory exists
mkdir -p "$DEFAULT_SOUNDS_DIR"

# Required sound files
SOUND_FILES=(
    "notification.ogg"
    "device-added.ogg"
    "device-removed.ogg"
    "charging.ogg"
    "login.ogg"
    "logout.ogg"
    "toggle_performance.ogg"
)

# Copy sound files to theme directory if they don't exist
for sound in "${SOUND_FILES[@]}"; do
    if [ ! -f "$DEFAULT_SOUNDS_DIR/$sound" ] && [ -f "$SOUNDS_BASE_DIR/$sound" ]; then
        cp "$SOUNDS_BASE_DIR/$sound" "$DEFAULT_SOUNDS_DIR/"
        echo "Copied $sound to theme directory"
    fi
done

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