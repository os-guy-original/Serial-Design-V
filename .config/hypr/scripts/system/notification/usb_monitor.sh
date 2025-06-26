#!/bin/bash

# usb_monitor.sh - Updated to use centralized sound manager and inotify for efficiency

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# USB device monitoring and notification script
# Detects newly connected/disconnected USB devices, shows notifications and plays sounds
# When notification is clicked, mounts the drive and opens file manager

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Create a log file for debugging - use cache directory instead of /tmp
CACHE_DIR="$HOME/.config/hypr/cache/logs"
mkdir -p "$CACHE_DIR"
DEBUG_LOG="$CACHE_DIR/usb_monitor_debug.log"
echo "Starting USB monitor at $(date)" > "$DEBUG_LOG"

# Debug function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG"
}

# Check for inotify-tools
if ! command -v inotifywait >/dev/null 2>&1; then
    echo "Error: inotify-tools not installed. Please install with 'sudo pacman -S inotify-tools' or equivalent."
    debug_log "Error: inotify-tools not installed"
    notify-send -i error "USB Monitor Error" "inotify-tools not installed. Please install with 'sudo pacman -S inotify-tools' or equivalent."
    exit 1
fi

# Print the sound folder path
echo "USB monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"
debug_log "USB monitor using sound theme: $SOUND_THEME, path: $SOUNDS_DIR"

# Define sound files
DEVICE_ADDED_SOUND="device-added.ogg"
DEVICE_REMOVED_SOUND="device-removed.ogg"

debug_log "Sound files: ADDED=$DEVICE_ADDED_SOUND, REMOVED=$DEVICE_REMOVED_SOUND"

# Create action script directory if it doesn't exist
ACTION_DIR="$HOME/.config/hypr/scripts/system/notification/usb_actions"
mkdir -p "$ACTION_DIR"

# Function to find file manager from XDG settings and fallbacks
find_file_manager() {
    local file_manager=""
    
    # First try XDG-MIME query to get default file manager
    if command -v xdg-mime >/dev/null 2>&1; then
        local mime_handler=$(xdg-mime query default inode/directory 2>/dev/null)
        if [[ -n "$mime_handler" ]]; then
            # Extract the command from the .desktop file
            local desktop_file=$(find /usr/share/applications /usr/local/share/applications ~/.local/share/applications -name "$mime_handler" 2>/dev/null | head -n1)
            if [[ -n "$desktop_file" && -f "$desktop_file" ]]; then
                file_manager=$(grep -oP "^Exec=\K.*?( |$)" "$desktop_file" | sed 's/ %[uUfF]//g' | sed 's/ -.*//g' | head -n1)
            fi
        fi
    fi
    
    # If XDG-MIME didn't work, try the XDG_CURRENT_DESKTOP environment variable
    if [[ -z "$file_manager" ]]; then
        case "$XDG_CURRENT_DESKTOP" in
            GNOME)
                file_manager="nautilus"
                ;;
            KDE)
                file_manager="dolphin"
                ;;
            XFCE)
                file_manager="thunar"
                ;;
            MATE)
                file_manager="caja"
                ;;
            LXQt|LXDE)
                file_manager="pcmanfm"
                ;;
            Cinnamon)
                file_manager="nemo"
                ;;
            Hyprland)
                # Check common file managers for Hyprland
                for fm in thunar dolphin nemo nautilus pcmanfm caja; do
                    if command -v "$fm" >/dev/null 2>&1; then
                        file_manager="$fm"
                        break
                    fi
                done
                ;;
            *)
                # Fallback to common file managers
                for fm in nautilus thunar dolphin pcmanfm nemo caja dbus-launch exo-open xdg-open gio; do
                    if command -v "$fm" >/dev/null 2>&1; then
                        file_manager="$fm"
                        break
                    fi
                done
                ;;
        esac
    fi
    
    # Final fallback to xdg-open
    if [[ -z "$file_manager" ]]; then
        file_manager="xdg-open"
    fi
    
    echo "$file_manager"
}

