#!/bin/bash

# Kill duplicate colorgen processes script

echo "Checking for duplicate colorgen processes..."

# Kill any running material_extract.sh processes
MATERIAL_PIDS=$(pgrep -f "material_extract.sh" | grep -v $$)
if [ -n "$MATERIAL_PIDS" ]; then
    echo "Killing material_extract.sh processes: $MATERIAL_PIDS"
    echo "$MATERIAL_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    # Force kill if still running
    MATERIAL_PIDS=$(pgrep -f "material_extract.sh" | grep -v $$)
    if [ -n "$MATERIAL_PIDS" ]; then
        echo "Force killing material_extract.sh processes: $MATERIAL_PIDS"
        echo "$MATERIAL_PIDS" | xargs kill -KILL 2>/dev/null || true
    fi
fi

# Kill any running apply_colors.sh processes
APPLY_PIDS=$(pgrep -f "apply_colors.sh" | grep -v $$)
if [ -n "$APPLY_PIDS" ]; then
    echo "Killing apply_colors.sh processes: $APPLY_PIDS"
    echo "$APPLY_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    # Force kill if still running
    APPLY_PIDS=$(pgrep -f "apply_colors.sh" | grep -v $$)
    if [ -n "$APPLY_PIDS" ]; then
        echo "Force killing apply_colors.sh processes: $APPLY_PIDS"
        echo "$APPLY_PIDS" | xargs kill -KILL 2>/dev/null || true
    fi
fi

# Remove any stale lock files
echo "Removing stale lock files..."
rm -f /tmp/material_extract.lock
rm -f /tmp/colorgen_apply_colors.lock

echo "Cleanup complete."