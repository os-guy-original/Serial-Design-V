#!/bin/bash

# service_manager.sh - A script to manage notification services efficiently
# This script starts services only when needed and stops them when idle

# Set the directory where notification scripts are located
SCRIPTS_DIR="$HOME/.config/hypr/scripts/system/notification"
CACHE_DIR="$HOME/.config/hypr/cache"
LOG_DIR="$CACHE_DIR/logs"
STATE_DIR="$CACHE_DIR/state"

# Create necessary directories
mkdir -p "$LOG_DIR" "$STATE_DIR"

# Log file
LOG_FILE="$LOG_DIR/service_manager.log"

# PID files
USB_MONITOR_PID_FILE="$STATE_DIR/usb_monitor.pid"
CHARGER_MONITOR_PID_FILE="$STATE_DIR/charger_monitor.pid"
MPRIS_MANAGER_PID_FILE="$STATE_DIR/mpris_manager.pid"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to check if a process is running
is_process_running() {
    local pid_file="$1"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # Process is running
        else
            rm -f "$pid_file"  # Clean up stale PID file
        fi
    fi
    return 1  # Process is not running
}

# Function to start a service
start_service() {
    local service="$1"
    local pid_file="$2"
    
    # Check if service is already running
    if is_process_running "$pid_file"; then
        log "$service is already running."
        return 0
    fi
    
    # Start the service
    log "Starting $service..."
    
    case "$service" in
        "usb_monitor")
            "$SCRIPTS_DIR/usb_monitor.sh" &
            echo $! > "$pid_file"
            ;;
        "charger_monitor")
            "$SCRIPTS_DIR/charger_monitor.sh" &
            echo $! > "$pid_file"
            ;;
        "mpris_manager")
            "$HOME/.config/hypr/scripts/media/media-management/mpris-manager.sh" &
            echo $! > "$pid_file"
            ;;
        *)
            log "Unknown service: $service"
            return 1
            ;;
    esac
    
    log "$service started with PID $(cat "$pid_file")"
    return 0
}

# Function to stop a service
stop_service() {
    local service="$1"
    local pid_file="$2"
    
    # Check if service is running
    if ! is_process_running "$pid_file"; then
        log "$service is not running."
        return 0
    fi
    
    # Stop the service
    local pid=$(cat "$pid_file")
    log "Stopping $service (PID: $pid)..."
    kill "$pid" 2>/dev/null
    
    # Wait for process to terminate
    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 5 ]; do
        sleep 0.5
        count=$((count + 1))
    done
    
    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        log "Force killing $service (PID: $pid)..."
        kill -9 "$pid" 2>/dev/null
    fi
    
    rm -f "$pid_file"
    log "$service stopped"
    return 0
}

# Function to check USB devices
check_usb_devices() {
    # Check if any USB storage devices are connected
    if lsblk -o TRAN | grep -q "usb"; then
        log "USB storage devices detected, ensuring USB monitor is running"
        start_service "usb_monitor" "$USB_MONITOR_PID_FILE"
    else
        # No USB devices, stop the monitor if it's running
        if is_process_running "$USB_MONITOR_PID_FILE"; then
            log "No USB storage devices connected, stopping USB monitor"
            stop_service "usb_monitor" "$USB_MONITOR_PID_FILE"
        fi
    fi
}

# Function to check power supply
check_power_supply() {
    # Always keep charger monitor running as it's event-based now
    if ! is_process_running "$CHARGER_MONITOR_PID_FILE"; then
        log "Starting charger monitor (event-based)"
        start_service "charger_monitor" "$CHARGER_MONITOR_PID_FILE"
    fi
}

# Function to check media players
check_media_players() {
    # Check if any media players are running
    if playerctl -l 2>/dev/null | grep -q .; then
        log "Media players detected, ensuring MPRIS manager is running"
        start_service "mpris_manager" "$MPRIS_MANAGER_PID_FILE"
    else
        # No media players, stop the manager if it's running
        if is_process_running "$MPRIS_MANAGER_PID_FILE"; then
            log "No media players running, stopping MPRIS manager"
            stop_service "mpris_manager" "$MPRIS_MANAGER_PID_FILE"
        fi
    fi
}

# Main function to check all services
check_all_services() {
    log "Checking services..."
    check_usb_devices
    check_power_supply
    check_media_players
}

# Clean up on exit
cleanup() {
    log "Cleaning up and stopping all services..."
    stop_service "usb_monitor" "$USB_MONITOR_PID_FILE"
    stop_service "charger_monitor" "$CHARGER_MONITOR_PID_FILE"
    stop_service "mpris_manager" "$MPRIS_MANAGER_PID_FILE"
    log "Service manager stopped"
    exit 0
}

# Set up trap for clean exit
trap cleanup INT TERM EXIT

# Initial check
log "Service manager started"
check_all_services

# Main loop - check services periodically
while true; do
    sleep 30  # Check every 30 seconds
    check_all_services
done 