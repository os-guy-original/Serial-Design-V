#!/bin/bash

options=("Lock" "Logout" "Suspend" "Reboot" "Shutdown" "Cancel")
icons=("system-lock-screen" "system-log-out" "system-suspend" "system-reboot" "system-shutdown" "window-close")

# Build menu lines without trailing newline
menu=""
for i in "${!options[@]}"; do
    menu+="${options[$i]}\0icon\x1f${icons[$i]}\n"
done

# Remove the final \n to avoid empty entry
menu="${menu%\\n}"

# Pass to Rofi with printf (no auto-newline)
chosen=$(printf "%b" "$menu" | rofi -dmenu -theme ~/.config/rofi/logout.rasi -format i -no-fixed-num-lines -no-custom -disable-history -hide-scrollbar)

# Handle selection
if [[ -n "$chosen" ]]; then
    case "${options[$chosen]}" in
        "Lock") loginctl lock-session ;;
        "Logout") mpv ~/.config/hypr/sounds/logout.ogg && loginctl terminate-user "$USER" ;;
        "Suspend") mpv ~/.config/hypr/sounds/logout.ogg &&  systemctl suspend ;;
        "Reboot") mpv ~/.config/hypr/sounds/logout.ogg && systemctl reboot ;;
        "Shutdown") mpv ~/.config/hypr/sounds/logout.ogg &&  systemctl poweroff ;;
        *) exit 0 ;;
    esac
fi
