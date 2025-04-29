#!/bin/bash

# Path to store the preference file
PREF_FILE="$HOME/.config/hypr/keybinds_notify_pref"

# Check if hyprland-keybinds is installed
if command -v hyprland-keybinds &> /dev/null; then
    # If the command exists, check if notification has already been shown
    if [ ! -f "$PREF_FILE" ]; then
        # Notification hasn't been shown before, show it now
        notify-send --icon=input-keyboard --app-name="Hyprland" "Keybinds Reminder" "Press SUPER + K to see all keybinds" -a "Hyprland" -t 10000
        
        # Create preference file to remember we've shown the notification
        touch "$PREF_FILE"
    fi
else
    # If the command doesn't exist, show notification with reminder to install
    notify-send --icon=dialog-warning --app-name="Hyprland" "Keybinds Tool Missing" "The 'hyprland-keybinds' command is not installed. Please install it to use SUPER + K for viewing keybinds." -a "Hyprland" -t 10000 --action="dont_show_again=Don't show again"
    
    # Listen for notification action
    action=$(echo -e "\n" | swaynotificationcenter-action)
    
    if [ "$action" = "dont_show_again" ]; then
        # Create preference file to remember user's choice
        touch "$PREF_FILE"
    fi
fi 