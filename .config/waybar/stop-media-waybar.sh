#!/bin/bash

# Kill the media waybar manager
echo "Stopping media waybar manager..."
pkill -f "media-waybar-manager.sh"
pkill -f "media-waybar-hover-manager.sh"

# Kill any media waybar instances
echo "Stopping media waybar instances..."
pkill -f "media-config.jsonc"

# Clean up state files
echo "Cleaning up state files..."
rm -f /tmp/waybar-media-hover-status /tmp/waybar-media-timeout /tmp/waybar-media-pid

echo "Media waybar stopped successfully" 