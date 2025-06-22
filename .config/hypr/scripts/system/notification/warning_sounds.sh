#!/bin/bash

# warning_sounds.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Warning sound system for Hyprland
# Plays different warning sounds based on severity level

# Determine the sound directory to use
# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Check if default-sound file exists and read its content
# Get sound theme from sound manager
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
fi

# Print the sound folder path
echo "Warning sounds using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

INFO_SOUND=
WARNING_SOUND=
ERROR_SOUND=
CRITICAL_SOUND=

# Create default sound files if they don't exist
if [ ! -f  ]; then
    mkdir -p "$SOUNDS_DIR"
    cp  "$INFO_SOUND"
fi

if [ ! -f  ]; then
    mkdir -p "$SOUNDS_DIR"
    cp  "$WARNING_SOUND"
fi

if [ ! -f  ]; then
    mkdir -p "$SOUNDS_DIR"
    cp  "$ERROR_SOUND"
fi

if [ ! -f  ]; then
    mkdir -p "$SOUNDS_DIR"
    cp  "$CRITICAL_SOUND"
fi


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
