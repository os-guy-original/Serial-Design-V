#!/bin/bash

# sound_manager.sh - Centralized sound management script for Hyprland
# This script provides functions for sound theme management and playback
# Other scripts should source this file to use its functions

# Base directories
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"
CACHE_DIR="$HOME/.config/hypr/cache/logs"
SOUND_LOG="$CACHE_DIR/sound_manager.log"

# Create necessary directories
mkdir -p "$CACHE_DIR"

# Initialize log file
init_log() {
    if [[ "$1" == "clear" ]]; then
        echo "Sound Manager initialized at $(date)" > "$SOUND_LOG"
    else
        echo "Sound Manager initialized at $(date)" >> "$SOUND_LOG"
    fi
}

# Log function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SOUND_LOG"
}

# Get the current sound theme
get_sound_theme() {
    if [[ -f "$DEFAULT_SOUND_FILE" ]]; then
        # Properly trim whitespace and newlines
        SOUND_THEME=$(tr -d '\n' < "$DEFAULT_SOUND_FILE" | tr -d '\r' | tr -d '[:space:]')
        
        if [[ -n "$SOUND_THEME" && -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]]; then
            echo "$SOUND_THEME"
            return 0
        fi
    fi
    
    # Default fallback
    echo "default"
    return 1
}

# Get the path to the sound directory
get_sound_dir() {
    local theme=$(get_sound_theme)
    local sound_dir="$SOUNDS_BASE_DIR/$theme"
    
    # Check if directory exists
    if [[ -d "$sound_dir" ]]; then
        echo "$sound_dir"
    else
        # Fallback to default
        echo "$SOUNDS_BASE_DIR/default"
    fi
}

# Get the path to a specific sound file
get_sound_file() {
    local sound_name="$1"
    local sound_dir=$(get_sound_dir)
    local sound_file="$sound_dir/$sound_name"
    
    # Check if file exists
    if [[ -f "$sound_file" ]]; then
        echo "$sound_file"
        return 0
    else
        # Try default directory if not in current theme
        if [[ "$sound_dir" != "$SOUNDS_BASE_DIR/default" ]]; then
            local default_sound="$SOUNDS_BASE_DIR/default/$sound_name"
            if [[ -f "$default_sound" ]]; then
                echo "$default_sound"
                return 0
            fi
        fi
        
        # Return empty if not found
        echo ""
        return 1
    fi
}

# Set the sound theme
set_sound_theme() {
    local theme="$1"
    
    # Validate theme
    if [[ -z "$theme" ]]; then
        log_message "Error: Cannot set empty theme"
        return 1
    fi
    
    # Create theme directory if it doesn't exist
    if [[ ! -d "$SOUNDS_BASE_DIR/$theme" ]]; then
        mkdir -p "$SOUNDS_BASE_DIR/$theme"
        log_message "Created theme directory: $SOUNDS_BASE_DIR/$theme"
    fi
    
    # Update the default-sound file
    echo "$theme" > "$DEFAULT_SOUND_FILE"
    log_message "Set sound theme to: $theme"
    
    return 0
}

# Play a sound file
play_sound() {
    local sound_name="$1"
    local volume="${2:-100}"  # Default volume is 100%
    local reverse="${3:-false}"  # Option to play sound in reverse
    
    # Get the sound file path
    local sound_file=$(get_sound_file "$sound_name")
    
    if [[ -n "$sound_file" && -f "$sound_file" ]]; then
        log_message "Playing sound: $sound_name ($sound_file) at volume $volume% reverse=$reverse"
        
        # Use mpv for playback
        if command -v mpv >/dev/null 2>&1; then
            if [ "$reverse" = "true" ]; then
                # Play in reverse with af=areverse filter
                mpv --no-terminal --volume="$volume" --af=areverse "$sound_file" 2>/dev/null &
            else
                mpv --no-terminal --volume="$volume" "$sound_file" 2>/dev/null &
            fi
            return 0
        else
            log_message "Error: mpv not installed"
            return 1
        fi
    else
        log_message "Error: Sound file not found: $sound_name"
        return 1
    fi
}

# List available sound themes
list_themes() {
    if [[ -d "$SOUNDS_BASE_DIR" ]]; then
        find "$SOUNDS_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    fi
}

# List available sounds in a theme
list_sounds() {
    local theme="${1:-$(get_sound_theme)}"
    local sound_dir="$SOUNDS_BASE_DIR/$theme"
    
    if [[ -d "$sound_dir" ]]; then
        find "$sound_dir" -name "*.ogg" -exec basename {} \;
    fi
}

# Check if required sounds exist in the theme
check_required_sounds() {
    local theme="${1:-$(get_sound_theme)}"
    local sound_dir="$SOUNDS_BASE_DIR/$theme"
    
    # List of required sounds
    local required_sounds=(
        "notification.ogg"
        "device-added.ogg"
        "device-removed.ogg"
        "screenshot.ogg"
        "volume-up.ogg"
        "volume-down.ogg"
        "mute.ogg"
        "unmute.ogg"
        "record-start.ogg"
        "record-stop.ogg"
        "error.ogg"
        "warning.ogg"
        "critical.ogg"
        "info.ogg"
        "login.ogg"
        "logout.ogg"
        "charging.ogg"
        "toggle_performance.ogg"
    )
    
    local missing=0
    local missing_sounds=()
    
    for sound in "${required_sounds[@]}"; do
        if [[ ! -f "$sound_dir/$sound" ]]; then
            missing=$((missing + 1))
            missing_sounds+=("$sound")
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        echo "All required sounds are present in theme: $theme"
        return 0
    else
        echo "$missing sounds are missing from theme: $theme"
        echo "Missing: ${missing_sounds[*]}"
        return 1
    fi
}

# If script is run directly (not sourced), show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize log
    init_log "clear"
    
    case "$1" in
        play)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 play <sound_name> [volume] [reverse]"
                exit 1
            fi
            # Handle reverse parameter properly
            if [[ "$4" == "true" || "$4" == "reverse" ]]; then
                play_sound "$2" "$3" "true"
            else
                play_sound "$2" "$3" "$4"
            fi
            ;;
        theme)
            if [[ -z "$2" ]]; then
                echo "Current theme: $(get_sound_theme)"
            else
                set_sound_theme "$2"
                echo "Theme set to: $2"
            fi
            ;;
        list-themes)
            echo "Available themes:"
            list_themes
            ;;
        list-sounds)
            echo "Sounds in theme $(get_sound_theme):"
            list_sounds "$2"
            ;;
        check)
            check_required_sounds "$2"
            ;;
        *)
            echo "Sound Manager - Centralized sound system for Hyprland"
            echo
            echo "Usage: $0 <command> [options]"
            echo
            echo "Commands:"
            echo "  play <sound> [volume] [reverse]   Play a sound file (volume 0-100, reverse=true/false)"
            echo "  theme [name]                      Get or set the current theme"
            echo "  list-themes                       List available sound themes"
            echo "  list-sounds [theme]               List sounds in the current or specified theme"
            echo "  check [theme]                     Check if required sounds exist in theme"
            echo
            echo "Current theme: $(get_sound_theme)"
            echo "Sound directory: $(get_sound_dir)"
            ;;
    esac
fi 