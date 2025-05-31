#!/bin/bash

# Monitors window events and plays warning sounds WITHOUT showing notifications
# This helps the user identify potentially dangerous applications

# Set the directory where notification scripts are located
SCRIPTS_DIR="$HOME/.config/hypr/scripts/notification"
SOUNDS_BASE_DIR="$HOME/.config/hypr/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    fi
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
fi

# Print the sound folder path
echo "Window monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Create a log file for debugging
LOG_FILE="/tmp/hypr_window_monitor.log"
echo "Starting window monitor... (logging to $LOG_FILE)" > "$LOG_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Define patterns to match potentially dangerous applications or critical error windows
DANGEROUS_APPS=(
    "terminator"
    "Terminator"
    "gnome-terminal"
    "Gnome-terminal"
    "xterm"
    "konsole"
    "yakuake"
    "alacritty"
    "URxvt"
    "XTerm"
    "kitty"
    "foot"
    "Hyprland"
    "wezterm"
)

# Define patterns to match file dialog windows
DIALOG_CLASSES=(
    "file-chooser"
    "file_chooser"
    "dialog"
    "Dialog"
    "filechooser"
    "FileChooser"
    "GtkFileChooserDialog"
    "open-dialog"
    "save-dialog"
)

# Define patterns to match file dialog titles
DIALOG_TITLES=(
    "Open File"
    "Save File"
    "Open Folder"
    "Save As"
    "Select Folder"
    "Select File"
    "Choose File"
    "Choose Folder"
    "Import"
    "Export"
    "Attach File"
)

# Define patterns to match critical error windows
CRITICAL_PATTERNS=(
    "CRITICAL"
    "Critical"
    "critical"
    "FATAL"
    "Fatal"
    "fatal"
    "CRASH"
    "Crash"
    "crash"
    "emergency"
    "Emergency"
    "EMERGENCY"
)

# Define patterns to match error windows
ERROR_PATTERNS=(
    "ERROR"
    "Error"
    "error"
    "WARNING"
    "Warning"
    "warning"
    "ALERT"
    "Alert"
    "alert"
    "PROBLEM"
    "Problem"
    "problem"
    "FAILED"
    "Failed"
    "failed"
)

# Function to play warning sound
play_sound_only() {
    local level="$1"
    local class="$2"
    local title="$3"
    
    # Call the warning_sounds.sh script with the sound_only parameter
    "$SCRIPTS_DIR/warning_sounds.sh" "$level" "$class" "$title" "" "sound_only"
}

# Function to check if a string matches any pattern in an array
matches_pattern() {
    local string="$1"
    local class="$2"
    shift 2
    local patterns=("$@")
    
    # Skip empty strings
    if [[ -z "$string" ]]; then
        return 1
    fi
    
    # Skip common terminal instances and system processes
    if [[ "$class" == "kitty" && "$string" == "kitty" ]] || 
       [[ "$class" == "firefox" && "$string" == "Firefox" ]] ||
       [[ "$class" == "foot" && "$string" == "foot" ]]; then
            return 1
    fi
    
    # Check against each pattern
    for pattern in "${patterns[@]}"; do
        if [[ "$string" == *"$pattern"* ]]; then
                return 0
        fi
    done
    
    return 1
}

# Track windows to prevent duplicate notifications
declare -A NOTIFICATION_COUNTS

