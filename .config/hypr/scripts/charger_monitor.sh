#!/bin/bash

# Charger connection monitoring and notification script
# Plays a sound and sends notifications when a charger is connected or disconnected

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Sound file path
SOUNDS_DIR="$HOME/.config/hypr/sounds"
CHARGING_SOUND="$SOUNDS_DIR/charging.ogg"

# Function to play sounds
play_sound() {
    local sound_file="$1"
    
    # Check if sound file exists
    if [[ -f "$sound_file" ]]; then
        # Use any available sound player
        if command -v paplay >/dev/null 2>&1; then
            paplay "$sound_file" &
        elif command -v ogg123 >/dev/null 2>&1; then
            ogg123 -q "$sound_file" &
        elif command -v mpv >/dev/null 2>&1; then
            mpv --no-terminal "$sound_file" &
        elif command -v aplay >/dev/null 2>&1; then
            aplay -q "$sound_file" &
        else
            echo "WARNING: No sound player found."
        fi
    else
        echo "WARNING: Sound file not found: $sound_file"
    fi
}

echo "Charger monitoring script is running. Press Ctrl+C to stop."
echo "Charging sound: $CHARGING_SOUND"

# Initialize the first check for charger status
FIRST_RUN=true
LAST_CHARGER_STATUS="unknown"

# Check initial power status silently
if ls /sys/class/power_supply/*/online >/dev/null 2>&1; then
    for adapter in /sys/class/power_supply/*/online; do
        if [[ -f "$adapter" ]]; then
            LAST_CHARGER_STATUS=$(cat "$adapter")
            echo "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"
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
    fi
fi

# Monitor power supply events
while true; do
    # Check if AC adapter is connected (works with most systems)
    if ls /sys/class/power_supply/*/online >/dev/null 2>&1; then
        for adapter in /sys/class/power_supply/*/online; do
            if [[ -f "$adapter" ]]; then
                CURRENT_STATUS=$(cat "$adapter")
                
                # If the adapter is plugged in (1) and previous state was not plugged in
                if [[ "$CURRENT_STATUS" == "1" && "$LAST_CHARGER_STATUS" != "1" ]]; then
                    echo "Charger connected"
                    play_sound "$CHARGING_SOUND"
                    notify-send -i battery-full-charging "Charger Connected" "Power adapter has been connected"
                
                # If the adapter is unplugged (0) and previous state was plugged in
                elif [[ "$CURRENT_STATUS" == "0" && "$LAST_CHARGER_STATUS" == "1" ]]; then
                    echo "Charger disconnected"
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
            
            # If charger is connected and previous state was not connected
            if [[ "$CHARGER_CONNECTED" == "1" && "$LAST_CHARGER_STATUS" != "1" ]]; then
                echo "Charger connected"
                play_sound "$CHARGING_SOUND"
                notify-send -i battery-full-charging "Charger Connected" "Power adapter has been connected"
            
            # If charger is disconnected and previous state was connected
            elif [[ "$CHARGER_CONNECTED" == "0" && "$LAST_CHARGER_STATUS" == "1" ]]; then
                echo "Charger disconnected"
                notify-send -i battery "Charger Disconnected" "Power adapter has been disconnected"
            fi
            
            # Update the last status
            LAST_CHARGER_STATUS="$CHARGER_CONNECTED"
        fi
    fi
    
    # Sleep for a short time before checking again
    sleep 2
done 