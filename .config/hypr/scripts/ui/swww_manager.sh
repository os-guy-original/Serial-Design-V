#!/bin/bash

# swww_manager.sh - Centralized SWWW wallpaper manager
# This script provides functions for managing wallpapers with SWWW
# Other scripts should source this file to use its functions

# Define paths
CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache/state"
DEFAULT_BG="$CONFIG_DIR/res/default_bg.jpg"
LAST_WALLPAPER_FILE="$CACHE_DIR/last_wallpaper"
COLORGEN_DIR="$CONFIG_DIR/colorgen"
FIRST_LAUNCH_FILE="$CACHE_DIR/first_launch_done"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to initialize swww with better error handling
initialize_swww() {
    echo "Initializing swww..."
    
    # Make sure no swww daemon is running
    pkill -x swww-daemon 2>/dev/null
    
    # Wait for any previous daemon to fully exit
    sleep 0.5
    
    # Start swww daemon with explicit error output
    swww-daemon 2>&1 | tee /tmp/swww_init.log &
    
    # Wait for daemon to be responsive by polling with timeout
    local max_attempts=15
    local attempt=0
    while ! swww query >/dev/null 2>&1 && [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        echo "Waiting for swww daemon to start (attempt $attempt/$max_attempts)..."
        # Longer wait between checks
        sleep 0.3
    done
    
    # Verify swww is running
    if ! swww query >/dev/null 2>&1; then
        echo "Failed to initialize swww after $max_attempts attempts"
        echo "Check /tmp/swww_init.log for errors"
        return 1
    fi
    
    echo "SWWW initialized successfully"
    return 0
}

# Function to check if swww is running and initialize if not
ensure_swww_running() {
    if ! pgrep -x "swww-daemon" > /dev/null || ! swww query >/dev/null 2>&1; then
        initialize_swww
        return $?
    fi
    return 0
}

# Function to set wallpaper with default transition
set_wallpaper() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        echo "Error: Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    # Make sure swww is running
    ensure_swww_running || return 1
    
    echo "Setting wallpaper: $wallpaper"
    if swww img "$wallpaper" --transition-type grow --transition-pos center; then
        # Remember the wallpaper
        echo "$wallpaper" > "$LAST_WALLPAPER_FILE"
        echo "Wallpaper set successfully"
        return 0
    else
        echo "Failed to set wallpaper"
        return 1
    fi
}

# Function to set wallpaper with custom transition
change_wallpaper_with_transition() {
    local wallpaper="$1"
    local transition="${2:-grow}"
    local position="${3:-center}"
    
    if [ ! -f "$wallpaper" ]; then
        echo "Error: Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    # Make sure swww is running
    ensure_swww_running || return 1
    
    echo "Setting wallpaper with transition $transition: $wallpaper"
    if swww img "$wallpaper" --transition-type "$transition" --transition-pos "$position"; then
        # Remember the wallpaper
        echo "$wallpaper" > "$LAST_WALLPAPER_FILE"
        echo "Wallpaper set successfully"
        return 0
    else
        echo "Failed to set wallpaper"
        return 1
    fi
}

# Function to set wallpaper and generate color scheme
set_wallpaper_with_colorgen() {
    local wallpaper="$1"
    local transition="${2:-grow}"
    local position="${3:-center}"
    
    # Set the wallpaper first
    if change_wallpaper_with_transition "$wallpaper" "$transition" "$position"; then
        # Run material_extract.sh to generate colors from the wallpaper
        if [ -f "$COLORGEN_DIR/material_extract.sh" ]; then
            echo "Generating color scheme from wallpaper..."
            bash "$COLORGEN_DIR/material_extract.sh"
            return $?
        else
            echo "Warning: material_extract.sh not found at $COLORGEN_DIR/material_extract.sh"
            return 1
        fi
    else
        return 1
    fi
}

# Function to set first wallpaper without color generation
set_first_wallpaper_without_colorgen() {
    # Check if this is the first launch
    if [ -f "$FIRST_LAUNCH_FILE" ]; then
        echo "Not first launch, skipping"
        return 0
    fi
    
    echo "First launch detected"
    
    # Check if default background exists
    if [ ! -f "$DEFAULT_BG" ]; then
        echo "Error: Default background not found: $DEFAULT_BG"
        return 1
    fi
    
    # Try to set the wallpaper
    if set_wallpaper "$DEFAULT_BG"; then
        # Create the first launch file
        touch "$FIRST_LAUNCH_FILE"
        echo "First launch setup completed"
        return 0
    else
        echo "Failed to set first wallpaper"
        # Still create the first launch file to prevent repeated attempts
        touch "$FIRST_LAUNCH_FILE"
        return 1
    fi
}

