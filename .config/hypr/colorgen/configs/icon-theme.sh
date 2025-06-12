#!/bin/bash

# icon-theme.sh - Applies a Fluent icon theme based on the current accent color
# Usage: ./icon-theme.sh

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="/usr/share/icons"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

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
    
    # Determine light or dark mode first (needed for both branches)
    BRIGHTNESS=$(( (R + G + B) / 3 ))
    if [ $BRIGHTNESS -gt 128 ]; then
        MODE="light"
    else
        MODE="dark"
    fi
    
    echo "Brightness: $BRIGHTNESS, Mode: $MODE"
    
    # If color is "blue", use Fluent directly (which is the blue version)
    if [ "$COLOR" = "blue" ]; then
        echo "Using Fluent for blue color"
        ICON_THEME="Fluent-$MODE"
    else
        echo "Detected dominant color: $COLOR"
        
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
fi

echo "Selected icon theme: $ICON_THEME"

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

# Update QT5 settings
if [ -f "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" ]; then
    echo "Updating QT5 icon theme to $ICON_THEME..."
    sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf"
fi

# Update QT6 settings
if [ -f "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" ]; then
    echo "Updating QT6 icon theme to $ICON_THEME..."
    sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf"
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