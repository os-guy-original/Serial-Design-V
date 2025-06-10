#!/bin/bash

# Toggle between normal mode and performance mode
# This script:
# 1. Kills current waybar instance
# 2. Starts performance waybar or normal waybar
# 3. Changes animation settings
# 4. Disables/enables background wallpaper
# 5. Disables window borders and anti-aliasing
# 6. Plays sound effects when toggling modes
# 7. Shows notifications for mode transitions

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

PERFORMANCE_MODE_FILE="$CONFIG_DIR/.performance_mode"
TEMP_CONF="$CONFIG_DIR/.temp_performance_conf"
TEMP_WALLPAPER="$CONFIG_DIR/.black_bg.png"
SAVED_ANIMATION_FILE="$CONFIG_DIR/.saved_animation_conf"
SAVED_WALLPAPER_FILE="$CONFIG_DIR/.saved_wallpaper"
LAST_WALLPAPER_FILE="$CONFIG_DIR/last_wallpaper"

# Sound files path - updated to use the sound theme system
SOUNDS_BASE_DIR="$CONFIG_DIR/sounds"
DEFAULT_SOUND_FILE="$SOUNDS_BASE_DIR/default-sound"

# Check if default-sound file exists and read its content
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    if [ -n "$SOUND_THEME" ] && [ -d "$SOUNDS_BASE_DIR/$SOUND_THEME" ]; then
        SOUNDS_DIR="$SOUNDS_BASE_DIR/$SOUND_THEME"
    else
        SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    fi
else
    SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
    # Create default-sound file if it doesn't exist
    mkdir -p "$SOUNDS_BASE_DIR"
    echo "default" > "$DEFAULT_SOUND_FILE"
fi

# Define performance sound file
PERFORMANCE_SOUND="$SOUNDS_DIR/toggle_performance.ogg"

# Ensure no hanging processes
killall -q swaybg 2>/dev/null

# Create black wallpaper if it doesn't exist (smaller size)
if [ ! -f "$TEMP_WALLPAPER" ]; then
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | base64 -d > "$TEMP_WALLPAPER"
fi

# Play sound function
play_sound() {
    if command -v mpv >/dev/null 2>&1; then
        if [ -f "$1" ]; then
            if [ "$2" = "reverse" ]; then
                # Play the sound backward
                mpv "$1" --volume=60 --af=areverse &>/dev/null &
            else
                # Play the sound normally
                mpv "$1" --volume=60 &>/dev/null &
            fi
        fi
    fi
}

# Save current wallpaper
save_current_wallpaper() {
    # Use the last_wallpaper file which contains the path to the current wallpaper
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        CURRENT_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        if [ -n "$CURRENT_WALLPAPER" ] && [ -f "$CURRENT_WALLPAPER" ]; then
            echo "$CURRENT_WALLPAPER" > "$SAVED_WALLPAPER_FILE"
            return
        fi
    fi
    
    # Fallback: Try to find current wallpaper path from swww
    if command -v swww >/dev/null 2>&1; then
        # Check if swww daemon is running
        if pgrep -x "swww-daemon" >/dev/null; then
            # Get current wallpaper path if possible
            CURRENT_WALLPAPER=$(swww query | grep -oP 'image: \K[^ ]+' 2>/dev/null)
            if [ -n "$CURRENT_WALLPAPER" ] && [ -f "$CURRENT_WALLPAPER" ]; then
                echo "$CURRENT_WALLPAPER" > "$SAVED_WALLPAPER_FILE"
                return
            fi
        fi
    fi
    
    # Fallback: check if common wallpaper paths exist
    for img in "$CONFIG_DIR/wallpaper.png" "$CONFIG_DIR/wallpaper.jpg"; do
        if [ -f "$img" ]; then
            echo "$img" > "$SAVED_WALLPAPER_FILE"
            return
        fi
    done
}

# Restore saved wallpaper - optimized for speed
restore_wallpaper() {
    # Check if we have a saved wallpaper
    if [ -f "$SAVED_WALLPAPER_FILE" ]; then
        WALLPAPER_PATH=$(cat "$SAVED_WALLPAPER_FILE")
        if [ -f "$WALLPAPER_PATH" ]; then
            # Kill any existing swww-daemon
            if pgrep -x "swww-daemon" >/dev/null; then
                killall -q swww-daemon 2>/dev/null
            fi
            
            # Let Hyprland restart swww-daemon
            hyprctl dispatch exec "[workspace special silent] swww-daemon" &>/dev/null
            
            # Let Hyprland apply the wallpaper
            sleep 0.1
            if [ -f "$WALLPAPER_PATH" ]; then
                hyprctl dispatch exec "[workspace special silent] swww img $WALLPAPER_PATH --transition-type none" &>/dev/null &
            fi
            return
        fi
    fi
    
    # Quick fallback to hyprpaper - don't wait
    if command -v hyprpaper >/dev/null 2>&1 && [ -f "$CONFIG_DIR/hyprpaper.conf" ]; then
        hyprctl dispatch exec "[workspace special silent] hyprpaper" &>/dev/null &
    fi
}

