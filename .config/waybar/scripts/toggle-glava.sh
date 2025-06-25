#!/bin/bash

# Script to toggle glava visualization
# Usage: toggle-glava.sh [-enable|-disable]

# Define paths
CACHE_DIR="$HOME/.config/hypr/cache/state"
STATE_FILE="$CACHE_DIR/glava_active"
GLAVA_CONFIG_DIR="$HOME/.config/glava"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to check if glava is running
is_glava_running() {
    pgrep -x "glava" > /dev/null
    return $?
}

# Function to start glava
start_glava() {
    # Check if glava is already running
    if is_glava_running; then
        echo "Glava is already running"
        # Ensure state file exists to match reality
        touch "$STATE_FILE"
        return
    fi
    
    # Create state file to indicate glava is active
    touch "$STATE_FILE"
    
    # Start glava in background
    glava --desktop &
    
    # Output JSON for waybar
    echo '{"text": "󱎴", "tooltip": "Glava: Active", "class": "active"}'
}

# Function to stop glava
stop_glava() {
    # Kill glava process if running
    if is_glava_running; then
        killall glava
    fi
    
    # Remove state file
    rm -f "$STATE_FILE"
    
    # Output JSON for waybar
    echo '{"text": "󱎳", "tooltip": "Glava: Inactive", "class": "inactive"}'
}

# Function to toggle glava
toggle_glava() {
    # Check actual process state first, then state file
    if is_glava_running; then
        stop_glava
    elif [ -f "$STATE_FILE" ]; then
        # State file exists but process doesn't - clean up and start
        rm -f "$STATE_FILE"
        start_glava
    else
        # Neither process nor state file exists
        start_glava
    fi
}

# Check current state for waybar
check_state() {
    # Always check actual process state first
    if is_glava_running; then
        # Ensure state file exists to match reality
        touch "$STATE_FILE"
        echo '{"text": "󱎴", "tooltip": "Glava: Active", "class": "active"}'
    else
        # Ensure state file is removed to match reality
        rm -f "$STATE_FILE"
        echo '{"text": "󱎳", "tooltip": "Glava: Inactive", "class": "inactive"}'
    fi
}

# Main logic based on arguments
case "$1" in
    -enable)
        start_glava
        ;;
    -disable)
        stop_glava
        ;;
    toggle)
        toggle_glava
        ;;
    *)
        # Default behavior: check state for waybar
        check_state
        ;;
esac

exit 0 