# Function to set first wallpaper with color generation
set_first_wallpaper_with_colorgen() {
    # Check if this is the first launch
    if [ -f "$FIRST_LAUNCH_FILE" ]; then
        echo "Not first launch, skipping"
        return 0
    fi
    
    echo "First launch detected"
    
    # Check if default background exists
    if [ ! -f "$DEFAULT_BG" ]; then
        echo "Error: Default background not found: $DEFAULT_BG"
        return 1
    fi
    
    # Try to set the wallpaper with color generation
    if set_wallpaper_with_colorgen "$DEFAULT_BG"; then
        # Create the first launch file
        touch "$FIRST_LAUNCH_FILE"
        echo "First launch setup completed"
        return 0
    else
        echo "Failed to set first wallpaper with color generation"
        # Still create the first launch file to prevent repeated attempts
        touch "$FIRST_LAUNCH_FILE"
        return 1
    fi
}

# Function to fix swww when it doesn't work
fix_swww_doesnt_work() {
    echo "Attempting to fix swww..."
    
    # Kill any existing swww processes
    pkill -x swww-daemon 2>/dev/null
    
    # Wait for processes to fully terminate
    sleep 1
    
    # Remove socket file if it exists
    SOCKET_FILE="/run/user/$(id -u)/swww-wayland-1.sock"
    if [ -S "$SOCKET_FILE" ]; then
        rm -f "$SOCKET_FILE"
        echo "Removed stale socket file: $SOCKET_FILE"
    fi
    
    # Try to initialize swww with retries
    max_retries=3
    retry=0
    success=false
    
    while [ $retry -lt $max_retries ] && [ "$success" = false ]; do
        retry=$((retry + 1))
        echo "Attempt $retry/$max_retries to fix swww"
        
        if initialize_swww; then
            success=true
            
            # Try to restore last wallpaper if available
            if [ -f "$LAST_WALLPAPER_FILE" ]; then
                LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
                if [ -f "$LAST_WALLPAPER" ]; then
                    echo "Restoring last wallpaper: $LAST_WALLPAPER"
                    swww img "$LAST_WALLPAPER" --transition-type none
                fi
            fi
        else
            echo "Failed to fix swww on attempt $retry"
            sleep 2
        fi
    done
    
    if [ "$success" = true ]; then
        echo "Successfully fixed swww"
        return 0
    else
        echo "Failed to fix swww after $max_retries attempts"
        return 1
    fi
}

# If script is run directly (not sourced), show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        init)
            initialize_swww
            ;;
        set)
            if [ -z "$2" ]; then
                echo "Usage: $0 set <wallpaper_path>"
                exit 1
            fi
            set_wallpaper "$2"
            ;;
        set-with-transition)
            if [ -z "$2" ]; then
                echo "Usage: $0 set-with-transition <wallpaper_path> [transition_type] [transition_pos]"
                exit 1
            fi
            change_wallpaper_with_transition "$2" "$3" "$4"
            ;;
        set-with-colorgen)
            if [ -z "$2" ]; then
                echo "Usage: $0 set-with-colorgen <wallpaper_path> [transition_type] [transition_pos]"
                exit 1
            fi
            set_wallpaper_with_colorgen "$2" "$3" "$4"
            ;;
        set-first)
            set_first_wallpaper_without_colorgen
            ;;
        set-first-with-colorgen)
            set_first_wallpaper_with_colorgen
            ;;
        fix)
            fix_swww_doesnt_work
            ;;
        *)
            echo "SWWW Manager - Centralized wallpaper management for Hyprland"
            echo
            echo "Usage: $0 <command> [options]"
            echo
            echo "Commands:"
            echo "  init                          Initialize swww daemon"
            echo "  set <path>                    Set wallpaper with default transition"
            echo "  set-with-transition <path> [type] [pos]  Set wallpaper with custom transition"
            echo "  set-with-colorgen <path> [type] [pos]    Set wallpaper and generate color scheme"
            echo "  set-first                     Set first wallpaper without color generation"
            echo "  set-first-with-colorgen       Set first wallpaper with color generation"
            echo "  fix                           Fix swww when it doesn't work"
            echo
            echo "Current wallpaper: $([ -f "$LAST_WALLPAPER_FILE" ] && cat "$LAST_WALLPAPER_FILE" || echo "None")"
            ;;
    esac
fi 