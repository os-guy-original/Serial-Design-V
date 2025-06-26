#!/bin/bash

# charger_monitor.sh - Updated to use a hybrid approach for reliability

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Charger connection monitoring and notification script
# Plays a sound and sends notifications when a charger is connected or disconnected

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

# Print the sound folder path
echo "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"
debug_log "Charger monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Define the charging sound
CHARGING_SOUND="charging.ogg"

debug_log "Final charging sound: $CHARGING_SOUND"
debug_log "Sound file exists: $([ -f "$(get_sound_file "$CHARGING_SOUND")" ] && echo "YES" || echo "NO")"

echo "Charger monitoring script is running with hybrid approach for reliability."
debug_log "Starting charger monitor with hybrid approach"

# Initialize the first check for charger status
LAST_CHARGER_STATUS="unknown"

# Function to get power supply directory
get_power_supply_dir() {
    if [ -d "/sys/class/power_supply" ]; then
        echo "/sys/class/power_supply"
    else
        echo ""
    fi
}

# Function to find AC adapters
find_ac_adapters() {
    local power_dir="$1"
    local adapters=()
    
    if [ -z "$power_dir" ]; then
        return
    fi
    
    for supply in "$power_dir"/*; do
        if [ -f "$supply/type" ]; then
            if grep -q "Mains" "$supply/type"; then
                adapters+=("$supply")
                debug_log "Found AC adapter: $supply"
            fi
        fi
    done
    
    echo "${adapters[@]}"
}

# Function to get current charger status
get_charger_status() {
    local power_dir=$(get_power_supply_dir)
    local status="0"
    
    if [ -z "$power_dir" ]; then
        debug_log "Power supply directory not found"
        return 1
    fi
    
    # Check all power supplies
    local adapters=($(find_ac_adapters "$power_dir"))
    
    for adapter in "${adapters[@]}"; do
        if [ -f "$adapter/online" ]; then
            status=$(cat "$adapter/online" 2>/dev/null || echo "0")
            if [ "$status" = "1" ]; then
                break
            fi
        fi
    done
    
    echo "$status"
}

# Function to handle charger status change
handle_charger_status_change() {
    local current_status="$1"
    
    debug_log "Handling charger status change: current=$current_status, previous=$LAST_CHARGER_STATUS"
    
    # If the adapter is plugged in (1) and previous state was not plugged in
    if [[ "$current_status" == "1" && "$LAST_CHARGER_STATUS" != "1" ]]; then
        echo "Charger connected"
        debug_log "Charger connected, playing sound"
        play_sound "$CHARGING_SOUND"
        notify-send -i battery-full-charging "Charger Connected" "Power adapter has been connected"
    
    # If the adapter is unplugged (0) and previous state was plugged in
    elif [[ "$current_status" == "0" && "$LAST_CHARGER_STATUS" == "1" ]]; then
        echo "Charger disconnected"
        debug_log "Charger disconnected, sending notification"
        notify-send -i battery "Charger Disconnected" "Power adapter has been disconnected"
    fi
    
    # Update the last status
    LAST_CHARGER_STATUS="$current_status"
}

# Get initial charger status
LAST_CHARGER_STATUS=$(get_charger_status)
debug_log "Initial charger status: $([ "$LAST_CHARGER_STATUS" == "1" ] && echo "Connected" || echo "Disconnected")"

# Hybrid monitoring approach
hybrid_monitor() {
    local power_dir=$(get_power_supply_dir)
    
    if [ -z "$power_dir" ]; then
        debug_log "Power supply directory not found, using polling only"
        polling_monitor
        return
    fi
    
    debug_log "Starting hybrid monitoring on $power_dir"
    
    # Start polling in the background (as a safety net)
    polling_monitor &
    local polling_pid=$!
    
    # Clean up on exit
    trap 'kill $polling_pid 2>/dev/null; exit 0' EXIT
    
    # Wait for the polling monitor to finish (which should never happen)
    wait $polling_pid
}

# Polling monitor function
polling_monitor() {
    debug_log "Starting polling monitor"
    
    while true; do
        # Get current status
        local current_status=$(get_charger_status)
        
        # Check if status changed
        if [ "$current_status" != "$LAST_CHARGER_STATUS" ]; then
            handle_charger_status_change "$current_status"
        fi
        
        # Sleep for a short time
        sleep 2
    done
}

# Start the hybrid monitor
hybrid_monitor
