#!/bin/bash

# Toggle between normal mode and performance mode
# This script:
# 1. Kills current waybar instance
# 2. Starts performance waybar or normal waybar
# 3. Changes animation settings
# 4. Disables/enables background wallpaper
# 5. Disables window borders and anti-aliasing

PERFORMANCE_MODE_FILE="$HOME/.config/hypr/.performance_mode"
TEMP_CONF="$HOME/.config/hypr/.temp_performance_conf"
TEMP_WALLPAPER="$HOME/.config/hypr/.black_bg.png"

# Ensure no hanging processes
killall -q swaybg 2>/dev/null

# Create black wallpaper if it doesn't exist (smaller size)
if [ ! -f "$TEMP_WALLPAPER" ]; then
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | base64 -d > "$TEMP_WALLPAPER"
fi

# Check if we're in performance mode
if [ -f "$PERFORMANCE_MODE_FILE" ]; then
    # We're in performance mode, switch to normal
    echo "Switching to normal mode..."
    
    # Kill performance waybar and start normal waybar
    killall -q waybar
    waybar & disown
    
    # Change animation config back to normal
    CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" ~/.config/hypr/hyprland.conf | awk '{print $NF}')
    sed -i "s|$CURRENT_ANI|~/.config/hypr/animations/ani-2.conf|g" ~/.config/hypr/hyprland.conf
    
    # Restart background process if needed
    if command -v swww &> /dev/null; then
        killall -q swww
        swww init & disown
    elif command -v hyprpaper &> /dev/null; then
        killall -q hyprpaper
        hyprpaper & disown
    fi
    
    # Remove performance mode and temp config files
    rm -f "$PERFORMANCE_MODE_FILE" "$TEMP_CONF"
    
    # Reload Hyprland config
    hyprctl reload
    
    # Quick notification
    notify-send -t 2000 "Normal Mode" "Switched to normal mode"
    
    # Exit cleanly
    exit 0
else
    # Switch to performance mode
    echo "Switching to performance mode..."
    
    # Kill current waybar and start performance waybar
    killall -q waybar
    # Start waybar with less features
    waybar -c ~/.config/waybar/performance-mode.jsonc -s ~/.config/waybar/performance-style.css & disown
    
    # Change animation config to performance
    CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" ~/.config/hypr/hyprland.conf | awk '{print $NF}')
    sed -i "s|$CURRENT_ANI|~/.config/hypr/animations/performance.conf|g" ~/.config/hypr/hyprland.conf
    
    # Kill background processes
    killall -q swww hyprpaper swaybg
    
    # Create temporary config with solid black background and disabled borders/anti-aliasing
    cat > "$TEMP_CONF" << EOL
# Performance mode - optimized settings
general {
    # Disable borders
    border_size = 0
    no_border_on_floating = true
    
    # Gaps
    gaps_in = 0
    gaps_out = 0
}

decoration {
    # Disable rounding
    rounding = 0
    
    # Disable shadows
    drop_shadow = false
    shadow_range = 0
    
    # Disable blur
    blur {
        enabled = false
    }
}

misc {
    background_color = 0x000000
    # Disable anti-aliasing
    disable_hyprland_logo = true
    disable_splash_rendering = true
    no_direct_scanout = false
    vfr = true
    
    # Reduce resource usage
    force_default_wallpaper = 0
    layers_hog_keyboard_focus = false
    animate_manual_resizes = false
    animate_mouse_windowdragging = false
}

# Disable extra effects
group {
    groupbar {
        enabled = false
    }
}
EOL
    
    # Apply the temporary config directly without reload first
    hyprctl keyword general:border_size 0
    hyprctl keyword general:no_border_on_floating true
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:drop_shadow false
    hyprctl keyword decoration:blur:enabled false
    
    # Set a solid color background (less resource intensive than running swaybg)
    hyprctl keyword misc:background_color 0x000000
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Apply source only once
    hyprctl keyword source "$TEMP_CONF"
    
    # Quick notification
    notify-send -t 2000 "PERFORMANCE MODE" "Maximum performance mode enabled"
    
    # Exit cleanly
    exit 0
fi 