#!/bin/bash

# Kill any existing instances
pkill -f "media-waybar-manager.sh" || true
pkill -f "media-waybar-hover-manager.sh" || true
pkill -f "media-config.jsonc" || true

# Remove any old state files
rm -f /tmp/waybar-media-hover-status /tmp/waybar-media-timeout /tmp/waybar-media-pid

# Make scripts executable
chmod +x ~/.config/waybar/scripts/media-waybar-manager.sh

# Start the manager in the background
nohup ~/.config/waybar/scripts/media-waybar-manager.sh > /tmp/media-waybar.log 2>&1 &

echo "Media waybar manager started in background (auto-start only, no auto-stop)"