#!/bin/bash

# Function to check a specific tool and show notification
check_tool() {
    local tool_name=$1
    local tool_cmd=$2
    local key=$3
    local display_name=$4
    local icon=$5
    local pref_file="$HOME/.config/hypr/${tool_name}_notify_pref"
    
    # Check if tool is installed
    if command -v "$tool_cmd" &> /dev/null; then
        # If the command exists, check if notification has already been shown
        if [ ! -f "$pref_file" ]; then
            # Notification hasn't been shown before, show it now
            notify-send --icon="$icon" --app-name="Hyprland" "$display_name Reminder" "Press SUPER + $key to ${display_name,,}" -a "Hyprland" -t 10000
            
            # Create preference file to remember we've shown the notification
            touch "$pref_file"
        fi
    else
        # If the command doesn't exist, show notification with reminder to install
        notify-send --icon=dialog-warning --app-name="Hyprland" "$display_name Missing" "The '$tool_cmd' command is not installed. Please install it to use SUPER + $key for ${display_name,,}." -a "Hyprland" -t 10000 --action="dont_show_again=Don't show again"
        
        # Listen for notification action
        action=$(echo -e "\n" | swaynotificationcenter-action)
        
        if [ "$action" = "dont_show_again" ]; then
            # Create preference file to remember user's choice
            touch "$pref_file"
        fi
    fi
}

# Sleep briefly to ensure notifications don't overlap
sleep 1

# Check for hyprland-keybinds
check_tool "keybinds" "hyprland-keybinds" "K" "Keybinds Viewer" "input-keyboard"

# Sleep briefly between notifications
sleep 2

# Check for main-center
check_tool "main_center" "main-center" "C" "Main Center" "preferences-system" 