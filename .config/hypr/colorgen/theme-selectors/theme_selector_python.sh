#!/bin/bash

# ============================================================================
# Theme Selector Dialog for Hyprland Colorgen (Python GTK Version)
# 
# Shows a dialog with Light Theme and Dark Theme options using Python and GTK
# ============================================================================

# Set strict error handling
set -euo pipefail

# Enable debug output
DEBUG=true

# Debug function
debug() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PYTHON_SCRIPT="$SCRIPT_DIR/theme_selector_python.py"

debug "XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
debug "COLORGEN_DIR: $COLORGEN_DIR"
debug "SCRIPT_DIR: $SCRIPT_DIR"
debug "PYTHON_SCRIPT: $PYTHON_SCRIPT"

# Set DISPLAY if not set (sometimes needed for GTK apps)
if [ -z "${DISPLAY:-}" ]; then
    export DISPLAY=:0
    debug "Set DISPLAY to :0"
fi

# Set XDG_SESSION_TYPE if not set
if [ -z "${XDG_SESSION_TYPE:-}" ]; then
    export XDG_SESSION_TYPE=wayland
    debug "Set XDG_SESSION_TYPE to wayland"
fi

# Check for Python and PyGObject
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed"
    echo "Please install Python 3: sudo pacman -S python"
    exit 1
else
    debug "Python 3 is installed"
    python3 --version
fi

# Check for PyGObject
if ! python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" &> /dev/null; then
    echo "PyGObject or GTK3 is not installed or not working properly"
    echo "Please install PyGObject and GTK3: sudo pacman -S python-gobject gtk3"
    exit 1
else
    debug "PyGObject and GTK3 are installed and working"
fi

# Check for GTK Layer Shell (optional)
if ! python3 -c "import gi; gi.require_version('GtkLayerShell', '0.1'); from gi.repository import GtkLayerShell" &> /dev/null; then
    debug "GTK Layer Shell is not installed"
    echo "Note: For better Wayland integration, consider installing gtk-layer-shell:"
    echo "sudo pacman -S gtk-layer-shell python-gobject"
    # Continue without layer shell
else
    debug "GTK Layer Shell is installed and working"
fi

# Check if the Python script exists and is executable
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Python theme selector script not found: $PYTHON_SCRIPT"
    debug "Current directory: $(pwd)"
    debug "Directory listing of theme-selectors:"
    ls -la "$SCRIPT_DIR/"
    exit 1
fi

# Make the Python script executable if it's not already
chmod +x "$PYTHON_SCRIPT"
debug "Made Python script executable"

# Create a temporary log file for debugging
LOG_FILE="/tmp/theme_selector_python_$(date +%s).log"
debug "Log file: $LOG_FILE"

# Try to run the Python script and capture its output
echo "Starting Python theme selector..."
SELECTED_THEME=$("$PYTHON_SCRIPT" 2> "$LOG_FILE")
exit_code=$?
debug "Python script exit code: $exit_code"
debug "Selected theme: $SELECTED_THEME"

# Check if there were any errors
if [ -f "$LOG_FILE" ]; then
    if grep -q "ERROR\|Error" "$LOG_FILE"; then
        echo "Errors detected in Python theme selector:"
        grep "ERROR\|Error" "$LOG_FILE"
    fi
    
    # Keep log file for debugging if there were errors, otherwise remove it
    if [ $exit_code -ne 0 ]; then
        debug "Keeping log file for debugging: $LOG_FILE"
    else
        debug "Removing log file: $LOG_FILE"
        rm -f "$LOG_FILE"
    fi
fi

# If the Python script exited with a non-zero code, it means the user cancelled
if [ $exit_code -ne 0 ]; then
    debug "User cancelled theme selection"
    exit 1  # Signal that the user cancelled
fi

# Check if we got a valid theme selection
# Extract just the last line which should be the theme name
THEME=$(echo "$SELECTED_THEME" | tail -n 1)
debug "Extracted theme: $THEME"

if [ "$THEME" = "light" ] || [ "$THEME" = "dark" ]; then
    # Return the selected theme to dark_light_switch.sh
    debug "Selected theme: $THEME"
    echo "$THEME"
    exit 0  # Signal success
else
    debug "Invalid theme selection: $THEME"
    exit 1  # Signal an error
fi