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

# Get sound directory more efficiently
if [ -f "$DEFAULT_SOUND_FILE" ]; then
    SOUND_THEME=$(cat "$DEFAULT_SOUND_FILE" | tr -d '[:space:]')
    SOUNDS_DIR="$SOUNDS_BASE_DIR/${SOUND_THEME:-default}"
    # Check if directory exists, fallback to default if not
    [ -d "$SOUNDS_DIR" ] || SOUNDS_DIR="$SOUNDS_BASE_DIR/default"
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
[ -f "$TEMP_WALLPAPER" ] || echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | base64 -d > "$TEMP_WALLPAPER"

# Play sound function - optimized
play_sound() {
    [ -f "$1" ] && command -v mpv >/dev/null 2>&1 && {
        if [ "$2" = "reverse" ]; then
            mpv "$1" --volume=60 --af=areverse &>/dev/null &
        else
            mpv "$1" --volume=60 &>/dev/null &
        fi
    }
}

# Save current wallpaper - optimized
save_current_wallpaper() {
    # Use the last_wallpaper file which contains the path to the current wallpaper
    if [ -f "$LAST_WALLPAPER_FILE" ] && [ -s "$LAST_WALLPAPER_FILE" ]; then
        CURRENT_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        [ -f "$CURRENT_WALLPAPER" ] && echo "$CURRENT_WALLPAPER" > "$SAVED_WALLPAPER_FILE" && return
    fi
    
    # Fallback: Try to find current wallpaper path from swww
    if command -v swww >/dev/null 2>&1 && pgrep -x "swww-daemon" >/dev/null; then
        CURRENT_WALLPAPER=$(swww query | grep -oP 'image: \K[^ ]+' 2>/dev/null)
        [ -f "$CURRENT_WALLPAPER" ] && echo "$CURRENT_WALLPAPER" > "$SAVED_WALLPAPER_FILE" && return
    fi
    
    # Fallback: check if common wallpaper paths exist
    for img in "$CONFIG_DIR/wallpaper.png" "$CONFIG_DIR/wallpaper.jpg"; do
        [ -f "$img" ] && echo "$img" > "$SAVED_WALLPAPER_FILE" && return
    done
}

# Restore saved wallpaper - optimized for speed and reliability
restore_wallpaper() {
    # Check if we have a saved wallpaper
    if [ -f "$SAVED_WALLPAPER_FILE" ] && [ -s "$SAVED_WALLPAPER_FILE" ]; then
        WALLPAPER_PATH=$(cat "$SAVED_WALLPAPER_FILE")
        if [ -f "$WALLPAPER_PATH" ]; then
            # Kill any existing swww-daemon
            pkill -x swww-daemon 2>/dev/null
            
            # Start swww-daemon and wait for it to initialize
            swww-daemon &>/dev/null &
            sleep 0.5
            
            # Apply the wallpaper with swww directly
            swww img "$WALLPAPER_PATH" --transition-type none &>/dev/null &
            return
        fi
    fi
    
    # Quick fallback to hyprpaper
    if command -v hyprpaper >/dev/null 2>&1 && [ -f "$CONFIG_DIR/hyprpaper.conf" ]; then
        pkill -x hyprpaper 2>/dev/null
        hyprpaper &>/dev/null &
    fi
}

# Create performance config - only if needed
create_performance_config() {
    # Only create if it doesn't exist or is empty
    if [ ! -f "$TEMP_CONF" ] || [ ! -s "$TEMP_CONF" ]; then
        cat > "$TEMP_CONF" << EOL
# Performance mode - optimized settings
general {
    # Disable borders
    border_size = 0
    no_border_on_floating = true
    gaps_in = 0
    gaps_out = 0
}

decoration {
    # Disable rounding and effects
    rounding = 0
    drop_shadow = false
    shadow_range = 0
    blur { enabled = false }
}

misc {
    # Force solid black background
    background_color = 0x000000
    
    # Disable visual effects
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
group { groupbar { enabled = false } }
EOL
    fi
}

# Function to check and apply animations config - optimized
update_animations_config() {
    local action=$1
    
    # Check if hyprland.conf contains animation source
    if ! grep -q "source = ~/.config/hypr/animations/" "$CONFIG_DIR/hyprland.conf"; then
        # Add animation source if it doesn't exist
        sed -i '/^#.*ANIMATIONS.*$/a source = ~/.config/hypr/animations/default.conf' "$CONFIG_DIR/hyprland.conf"
    fi

    if [ "$action" = "performance" ]; then
        # Save current animation config
        grep "source = ~/.config/hypr/animations/" "$CONFIG_DIR/hyprland.conf" > "$SAVED_ANIMATION_FILE"
        
        # Change to performance animations
        sed -i "s|source = ~/.config/hypr/animations/.*\.conf|source = ~/.config/hypr/animations/performance.conf|g" "$CONFIG_DIR/hyprland.conf"
    else
        # Restore original animation config
        if [ -f "$SAVED_ANIMATION_FILE" ] && [ -s "$SAVED_ANIMATION_FILE" ]; then
            ORIGINAL_ANI=$(cat "$SAVED_ANIMATION_FILE")
            sed -i "s|source = ~/.config/hypr/animations/.*\.conf|$ORIGINAL_ANI|g" "$CONFIG_DIR/hyprland.conf"
            rm -f "$SAVED_ANIMATION_FILE"
        fi
    fi
}

# Check if we're in performance mode
if [ -f "$PERFORMANCE_MODE_FILE" ]; then
    # We're in performance mode, switch to normal
    
    # Play normal mode sound in background
    play_sound "$PERFORMANCE_SOUND" "reverse" &
    
    # Kill performance waybar and start normal waybar
    pkill -x waybar 2>/dev/null
    waybar &>/dev/null & disown
    
    # Restore original animation config
    update_animations_config "normal"
    
    # Remove performance mode and temp config files
    rm -f "$PERFORMANCE_MODE_FILE"
    
    # Restore wallpaper
    restore_wallpaper
    
    # Reload Hyprland config
    hyprctl reload &>/dev/null &
    
    # Show completion notification
    notify-send -t 2000 "Mode" "Normal mode activated" &
else
    # We're in normal mode, switch to performance
    
    # Create performance config
    create_performance_config
    
    # Save current wallpaper before switching
    save_current_wallpaper
    
    # Play performance mode sound in background
    play_sound "$PERFORMANCE_SOUND" &
    
    # Update animation config
    update_animations_config "performance"
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Kill normal waybar and start performance waybar
    pkill -x waybar 2>/dev/null
    
    # Apply performance config
    hyprctl keyword source "$TEMP_CONF" &>/dev/null
    
    # Kill wallpaper daemon
    pkill -x swww-daemon 2>/dev/null
    pkill -x hyprpaper 2>/dev/null
    
    # Set solid color background
    hyprctl keyword misc:background_color 0x000000 &>/dev/null
    
    # Start performance waybar
    WAYBAR_CONFIG="$HOME/.config/waybar/performance-mode.jsonc"
    WAYBAR_STYLE="$HOME/.config/waybar/performance-style.css"
    
    if [ -f "$WAYBAR_CONFIG" ] && [ -f "$WAYBAR_STYLE" ]; then
        waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_STYLE" &>/dev/null & disown
    else
        waybar &>/dev/null & disown
    fi
    
    # Show completion notification
    notify-send -t 2000 "Mode" "Performance mode activated" &
fi 
