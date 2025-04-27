#!/bin/bash

# Auto-generated script to mount and open USB drive /dev/sda
echo "Attempting to mount /dev/sda..."

# Use udisksctl which handles mounting automatically
if command -v udisksctl >/dev/null 2>&1; then
    # Try to mount each partition
    MOUNTED=0
    
    # First try to get a list of partitions
    PARTITIONS=$(ls /dev/sda[0-9]* 2>/dev/null)
    
    if [ -n "$PARTITIONS" ]; then
        for part in $PARTITIONS; do
            # Check if already mounted
            MOUNT_POINT=$(lsblk -no MOUNTPOINT "$part" | grep -v "^$" | head -n1)
            
            if [ -n "$MOUNT_POINT" ]; then
                echo "Partition $part already mounted at $MOUNT_POINT"
                nemo  "$MOUNT_POINT" &
                MOUNTED=1
                break
            else
                # Try to mount
                echo "Mounting $part..."
                if output=$(udisksctl mount -b "$part" 2>&1); then
                    echo "$output"
                    # Extract mount point from output
                    MOUNT_POINT=$(echo "$output" | grep -o "at [^ ]*$" | cut -d' ' -f2)
                    if [ -n "$MOUNT_POINT" ]; then
                        nemo  "$MOUNT_POINT" &
                        MOUNTED=1
                        break
                    fi
                fi
            fi
        done
    fi
    
    # If no partitions were found or mounted, try mounting the whole device
    if [ $MOUNTED -eq 0 ]; then
        if output=$(udisksctl mount -b "/dev/sda" 2>&1); then
            echo "$output"
            MOUNT_POINT=$(echo "$output" | grep -o "at [^ ]*$" | cut -d' ' -f2)
            if [ -n "$MOUNT_POINT" ]; then
                nemo  "$MOUNT_POINT" &
                MOUNTED=1
            fi
        fi
    fi
    
    # Report failure if nothing was mounted
    if [ $MOUNTED -eq 0 ]; then
        notify-send "USB Mount Error" "Failed to mount /dev/sda or any of its partitions."
    fi
else
    # Fallback for systems without udisksctl
    notify-send "USB Mount Error" "udisksctl command not found. Please install udisks2 package."
fi