# Function to handle Hyprland window events
handle_window_event() {
    local event="$1"
    local window_data="$2"
    
    case "$event" in
        openwindow)
            # Parse window data (format: windowaddress,workspace,class,title)
            IFS=',' read -r window_address workspace class window_title <<< "$window_data"
            
            # Skip empty windows
            if [[ -z "$class" ]] || [[ -z "$window_title" ]]; then
                return
            fi
    
    # Create a unique key for this window
            local window_key="${class}:${window_title}"
    
            # Increment notification count for this window
            if [[ -z "${NOTIFICATION_COUNTS[$window_key]}" ]]; then
                NOTIFICATION_COUNTS[$window_key]=1
            else
            NOTIFICATION_COUNTS[$window_key]=$((NOTIFICATION_COUNTS[$window_key] + 1))
            fi
            
            # If we've shown too many notifications for this window, skip
            if [[ ${NOTIFICATION_COUNTS[$window_key]} -gt 2 ]]; then
                return
            fi
            
            # Check for potentially dangerous applications
            if matches_pattern "$class" "$class" "${DANGEROUS_APPS[@]}"; then
                play_sound_only "warning" "$class" "$window_title"
                NOTIFICATION_COUNTS[$window_key]=1
                return
            fi
            
            # Check for file dialogs by class
            if matches_pattern "$class" "$class" "${DIALOG_CLASSES[@]}"; then
                play_sound_only "info" "$class" "$window_title"
                NOTIFICATION_COUNTS[$window_key]=1
                return
            fi
            
            # Check for file dialogs by title
            if matches_pattern "$window_title" "$class" "${DIALOG_TITLES[@]}"; then
                play_sound_only "info" "$class" "$window_title"
                return
            fi
            
            # Check for critical error windows first (higher priority)
            if matches_pattern "$window_title" "$class" "${CRITICAL_PATTERNS[@]}"; then
                play_sound_only "critical" "$class" "$window_title"
                return
            fi
            
            # Check for error windows
            if matches_pattern "$window_title" "$class" "${ERROR_PATTERNS[@]}"; then
                play_sound_only "error" "$class" "$window_title"
                return
            fi
            
            # Special case: Check for GTK file chooser windows
            if [[ "$class" == *"gtk"* || "$class" == *"Gtk"* || "$class" == *"chooser"* || "$class" == *"Chooser"* ]] && [[ -z "$window_title" ]]; then
                play_sound_only "info" "$class" "(No title)"
                return
            fi
            ;;
            
        closewindow)
            # Optional: Handle window close events if needed
            ;;
            
        movewindow)
            # Optional: Handle window move events if needed
            ;;
            
        fullscreen)
            # Play info sound when an application goes fullscreen
            play_sound_only "info" "$effective_class" "$window_title"
            ;;
    esac
}

# Function to process window with hyprctl
process_window_hyprctl() {
    local class="$1"
    local title="$2"
    local app_id="$3"
    local pid="$4"
    
    # Skip empty windows with enhanced validation
    if [[ -z "$class" && -z "$app_id" ]] || [[ -z "$title" ]]; then
        return
    fi
    
    # For dialogs, we need to check both class and app_id
    local effective_class="$class"
    [[ -z "$effective_class" ]] && effective_class="$app_id"
    
    # Skip generic window titles which are likely false positives
    if [[ "$title" == "Gtk" || "$title" == "Qt" || "$title" == "dialog" || "$title" == "Dialog" ]]; then
        return
    fi
    
    # Skip checking windows we've seen too many times
    local window_key="${effective_class}:${title}"
    if [[ -n "${NOTIFICATION_COUNTS[$window_key]}" && ${NOTIFICATION_COUNTS[$window_key]} -gt 2 ]]; then
        return
    fi
    
    # Check for potentially dangerous applications
    if matches_pattern "$effective_class" "$effective_class" "${DANGEROUS_APPS[@]}"; then
        play_sound_only "warning" "$effective_class" "$title"
        return
    fi
    
    # Check for file dialogs by class
    if matches_pattern "$effective_class" "$effective_class" "${DIALOG_CLASSES[@]}"; then
        play_sound_only "info" "$effective_class" "$title"
        return
    fi
    
    # Check for file dialogs by title
    if matches_pattern "$title" "$effective_class" "${DIALOG_TITLES[@]}"; then
        play_sound_only "info" "$effective_class" "$title"
        return
    fi
    
    # Check for critical error windows first (higher priority)
    if matches_pattern "$title" "$effective_class" "${CRITICAL_PATTERNS[@]}"; then
        play_sound_only "critical" "$effective_class" "$title"
        return
    fi
    
    # Check for error windows
    if matches_pattern "$title" "$effective_class" "${ERROR_PATTERNS[@]}"; then
        play_sound_only "error" "$effective_class" "$title"
        return
    fi
    
    # Special case: Check for GTK file chooser windows
    if [[ "$effective_class" == *"gtk"* || "$effective_class" == *"Gtk"* || "$effective_class" == *"chooser"* || "$effective_class" == *"Chooser"* ]] && [[ -z "$title" ]]; then
        play_sound_only "info" "$effective_class" "(No title)"
        return
    fi
}