# Create performance config before it's needed
create_performance_config() {
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
}

# Function to check and apply animations config
update_animations_config() {
    local action=$1
    
    # Check if hyprland.conf contains animation source
    if ! grep -q "source = ~/.config/hypr/animations/" "$CONFIG_DIR/hyprland.conf"; then
        # Add animation source if it doesn't exist
        echo "Adding default animation source to hyprland.conf"
        sed -i '/^#.*ANIMATIONS.*$/a source = ~/.config/hypr/animations/default.conf' "$CONFIG_DIR/hyprland.conf"
    fi

    if [ "$action" = "performance" ]; then
        # Save current animation config
        CURRENT_ANI=$(grep "source = ~/.config/hypr/animations/" "$CONFIG_DIR/hyprland.conf")
        echo "$CURRENT_ANI" > "$SAVED_ANIMATION_FILE"
        echo "Saved current animation config: $CURRENT_ANI"
        
        # Change to performance animations
        sed -i "s|source = ~/.config/hypr/animations/.*\.conf|source = ~/.config/hypr/animations/performance.conf|g" "$CONFIG_DIR/hyprland.conf"
        echo "Changed animation to performance mode"
    else
        # Restore original animation config
        if [ -f "$SAVED_ANIMATION_FILE" ]; then
            ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
            echo "Restoring animation config: $ORIGINAL_ANI"
            sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" "$CONFIG_DIR/hyprland.conf"
            rm -f "$SAVED_ANIMATION_FILE"
        else
            echo "Warning: No saved animation config found"
        fi
    fi
}

# Create performance config ahead of time
create_performance_config

# Check if we're in performance mode
if [ -f "$PERFORMANCE_MODE_FILE" ]; then
    # We're in performance mode, switch to normal
    echo "Switching to normal mode..."
    
    # Play normal mode sound (the performance sound in reverse) in background
    play_sound "$PERFORMANCE_SOUND" "reverse" &
    
    # Kill performance waybar and start normal waybar (in parallel)
    killall -q waybar
    waybar &>/dev/null & disown
    
    # Restore original animation config - no logging to speed up process
    if [ -f "$SAVED_ANIMATION_FILE" ]; then
        ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
        sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" "$CONFIG_DIR/hyprland.conf"
        rm -f "$SAVED_ANIMATION_FILE"
    fi
    
    # Remove performance mode and temp config files
    rm -f "$PERFORMANCE_MODE_FILE"
    rm -f "$TEMP_CONF"
    
    # Start swww-daemon directly using hyprctl
    hyprctl dispatch exec "swww-daemon" &>/dev/null &
    
    # Wait a moment for swww-daemon to start
    sleep 0.1
    
    # If we have a saved wallpaper, set it
    if [ -f "$SAVED_WALLPAPER_FILE" ]; then
        WALLPAPER_PATH=$(cat "$SAVED_WALLPAPER_FILE")
        if [ -f "$WALLPAPER_PATH" ]; then
            hyprctl dispatch exec "swww img \"$WALLPAPER_PATH\" --transition-type none" &>/dev/null &
        fi
    fi
    
    # Reload Hyprland config (no waiting)
    hyprctl reload &>/dev/null &
    
    # Show completion notification
    notify-send -u normal -t 4000 "NORMAL MODE" "Switched to NORMAL mode."
    
    # Exit cleanly
    exit 0
else
    # Switch to performance mode
    echo "Switching to performance mode..."
    
    # Play performance mode sound
    play_sound "$PERFORMANCE_SOUND" &
    
    # Save current wallpaper before changing
    save_current_wallpaper
    
    # Kill current waybar and start performance waybar (in parallel)
    killall -q waybar
    if [ -f "$HOME/.config/waybar/performance-mode.jsonc" ]; then
        waybar -c "$HOME/.config/waybar/performance-mode.jsonc" -s "$HOME/.config/waybar/performance-style.css" &>/dev/null & disown
    else
        waybar &>/dev/null & disown
    fi
    
    # Change animation config to performance
    update_animations_config "performance"
    
    # Kill all wallpaper processes - be thorough
    killall -q hyprpaper swaybg swww-daemon 2>/dev/null
    
    # Set solid black background immediately
    hyprctl keyword misc:background_color 0x000000 &>/dev/null &
    hyprctl keyword misc:force_default_wallpaper 0 &>/dev/null &
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Apply config settings in parallel
    hyprctl keyword general:border_size 0 &>/dev/null &
    hyprctl keyword general:no_border_on_floating true &>/dev/null &
    hyprctl keyword decoration:rounding 0 &>/dev/null &
    hyprctl keyword decoration:drop_shadow false &>/dev/null &
    hyprctl keyword decoration:blur:enabled false &>/dev/null &
    
    # Apply source
    hyprctl keyword source "$TEMP_CONF" &>/dev/null
    
    # Force black background with swaybg
    swaybg -c "#000000" -m solid_color &>/dev/null & disown
    
    # Show completion notification
    notify-send -t 4000 "PERFORMANCE MODE" "Switched to PERFORMANCE mode."
    
    # Exit cleanly
    exit 0
fi 
