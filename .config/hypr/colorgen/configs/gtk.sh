#!/bin/bash

# Debug info
echo "GTK SCRIPT START: $(date +%H:%M:%S) - Called by: $0"
echo "PWD: $(pwd)"
echo "PPID: $(ps -o cmd= $PPID)"

# Script to apply custom colors from colorgen/colors.conf to the serial-design-V-dark theme
# Usage: ./gtk.sh

# Check for an existing lock file to prevent multiple simultaneous executions
LOCK_FILE="/tmp/gtk_theme_lock"
if [ -e "$LOCK_FILE" ]; then
    # Get the timestamp of the lock file
    LOCK_TIME=$(stat -c %Y "$LOCK_FILE" 2>/dev/null)
    CURRENT_TIME=$(date +%s)
    
    # If the lock is older than 60 seconds, it's probably stale
    if [ -n "$LOCK_TIME" ] && [ $((CURRENT_TIME - LOCK_TIME)) -lt 60 ]; then
        echo "Another instance of this script is already running. Exiting."
        exit 0
    else
        echo "Removing stale lock file."
        rm -f "$LOCK_FILE"
    fi
fi

# Create a lock file with current PID
echo "$$" > "$LOCK_FILE"

# Ensure the lock file is removed when the script exits
trap "rm -f $LOCK_FILE" EXIT

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="$HOME/.themes/serial-design-V-dark"
SCRIPTS_DIR="$HOME/.config/hypr/colorgen/configs/gtk"

# Check if files exist
if [ ! -f "$COLORGEN_CONF" ]; then
    echo "Error: $COLORGEN_CONF not found!"
    exit 1
fi

if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Theme directory $THEME_DIR not found!"
    exit 1
fi

# Check if script directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "Error: Script directory $SCRIPTS_DIR not found!"
    exit 1
fi

# Function to replace colors in a file - used by all subscripts
replace_color() {
    local file=$1
    local pattern=$2
    local replacement=$3
    
    # Use perl for more reliable regex replacement
    perl -i -pe "s/$pattern/$replacement/g" "$file"
}
export -f replace_color

# Function to determine if a color is bright (returns 0 if bright, 1 if dark)
# Determines brightness based on RGB values using perceived luminance formula
is_color_bright() {
    local color_hex="$1"
    # Remove leading # if present
    color_hex="${color_hex#\#}"
    
    # Convert hex to RGB values
    local r=$(printf "%d" 0x${color_hex:0:2})
    local g=$(printf "%d" 0x${color_hex:2:2})
    local b=$(printf "%d" 0x${color_hex:4:2})
    
    # Calculate perceived brightness using luminance formula (ITU-R BT.709)
    # Brightness = 0.2126*R + 0.7152*G + 0.0722*B
    local brightness=$(echo "scale=2; 0.2126*$r + 0.7152*$g + 0.0722*$b" | bc)
    
    # Brightness threshold (0-255): values above this are considered "bright"
    local threshold=160
    
    # Compare brightness to threshold
    if (( $(echo "$brightness > $threshold" | bc -l) )); then
        return 0  # Color is bright
    else
        return 1  # Color is dark
    fi
}
export -f is_color_bright

