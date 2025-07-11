#!/bin/bash

# volume-control.sh - Simple wrapper for OSD-gtk3 volume control

# Path to OSD control script
OSD_SCRIPT="$HOME/.config/hypr/scripts/media/OSD-gtk3/osd_control.py"

case $1 in
    up)
        python3 "$OSD_SCRIPT" volume up 5
        ;;
    down)
        python3 "$OSD_SCRIPT" volume down 5
        ;;
    mute)
        python3 "$OSD_SCRIPT" volume mute
        ;;
    *)
        echo "Usage: $0 {up|down|mute}"
        exit 1
esac

# Logging for debugging
echo "[$(date)] Volume $1 - Status: $?" >> ~/.cache/hypr_volume.log
