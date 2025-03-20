#!/usr/bin/env bash

STATUS=$(nmcli -t -f STATE g)
WIFI_STATUS=$(nmcli -t -f WIFI radio)

if [[ $WIFI_STATUS == "disabled" ]]; then
    echo '{"text": "󰖪", "tooltip": "Wi-Fi Disabled"}'
elif [[ $STATUS == "disconnected" ]]; then
    echo '{"text": "󰖩", "tooltip": "Disconnected"}'
else
    CONNECTION=$(nmcli -t -f NAME,DEVICE connection show --active | grep wlan | head -1 | cut -d: -f1)
    SIGNAL=$(nmcli -t -f IN-USE,SIGNAL device wifi | grep '*' | cut -d: -f2)
    echo "{\"text\": \"󰖩 $CONNECTION ($SIGNAL%)\", \"tooltip\": \"Connected to $CONNECTION\"}"
fi
