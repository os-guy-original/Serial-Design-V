#!/bin/bash

# icon-theme.sh - Applies a Fluent icon theme based on the current accent color
# Usage: ./icon-theme.sh

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="/usr/share/icons"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
LOCK_FILE="/tmp/icon_theme_detection.lock"

# Prevent multiple simultaneous executions
if [ -f "$LOCK_FILE" ]; then
    if ps -p $(cat "$LOCK_FILE") > /dev/null 2>&1; then
        echo "Another instance of icon theme detection is already running. Exiting."
        exit 0
    else
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Debug info
echo "ICON THEME SCRIPT START: $(date +%H:%M:%S)"
echo "PWD: $(pwd)"

# Function to log color detection for debugging
log_color_detection() {
    local detected_color="$1"
    local reason="$2"
    local log_file="$HOME/.config/hypr/colorgen/icon_theme_detection.log"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Color: $detected_color, Reason: $reason, RGB: ($R,$G,$B)" >> "$log_file"
    
    # Keep only last 50 entries to prevent log bloat
    if [ -f "$log_file" ]; then
        tail -n 50 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    fi
}

# Check if files exist
if [ ! -f "$COLORGEN_CONF" ]; then
    echo "Error: $COLORGEN_CONF not found!"
    exit 1
fi

# Determine if we're in light or dark mode
THEME_MODE="dark"  # Default to dark mode
if [ -f "$CACHE_DIR/generated/gtk/light_theme_mode" ]; then
    IS_LIGHT_MODE=$(cat "$CACHE_DIR/generated/gtk/light_theme_mode")
    if [ "$IS_LIGHT_MODE" = "true" ]; then
        THEME_MODE="light"
    fi
fi
echo "Current theme mode: $THEME_MODE"

# Read accent color from colorgen/colors.conf
echo "Reading accent color from $COLORGEN_CONF..."
ACCENT=$(grep "^accent = " "$COLORGEN_CONF" | cut -d'#' -f2)

if [ -z "$ACCENT" ]; then
    echo "Error: Could not find accent color in $COLORGEN_CONF"
    echo "Using default Fluent icon theme"
    ICON_THEME="Fluent"
