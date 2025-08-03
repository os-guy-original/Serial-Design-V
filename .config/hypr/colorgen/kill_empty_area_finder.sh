#!/bin/bash

# Kill Empty Area Finder Script
# This script kills any running empty area analysis processes to save resources

COLORGEN_DIR="$HOME/.config/hypr/colorgen"
PID_FILE="$COLORGEN_DIR/empty_area_analysis.pid"

echo "Killing empty area finder processes..."

# Kill process using PID file if it exists
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "Killing empty area analysis process: $PID"
        kill "$PID" 2>/dev/null
        # Kill children too
        pkill -P "$PID" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

# Kill Python empty area processes by name
pkill -f "empty_area.py" 2>/dev/null
pkill -f "empty_area_fast.py" 2>/dev/null

# Kill any OpenCV/Python processes that might be doing image analysis
pkill -f "cv2" 2>/dev/null

# Also kill any background processes from material_extract.sh that might be running empty area analysis
pgrep -f "material_extract.sh" 2>/dev/null | while read pid; do
    # Get child processes of material_extract.sh
    children=$(pgrep -P $pid 2>/dev/null)
    for child in $children; do
        # Check if child is running empty area analysis
        if ps -p $child -o cmd= 2>/dev/null | grep -q "empty_area"; then
            echo "Killing empty area analysis child process: $child"
            kill $child 2>/dev/null
        fi
    done
done

echo "Empty area finder processes killed."