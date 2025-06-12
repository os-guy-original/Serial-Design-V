#!/bin/bash
STYLE="-theme $HOME/.config/rofi/theme.rasi"

# Function to handle wlr-specific logic
get_active_windows() {
    hyprctl clients -j | jq -r '.[] | select(.title != "") | "[\(.workspace.id)] \(.title) [\(.class)]"'
}

# Select window
selected=$(get_active_windows | rofi -dmenu -p "Select window" -markup-rows $STYLE)

if [ -z "$selected" ]; then
    exit 0
fi

# Parse window info
workspace=$(echo "$selected" | sed -E 's/^\[([0-9]+)\].*/\1/')
class=$(echo "$selected" | sed -E 's/.*\[([^]]+)\]$/\1/')

# Select action
action=$(echo -e "Focus\nMove to current workspace\nMove to another workspace\nClose" | rofi -dmenu -p "Action for $class" $STYLE)

case "$action" in
    "Focus")
        hyprctl dispatch focuswindow "class:$class"
        ;;
    "Move to current workspace")
        hyprctl dispatch movewindow "class:$class"
        ;;
    "Move to another workspace")
        target=$(seq 1 10 | rofi -dmenu -p "Destination workspace" $STYLE)
        if [ -n "$target" ]; then
            hyprctl dispatch movetoworkspacesilent "$target,class:$class"
        fi
        ;;
    "Close")
        hyprctl dispatch closewindow "class:$class"
        ;;
esac
