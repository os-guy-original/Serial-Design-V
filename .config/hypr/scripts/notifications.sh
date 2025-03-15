#!/usr/bin/env bash

# Notification popup system for Hyprland
# Dependencies: jq, yad, dbus

# Kill existing instances
pkill -f "dbus-monitor"
pkill -f "yad --notification"

# Listen for notifications
dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | \
while read -r line; do
    if [[ "$line" =~ member=Notify ]]; then
        # Extract notification content
        app_name=$(echo "$line" | awk -F '"' '{print $2}')
        summary=$(echo "$line" | awk -F '"' '{print $4}')
        body=$(echo "$line" | awk -F '"' '{print $6}')

        # Get monitor info using hyprctl
        monitor_info=$(hyprctl monitors -j | jq '.[0]')
        width=$(jq '.width' <<< "$monitor_info")
        height=$(jq '.height' <<< "$monitor_info")
        x=$(jq '.x' <<< "$monitor_info")
        y=$(jq '.y' <<< "$monitor_info")

        # Calculate position (top-right with 20px padding)
        pos_x=$((x + width - 400))  # 400px wide notification
        pos_y=$((y + 20))

        # Close previous notification
        pkill -f "yad --notification"

        # Show notification with yad
        yad --notification \
            --no-middle \
            --geometry=400x100+"$pos_x"+"$pos_y" \
            --title="$app_name" \
            --text="<b>$summary</b>\n$body" \
            --button=gtk-ok:0 \
            --escape-ok \
            --timeout=5 &
    fi
done