else
    echo "Found accent color: #$ACCENT"
    
    # Extract RGB components
    R=$((16#${ACCENT:0:2}))
    G=$((16#${ACCENT:2:2}))
    B=$((16#${ACCENT:4:2}))
    
    echo "RGB components: R=$R, G=$G, B=$B"
    
    # Improved color detection with clear priority and no duplicates
    
    # Calculate color differences for gray detection
    rg_diff=$(( R > G ? R - G : G - R ))
    gb_diff=$(( G > B ? G - B : B - G ))
    rb_diff=$(( R > B ? R - B : B - R ))
    max_diff=$(( rg_diff > gb_diff ? rg_diff : gb_diff ))
    max_diff=$(( max_diff > rb_diff ? max_diff : rb_diff ))
    
    # Find the dominant color component
    max_component=$R
    if [ $G -gt $max_component ]; then max_component=$G; fi
    if [ $B -gt $max_component ]; then max_component=$B; fi
    
    echo "Color analysis: R=$R, G=$G, B=$B, max_diff=$max_diff, max_component=$max_component"
    
    # Priority-based color detection (most specific first, no duplicates)
    if [ $max_diff -lt 25 ]; then
        # Gray: all components are similar
        COLOR="grey"
        reason="similar RGB values (max difference: $max_diff)"
        echo "Detected gray: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $R -gt 180 ] && [ $G -lt 120 ] && [ $B -gt 140 ] && [ $R -gt $B ]; then
        # Pink: high red, low-medium green, high blue, but red still dominant
        COLOR="pink"
        reason="high red ($R) > blue ($B), low-medium green ($G)"
        echo "Detected pink: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $R -gt 150 ] && [ $G -gt 100 ] && [ $B -lt 80 ] && [ $R -gt $G ]; then
        # Orange: high red, medium-high green, low blue
        COLOR="orange"
        reason="red ($R) > green ($G), low blue ($B)"
        echo "Detected orange: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $G -gt 120 ] && [ $B -gt 100 ] && [ $R -lt 100 ]; then
        # Teal: low red, high green and blue
        COLOR="teal"
        reason="low red ($R), high green ($G) and blue ($B)"
        echo "Detected teal: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $R -gt 60 ] && [ $B -gt 80 ] && [ $G -lt $(($R - 15)) ] && [ $G -lt $(($B - 15)) ]; then
        # Purple: both red and blue are significant, green is lower than both
        COLOR="purple"
        reason="red ($R) and blue ($B) both significant, green ($G) lower"
        echo "Detected purple: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $R -gt $G ] && [ $R -gt $B ] && [ $R -gt 120 ]; then
        # Red: red is clearly dominant
        COLOR="red"
        reason="red dominant ($R) over green ($G) and blue ($B)"
        echo "Detected red: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $G -gt $R ] && [ $G -gt $B ] && [ $G -gt 120 ]; then
        # Green: green is clearly dominant
        COLOR="green"
        reason="green dominant ($G) over red ($R) and blue ($B)"
        echo "Detected green: $reason"
        log_color_detection "$COLOR" "$reason"
    elif [ $B -gt $R ] && [ $B -gt $G ] && [ $B -gt 120 ]; then
        # Blue: blue is clearly dominant
        COLOR="blue"
        reason="blue dominant ($B) over red ($R) and green ($G)"
        echo "Detected blue: $reason"
        log_color_detection "$COLOR" "$reason"
    else
        # Fallback for low-intensity or ambiguous colors
        COLOR="grey"
        reason="ambiguous or low-intensity color (max: $max_component)"
        echo "Fallback to grey: $reason"
        log_color_detection "$COLOR" "$reason"
    fi
    
    # Build icon theme with color and theme mode
    if [ "$COLOR" = "blue" ]; then
        # For default (blue) use base Fluent with theme mode suffix
        if [ "$THEME_MODE" = "dark" ]; then
            ICON_THEME="Fluent-dark"
        else
            ICON_THEME="Fluent"  # Light mode is the default for Fluent
        fi
    else
        # For other colors, use Fluent-COLOR-THEME format
        if [ "$THEME_MODE" = "dark" ]; then
            ICON_THEME="Fluent-${COLOR}-dark"
        else
            ICON_THEME="Fluent-${COLOR}-light"
        fi
    fi

    # Validate that the directory exists; if not, fall back progressively
    if [ ! -d "$THEME_DIR/$ICON_THEME" ]; then
        echo "Theme directory $ICON_THEME not found, trying without theme mode suffix"
        
        # Try without the theme mode suffix
        if [ "$COLOR" = "blue" ]; then
            ICON_THEME="Fluent"
        else
            ICON_THEME="Fluent-${COLOR}"
        fi
        
        # Check if this fallback exists
        if [ ! -d "$THEME_DIR/$ICON_THEME" ]; then
            echo "Theme directory $ICON_THEME not found, falling back to base Fluent with theme mode"
            
            # Try base Fluent with theme mode
            if [ "$THEME_MODE" = "dark" ]; then
                ICON_THEME="Fluent-dark"
            else
                ICON_THEME="Fluent"
            fi
            
            # Final fallback to base Fluent
            if [ ! -d "$THEME_DIR/$ICON_THEME" ]; then
                echo "Theme directory $ICON_THEME not found, falling back to base Fluent"
                ICON_THEME="Fluent"
            fi
        fi
    fi
fi

echo "Selected icon theme: $ICON_THEME"

# Check if theme is already applied (but don't exit early)
OLD_THEME_FILE="$HOME/.config/hypr/colorgen/icon_theme.txt"
if [ -f "$OLD_THEME_FILE" ]; then
    OLD_THEME=$(head -n 1 "$OLD_THEME_FILE" | tr -d '\n')
    if [ "$ICON_THEME" = "$OLD_THEME" ]; then
        echo "Icon theme is already '$ICON_THEME', but applying anyway as requested."
    fi
fi

# Save the icon theme name to a file for other scripts to use
echo "$ICON_THEME" > "$HOME/.config/hypr/colorgen/icon_theme.txt"

# Apply the theme
if command -v gsettings >/dev/null 2>&1; then
    echo "Setting icon theme via gsettings..."
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    
    # Also update cursor theme for consistency
    gsettings set org.gnome.desktop.interface cursor-theme "Graphite-dark-cursors"
    gsettings set org.gnome.desktop.interface cursor-size 24
fi

# Apply KDE settings if kwriteconfig5 or kwriteconfig6 is available
if command -v kwriteconfig6 >/dev/null 2>&1; then
    echo "Setting icon theme via KDE6 configuration..."
    kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "$ICON_THEME"
    
    # Update cursor theme for KDE as well
    kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorTheme" "Graphite-dark-cursors"
    kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorSize" "24"
    
    # Reload KDE settings if running
    if command -v qdbus >/dev/null 2>&1; then
        echo "Reloading KDE settings..."
        qdbus org.kde.KWin /KWin reconfigure || true
        qdbus org.kde.plasmashell /PlasmaShell refreshCurrentShell || true
    fi
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    echo "Setting icon theme via KDE5 configuration..."
    kwriteconfig5 --file kdeglobals --group "Icons" --key "Theme" "$ICON_THEME"
    
    # Update cursor theme for KDE as well
    kwriteconfig5 --file kcminputrc --group "Mouse" --key "cursorTheme" "Graphite-dark-cursors"
    kwriteconfig5 --file kcminputrc --group "Mouse" --key "cursorSize" "24"
    
    # Reload KDE settings if running
    if command -v qdbus >/dev/null 2>&1; then
        echo "Reloading KDE settings..."
        qdbus org.kde.KWin /KWin reconfigure || true
        qdbus org.kde.plasmashell /PlasmaShell refreshCurrentShell || true
    fi
fi

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting icon theme via Hyprland..."
    hyprctl keyword env GTK_ICON_THEME="$ICON_THEME"
    hyprctl keyword env QT_ICON_THEME="$ICON_THEME"
fi

# Create a notification if notify-send is available
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Icon Theme Updated" "Applied $ICON_THEME based on your accent color." -i preferences-desktop-theme
fi

echo "Icon theme applied successfully!"
echo "ICON THEME SCRIPT END: $(date +%H:%M:%S)"
exit 0 