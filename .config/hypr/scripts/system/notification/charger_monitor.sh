#!/bin/bash

# Charger connection monitoring and notification script
# Plays a sound and sends notifications when a charger is connected or disconnected

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Create a log file for debugging
DEBUG_LOG="/tmp/charger_monitor_debug.log"
echo "Starting charger monitor at $(date)" > "$DEBUG_LOG"

# Debug function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG"
}

# Sound file path
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    debug_log "Read sound theme from default-sound file: '$SOUND_THEME'"
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
        debug_log "Theme directory doesn't exist, falling back to default"
    fi
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    debug_log "No default-sound file found, using default directory"
fi

# Print the sound folder path
echo "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"
debug_log "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

CHARGING_SOUND="$SOUNDS_DIR/charging.ogg"

# Fallback to original location if file doesn't exist
if [ ! -f "$CHARGING_SOUND" ]; then
    debug_log "Charging sound not found in theme directory: $CHARGING_SOUND"
    if [ -f "$SOUNDS_BASE_DIR/charging.ogg" ]; then
        # Try to create the directory and copy the file
        mkdir -p "$SOUNDS_DIR"
        cp "$SOUNDS_BASE_DIR/charging.ogg" "$CHARGING_SOUND"
        debug_log "Copied charging.ogg to theme directory"
    else
        # If all else fails, use the original file
        SOUNDS_DIR="$SOUNDS_BASE_DIR"
        CHARGING_SOUND="$SOUNDS_DIR/charging.ogg"
        debug_log "Still couldn't find charging sound, falling back to base sounds directory"
    fi
fi

debug_log "Final charging sound: $CHARGING_SOUND"
debug_log "Sound file exists: $([ -f "$CHARGING_SOUND" ] && echo "YES" || echo "NO")"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        debug_log "Playing sound: $sound_file"
        # Use mpv only
        if command -v mpv >/dev/null 2>&1; then
            debug_log "Using mpv to play sound"
            mpv --no-terminal "$sound_file" 2>> "$DEBUG_LOG" &
        else
            debug_log "WARNING: mpv not found. Please install mpv to play sounds."
            echo "WARNING: mpv not found. Please install mpv to play sounds."
        fi
    else
        debug_log "WARNING: Sound file not found: $sound_file"
        echo "WARNING: Sound file not found: $sound_file"
    fi
}

echo "Charger monitoring script is running. Press Ctrl+C to stop."
echo "Charging sound: $CHARGING_SOUND"
debug_log "Starting charger monitor loop"

# Initialize the first check for charger status
FIRST_RUN=true
LAST_CHARGER_STATUS="unknown"

# Check initial power status silently
if ls /sys/class/power_supply/*/online >/dev/null 2>&1; then
    for adapter in /sys/class/power_supply/*/online; do
        if [[ -f "$adapter" ]]; then
            LAST_CHARGER_STATUS=$(cat "$adapter")
            echo "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"
            debug_log "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"
            break
        fi
    done
else
    # Alternative method for initial check
    if ls /sys/class/power_supply/*/type >/dev/null 2>&1; then
        CHARGER_CONNECTED=0
        for type_file in /sys/class/power_supply/*/type; do
            if [[ -f "$type_file" ]]; then
                TYPE=$(cat "$type_file")
                if [[ "$TYPE" == "Mains" ]]; then
                    SUPPLY_NAME=$(basename "$(dirname "$type_file")")
                    STATUS_FILE="/sys/class/power_supply/$SUPPLY_NAME/online"
                    if [[ -f "$STATUS_FILE" && "$(cat "$STATUS_FILE")" == "1" ]]; then
                        CHARGER_CONNECTED=1
                    fi
                fi
            fi
        done
        LAST_CHARGER_STATUS="$CHARGER_CONNECTED"
        echo "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"
        debug_log "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"
    fi
fi

# Monitor power supply events
while true; do
    # Check if AC adapter is connected (works with most systems)
    if ls /sys/class/power_supply/*/online >/dev/null 2>&1; then
        for adapter in /sys/class/power_supply/*/online; do
            if [[ -f "$adapter" ]]; then
                CURRENT_STATUS=$(cat "$adapter")
                debug_log "Checking adapter $adapter, status: $CURRENT_STATUS, previous: $LAST_CHARGER_STATUS"
                
                # If the adapter is plugged in (1) and previous state was not plugged in
                if [[ "$CURRENT_STATUS" == "1" && "$LAST_CHARGER_STATUS" != "1" ]]; then
                    echo "Charger connected"
                    debug_log "Charger connected, playing sound"
                    play_sound "$CHARGING_SOUND"
                    notify-send -i battery-full-charging "Charger Connected" "Power adapter has been connected"
                
                # If the adapter is unplugged (0) and previous state was plugged in
                elif [[ "$CURRENT_STATUS" == "0" && "$LAST_CHARGER_STATUS" == "1" ]]; then
                    echo "Charger disconnected"
                    debug_log "Charger disconnected, sending notification"
                    notify-send -i battery "Charger Disconnected" "Power adapter has been disconnected"
                fi
                
                # Update the last status
                LAST_CHARGER_STATUS="$CURRENT_STATUS"
            fi
        done
    else
        # Alternative method for systems that don't have online indicator
        if ls /sys/class/power_supply/*/type >/dev/null 2>&1; then
            CHARGER_CONNECTED=0
            for type_file in /sys/class/power_supply/*/type; do
                if [[ -f "$type_file" ]]; then
                    TYPE=$(cat "$type_file")
                    if [[ "$TYPE" == "Mains" ]]; then
                        SUPPLY_NAME=$(basename "$(dirname "$type_file")")
                        STATUS_FILE="/sys/class/power_supply/$SUPPLY_NAME/online"
                        if [[ -f "$STATUS_FILE" && "$(cat "$STATUS_FILE")" == "1" ]]; then
                            CHARGER_CONNECTED=1
                        fi
                    fi
                fi
            done
            
            debug_log "Alternative check: CHARGER_CONNECTED=$CHARGER_CONNECTED, LAST_CHARGER_STATUS=$LAST_CHARGER_STATUS"
            
            # If charger is connected and previous state was not connected
            if [[ "$CHARGER_CONNECTED" == "1" && "$LAST_CHARGER_STATUS" != "1" ]]; then
                echo "Charger connected"
                debug_log "Charger connected (alternative), playing sound"
                play_sound "$CHARGING_SOUND"
                notify-send -i battery-full-charging "Charger Connected" "Power adapter has been connected"
            
            # If charger is disconnected and previous state was connected
            elif [[ "$CHARGER_CONNECTED" == "0" && "$LAST_CHARGER_STATUS" == "1" ]]; then
                echo "Charger disconnected"
                debug_log "Charger disconnected (alternative), sending notification"
                notify-send -i battery "Charger Disconnected" "Power adapter has been disconnected"
            fi
            
            # Update the last status
            LAST_CHARGER_STATUS="$CHARGER_CONNECTED"
        fi
    fi
    
    # Sleep for a short time before checking again
    sleep 2
done 