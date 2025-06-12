#!/bin/bash

# Script to check if all required sound files are present in the sound theme directories
# This helps diagnose missing sound files and creates placeholders if needed

# Sound file paths
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Ensure the base sounds directory exists
mkdir -p "$SOUNDS_BASE_DIR"

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        CURRENT_THEME="$SOUND_THEME"
    else
        CURRENT_THEME="default"
        # Update the default-sound file
        echo "default" > "$DEFAULT_SOUND_FILE"
    fi
else
    CURRENT_THEME="default"
    # Create default-sound file
    echo "default" > "$DEFAULT_SOUND_FILE"
fi

echo "Current sound theme: $CURRENT_THEME"

# Create sound directories if they don't exist
mkdir -p "$SOUNDS_BASE_DIR/default"

# If current theme is not default, create that directory too
if [ "$CURRENT_THEME" != "default" ]; then
    mkdir -p "$SOUNDS_BASE_DIR/$CURRENT_THEME"
fi

# List of all required sound files
REQUIRED_SOUNDS=(
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

# Check for missing sound files and report
check_theme_sounds() {
    local theme="$1"
    local theme_dir="$SOUNDS_BASE_DIR/$theme"
    local missing=0
    
    echo "Checking sound files for theme: $theme"
    echo "Theme directory: $theme_dir"
    
    # Check if directory exists
    if [ ! -d "$theme_dir" ]; then
        echo "Error: Theme directory does not exist: $theme_dir"
        mkdir -p "$theme_dir"
        echo "Created theme directory: $theme_dir"
    fi
    
    # First, list all files in the theme directory
    echo "Files currently in theme directory:"
    find "$theme_dir" -type f -name "*.ogg" | sort
    
    for sound in "${REQUIRED_SOUNDS[@]}"; do
        if [ ! -f "$theme_dir/$sound" ]; then
            echo "  Missing: $sound"
            missing=$((missing + 1))
            
            # If this is the default theme, copy a similar sound if possible
            if [ "$theme" = "default" ]; then
                # Try to find a suitable replacement from existing files
                if [ "$sound" = "screenshot.ogg" ] && [ -f "$theme_dir/notification.ogg" ]; then
                    cp "$theme_dir/notification.ogg" "$theme_dir/$sound"
                    echo "    Created copy from notification.ogg"
                elif [[ "$sound" =~ ^(warning|error|critical).ogg$ ]] && [ -f "$theme_dir/device-removed.ogg" ]; then
                    cp "$theme_dir/device-removed.ogg" "$theme_dir/$sound"
                    echo "    Created copy from device-removed.ogg"
                elif [[ "$sound" =~ ^(volume-up|volume-down|mute|unmute).ogg$ ]] && [ -f "$theme_dir/device-added.ogg" ]; then
                    cp "$theme_dir/device-added.ogg" "$theme_dir/$sound"
                    echo "    Created copy from device-added.ogg"
                elif [[ "$sound" =~ ^(record-start|record-stop|info).ogg$ ]] && [ -f "$theme_dir/notification.ogg" ]; then
                    cp "$theme_dir/notification.ogg" "$theme_dir/$sound"
                    echo "    Created copy from notification.ogg"
                elif [[ "$sound" =~ ^(charging).ogg$ ]] && [ -f "$theme_dir/device-added.ogg" ]; then
                    cp "$theme_dir/device-added.ogg" "$theme_dir/$sound"
                    echo "    Created copy from device-added.ogg"
                elif [[ "$sound" =~ ^(toggle_performance).ogg$ ]] && [ -f "$theme_dir/notification.ogg" ]; then
                    cp "$theme_dir/notification.ogg" "$theme_dir/$sound"
                    echo "    Created copy from notification.ogg"
                fi
            fi
        else
            echo "  Found: $sound"
            # Check if file is actually a symlink and replace with a real file
            if [ -L "$theme_dir/$sound" ]; then
                TARGET=$(readlink -f "$theme_dir/$sound")
                if [ -f "$TARGET" ]; then
                    echo "    Converting symlink to real file"
                    cp "$TARGET" "$theme_dir/$sound.tmp"
                    rm "$theme_dir/$sound"
                    mv "$theme_dir/$sound.tmp" "$theme_dir/$sound"
                fi
            fi
        fi
    done
    
    if [ $missing -eq 0 ]; then
        echo "All required sound files are present for theme: $theme"
        return 0
    else
        echo "$missing sound files are missing for theme: $theme"
        return 1
    fi
}

# Test sound playback function
test_sound_playback() {
    local sound_file="$1"
    
    echo "Testing sound playback with: $sound_file"
    
    if [ ! -f "$sound_file" ]; then
        echo "Error: Sound file not found: $sound_file"
        return 1
    fi
    
    # Use mpv only
    if command -v mpv >/dev/null 2>&1; then
        echo "Testing with mpv..."
        mpv --no-terminal --volume=100 "$sound_file" 2>/dev/null
        echo "mpv exit code: $?"
    else
        echo "Error: mpv is not installed. Please install mpv to play sounds."
        return 1
    fi
}

# Make sure default-sound file exists with correct permissions
if [ ! -f "$DEFAULT_SOUND_FILE" ]; then
    echo "default" > "$DEFAULT_SOUND_FILE"
    echo "Created default-sound file with 'default' theme"
fi

# Ensure the default-sound file is readable and writable
chmod 644 "$DEFAULT_SOUND_FILE"

# Check default theme first
check_theme_sounds "default"

# If current theme is not default, check that too
if [ "$CURRENT_THEME" != "default" ]; then
    check_theme_sounds "$CURRENT_THEME"
fi

# Test sound playback
if [ -f "$SOUNDS_BASE_DIR/default/notification.ogg" ]; then
    test_sound_playback "$SOUNDS_BASE_DIR/default/notification.ogg"
fi

echo "Sound theme check complete."
echo "If sounds are missing, you can add them to:"
echo "  $SOUNDS_BASE_DIR/default/ (for the default theme)"
if [ "$CURRENT_THEME" != "default" ]; then
    echo "  $SOUNDS_BASE_DIR/$CURRENT_THEME/ (for your current theme)"
fi
echo
echo "Note: Any missing sounds will be replaced with similar sounds where possible." 