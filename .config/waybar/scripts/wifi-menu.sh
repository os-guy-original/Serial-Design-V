#!/usr/bin/env bash

toggle_wifi() {
    if [[ $(nmcli radio wifi) == "enabled" ]]; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
        sleep 2
    fi
}

list_networks() {
    nmcli -t -f SSID,SECURITY,BARS dev wifi list | \
    awk -F: '{printf "%-24s %-12s %s\n", $1, ($2 ? "" : " "), $3}' | \
    column -t | sed 's///g'
}

CURRENT_CONN=$(nmcli -t -f NAME connection show --active | head -1)

CHOICE=$(list_networks | wofi --dmenu -i -p "Wi-Fi" \
    --width 400 \
    --height 300 \
    --style ~/.config/wofi/password.css \
    --mesg "Current: ${CURRENT_CONN:-None}" \
    --bind=alt+t,action:toggle)

case $? in
    0)  # Normal selection
        SSID=$(echo "$CHOICE" | awk '{print $1}')
        if [[ "$CHOICE" == *"🔒"* ]]; then
            PASS=$(wofi --dmenu -password -p "Password for $SSID" \
                --style ~/.config/wofi/wifi.css)
            nmcli dev wifi connect "$SSID" password "$PASS"
        else
            nmcli dev wifi connect "$SSID"
        fi
        ;;
    10) # Alt+t pressed
        toggle_wifi
        ;;
esac
