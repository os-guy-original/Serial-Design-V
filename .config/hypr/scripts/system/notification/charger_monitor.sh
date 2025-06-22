#!/bin/bash

# charger_monitor.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Charger connection monitoring and notification script
# Plays a sound and sends notifications when a charger is connected or disconnected

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Create a log file for debugging - use cache directory instead of /tmp
CACHE_DIR="$HOME/.config/hypr/cache/logs"
mkdir -p "$CACHE_DIR"
DEBUG_LOG="$CACHE_DIR/charger_monitor_debug.log"
echo "Starting charger monitor at $(date)" > "$DEBUG_LOG"

# Debug function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG"
}

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Print the sound folder path
echo "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"
debug_log "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Define the charging sound
CHARGING_SOUND="charging.ogg"

debug_log "Final charging sound: $CHARGING_SOUND"
debug_log "Sound file exists: $([ -f "$(get_sound_file "$CHARGING_SOUND")" ] && echo "YES" || echo "NO")"

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
