#!/bin/bash

# Warning sound system for Hyprland
# Plays different warning sounds based on severity level

# Determine the sound directory to use
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

# Print the sound folder path
echo "Warning sounds using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Sound file paths
INFO_SOUND="$SOUNDS_DIR/notification.ogg"
WARNING_SOUND="$SOUNDS_DIR/device-removed.ogg"
ERROR_SOUND="$SOUNDS_DIR/logout.ogg"
CRITICAL_SOUND="$SOUNDS_DIR/logout.ogg"

# Create default sound files if they don't exist
if [ ! -f "$INFO_SOUND" ] && [ -f "$SOUNDS_BASE_DIR/notification.ogg" ]; then
    mkdir -p "$SOUNDS_DIR"
    cp "$SOUNDS_BASE_DIR/notification.ogg" "$INFO_SOUND"
fi

if [ ! -f "$WARNING_SOUND" ] && [ -f "$SOUNDS_BASE_DIR/device-removed.ogg" ]; then
    mkdir -p "$SOUNDS_DIR"
    cp "$SOUNDS_BASE_DIR/device-removed.ogg" "$WARNING_SOUND"
fi

if [ ! -f "$ERROR_SOUND" ] && [ -f "$SOUNDS_BASE_DIR/logout.ogg" ]; then
    mkdir -p "$SOUNDS_DIR"
    cp "$SOUNDS_BASE_DIR/logout.ogg" "$ERROR_SOUND"
fi

if [ ! -f "$CRITICAL_SOUND" ] && [ -f "$SOUNDS_BASE_DIR/logout.ogg" ]; then
    mkdir -p "$SOUNDS_DIR"
    cp "$SOUNDS_BASE_DIR/logout.ogg" "$CRITICAL_SOUND"
fi

# Function to play sounds
play_sound() {
    local sound_file="$1"
    local volume="$2"
    
    # Default volume if not specified
    [[ -z "$volume" ]] && volume="100%"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal --volume="$volume" "$sound_file" &
        else
            echo "WARNING: mpv not found. Please install mpv to play sounds."
            return 1
        fi
        return 0
    else
        echo "WARNING: Sound file not found: $sound_file"
        return 1
    fi
}

# Function to play warning sound and show notification
play_warning() {
    local level="$1"
    local title="$2"
    local message="$3"
    local volume="$4"
    local sound_only="$5"
    
    local icon="dialog-information"
    local sound_file="$INFO_SOUND"
    local urgency="normal"
    
    # Set icon, sound, and volume based on level
    case "$level" in
        info|INFO)
            icon="dialog-information"
            sound_file="$INFO_SOUND"
            urgency="low"
            [[ -z "$volume" ]] && volume="80%"
            ;;
        warning|WARNING)
            icon="dialog-warning"
            sound_file="$WARNING_SOUND"
            urgency="normal"
            [[ -z "$volume" ]] && volume="100%"
            ;;
        error|ERROR)
            icon="dialog-error"
            sound_file="$ERROR_SOUND"
            urgency="critical"
            [[ -z "$volume" ]] && volume="120%"
            ;;
        critical|CRITICAL)
            icon="dialog-error"
            sound_file="$CRITICAL_SOUND"
            urgency="critical"
            [[ -z "$volume" ]] && volume="150%"
            ;;
        *)
            echo "Unknown warning level: $level"
            return 1
            ;;
    esac
    
    # Play sound
    play_sound "$sound_file" "$volume"
    
    # Show notification if title and message provided AND sound_only is not set
    if [[ -n "$title" && -n "$message" && "$sound_only" != "sound_only" ]]; then
        notify-send -i "$icon" -u "$urgency" "$title" "$message"
    fi
}

# If script is called directly, handle command line arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if at least level is provided
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <level> [title] [message] [volume] [sound_only]"
        echo "  level: info, warning, error, critical"
        echo "  title: Notification title (optional)"
        echo "  message: Notification message (optional)"
        echo "  volume: Sound volume (optional, default depends on level)"
        echo "  sound_only: Set to 'sound_only' to prevent showing notification"
        exit 1
    fi
    
    # Call the function with provided arguments
    play_warning "$@"
fi 