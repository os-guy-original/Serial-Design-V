#!/bin/bash

# Utility script to manage notification services
# Allows starting, stopping, restarting or checking status of notification services

# Set the directory where notification scripts are located
SCRIPTS_DIR="$HOME/.config/hypr/scripts/notification"

# Function to check if notification services are running
check_status() {
    # Get our own PID and PPID to exclude them
    local my_pid=$$
    local parent_pid=$PPID
    
    # Check for any notification script processes, excluding our management script
    local running_pids=$(pgrep -f "notification|monitor.sh" | grep -v -E "($$|$PPID|manage_notifications)")
    local running_count=$(echo "$running_pids" | wc -l)
    
    # Trim whitespace from count
    running_count=$(echo "$running_count" | tr -d '[:space:]')
    
    if [ -n "$running_pids" ] && [ "$running_count" -gt 0 ]; then
        echo "Notification services status: RUNNING ($running_count processes)"
        return 0
    else
        echo "Notification services status: STOPPED"
        return 1
    fi
}

# Function to stop all notification services
stop_services() {
    echo "Stopping notification services..."
    
    # Get our own PID to avoid killing ourselves
    local my_pid=$$
    local parent_pid=$PPID
    
    # Find all notification-related processes
    local notification_pids=$(pgrep -f "notification|monitor.sh" | grep -v -E "($$|$PPID|manage_notifications)")
    
    if [ -z "$notification_pids" ]; then
        echo "No notification services are running."
    else
        # Kill each process
        echo "$notification_pids" | while read pid; do
            if [ -n "$pid" ]; then
                local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                echo "Killing process $pid ($process_name)"
                kill "$pid" 2>/dev/null
            fi
        done
        
        # Give processes time to terminate
        sleep 1
        
        # Check for remaining processes and force kill them
        notification_pids=$(pgrep -f "notification|monitor.sh" | grep -v -E "($$|$PPID|manage_notifications)")
        
        if [ -n "$notification_pids" ]; then
            echo "Some processes are still running. Using SIGKILL..."
            echo "$notification_pids" | while read pid; do
                if [ -n "$pid" ]; then
                    local process_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                    echo "Force killing process $pid ($process_name)"
                    kill -9 "$pid" 2>/dev/null
                fi
            done
            sleep 1
        fi
    fi
    
    # Kill any remaining notification-related UI elements
    pkill -f "yad --notification" 2>/dev/null
    pkill -f "dbus-monitor" 2>/dev/null
    
    # Final check
    if pgrep -f "notification|monitor.sh" | grep -v -E "($$|$PPID|manage_notifications)" >/dev/null; then
        echo "Warning: Some notification processes could not be stopped."
    else
        echo "All notification services stopped successfully."
    fi
}

# Function to start notification services
start_services() {
    if check_status >/dev/null; then
        echo "Notification services are already running."
    else
        echo "Starting notification services..."
        nohup "$SCRIPTS_DIR/run_notifications.sh" >/dev/null 2>&1 &
        disown
        sleep 2
        check_status
    fi
}

# Function to restart services
restart_services() {
    stop_services
    sleep 1
    start_services
}

# Function to show detailed status
show_detailed_status() {
    echo "=== Notification Services Status ==="
    check_status
    
    echo
    echo "Running processes:"
    
    # Get our PIDs to exclude them
    local my_pid=$$
    local parent_pid=$PPID
    
    local services=(
        "window_monitor.sh" 
        "usb_monitor.sh" 
        "charger_monitor.sh" 
        "tools_notify.sh" 
        "run_notifications.sh"
    )
    
    for service in "${services[@]}"; do
        local pids=$(pgrep -f "$service" | grep -v -E "($$|$PPID|manage_notifications)")
        if [ -n "$pids" ]; then
            echo "$pids" | while read pid; do
                if [ -n "$pid" ]; then
                    echo "  ✓ $service (PID: $pid)"
                fi
            done
        else
            echo "  ✗ $service (not running)"
        fi
    done
    
    echo
    echo "Sound files:"
    local sounds_dir="$HOME/.config/hypr/sounds"
    local default_sound_file="$sounds_dir/default-sound"
    
    if [ -f "$default_sound_file" ]; then
        local theme=$(cat "$default_sound_file" | tr -d '[:space:]')
        echo "  Sound theme: $theme"
        
        # Check if sound files exist
        local theme_dir="$sounds_dir/$theme"
        if [ -d "$theme_dir" ]; then
            local sound_count=$(find "$theme_dir" -name "*.ogg" | wc -l)
            echo "  Sound files: $sound_count found in $theme_dir"
        else
            echo "  Warning: Theme directory $theme_dir does not exist"
        fi
    else
        echo "  No default sound theme set"
    fi
}

# Print usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {start|stop|restart|status|detailed}"
    echo
    echo "Commands:"
    echo "  start     - Start notification services if not already running"
    echo "  stop      - Stop all running notification services"
    echo "  restart   - Stop and then start notification services"
    echo "  status    - Show if notification services are running"
    echo "  detailed  - Show detailed status of services and sound files"
    exit 1
fi

# Process command
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        check_status
        ;;
    detailed)
        show_detailed_status
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: $0 {start|stop|restart|status|detailed}"
        exit 1
        ;;
esac

exit 0 