# Function to create action script for auto-mounting and opening file manager
create_action_script() {
    local device="$1"
    local action_script="$ACTION_DIR/mount_${device}.sh"
    local file_manager=$(find_file_manager)
    
    echo "Using file manager: $file_manager" >&2
    
    # Create a script to mount the drive and open file manager
    cat > "$action_script" << EOF
#!/bin/bash

# Auto-generated script to mount and open USB drive /dev/$device
echo "Attempting to mount /dev/$device..."

# Use udisksctl which handles mounting automatically
if command -v udisksctl >/dev/null 2>&1; then
    # Try to mount each partition
    MOUNTED=0
    
    # First try to get a list of partitions
    PARTITIONS=\$(ls /dev/${device}[0-9]* 2>/dev/null)
    
    if [ -n "\$PARTITIONS" ]; then
        for part in \$PARTITIONS; do
            # Check if already mounted
            MOUNT_POINT=\$(lsblk -no MOUNTPOINT "\$part" | grep -v "^$" | head -n1)
            
            if [ -n "\$MOUNT_POINT" ]; then
                echo "Partition \$part already mounted at \$MOUNT_POINT"
                $file_manager "\$MOUNT_POINT" >/dev/null 2>&1 &
                MOUNTED=1
                break
            else
                # Try to mount
                echo "Mounting \$part..."
                if output=\$(udisksctl mount -b "\$part" 2>&1); then
                    echo "\$output"
                    # Extract mount point from output
                    MOUNT_POINT=\$(echo "\$output" | grep -o "at [^ ]*\$" | cut -d' ' -f2)
                    if [ -n "\$MOUNT_POINT" ]; then
                        $file_manager "\$MOUNT_POINT" >/dev/null 2>&1 &
                        MOUNTED=1
                        break
                    fi
                fi
            fi
        done
    fi
    
    # If no partitions were found or mounted, try mounting the whole device
    if [ \$MOUNTED -eq 0 ]; then
        if output=\$(udisksctl mount -b "/dev/$device" 2>&1); then
            echo "\$output"
            MOUNT_POINT=\$(echo "\$output" | grep -o "at [^ ]*\$" | cut -d' ' -f2)
            if [ -n "\$MOUNT_POINT" ]; then
                $file_manager "\$MOUNT_POINT" >/dev/null 2>&1 &
                MOUNTED=1
            fi
        fi
    fi
    
    # Report failure if nothing was mounted
    if [ \$MOUNTED -eq 0 ]; then
        notify-send "USB Mount Error" "Failed to mount /dev/$device or any of its partitions."
    fi
else
    # Fallback for systems without udisksctl
    notify-send "USB Mount Error" "udisksctl command not found. Please install udisks2 package."
fi
EOF

    # Make script executable
    chmod +x "$action_script"
    echo "$action_script"
}

echo "USB monitoring script is running using inotify for efficient event detection."
echo "Sound files: $DEVICE_ADDED_SOUND, $DEVICE_REMOVED_SOUND"
echo "Action scripts: $ACTION_DIR"

# Track devices to prevent duplicates
LAST_ADDED_DEVICE=""
LAST_ADDED_TIME=0

