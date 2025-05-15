#!/bin/bash

# icon-theme.sh - Applies a Fluent icon theme based on the current accent color
# Usage: ./icon-theme.sh

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="/usr/share/icons"

# Debug info
echo "ICON THEME SCRIPT START: $(date +%H:%M:%S)"
echo "PWD: $(pwd)"

# Check if files exist
if [ ! -f "$COLORGEN_CONF" ]; then
    echo "Error: $COLORGEN_CONF not found!"
    exit 1
fi

# Read accent color from colorgen/colors.conf
echo "Reading accent color from $COLORGEN_CONF..."
ACCENT=$(grep "^accent = " "$COLORGEN_CONF" | cut -d'#' -f2)

if [ -z "$ACCENT" ]; then
    echo "Error: Could not find accent color in $COLORGEN_CONF"
    echo "Using default Fluent icon theme"
    ICON_THEME="Fluent-dark"
else
    echo "Found accent color: #$ACCENT"
    
    # Extract RGB components
    R=$((16#${ACCENT:0:2}))
    G=$((16#${ACCENT:2:2}))
    B=$((16#${ACCENT:4:2}))
    
    echo "RGB components: R=$R, G=$G, B=$B"
    
    # Determine the dominant color
    if [ $R -gt $G ] && [ $R -gt $B ]; then
        if [ $R -gt 200 ] && [ $G -gt 150 ]; then
            COLOR="yellow"
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
        # Better blue detection - use teal for blue colors since there's no Fluent-blue
        if [ $R -gt 150 ] && [ $G -gt 150 ] && [ $B -gt 200 ]; then
            COLOR="teal" # Light blue / sky blue - use teal
        elif [ $R -gt 150 ] && [ $G -gt 150 ]; then
            COLOR="purple" # Purple has high red & green with dominant blue
        elif [ $R -gt 120 ] && [ $G -lt 120 ]; then
            COLOR="purple" # Deep purple has medium red, low green, high blue
        else
            COLOR="teal" # Teal has low red, medium-high green, high blue
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
    
    echo "Detected dominant color: $COLOR"
    
    # Determine light or dark mode
    BRIGHTNESS=$(( (R + G + B) / 3 ))
    if [ $BRIGHTNESS -gt 128 ]; then
        MODE="light"
    else
        MODE="dark"
    fi
    
    echo "Brightness: $BRIGHTNESS, Mode: $MODE"
    
    # Set theme name
    ICON_THEME="Fluent-${COLOR}-${MODE}"
    
    # If specific theme doesn't exist, fall back to base theme
    if [ ! -d "$THEME_DIR/$ICON_THEME" ]; then
        echo "Theme $ICON_THEME not found, falling back to Fluent-$COLOR"
        ICON_THEME="Fluent-$COLOR"
        
        # If color theme doesn't exist, fall back to base Fluent
        if [ ! -d "$THEME_DIR/$ICON_THEME" ]; then
            echo "Theme $ICON_THEME not found, falling back to Fluent-$MODE"
            ICON_THEME="Fluent-$MODE"
        fi
    fi
fi

echo "Selected icon theme: $ICON_THEME"

# Apply the theme
if command -v gsettings >/dev/null 2>&1; then
    echo "Setting icon theme via gsettings..."
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    
    # Also update cursor theme for consistency
    gsettings set org.gnome.desktop.interface cursor-theme "Graphite-dark-cursors"
    gsettings set org.gnome.desktop.interface cursor-size 24
fi

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting icon theme via Hyprland..."
    hyprctl keyword env GTK_ICON_THEME="$ICON_THEME"
fi

# Create a notification if notify-send is available
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Icon Theme Updated" "Applied $ICON_THEME based on your accent color." -i preferences-desktop-theme
fi

echo "Icon theme applied successfully!"
echo "ICON THEME SCRIPT END: $(date +%H:%M:%S)"
exit 0 