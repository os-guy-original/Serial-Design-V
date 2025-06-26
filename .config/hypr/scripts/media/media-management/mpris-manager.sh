#!/bin/bash

# MPRIS Manager
# This script monitors MPRIS players and ensures only one is active at a time
# When a new player starts, it pauses any previously active players
# Optimized to only run when media players are active

LAST_ACTIVE_PLAYER=""
DEBUG=false
LOG_FILE="$HOME/.config/hypr/scripts/media/media-management/mpris-manager.log"
SLEEP_INTERVAL=0.5  # Slightly increased for less CPU usage

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

# Function to check if any media players are running
any_players_running() {
    if playerctl -l --no-messages 2>/dev/null | grep -q .; then
        return 0  # Players running
    else
        return 1  # No players running
    fi
}

# Function to check if any players are playing
any_players_playing() {
    for player in $(playerctl -l --no-messages 2>/dev/null); do
        if playerctl -p "$player" status 2>/dev/null | grep -q "Playing"; then
            return 0  # At least one player is playing
        fi
    done
    return 1  # No players are playing
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

# Check if playerctl is available
if ! command -v playerctl >/dev/null 2>&1; then
    echo "Error: playerctl not found. Please install it."
    exit 1
fi

log "MPRIS manager started"

# Main loop - adaptive monitoring
while true; do
    # Check if any players are running
    if any_players_running; then
        # Check if any players are playing
        if any_players_playing; then
            # Players are active, monitor more frequently
            handle_media_players
            sleep $SLEEP_INTERVAL
        else
            # Players exist but none are playing, check less frequently
            log "Players exist but none are playing, sleeping longer"
            sleep 2
        fi
    else
        # No players running, sleep longer to save resources
        log "No players running, sleeping longer"
        sleep 5
        
        # Reset last active player when no players are running
        if [ -n "$LAST_ACTIVE_PLAYER" ]; then
            log "Resetting last active player (was: $LAST_ACTIVE_PLAYER)"
            LAST_ACTIVE_PLAYER=""
        fi
    fi
done 