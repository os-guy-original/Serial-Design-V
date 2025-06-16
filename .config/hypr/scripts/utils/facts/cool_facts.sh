#!/usr/bin/env bash

# Cool Facts Script
# Displays random facts using rofi

# Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/facts_config.conf"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

# Default configuration (will be overridden by config file)
ENABLE_FACTS=yes
INTERVAL=5
DISPLAY_TIME=10
TITLE="Did you know?"
FACTS_API="https://uselessfacts.jsph.pl/api/v2/facts/random"
TTS_ENABLED=no
THEME_FILE="$HOME/.config/rofi/facts.rasi"
DEBUG_ENABLED=yes
DEBUG_LOG_FILE="$HOME/.cache/cool_facts_debug.log"
DEBUG_LEVEL=3

# Debug levels
DEBUG_ERROR=1
DEBUG_WARNING=2
DEBUG_INFO=3
DEBUG_VERBOSE=4

# Debug function
debug() {
  local level=$1
  local message=$2
  local level_name="INFO"
  
  [[ "$DEBUG_ENABLED" != "yes" || -z "$DEBUG_LEVEL" || $level -gt ${DEBUG_LEVEL:-3} ]] && return
  
  case $level in
    1) level_name="ERROR" ;;
    2) level_name="WARNING" ;;
    3) level_name="INFO" ;;
    4) level_name="VERBOSE" ;;
  esac
  
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  # Redirect debug output to log file only, not to stdout
  echo "[$timestamp] [$level_name] $message" >> "${DEBUG_LOG_FILE:-/tmp/cool_facts.log}"
}

# Load configuration
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    debug 3 "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
    debug 3 "Configuration loaded successfully"
  else
    debug 2 "Config file not found. Using defaults."
    echo "Config file not found. Using defaults."
  fi
}

# Get a random fact from the internet
get_fact() {
  local fact
  local api_response
  
  debug 3 "Fetching fact from API: $FACTS_API"
  
  # Try to get a fact with curl, redirecting stderr to /dev/null
  api_response=$(curl -s "$FACTS_API" 2>/dev/null)
  
  # Extract just the text field
  if ! fact=$(echo "$api_response" | jq -r '.text' 2>/dev/null); then
    debug 1 "Failed to fetch fact from API"
    fact="Could not fetch a fact. Check your internet connection."
  fi
  
  # If the fact is empty or null, provide a fallback
  if [[ -z "$fact" || "$fact" == "null" ]]; then
    debug 2 "Received empty or null fact, using fallback"
    fact="Did you know that your fact service is currently unavailable?"
  else
    debug 4 "Received fact: '$fact'"
  fi
  
  # Return only the fact, no debug info
  printf "%s\n" "$fact"
}

# Display a fact using rofi
display_fact() {
  local fact="$1"
  
  debug 3 "Preparing to display fact with rofi"
  
  # Text-to-speech if enabled
  if [[ "$TTS_ENABLED" == "yes" && -x "$(command -v espeak)" ]]; then
    debug 3 "Using text-to-speech with espeak"
    espeak "$fact" &
  fi
  
  # Create a temporary script to close rofi after the display time
  local tmp_script=$(mktemp)
  echo "#!/bin/bash
  sleep $DISPLAY_TIME
  pkill -f 'rofi -dmenu'
  rm -f '$tmp_script'
  " > "$tmp_script"
  chmod +x "$tmp_script"
  debug 4 "Created temporary timer script: $tmp_script"
  
  # Format the fact for better display
  # Wrap text at 80 characters
  local formatted_fact=$(echo "$fact" | fold -s -w 80)
  
  # Display using rofi with theme
  debug 3 "Launching rofi with theme: $THEME_FILE"
  echo "$formatted_fact" | rofi -dmenu \
    -p "$TITLE" \
    -theme "$THEME_FILE" &
  
  # Start the timer to close rofi
  "$tmp_script" &
  debug 3 "Started timer to close rofi after $DISPLAY_TIME seconds"
}

# Monitor config file for changes
monitor_config() {
  local last_modified
  last_modified=$(stat -c %Y "$CONFIG_FILE" 2>/dev/null || echo "0")
  debug 3 "Starting config file monitor for $CONFIG_FILE (initial mtime: $last_modified)"
  
  while true; do
    sleep 10
    if [[ -f "$CONFIG_FILE" ]]; then
      current_modified=$(stat -c %Y "$CONFIG_FILE")
      debug 4 "Checking config modification time: $current_modified vs $last_modified"
      if (( current_modified > last_modified )); then
        debug 2 "Config file changed. Restarting script..."
        echo "Config file changed. Restarting script..."
        exec "$SCRIPT_PATH" &
        exit 0
      fi
    else
      debug 2 "Config file disappeared!"
    fi
  done
}

# Main function
main() {
  # Set up debug log file
  if [[ "$DEBUG_ENABLED" == "yes" && -n "$DEBUG_LOG_FILE" ]]; then
    mkdir -p "$(dirname "$DEBUG_LOG_FILE")" 2>/dev/null
    echo "=== Cool Facts Debug Log - $(date) ===" > "$DEBUG_LOG_FILE"
  fi
  
  debug 3 "Starting Cool Facts script"
  
  # Initial configuration load
  load_config
  
  # Check if facts are enabled
  if [[ "$ENABLE_FACTS" != "yes" ]]; then
    debug 2 "Facts are disabled in configuration. Exiting."
    echo "Facts are disabled in configuration. Exiting."
    exit 0
  fi
  
  # Start config monitoring in background
  monitor_config &
  monitor_pid=$!
  debug 3 "Config monitor started with PID: $monitor_pid"
  
  # Main loop
  debug 3 "Entering main loop with interval of $INTERVAL minutes"
  while true; do
    debug 3 "Getting a new fact"
    fact=$(get_fact)
    display_fact "$fact"
    debug 3 "Sleeping for $INTERVAL minutes"
    sleep $(( INTERVAL * 60 ))
  done
  
  # Kill the monitor process if we ever exit the loop
  debug 3 "Exiting main loop, cleaning up"
  kill $monitor_pid 2>/dev/null
}

# Ensure only one instance is running
cleanup_old_instances() {
  local current_pid=$$
  local script_name=$(basename "$0")
  
  debug 3 "Cleaning up old instances of $script_name"
  # Find other instances of this script and kill them
  local killed_pids=$(pgrep -f "$script_name" | grep -v "$current_pid")
  if [[ -n "$killed_pids" ]]; then
    debug 3 "Killing processes: $killed_pids"
    echo "$killed_pids" | xargs kill -9 2>/dev/null
  fi
}

# Print debug info to console
print_debug_info() {
  echo "====== Cool Facts Script ======"
  echo "Status: $([ "$ENABLE_FACTS" == "yes" ] && echo "Enabled" || echo "Disabled")"
  echo "Debug mode: $([ "$DEBUG_ENABLED" == "yes" ] && echo "Enabled" || echo "Disabled")"
  if [[ "$DEBUG_ENABLED" == "yes" ]]; then
    echo "Debug log: $DEBUG_LOG_FILE"
    echo "Debug level: $DEBUG_LEVEL"
    echo ""
    echo "To view logs in real-time:"
    echo "  tail -f \"$DEBUG_LOG_FILE\""
  fi
  echo "============================="
}

# Run cleanup and start main function
cleanup_old_instances
print_debug_info

# Only run if enabled
if [[ "$ENABLE_FACTS" == "yes" ]]; then
  main &
  
  # Exit the parent process, letting the child run in the background
  disown
fi

exit 0 