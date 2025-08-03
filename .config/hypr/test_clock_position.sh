#!/bin/bash

# Test script to verify clock positioning
echo "Testing clock positioning system..."

# Kill any existing clock
if pgrep -f "gtk_layer_clock.py" > /dev/null; then
    echo "Stopping existing clock..."
    pkill -f "gtk_layer_clock.py"
    sleep 2
fi

# Run empty area analysis
echo "Running empty area analysis..."
cd scripts/ui
python3 empty_area.py /home/sd-v/Pictures/gray-circles-material-design-ynrcce6srabk1slr-2118035892.jpg > /tmp/empty_area_test.txt

# Show the results
echo "Empty area analysis results:"
cat /tmp/empty_area_test.txt

# Extract position from JSON
center_x=$(cat /tmp/empty_area_test.txt | grep -A 20 "--- JSON ---" | jq -r '.center[0]' 2>/dev/null)
center_y=$(cat /tmp/empty_area_test.txt | grep -A 20 "--- JSON ---" | jq -r '.center[1]' 2>/dev/null)

echo "Extracted position: ($center_x, $center_y)"

# Test the clock with this position
if [ -n "$center_x" ] && [ -n "$center_y" ]; then
    echo "Starting clock at position ($center_x, $center_y)..."
    cd ../..
    python3 scripts/ui/gtk_layer_clock.py --x "$center_x" --y "$center_y" --primary-color "#6750a4" &
    
    echo "Clock started! Check if it appears at the correct position."
    echo "The clock should be positioned at ($center_x, $center_y)"
else
    echo "Failed to extract position from empty area analysis"
fi