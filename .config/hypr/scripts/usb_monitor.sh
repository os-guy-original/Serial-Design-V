#!/bin/bash

# USB device monitoring and notification script
# Detects newly connected/disconnected USB devices, shows notifications and plays sounds
# When notification is clicked, mounts the drive and opens file manager

# Kill previous instances
for pid in $(pgrep -f "$(basename "$0")"); do
    if [ $pid != $$ ]; then
        kill -9 $pid 2>/dev/null
    fi
done

# Sound file paths
SOUNDS_DIR="$HOME/.config/hypr/sounds"
DEVICE_ADDED_SOUND="$SOUNDS_DIR/device-added.ogg"
DEVICE_REMOVED_SOUND="$SOUNDS_DIR/device-removed.ogg"

# Create action script directory if it doesn't exist
ACTION_DIR="$HOME/.config/hypr/scripts/usb_actions"
mkdir -p "$ACTION_DIR"

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

echo "USB monitoring script is running. Press Ctrl+C to stop."
echo "Sound files: $SOUNDS_DIR"
echo "Action scripts: $ACTION_DIR"

# Track devices to prevent duplicates
LAST_ADDED_DEVICE=""
LAST_ADDED_TIME=0

# Monitor USB events and send notifications
stdbuf -o0 udevadm monitor --udev --subsystem-match=block | while read -r line; do
    CURRENT_TIME=$(date +%s)
    
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
                                message="$header\n\nPartitions:\n$partition_info\n\nClick to open"
                            else
                                message="$header\n\nNo partitions found.\n\nClick to open"
                            fi
                            
                            # Send notification with action
                            notify-send -i drive-removable-media -a "USB Monitor" "$title" "$message" --action="default=Open drive" && {
                                # Execute the action script directly when notification is clicked
                                bash "$action_script" &
                            } &
                            
                            echo "$(date): $title: /dev/$device - $header"
                            echo "Partitions:"
                            echo -e "$partition_info"
                            echo "Action script created: $action_script"
                        } &
                    fi
                fi
            fi
        fi
    elif echo "$line" | grep -q "UDEV.*remove.*block"; then
        DEVPATH=$(echo "$line" | grep -o "/devices/.*" | cut -d " " -f 1)
        device=$(basename "$DEVPATH" 2>/dev/null)
        
        if [[ $device =~ ^sd[a-z]$ ]]; then
            # Play sound
            play_sound "$DEVICE_REMOVED_SOUND"
            
            # Clean up action script
            rm -f "$ACTION_DIR/mount_${device}.sh" 2>/dev/null
            
            title="USB Drive Disconnected"
            message="/dev/$device has been disconnected"
            notify-send -i drive-removable-media "$title" "$message"
            echo "$(date): $title: $message"
        fi
    fi
done
