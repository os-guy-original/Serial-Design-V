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
SAVED_ANIMATION_FILE="$HOME/.config/hypr/.saved_animation_conf"

# Ensure no hanging processes
killall -q swaybg 2>/dev/null

# Create black wallpaper if it doesn't exist (smaller size)
if [ ! -f "$TEMP_WALLPAPER" ]; then
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | base64 -d > "$TEMP_WALLPAPER"
fi

# Restore normal wallpaper
restore_wallpaper() {
    # Try swww first
    if command -v swww >/dev/null 2>&1; then
        # Restart swww if not running
        if ! pgrep -x "swww-daemon" >/dev/null; then
            swww init
            sleep 1
        fi
        
        # Find a wallpaper
        for img in "$HOME/.config/hypr/wallpaper.png" "$HOME/.config/hypr/wallpaper.jpg" \
                   "$HOME/Pictures/wallpaper.png" "$HOME/Pictures/wallpaper.jpg"; do
            if [ -f "$img" ]; then
                swww img "$img" --transition-type simple
                return
            fi
        done
    fi
    
    # Fall back to hyprpaper
    if command -v hyprpaper >/dev/null 2>&1 && [ -f "$HOME/.config/hypr/hyprpaper.conf" ]; then
        hyprpaper & disown
    fi
}

# Check if we're in performance mode
if [ -f "$PERFORMANCE_MODE_FILE" ]; then
    # We're in performance mode, switch to normal
    echo "Switching to normal mode..."
    
    # Kill performance waybar and start normal waybar
    killall -q waybar
    waybar & disown
    
    # Restore original animation config
    if [ -f "$SAVED_ANIMATION_FILE" ]; then
        ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
        sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" ~/.config/hypr/hyprland.conf
        rm -f "$SAVED_ANIMATION_FILE"
    fi
    
    # Restore normal wallpaper
    restore_wallpaper
    
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
    
    # Save current animation config
    CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" ~/.config/hypr/hyprland.conf)
    echo "$CURRENT_ANI" > "$SAVED_ANIMATION_FILE"
    
    # Kill current waybar and start performance waybar
    killall -q waybar
    # Start waybar with less features
    waybar -c ~/.config/waybar/performance-mode.jsonc -s ~/.config/waybar/performance-style.css & disown
    
    # Change animation config to performance
    sed -i "s|source = ~/.config/hypr/animations/.*\.conf|source = ~/.config/hypr/animations/performance.conf|g" ~/.config/hypr/hyprland.conf
    
    # Kill all wallpaper processes - be thorough
    killall -q hyprpaper 2>/dev/null
    killall -q swaybg 2>/dev/null
    
    # We'll leave swww running if it's already running
    
    # Set solid black background first
    hyprctl keyword misc:background_color 0x000000
    hyprctl keyword misc:force_default_wallpaper 0
    
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
    # Force solid black background
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
    
    # Apply config settings
    hyprctl keyword general:border_size 0
    hyprctl keyword general:no_border_on_floating true
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:drop_shadow false
    hyprctl keyword decoration:blur:enabled false
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Apply source
    hyprctl keyword source "$TEMP_CONF"
    
    # Force black background with swaybg
    swaybg -c "#000000" -m solid_color & disown
    (sleep 0.5 && swaybg -c "#000000" -i "$TEMP_WALLPAPER" -m solid_color) & disown
    
    # Quick notification
    notify-send -t 2000 "PERFORMANCE MODE" "Maximum performance mode enabled"
    
    # Exit cleanly
    exit 0
fi 