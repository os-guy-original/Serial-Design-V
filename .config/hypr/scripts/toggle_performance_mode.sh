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

# Create black wallpaper if it doesn't exist
if [ ! -f "$TEMP_WALLPAPER" ]; then
    convert -size 16x16 xc:black "$TEMP_WALLPAPER" 2>/dev/null || \
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVQI12P4//8/AAX+Av7czFnnAAAAAElFTkSuQmCC" | base64 -d > "$TEMP_WALLPAPER"
fi

# Check if we're in performance mode
if [ -f "$PERFORMANCE_MODE_FILE" ]; then
    # We're in performance mode, switch to normal
    echo "Switching to normal mode..."
    
    # Kill performance waybar and start normal waybar
    killall waybar
    waybar &
    
    # Change animation config back to normal
    CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" ~/.config/hypr/hyprland.conf | awk '{print $NF}')
    sed -i "s|$CURRENT_ANI|~/.config/hypr/animations/ani-2.conf|g" ~/.config/hypr/hyprland.conf
    
    # Restart background process if needed
    if command -v swww &> /dev/null; then
        swww init
    elif command -v hyprpaper &> /dev/null; then
        hyprpaper &
    fi
    
    # Remove performance mode and temp config files
    rm -f "$PERFORMANCE_MODE_FILE" "$TEMP_CONF"
    
    # Reload Hyprland config
    hyprctl reload
    
    notify-send "Normal Mode" "Switched to normal mode"
else
    # Switch to performance mode
    echo "Switching to performance mode..."
    
    # Kill current waybar and start performance waybar
    killall waybar
    waybar -c ~/.config/waybar/performance-mode.jsonc -s ~/.config/waybar/performance-style.css &
    
    # Change animation config to performance
    CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" ~/.config/hypr/hyprland.conf | awk '{print $NF}')
    sed -i "s|$CURRENT_ANI|~/.config/hypr/animations/performance.conf|g" ~/.config/hypr/hyprland.conf
    
    # Kill background processes
    if command -v swww &> /dev/null; then
        swww kill
    elif command -v hyprpaper &> /dev/null; then
        killall hyprpaper
    fi
    
    # Create temporary config with solid black background and disabled borders/anti-aliasing
    cat > "$TEMP_CONF" << EOL
# Performance mode - optimized settings
general {
    # Disable borders
    border_size = 0
    col.active_border = rgba(000000ff)
    col.inactive_border = rgba(000000ff)
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
    col.shadow = rgba(000000ff)
    col.shadow_inactive = rgba(000000ff)
    
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
    force_default_wallpaper = 0
    no_direct_scanout = false
    vfr = true
    vrr = 2
}
EOL
    
    # Apply the temporary config
    hyprctl keyword source "$TEMP_CONF"
    
    # Disable window borders explicitly
    hyprctl keyword general:border_size 0
    hyprctl keyword general:no_border_on_floating true
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:drop_shadow false
    
    # Additional fallback: Try to set a black wallpaper
    if command -v hyprctl &> /dev/null; then
        hyprctl hyprpaper unload all 2>/dev/null
        sleep 0.1
        swaybg -c "#000000" -i "$TEMP_WALLPAPER" &
    fi
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Reload Hyprland config
    hyprctl reload
    
    # Apply solid black background again after reload
    sleep 0.5
    hyprctl keyword source "$TEMP_CONF"
    
    # Final fallback after reload
    swaybg -c "#000000" -i "$TEMP_WALLPAPER" &
    
    notify-send "PERFORMANCE MODE" "Maximum performance mode enabled"
fi 