#!/bin/bash

# Script to copy backup scripts from Desktop to the scripts/backup directory
# This script will:
# 1. Copy the backup scripts from Desktop/backup/subscripts to scripts/backup
# 2. Update paths in the scripts to use the new location

# Exit on any error
set -e

# Define paths
CONFIG_DIR="$HOME/.config/hypr"
DESKTOP_BACKUP_DIR="$HOME/Desktop/backup"
SCRIPTS_BACKUP_DIR="$CONFIG_DIR/scripts/backup"

# Timestamp for logging
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

echo "[$(timestamp)] Starting backup scripts setup"

# Copy the backup scripts from Desktop to scripts/backup
echo "[$(timestamp)] Copying backup scripts from Desktop"
cp -r "$DESKTOP_BACKUP_DIR/subscripts/"* "$SCRIPTS_BACKUP_DIR/"
cp "$DESKTOP_BACKUP_DIR/run_backup.sh" "$SCRIPTS_BACKUP_DIR/"

# Make all scripts executable
chmod +x "$SCRIPTS_BACKUP_DIR/"*.sh

# Update paths in run_backup.sh
echo "[$(timestamp)] Updating paths in run_backup.sh"
sed -i "s|SCRIPT_DIR=\"\$(dirname \"\$(readlink -f \"\$0\")\")\"|\
SCRIPT_DIR=\"\$HOME/.config/hypr/scripts/backup\"|g" "$SCRIPTS_BACKUP_DIR/run_backup.sh"

echo "[$(timestamp)] Backup scripts setup completed!"
echo "You can now run the backup script with: ~/.config/hypr/scripts/backup/run_backup.sh" 