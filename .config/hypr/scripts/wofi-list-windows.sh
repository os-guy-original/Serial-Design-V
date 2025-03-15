#!/bin/bash
STYLE=~/.config/wofi/style.css


# Get window list and show selection
selected=$(hyprctl clients -j | jq -r '
    group_by(.workspace.name) | 
    sort_by(.[0].workspace.name)[] | 
    "<b>Workspace \(.[0].workspace.name)</b>\n" + 
    (map("  \(.class)<span foreground=\"#00000000\">|\(.address)</span>") | join("\n"))' | 
    wofi --show dmenu --prompt="Select window" --allow-markup --style="$STYLE")

[[ -z "$selected" ]] && exit

# Extract hidden address
if [[ $selected == *"|"* ]]; then
    address=$(echo "$selected" | sed 's/.*|//;s/<\/span>//' | tr -d ' ')
    class=$(echo "$selected" | sed 's/<span.*//;s/^  //')

    action=$(echo -e "Focus\nMove to workspace\nFullscreen" | \
        wofi --show dmenu --prompt="Action for $class" --style="$STYLE")

    case "$action" in
        "Focus")
            hyprctl dispatch focuswindow "address:${address}"
            ;;
        "Move to workspace")
            target_ws=$(seq 1 10 | awk '{printf "%02d\n", $0}' | \
                wofi --show dmenu --prompt="Destination workspace" --style="$STYLE")
            target_ws=$(echo "$target_ws" | sed 's/^0*//')
            
            if [[ "$target_ws" =~ ^[0-9]+$ ]] && [ "$target_ws" -ge 1 ] && [ "$target_ws" -le 10 ]; then
                hyprctl dispatch movetoworkspacesilent "$target_ws,address:${address}"
            fi
            ;;
        "Fullscreen")
            # Get the current workspace of the selected window
            workspace=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$address\") | .workspace.name")
            
            # Switch to the workspace of the selected window
            hyprctl dispatch workspace "$workspace"
            
            # Toggle fullscreen for the selected window
            hyprctl dispatch fullscreen "address:${address}"
            ;;
    esac
fi