# Function to handle USB device connection
handle_usb_device_add() {
    local device="$1"
    CURRENT_TIME=$(date +%s)
    
    # Avoid duplicate notifications (within 3 seconds)
    if [[ "$device" != "$LAST_ADDED_DEVICE" || $((CURRENT_TIME - LAST_ADDED_TIME)) -gt 3 ]]; then
        echo "USB device detected: /dev/$device"
        LAST_ADDED_DEVICE="$device"
        LAST_ADDED_TIME=$CURRENT_TIME
        
        # Play sound immediately
        play_sound "$DEVICE_ADDED_SOUND"
        
        # Get device information in parallel
        {
            # Get device info
            size=$(lsblk -dno SIZE "/dev/$device" 2>/dev/null || echo "?")
            vendor=$(lsblk -dno VENDOR "/dev/$device" 2>/dev/null)
            model=$(lsblk -dno MODEL "/dev/$device" 2>/dev/null)
            
            # Get partition info
            partition_info=""
            mount_point=""
            
            # Find all partitions
            while read -r part_line; do
                if [[ -n "$part_line" ]]; then
                    part_name=$(echo "$part_line" | awk '{print $1}')
                    part_size=$(echo "$part_line" | awk '{print $2}')
                    part_label=$(echo "$part_line" | awk '{print $3}')
                    part_fs=$(echo "$part_line" | awk '{print $4}')
                    part_mp=$(echo "$part_line" | awk '{print $5}')
                    
                    # Add partition info
                    if [[ -n "$part_label" ]]; then
                        partition_info="${partition_info}• ${part_name}: ${part_label} (${part_size}, ${part_fs})"
                    else
                        partition_info="${partition_info}• ${part_name}: ${part_size}, ${part_fs}"
                    fi
                    
                    # Add mount point if exists
                    if [[ -n "$part_mp" && "$part_mp" != "/" ]]; then
                        partition_info="${partition_info}, mounted at ${part_mp}"
                        # Save first mount point
                        if [[ -z "$mount_point" ]]; then
                            mount_point="$part_mp"
                        fi
                    fi
                    
                    partition_info="${partition_info}\n"
                fi
            done < <(lsblk -pno NAME,SIZE,LABEL,FSTYPE,MOUNTPOINT "/dev/$device" | grep -v "^$device ")
            
            # Create action script for mounting and opening
            action_script=$(create_action_script "$device")
            
            # Create notification content
            title="USB Drive Connected"
            
            if [[ -n "$vendor" || -n "$model" ]]; then
                header="${vendor} ${model} ($size)"
            else
                header="USB Drive ($size)"
            fi
            
            # Add partition info if available
            if [[ -n "$partition_info" ]]; then
                message="$header\n\nPartitions:\n$partition_info"
            else
                message="$header\n\nNo partitions found."
            fi
            
            # Send notification with action button
            notify-send -i drive-removable-media -a "USB Monitor" "$title" "$message" --action="open=Open folder" && {
                # Execute the action script directly when 'Open folder' is clicked
                bash "$action_script" &
            } &
            
            echo "$(date): $title: /dev/$device - $header"
            echo "Partitions:"
            echo -e "$partition_info"
            echo "Action script created: $action_script"
        } &
    fi
}

# Function to handle USB device removal
handle_usb_device_remove() {
    local device="$1"
    
    # Play sound
    play_sound "$DEVICE_REMOVED_SOUND"
    
    # Clean up action script
    rm -f "$ACTION_DIR/mount_${device}.sh" 2>/dev/null
    
    title="USB Drive Disconnected"
    message="/dev/$device has been disconnected"
    notify-send -i drive-removable-media "$title" "$message"
    echo "$(date): $title: $message"
}

# Function to process udev events from a file
process_udev_events() {
    while read -r line; do
        if echo "$line" | grep -q "UDEV.*add.*block"; then
            DEVPATH=$(echo "$line" | grep -o "/devices/.*" | cut -d " " -f 1)
            
            if [[ -n "$DEVPATH" ]]; then
                # Check if it's a USB device
                udevinfo=$(udevadm info -p "$DEVPATH" 2>/dev/null)
                
                if echo "$udevinfo" | grep -q "ID_BUS=usb"; then
                    # Get device name
                    device=$(echo "$udevinfo" | grep "DEVNAME=" | sed 's/E: DEVNAME=\/dev\///')
                    
                    # Check if it's a disk (not a partition)
                    if [[ $device =~ ^sd[a-z]$ ]]; then
                        handle_usb_device_add "$device"
                    fi
                fi
            fi
        elif echo "$line" | grep -q "UDEV.*remove.*block"; then
            DEVPATH=$(echo "$line" | grep -o "/devices/.*" | cut -d " " -f 1)
            device=$(basename "$DEVPATH" 2>/dev/null)
            
            if [[ $device =~ ^sd[a-z]$ ]]; then
                handle_usb_device_remove "$device"
            fi
        fi
    done
}

# Use inotify to monitor for USB device changes
debug_log "Starting inotify monitoring of /dev"

# Create a named pipe for udevadm output
UDEV_PIPE=$(mktemp -u)
mkfifo "$UDEV_PIPE"

# Start udevadm in the background, writing to the pipe
udevadm monitor --udev --subsystem-match=block > "$UDEV_PIPE" &
UDEVADM_PID=$!

# Process events from the pipe
process_udev_events < "$UDEV_PIPE" &
PROCESSOR_PID=$!

# Clean up on exit
trap 'kill $UDEVADM_PID $PROCESSOR_PID 2>/dev/null; rm -f "$UDEV_PIPE"; echo "USB monitor stopped"; exit 0' INT TERM EXIT

# Wait for the processor to finish (which should never happen unless terminated)
wait $PROCESSOR_PID
