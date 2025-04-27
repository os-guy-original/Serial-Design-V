#!/bin/bash

# Get keybinding for performance mode
get_keybind() {
    local mainmod=$(grep -r '^\$mainMod =' ~/.config/hypr/ --include="*.conf" | head -1 | awk -F '=' '{print $2}' | tr -d ' ')
    local keybind_line=$(grep -r "toggle_performance_mode\|toggle_gaming_mode" ~/.config/hypr/ --include="*.conf" | head -1)
    
    if [ -n "$keybind_line" ]; then
        # Extract key combination
        local key_combo=$(echo "$keybind_line" | awk -F 'bind = ' '{print $2}' | awk -F ', exec,' '{print $1}' | sed 's/, /+/g')
        
        # Replace $mainMod with its value
        if [ -n "$mainmod" ]; then
            key_combo=$(echo "$key_combo" | sed "s/\$mainMod/$mainmod/g")
        fi
        
        # Clean up spaces
        key_combo=$(echo "$key_combo" | tr -s ' ' | tr ' ' '+')
        echo "$key_combo"
    else
        echo "SUPER+ALT+G"  # Default fallback
    fi
}

# Get keybinding
KEYBIND=$(get_keybind)

# Generate Waybar JSON output
echo "{\"text\": \"PERFORMANCE MODE\", \"tooltip\": \"System running in performance mode\\n\\nExit with: $KEYBIND\\n\\nClick to exit performance mode\", \"class\": \"performance-mode\"}" 