# Function to determine the dominant hue of a color
# Returns: red, orange, yellow, green, teal, blue, purple, pink, grey
get_dominant_hue() {
    local color_hex="$1"
    # Remove leading # if present
    color_hex="${color_hex#\#}"
    
    # Convert hex to RGB values
    local r=$(printf "%d" 0x${color_hex:0:2})
    local g=$(printf "%d" 0x${color_hex:2:2})
    local b=$(printf "%d" 0x${color_hex:4:2})
    
    # Calculate hue, saturation, and value
    local max_val=$(echo "$r $g $b" | tr ' ' '\n' | sort -nr | head -n1)
    local min_val=$(echo "$r $g $b" | tr ' ' '\n' | sort -n | head -n1)
    local diff=$((max_val - min_val))
    
    # Detect greyscale
    if [ "$diff" -lt 30 ]; then
        echo "grey"
        return
    fi
    
    # Calculate hue angle
    local hue=0
    if [ "$max_val" -eq "$r" ] && [ "$g" -ge "$b" ]; then
        hue=$(echo "scale=2; 60 * ($g - $b) / $diff" | bc)
    elif [ "$max_val" -eq "$r" ] && [ "$g" -lt "$b" ]; then
        hue=$(echo "scale=2; 60 * ($g - $b) / $diff + 360" | bc)
    elif [ "$max_val" -eq "$g" ]; then
        hue=$(echo "scale=2; 60 * ($b - $r) / $diff + 120" | bc)
    elif [ "$max_val" -eq "$b" ]; then
        hue=$(echo "scale=2; 60 * ($r - $g) / $diff + 240" | bc)
    fi
    
    # Map hue angle to color name
    hue_int=${hue%.*}  # Remove decimal part
    
    if [ "$hue_int" -lt 20 ] || [ "$hue_int" -ge 345 ]; then
        echo "red"
    elif [ "$hue_int" -lt 45 ]; then
        echo "orange"
    elif [ "$hue_int" -lt 70 ]; then
        echo "yellow"
    elif [ "$hue_int" -lt 170 ]; then
        echo "green"
    elif [ "$hue_int" -lt 195 ]; then
        echo "teal"
    elif [ "$hue_int" -lt 260 ]; then
        echo "blue"
    elif [ "$hue_int" -lt 290 ]; then
        echo "purple"
    elif [ "$hue_int" -lt 345 ]; then
        echo "pink"
    else
        echo "red"  # fallback
    fi
}
export -f get_dominant_hue

# Function to select the most appropriate Fluent icon theme based on accent color
select_fluent_theme() {
    local color_hex="$1"
    local brightness_mode=""
    local color_name=""
    
    # Determine light/dark variant
    if is_color_bright "$color_hex"; then
        brightness_mode="light"
    else
        brightness_mode="dark"
    fi
    
    # Get the dominant hue
    color_name=$(get_dominant_hue "$color_hex")
    
    # Build the theme name - format is "Fluent-[color]-[brightness]"
    # Check if the theme exists, fallback to default if not
    local theme_name="Fluent-${color_name}-${brightness_mode}"
    
    # Check if this specific theme exists
    if [ -d "/usr/share/icons/${theme_name}" ]; then
        echo "${theme_name}"
    # Try without brightness variant
    elif [ -d "/usr/share/icons/Fluent-${color_name}" ]; then
        echo "Fluent-${color_name}"
    # Fallback to just Fluent with brightness
    elif [ -d "/usr/share/icons/Fluent-${brightness_mode}" ]; then
        echo "Fluent-${brightness_mode}"
    # Last resort - just Fluent
    else
        echo "Fluent"
    fi
}

