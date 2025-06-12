#!/bin/bash

# MPRIS Manager
# This script monitors MPRIS players and ensures only one is active at a time
# When a new player starts, it pauses any previously active players

LAST_ACTIVE_PLAYER=""
DEBUG=false
LOG_FILE="$HOME/.config/hypr/scripts/media/media-management/mpris-manager.log"
SLEEP_INTERVAL=0.2  # Reduced sleep interval for faster response

log() {
    if [ "$DEBUG" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

pause_player() {
    local player=$1
    if [ -n "$player" ]; then
        log "Pausing player: $player"
        playerctl -p "$player" pause 2>/dev/null &
    fi
}

handle_media_players() {
    # Get currently playing players more efficiently
    local playing_players=$(playerctl -l --no-messages 2>/dev/null)
    local new_player=""
    
    # Check each player's status in parallel
    for player in $playing_players; do
        if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
            if [ "$player" != "$LAST_ACTIVE_PLAYER" ] && [ -n "$LAST_ACTIVE_PLAYER" ]; then
                # A new player started while another was already playing
                new_player="$player"
                break
            elif [ -z "$LAST_ACTIVE_PLAYER" ]; then
                # First player to start
                LAST_ACTIVE_PLAYER="$player"
                log "First player detected: $LAST_ACTIVE_PLAYER"
            fi
        fi
    done
    
    # If we found a new player, pause the old one
    if [ -n "$new_player" ]; then
        log "New player detected: $new_player (previous: $LAST_ACTIVE_PLAYER)"
        pause_player "$LAST_ACTIVE_PLAYER"
        LAST_ACTIVE_PLAYER="$new_player"
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Use trap to ensure clean exit
trap 'log "MPRIS manager stopped"; exit 0' TERM INT

# Main loop
while true; do
    handle_media_players
    sleep $SLEEP_INTERVAL
done & 