#!/bin/bash
DEVICE=$(pactl get-default-sink 2>/dev/null || echo "alsa_output.pci-0000_08_00.6.HiFi__hw_Generic_1__sink")

case $1 in
    up)
        swayosd-client --output-volume raise --device "$DEVICE"
        ;;
    down)
        swayosd-client --output-volume lower --device "$DEVICE"
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
esac

# Logging for debugging
echo "[$(date)] Volume $1 - Device: $DEVICE - Status: $?" >> ~/.cache/hypr_volume.log