# Read color values from colorgen/colors.conf
echo "Reading colors from $COLORGEN_CONF..."
PRIMARY=$(grep "^primary = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_0=$(grep "^primary-0 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_10=$(grep "^primary-10 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_20=$(grep "^primary-20 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_30=$(grep "^primary-30 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_40=$(grep "^primary-40 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_50=$(grep "^primary-50 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_60=$(grep "^primary-60 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_80=$(grep "^primary-80 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_90=$(grep "^primary-90 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_95=$(grep "^primary-95 = " "$COLORGEN_CONF" | cut -d'#' -f2)
PRIMARY_99=$(grep "^primary-99 = " "$COLORGEN_CONF" | cut -d'#' -f2)
ACCENT=$(grep "^accent = " "$COLORGEN_CONF" | cut -d'#' -f2)
ACCENT_DARK=$(grep "^accent_dark = " "$COLORGEN_CONF" | cut -d'#' -f2)
ACCENT_LIGHT=$(grep "^accent_light = " "$COLORGEN_CONF" | cut -d'#' -f2)
SECONDARY=$(grep "^secondary = " "$COLORGEN_CONF" | cut -d'#' -f2)
TERTIARY=$(grep "^tertiary = " "$COLORGEN_CONF" | cut -d'#' -f2)

# If any of the values is empty, use fallbacks
if [ -z "$PRIMARY" ]; then PRIMARY="feb877"; fi
if [ -z "$PRIMARY_0" ]; then PRIMARY_0="130d07"; fi
if [ -z "$PRIMARY_10" ]; then PRIMARY_10="221a14"; fi
if [ -z "$PRIMARY_20" ]; then PRIMARY_20="261e18"; fi
if [ -z "$PRIMARY_30" ]; then PRIMARY_30="312822"; fi
if [ -z "$PRIMARY_40" ]; then PRIMARY_40="3c332c"; fi
if [ -z "$PRIMARY_50" ]; then PRIMARY_50="19120c"; fi
if [ -z "$PRIMARY_60" ]; then PRIMARY_60="403730"; fi
if [ -z "$PRIMARY_80" ]; then PRIMARY_80="feb877"; fi
if [ -z "$PRIMARY_90" ]; then PRIMARY_90="ffdcc0"; fi
if [ -z "$PRIMARY_95" ]; then PRIMARY_95="efe0d5"; fi
if [ -z "$PRIMARY_99" ]; then PRIMARY_99="ffffff"; fi
if [ -z "$ACCENT" ]; then ACCENT="feb877"; fi
if [ -z "$ACCENT_DARK" ]; then ACCENT_DARK="6a3b02"; fi
if [ -z "$ACCENT_LIGHT" ]; then ACCENT_LIGHT="efe0d5"; fi
if [ -z "$SECONDARY" ]; then SECONDARY="e2c0a4"; fi
if [ -z "$TERTIARY" ]; then TERTIARY="c2cc99"; fi

# Use waybar border style variables
BORDER_COLOR="$ACCENT"
BORDER_WIDTH="2px"
BORDER_RADIUS="8px"

echo "Using colors:"
echo "PRIMARY: #$PRIMARY"
echo "ACCENT: #$ACCENT"
echo "ACCENT_DARK: #$ACCENT_DARK"
echo "BORDER_COLOR: #$BORDER_COLOR"
echo "SECONDARY: #$SECONDARY"
echo "TERTIARY: #$TERTIARY"

# Export variables for scripts
export COLORGEN_CONF
export THEME_DIR
export PRIMARY PRIMARY_0 PRIMARY_10 PRIMARY_20 PRIMARY_30 PRIMARY_40 PRIMARY_50
export PRIMARY_60 PRIMARY_80 PRIMARY_90 PRIMARY_95 PRIMARY_99
export ACCENT ACCENT_DARK ACCENT_LIGHT
export SECONDARY TERTIARY
export BORDER_COLOR BORDER_WIDTH BORDER_RADIUS

# Make script files executable
chmod +x "$SCRIPTS_DIR/gtk3.sh" "$SCRIPTS_DIR/gtk4.sh" "$SCRIPTS_DIR/libadw.sh" "$SCRIPTS_DIR/apply_icon_theme.sh" "$SCRIPTS_DIR/apply_colors.sh"

# Call the individual scripts
echo "Applying GTK3 styling..."
"$SCRIPTS_DIR/gtk3.sh"
echo "Applying GTK4 styling..."
"$SCRIPTS_DIR/gtk4.sh"
echo "Applying Libadwaita styling..."
"$SCRIPTS_DIR/libadw.sh"

# Select the most appropriate icon theme based on accent color
echo "Determining appropriate icon theme based on accent color..."
ICON_THEME=$(select_fluent_theme "$ACCENT")
echo "Selected icon theme: $ICON_THEME"

# Save selected icon theme to permanent and temporary files
ICON_THEME_FILE="$HOME/.config/hypr/colorgen/icon_theme.txt"
ICON_THEME_TMP_FILE="$HOME/.config/hypr/colorgen/icon_theme.tmp"
echo "$ICON_THEME" > "$ICON_THEME_FILE"
echo "$ICON_THEME" > "$ICON_THEME_TMP_FILE"

# Now run the apply_colors.sh script to apply the theme settings and colors
echo "Applying GTK theme settings and colors..."
"$SCRIPTS_DIR/apply_colors.sh"

# Icon cache will be refreshed by the apply_icon_theme.sh script

# Run the icon theme application script
echo "Running icon theme application script..."
"$SCRIPTS_DIR/apply_icon_theme.sh"

# Clean up the lock file
rm -f "$LOCK_FILE"

echo "Colors applied successfully!"
echo "Theme has been applied to Hyprland. Some applications may need to be restarted to see the changes."

echo "GTK SCRIPT END: $(date +%H:%M:%S)"
exit 0  