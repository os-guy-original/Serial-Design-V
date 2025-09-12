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

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"
CACHE_DIR="$CONFIG_DIR/cache"
STATE_DIR="$CACHE_DIR/state"
TEMP_DIR="$CACHE_DIR/temp"

# Create cache directories if they don't exist
mkdir -p "$STATE_DIR"
mkdir -p "$TEMP_DIR"

PERFORMANCE_MODE_FILE="$STATE_DIR/.performance_mode"
TEMP_CONF="$TEMP_DIR/.temp_performance_conf"
TEMP_WALLPAPER="$TEMP_DIR/.black_bg.png"
SAVED_ANIMATION_FILE="$STATE_DIR/.saved_animation_conf"
SAVED_WALLPAPER_FILE="$STATE_DIR/.saved_wallpaper"
SAVED_DECORATION_FILE="$STATE_DIR/.saved_decoration_conf"
LAST_WALLPAPER_FILE="$STATE_DIR/last_wallpaper"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)

# Define performance sound file
PERFORMANCE_SOUND="toggle_performance.ogg"

# Ensure no hanging processes
killall -q swaybg 2>/dev/null

# Create black wallpaper if it doesn't exist (smaller size)
[ -f "$TEMP_WALLPAPER" ] || echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" | base64 -d > "$TEMP_WALLPAPER"

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
    
    # Call the exit_performance_mode.sh script to handle exiting performance mode
    "$CONFIG_DIR/scripts/system/performance/exit_performance_mode.sh"
    
    exit 0
else
    # We're in normal mode, switch to performance
    
    # Save current decoration config
    grep "source = ~/.config/hypr/decorations/.*\.conf" "$CONFIG_DIR/hyprland.conf" > "$SAVED_DECORATION_FILE"
    
    # Change to performance decorations
    sed -i "s|source = ~/.config/hypr/decorations/.*\.conf|source = ~/.config/hypr/decorations/performance.conf|g" "$CONFIG_DIR/hyprland.conf"
    
    # Save current wallpaper before switching
    save_current_wallpaper
    
    # Play performance mode sound in background
    play_sound "$PERFORMANCE_SOUND"
    
    # Update animation config
    update_animations_config "performance"
    
    # Create performance mode file
    touch "$PERFORMANCE_MODE_FILE"
    
    # Kill normal waybar and start performance waybar
    pkill -x waybar 2>/dev/null
    
    # Apply performance config
    hyprctl reload &>/dev/null
    
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
