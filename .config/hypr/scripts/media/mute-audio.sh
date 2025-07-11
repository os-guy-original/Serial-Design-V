#!/bin/bash

# mute-audio.sh - Simple wrapper for OSD-gtk3 mute control

# Path to OSD control script
OSD_SCRIPT="$HOME/.config/hypr/scripts/media/OSD-gtk3/osd_control.py"

# Toggle mute using OSD control
python3 "$OSD_SCRIPT" volume mute

# Logging for debugging
echo "[$(date)] Audio mute toggled" >> ~/.cache/hypr_volume.log
