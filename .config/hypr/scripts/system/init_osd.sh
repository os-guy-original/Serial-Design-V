#!/bin/bash

# init_osd.sh - Initialize OSD-gtk3 manager

# Define paths
OSD_SCRIPT_DIR="$HOME/.config/hypr/scripts/media/OSD-gtk3"
OSD_CONTROL="$OSD_SCRIPT_DIR/osd_control.py"
LOG_DIR="$HOME/.config/hypr/cache/logs"
LOG_FILE="$LOG_DIR/osd_init.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Starting OSD initialization"

# Check if OSD scripts exist
if [ ! -f "$OSD_CONTROL" ]; then
    log "ERROR: OSD control script not found at $OSD_CONTROL"
    exit 1
fi

# Make sure the scripts are executable
chmod +x "$OSD_SCRIPT_DIR"/*.py
log "Made OSD scripts executable"

# Kill any existing OSD processes
log "Stopping any existing OSD processes"
python3 "$OSD_CONTROL" stop 2>&1 | tee -a "$LOG_FILE"

# Start the OSD service via manager
log "Starting OSD service via manager"
python3 "$OSD_CONTROL" start 2>&1 | tee -a "$LOG_FILE"

log "OSD initialization complete"
exit 0 