# Find the correct Hyprland socket
find_hyprland_socket() {
    # First try the environment variable
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        SOCKET_PATH="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        if [ -S "$SOCKET_PATH" ]; then
            echo "$SOCKET_PATH"
            return 0
        fi
    fi
    
    # If environment variable didn't work, try to find the socket
    for socket in /tmp/hypr/*/.socket2.sock; do
        if [ -S "$socket" ]; then
            echo "$socket"
            return 0
        fi
    done
    
    # If no socket found, check if we're even running Hyprland
    if ! pgrep -x Hyprland > /dev/null; then
        echo "Error: Hyprland is not running"
        return 1
    fi
    
    echo "Error: Could not find Hyprland socket"
    return 1
}

# Check if hyprctl command is available
if ! command -v hyprctl &> /dev/null; then
    log_message "Error: hyprctl command not found"
    exit 1
fi

# Try to use socket method first
if command -v socat &> /dev/null; then
    # Get the socket path
    SOCKET_PATH=$(find_hyprland_socket)
    if [ $? -eq 0 ]; then
        echo "Using Hyprland socket: $SOCKET_PATH for window monitoring"
        
        # Monitor Hyprland socket for window events
        socat -u UNIX-CONNECT:"$SOCKET_PATH" - | while read -r line; do
            # Process events related to windows
            if echo "$line" | grep -q -E "^(openwindow|closewindow|movewindow|fullscreen)>>"; then
                # Extract event type and window data
                event=$(echo "$line" | cut -d'>' -f1)
                window_data=$(echo "$line" | cut -d'>' -f3-)
                
                # Handle the event
                handle_window_event "$event" "$window_data"
            fi
        done
        
        # If socat exits, fall back to polling method
        echo "Socket monitoring ended, falling back to polling method"
    else
        echo "Could not find Hyprland socket, using polling method"
    fi
fi

# Fallback: Use polling method with hyprctl
echo "Using hyprctl polling method for window monitoring"

# Store previous window list to detect changes
PREV_WINDOWS=""

# Function to check for windows using hyprctl
check_windows_hyprctl() {
    # Get current window list
    CURRENT_WINDOWS=$(hyprctl clients -j 2>/dev/null)
    
    # Skip if hyprctl command failed
    if [ $? -ne 0 ] || [ -z "$CURRENT_WINDOWS" ]; then
        return
    fi
    
    # If it's the first run or windows have changed
    if [ "$CURRENT_WINDOWS" != "$PREV_WINDOWS" ]; then
        # Process each window
        echo "$CURRENT_WINDOWS" | jq -c '.[]' 2>/dev/null | while read -r window; do
            class=$(echo "$window" | jq -r '.class' 2>/dev/null || echo "")
            title=$(echo "$window" | jq -r '.title' 2>/dev/null || echo "")
            app_id=$(echo "$window" | jq -r '.initialClass' 2>/dev/null || echo "")
            pid=$(echo "$window" | jq -r '.pid' 2>/dev/null || echo "")
            
            # Process this window
            process_window_hyprctl "$class" "$title" "$app_id" "$pid"
        done
        
        # Update previous window list
        PREV_WINDOWS="$CURRENT_WINDOWS"
    fi
}

# Main polling loop
while true; do
    check_windows_hyprctl
    sleep 5  # Increased sleep to reduce frequent checks
done 