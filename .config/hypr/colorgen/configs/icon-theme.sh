#!/bin/bash

# icon-theme.sh - Applies a Fluent icon theme based on the current accent color
# Usage: ./icon-theme.sh

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="/usr/share/icons"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"

# Debug info
echo "ICON THEME SCRIPT START: $(date +%H:%M:%S)"
echo "PWD: $(pwd)"

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
    
    # Special case for light blue colors like #bcc2ff
    if [ $B -gt 220 ] && [ $R -gt 160 ] && [ $G -gt 160 ] && [ $B -gt $R ] && [ $B -gt $G ]; then
        COLOR="blue"
        echo "Detected blue color based on high blue value"
    # Special case for orange/coral colors like #ffb597
    elif [ $R -gt 220 ] && [ $G -gt 150 ] && [ $G -lt 200 ] && [ $B -gt 100 ] && [ $B -lt 180 ] && [ $R -gt $G ] && [ $G -gt $B ]; then
        COLOR="orange"
        echo "Detected orange color based on RGB values"
    # Improved dominant color detection with better blue/pink detection
    elif [ $R -gt $G ] && [ $R -gt $B ]; then
        if [ $B -gt 150 ] && [ $R -gt 200 ] && [ $G -lt $R ] && [ $G -lt 160 ]; then
            # Pink has high red, medium-to-high blue, and lower green
            COLOR="pink"
        elif [ $R -gt 200 ] && [ $G -gt 150 ]; then
            # If green is relatively high compared to blue, it's more yellow/orange
            if [ $G -gt $(($B + 30)) ]; then
                COLOR="orange"
            else
                COLOR="pink"
            fi
        else
            COLOR="red"
        fi
    elif [ $G -gt $R ] && [ $G -gt $B ]; then
        if [ $B -gt 150 ] && [ $G -gt 150 ]; then
            COLOR="teal"
        else
            COLOR="green"
        fi
    elif [ $B -gt $R ] && [ $B -gt $G ]; then
        # Better blue detection
        if [ $B -gt 200 ]; then
            if [ $R -lt 150 ] && [ $G -lt 150 ]; then
                COLOR="blue"  # Deep blue
            elif [ $R -gt 150 ] && [ $G -gt 150 ]; then
                COLOR="blue"  # Light blue / sky blue
            elif [ $R -gt 150 ] && [ $G -lt 120 ]; then
                COLOR="purple" # Deep purple has medium red, low green, high blue
            else
                COLOR="blue"  # Default to blue for high blue values
            fi
        else
            COLOR="blue"  # Default to blue for all other blue-dominant colors
        fi
    elif [ $R -gt 200 ] && [ $G -gt 200 ] && [ $B -gt 200 ]; then
        COLOR="grey"
    elif [ $R -gt 200 ] && [ $G -lt 150 ] && [ $B -gt 150 ]; then
        COLOR="pink"
    elif [ $R -gt 200 ] && [ $G -gt 150 ] && [ $B -lt 150 ]; then
        COLOR="orange"
    else
        COLOR="grey"
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