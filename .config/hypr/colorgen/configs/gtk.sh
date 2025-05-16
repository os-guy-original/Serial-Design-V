#!/bin/bash

# Debug info
echo "GTK SCRIPT START: $(date +%H:%M:%S) - Called by: $0"
echo "PWD: $(pwd)"
echo "PPID: $(ps -o cmd= $PPID)"

# Script to apply custom colors from colorgen/colors.conf to the serial-design-V-dark theme
# Usage: ./gtk.sh

# Define paths
COLORGEN_CONF="$HOME/.config/hypr/colorgen/colors.conf"
THEME_DIR="$HOME/.themes/serial-design-V-dark"
GTK3_CSS="$THEME_DIR/gtk-3.0/gtk.css"
GTK3_DARK_CSS="$THEME_DIR/gtk-3.0/gtk-dark.css"
GTK4_CSS="$THEME_DIR/gtk-4.0/gtk.css"
GTK4_DARK_CSS="$THEME_DIR/gtk-4.0/gtk-dark.css"
LIBADWAITA_CSS="$THEME_DIR/gtk-4.0/libadwaita.css"
LIBADWAITA_TWEAKS="$THEME_DIR/gtk-4.0/libadwaita-tweaks.css"

# Check if files exist
if [ ! -f "$COLORGEN_CONF" ]; then
    echo "Error: $COLORGEN_CONF not found!"
    exit 1
fi

if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Theme directory $THEME_DIR not found!"
    exit 1
fi

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

# Create backup of original files if they don't exist
if [ ! -f "${GTK3_CSS}.original" ]; then
    echo "Creating original backups..."
    cp "$GTK3_CSS" "${GTK3_CSS}.original"
    cp "$GTK3_DARK_CSS" "${GTK3_DARK_CSS}.original"
    cp "$GTK4_CSS" "${GTK4_CSS}.original"
    cp "$GTK4_DARK_CSS" "${GTK4_DARK_CSS}.original"
    cp "$LIBADWAITA_CSS" "${LIBADWAITA_CSS}.original"
    cp "$LIBADWAITA_TWEAKS" "${LIBADWAITA_TWEAKS}.original"
fi

# First restore original files to ensure script always starts from a clean state
echo "Restoring original files..."
if [ -f "${GTK3_CSS}.original" ]; then
    cp "${GTK3_CSS}.original" "$GTK3_CSS"
    cp "${GTK3_DARK_CSS}.original" "$GTK3_DARK_CSS"
    cp "${GTK4_CSS}.original" "$GTK4_CSS"
    cp "${GTK4_DARK_CSS}.original" "$GTK4_DARK_CSS"
    cp "${LIBADWAITA_CSS}.original" "$LIBADWAITA_CSS"
    cp "${LIBADWAITA_TWEAKS}.original" "$LIBADWAITA_TWEAKS"
fi

# Create backup of current run
BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "Creating backups of this run with timestamp $BACKUP_TIMESTAMP..."
cp "$GTK3_CSS" "${GTK3_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$GTK3_DARK_CSS" "${GTK3_DARK_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$GTK4_CSS" "${GTK4_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$GTK4_DARK_CSS" "${GTK4_DARK_CSS}.backup.${BACKUP_TIMESTAMP}"

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

# Function to replace colors in a file
replace_color() {
    local file=$1
    local pattern=$2
    local replacement=$3
    
    # Use perl for more reliable regex replacement
    perl -i -pe "s/$pattern/$replacement/g" "$file"
}

# Apply to GTK3
echo "Applying colors to GTK3 theme..."
# Update accent/accent_bg_color
replace_color "$GTK3_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"
replace_color "$GTK3_DARK_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"

# Update window bg/fg colors
replace_color "$GTK3_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color #$PRIMARY_20;"
replace_color "$GTK3_DARK_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color #$PRIMARY_20;"

# Update view bg/fg colors
replace_color "$GTK3_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color #$PRIMARY_10;"
replace_color "$GTK3_DARK_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color #$PRIMARY_10;"

# Update headerbar colors
replace_color "$GTK3_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color #$PRIMARY_30;"
replace_color "$GTK3_DARK_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color #$PRIMARY_30;"

# Update sidebar colors
replace_color "$GTK3_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color #$PRIMARY_30;"
replace_color "$GTK3_DARK_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color #$PRIMARY_30;"
replace_color "$GTK3_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color #$PRIMARY_20;"
replace_color "$GTK3_DARK_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color #$PRIMARY_20;"

# Update dialog and popover colors
replace_color "$GTK3_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color #$PRIMARY_40;"
replace_color "$GTK3_DARK_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color #$PRIMARY_40;"
replace_color "$GTK3_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color #$PRIMARY_40;"
replace_color "$GTK3_DARK_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color #$PRIMARY_40;"

# Update border color
replace_color "$GTK3_CSS" '@define-color borders mix\(currentColor,@window_bg_color,0.85\);' "@define-color borders mix(#$ACCENT,@window_bg_color,0.85);"
replace_color "$GTK3_DARK_CSS" '@define-color borders mix\(currentColor,@window_bg_color,0.85\);' "@define-color borders mix(#$ACCENT,@window_bg_color,0.85);"

# Fix remaining blue colors in GTK3
replace_color "$GTK3_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$GTK3_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$GTK3_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$GTK3_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$GTK3_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"
replace_color "$GTK3_DARK_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$GTK3_DARK_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$GTK3_DARK_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$GTK3_DARK_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$GTK3_DARK_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

# Fix GTK3 selection colors
replace_color "$GTK3_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
replace_color "$GTK3_DARK_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
replace_color "$GTK3_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"
replace_color "$GTK3_DARK_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"

# Fix other GTK3 selection related colors
replace_color "$GTK3_CSS" '-gtk-secondary-caret-color: @blue_3;' "-gtk-secondary-caret-color: #$ACCENT;"
replace_color "$GTK3_DARK_CSS" '-gtk-secondary-caret-color: @blue_3;' "-gtk-secondary-caret-color: #$ACCENT;"

# Apply to GTK4
echo "Applying colors to GTK4 theme..."
# Update accent/accent_bg_color
replace_color "$GTK4_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"

# Update window bg/fg colors - make more vibrant
replace_color "$GTK4_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"
replace_color "$GTK4_DARK_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"

# Update view bg/fg colors - make more vibrant
replace_color "$GTK4_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color color-mix(in srgb, #$PRIMARY_10 92%, #$ACCENT 8%);"
replace_color "$GTK4_DARK_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color color-mix(in srgb, #$PRIMARY_10 92%, #$ACCENT 8%);"

# Update headerbar colors - make more vibrant
replace_color "$GTK4_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"

# Update sidebar colors - make more vibrant
replace_color "$GTK4_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"
replace_color "$GTK4_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"

# Update dialog and popover colors - make more vibrant
replace_color "$GTK4_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"
replace_color "$GTK4_DARK_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"
replace_color "$GTK4_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"
replace_color "$GTK4_DARK_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"

# Update thumbnail bg color - make more vibrant
replace_color "$GTK4_CSS" '@define-color thumbnail_bg_color #39393d;' "@define-color thumbnail_bg_color color-mix(in srgb, #$PRIMARY_40 85%, #$ACCENT 15%);"
replace_color "$GTK4_DARK_CSS" '@define-color thumbnail_bg_color #39393d;' "@define-color thumbnail_bg_color color-mix(in srgb, #$PRIMARY_40 85%, #$ACCENT 15%);"

# Update CSS variables in GTK4
replace_color "$GTK4_CSS" '--accent-blue: #3584e4;' "--accent-blue: #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '--accent-blue: #3584e4;' "--accent-blue: #$ACCENT;"

# Update primary colors in Root variables
replace_color "$GTK4_CSS" ':root \{ --blue-1: #99c1f1; --blue-2: #62a0ea; --blue-3: #3584e4; --blue-4: #1c71d8; --blue-5: #1a5fb4;' ":root { --blue-1: #$PRIMARY_95; --blue-2: #$PRIMARY_90; --blue-3: #$ACCENT; --blue-4: #$ACCENT_DARK; --blue-5: #$ACCENT_DARK;"
replace_color "$GTK4_DARK_CSS" ':root \{ --blue-1: #99c1f1; --blue-2: #62a0ea; --blue-3: #3584e4; --blue-4: #1c71d8; --blue-5: #1a5fb4;' ":root { --blue-1: #$PRIMARY_95; --blue-2: #$PRIMARY_90; --blue-3: #$ACCENT; --blue-4: #$ACCENT_DARK; --blue-5: #$ACCENT_DARK;"

# Fix GTK4 selection colors
replace_color "$GTK4_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"

# Update direct Adwaita color definitions
replace_color "$LIBADWAITA_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

# Update secondary colors
replace_color "$GTK4_CSS" '--green-1: #8ff0a4;' "--green-1: #$SECONDARY;"
replace_color "$GTK4_DARK_CSS" '--green-1: #8ff0a4;' "--green-1: #$SECONDARY;"

# Update tertiary colors
replace_color "$GTK4_CSS" '--yellow-3: #f6d32d;' "--yellow-3: #$TERTIARY;"
replace_color "$GTK4_DARK_CSS" '--yellow-3: #f6d32d;' "--yellow-3: #$TERTIARY;"

# Fix text selection colors in libadwaita
echo "Fixing text selection colors..."

# Fix selection class - with less intense color
replace_color "$LIBADWAITA_CSS" 'selection { background-color: color-mix\(in srgb, var\(--view-fg-color\) 10%, transparent\); color: transparent; }' "selection { background-color: color-mix(in srgb, #$ACCENT 40%, transparent); color: inherit; }"

# Fix selection:focus-within 
replace_color "$LIBADWAITA_CSS" 'selection:focus-within { background-color: color-mix\(in srgb, var\(--accent-bg-color\) 30%, transparent\); }' "selection:focus-within { background-color: color-mix(in srgb, #$ACCENT 50%, transparent); }"

# Fix theme_selected variables
replace_color "$LIBADWAITA_CSS" '@define-color theme_selected_bg_color @accent_bg_color;' "@define-color theme_selected_bg_color color-mix(in srgb, #$ACCENT 50%, transparent);"
replace_color "$LIBADWAITA_CSS" '@define-color theme_selected_fg_color @accent_fg_color;' "@define-color theme_selected_fg_color inherit;"
replace_color "$LIBADWAITA_CSS" '@define-color theme_unfocused_selected_bg_color @accent_bg_color;' "@define-color theme_unfocused_selected_bg_color color-mix(in srgb, #$ACCENT 40%, transparent);"
replace_color "$LIBADWAITA_CSS" '@define-color theme_unfocused_selected_fg_color @accent_fg_color;' "@define-color theme_unfocused_selected_fg_color inherit;"

# Fix ::selection pseudo-element if it exists
replace_color "$LIBADWAITA_CSS" '::selection' "::selection { background-color: color-mix(in srgb, #$ACCENT 40%, transparent); color: inherit; }"

# Fix selection in text views and entries
replace_color "$LIBADWAITA_CSS" '.view:selected:focus, .view:selected' ".view:selected:focus, .view:selected { background-color: color-mix(in srgb, #$ACCENT 50%, transparent) !important; color: inherit !important; }" 

# Fix .selection-mode class
replace_color "$LIBADWAITA_CSS" 'checkbutton.selection-mode { background-color: #ffb4ac; color: #f1dedc; }' "checkbutton.selection-mode { background-color: color-mix(in srgb, #$ACCENT 60%, transparent); color: inherit; }"

# Fix any other selection related CSS with direct hard-coded values
replace_color "$LIBADWAITA_CSS" 'calendar > grid > label.day-number:selected { border-radius: 9px; background-color: #ffb4ac;' "calendar > grid > label.day-number:selected { border-radius: 9px; background-color: color-mix(in srgb, #$ACCENT 60%, transparent);"

# Fix button colors in libadwaita.css - use waybar border style with MORE intensity
echo "Fixing GTK4 button colors with more vibrant style..."

# Check if the accent color is bright and determine text color
BUTTON_FG_COLOR="#$PRIMARY_95"
if is_color_bright "$ACCENT"; then
    echo "Accent color #$ACCENT is bright, using dark text for buttons"
    BUTTON_FG_COLOR="#$PRIMARY_10"
else
    echo "Accent color #$ACCENT is not bright, using light text for buttons"
fi

# Update button classes - use more intense background color 
perl -i -0777 -pe "s/button \{\n.*?min-height: 24px;.*?min-width: 16px;.*?padding: 5px 10px;.*?border-radius: ${BORDER_RADIUS};.*?font-weight: bold;.*?border: 1px solid transparent;.*?background-color: color-mix\(in srgb, #$ACCENT 8%, transparent\);.*?\}/button \{\n  min-height: 24px;\n  min-width: 16px;\n  padding: 5px 10px;\n  border-radius: ${BORDER_RADIUS};\n  font-weight: bold;\n  border: 1px solid #$ACCENT;\n  background-color: color-mix(in srgb, #$ACCENT 15%, transparent);\n}/gs" "$LIBADWAITA_CSS" || true

# Fix button hover colors - more vibrant
perl -i -0777 -pe "s/button:hover \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 12%, transparent\);.*?border: 1px solid #$ACCENT;.*?\}/button:hover \{\n  background-color: color-mix(in srgb, #$ACCENT 25%, transparent);\n  border: 2px solid #$ACCENT;\n}/gs" "$LIBADWAITA_CSS" || true

# Fix button active/checked colors - more vibrant
perl -i -0777 -pe "s/button.keyboard-activating, button:active \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 20%, transparent\);.*?border: 1px solid #$ACCENT;.*?\}/button.keyboard-activating, button:active \{\n  background-color: color-mix(in srgb, #$ACCENT 35%, transparent);\n  border: 2px solid #$ACCENT;\n  box-shadow: inset 0 0 3px rgba(0, 0, 0, 0.3);\n}/gs" "$LIBADWAITA_CSS" || true

perl -i -0777 -pe "s/button:checked \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 20%, transparent\);.*?border: ${BORDER_WIDTH} solid #$ACCENT;.*?\}/button:checked \{\n  background-color: color-mix(in srgb, #$ACCENT 40%, transparent);\n  border: ${BORDER_WIDTH} solid #$ACCENT;\n  box-shadow: inset 0 0 3px rgba(0, 0, 0, 0.3);\n}/gs" "$LIBADWAITA_CSS" || true

# Add direct CSS for button text colors - with much higher specificity and !important flags
# First, add a direct modification to the original button definition
sed -i -E "s/(button \{)(.*)(\})/\1\n  color: $BUTTON_FG_COLOR !important;\2\n\}/g" "$LIBADWAITA_CSS" || true
sed -i -E "s/(button \{)(.*)(\})/\1\n  color: $BUTTON_FG_COLOR !important;\2\n\}/g" "$GTK4_CSS" || true
sed -i -E "s/(button \{)(.*)(\})/\1\n  color: $BUTTON_FG_COLOR !important;\2\n\}/g" "$GTK4_DARK_CSS" || true

# Add even more comprehensive button text color rules with very high specificity
cat >> "$LIBADWAITA_CSS" << EOF

/* Comprehensive button text color fix */
button,
button.text-button,
button.image-button,
dialog button,
headerbar button,
actionbar button,
popover button,
placessidebar button,
dialog .dialog-action-area button,
.app-notification button,
stackswitcher button,
.stack-switcher button,
.inline-toolbar button,
toolbar button,
.toolbar button,
.titlebar button,
filechooser button {
  color: $BUTTON_FG_COLOR !important;
}

/* Ensure suggested/destructive buttons have proper text color */
button.suggested-action, 
button.destructive-action,
.suggested-action button,
.destructive-action button {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR !important;
}

/* Primary buttons often used in dialogs and confirmations */
button.default,
button.text-button.default,
button.suggested-action,
.default-button,
.primary-toolbar button {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR !important;
}

/* Ensure all button states have correct text color */
button:hover, 
button:active, 
button:checked, 
button:selected,
button:focus,
button.flat:hover {
  color: $BUTTON_FG_COLOR !important;
}
EOF

# Apply the same to GTK4 CSS files with more specificity
for CSS_FILE in "$GTK4_CSS" "$GTK4_DARK_CSS"; do
  cat >> "$CSS_FILE" << EOF

/* Comprehensive button text color fix for GTK4 */
button,
button.text-button,
button.image-button,
dialog button,
headerbar button,
actionbar button,
popover button,
placessidebar button,
.titlebar button,
filechooser button {
  color: $BUTTON_FG_COLOR !important;
}

/* Ensure suggested/destructive buttons have proper text color */
button.suggested-action, 
button.destructive-action,
.suggested-action button,
.destructive-action button {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR !important;
}

/* Confirm dialog style buttons */
dialog .dialog-action-area button,
.dialog .dialog-action-area button {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR !important;
}

/* Ensure all button states have correct text color */
button:hover, 
button:active, 
button:checked, 
button:selected,
button:focus {
  color: $BUTTON_FG_COLOR !important;
}
EOF
done

# Force GTK4 Applications to recognize the changes by modifying the settings directly
# This section ensures GTK4 applications reload the theme with our button text color fixes
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Direct GTK4 overrides for button text colors */
button {
  color: $BUTTON_FG_COLOR !important;
}

button:hover, button:active, button:checked {
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action, button.destructive-action {
  color: $BUTTON_FG_COLOR !important;
}

/* Custom accent color overrides */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
EOF

# Enhance checks and radio buttons - more vibrant
replace_color "$LIBADWAITA_CSS" 'check:checked, radio:checked, .check:checked, .radio:checked' "check:checked, radio:checked, .check:checked, .radio:checked { background-color: #$ACCENT; box-shadow: 0 0 3px #$ACCENT; }"

# Fix focus outline - make more visible
replace_color "$LIBADWAITA_CSS" 'outline-color: color-mix\(in srgb, #$ACCENT 40%, transparent\);' "outline-color: color-mix(in srgb, #$ACCENT 70%, transparent);"

# Fix general accent colors - Essential section to fix remaining blue colors
echo "Fixing remaining blue accent colors with more comprehensive approach..."

# Add support for toast notifications in GTK4
echo "Fixing toast notification colors in GTK4..."
cat >> "$LIBADWAITA_CSS" << EOF

/* Toast notification styling based on accent color */
toast {
  background-color: color-mix(in srgb, #$PRIMARY_40 80%, #$ACCENT 20%);
  border: 1px solid color-mix(in srgb, #$ACCENT 80%, transparent 20%);
}

toast button {
  background-color: color-mix(in srgb, #$ACCENT 20%, transparent 80%);
  color: $BUTTON_FG_COLOR !important;
}

toast button:hover {
  background-color: color-mix(in srgb, #$ACCENT 30%, transparent 70%);
}

toast .title {
  color: #$PRIMARY_95;
  font-weight: bold;
}

toast .body {
  color: color-mix(in srgb, #$PRIMARY_95 90%, transparent 10%);
}
EOF

# Apply the same to GTK4 CSS
cat >> "$GTK4_CSS" << EOF

/* Toast notification styling */
toast {
  background-color: color-mix(in srgb, #$PRIMARY_40 80%, #$ACCENT 20%);
  border: 1px solid color-mix(in srgb, #$ACCENT 80%, transparent 20%);
}

toast button {
  background-color: color-mix(in srgb, #$ACCENT 20%, transparent 80%);
  color: $BUTTON_FG_COLOR !important;
}

toast .title {
  color: #$PRIMARY_95;
  font-weight: bold;
}

toast .body {
  color: color-mix(in srgb, #$PRIMARY_95 90%, transparent 10%);
}
EOF

# Apply the same to GTK4 Dark CSS
cat >> "$GTK4_DARK_CSS" << EOF

/* Toast notification styling */
toast {
  background-color: color-mix(in srgb, #$PRIMARY_40 80%, #$ACCENT 20%);
  border: 1px solid color-mix(in srgb, #$ACCENT 80%, transparent 20%);
}

toast button {
  background-color: color-mix(in srgb, #$ACCENT 20%, transparent 80%);
  color: $BUTTON_FG_COLOR !important;
}

toast .title {
  color: #$PRIMARY_95;
  font-weight: bold;
}

toast .body {
  color: color-mix(in srgb, #$PRIMARY_95 90%, transparent 10%);
}
EOF

# Replace Libadwaita-tweaks CSS file with hardcoded values
echo "Updating libadwaita-tweaks.css..."
replace_color "$LIBADWAITA_TWEAKS" '--accent-blue: #3584e4;' "--accent-blue: #$ACCENT;"
replace_color "$LIBADWAITA_TWEAKS" '#3584e4' "#$ACCENT"
replace_color "$LIBADWAITA_TWEAKS" '#1c71d8' "#$ACCENT_DARK"
replace_color "$LIBADWAITA_TWEAKS" '#1a5fb4' "#$ACCENT_DARK"
replace_color "$LIBADWAITA_TWEAKS" '#ffb4ac' "#$ACCENT"

# Direct replacements for common blue color codes
echo "Fixing hardcoded blue color values in all CSS files..."
sed -i "s/#3584e4/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/#1c71d8/#$ACCENT_DARK/g" "$LIBADWAITA_CSS"
sed -i "s/#1a5fb4/#$ACCENT_DARK/g" "$LIBADWAITA_CSS"
sed -i "s/#ffb4ac/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/#f1dedc/#$PRIMARY_95/g" "$LIBADWAITA_CSS"

# Remove any remaining "var(--accent-*" variables and replace with direct values
sed -i "s/var(--accent-bg-color)/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/var(--accent-color)/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/var(--accent-fg-color)/#$PRIMARY_95/g" "$LIBADWAITA_CSS"

# Replace instances that match specific patterns
sed -i "s/border-color: .* var(--accent-bg-color)/border-color: #$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/box-shadow: .* var(--accent-bg-color)/box-shadow: inset 0 0 0 2px #$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/color: .* var(--accent-bg-color)/color: #$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/caret-color: .* var(--accent-bg-color)/caret-color: #$ACCENT/g" "$LIBADWAITA_CSS"

# Replace variable references directly
sed -i "s/@accent_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/@accent_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"
sed -i "s/@theme_selected_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS" 
sed -i "s/@theme_selected_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"

# Fix GTK Dialog specific styles
echo "Adding specific fixes for GTK Dialogs..."
# Target dialog CSS directly in GTK3
sed -i "s/dialog { background-color: @dialog_bg_color;/dialog { background-color: @dialog_bg_color; border: 1px solid #$ACCENT;/g" "$GTK3_CSS"
sed -i "s/dialog { background-color: @dialog_bg_color;/dialog { background-color: @dialog_bg_color; border: 1px solid #$ACCENT;/g" "$GTK3_DARK_CSS"

# Target dialog CSS directly in GTK4
sed -i "s/dialog { background-color: @dialog_bg_color;/dialog { background-color: color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%); border: 1px solid #$ACCENT;/g" "$GTK4_CSS"
sed -i "s/dialog { background-color: @dialog_bg_color;/dialog { background-color: color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%); border: 1px solid #$ACCENT;/g" "$GTK4_DARK_CSS"

# Fix dialog buttons in libadwaita
sed -i "s/dialog button {/dialog button { border: 1px solid #$ACCENT; background-color: color-mix(in srgb, #$ACCENT 20%, transparent);/g" "$LIBADWAITA_CSS"
sed -i "s/dialog button:hover {/dialog button:hover { border: 2px solid #$ACCENT; background-color: color-mix(in srgb, #$ACCENT 30%, transparent);/g" "$LIBADWAITA_CSS"

# Make sure dialog headers have the proper color
sed -i "s/dialog headerbar {/dialog headerbar { background-color: color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);/g" "$LIBADWAITA_CSS"

# Replace any remaining dialog-related blue colors
replace_color "$LIBADWAITA_CSS" 'messagedialog grid.horizontal > box:nth-child\(1\) > .image { color: @blue_3; }' "messagedialog grid.horizontal > box:nth-child(1) > .image { color: #$ACCENT; }"

# Fix dialog window background (more thorough regex for dialogs)
perl -i -0777 -pe "s/window\.dialog .*?\{.*?background-color: .*?;/window.dialog \{\n  background-color: color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);/gs" "$LIBADWAITA_CSS" || true

# Replace hardcoded dialog colors
sed -i "s/#36363a/#$PRIMARY_40/g" "$LIBADWAITA_CSS"

# Direct replacements for common blue color codes
echo "Fixing hardcoded blue color values in all CSS files..."

# Apply the theme to Hyprland
echo "Applying theme changes to Hyprland..."

# Select the appropriate Fluent icon theme based on accent color
ICON_THEME=$(select_fluent_theme "$ACCENT")
echo "Selected icon theme: $ICON_THEME based on accent color #$ACCENT"

# Set the GTK theme system-wide
if command -v gsettings >/dev/null 2>&1; then
    echo "Setting GTK theme via gsettings..."
    gsettings set org.gnome.desktop.interface gtk-theme "serial-design-V-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    # Explicitly set the icon theme to Fluent
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    # Set cursor theme
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
fi

# Update GTK_THEME environment variable for current session
export GTK_THEME="serial-design-V-dark"
export GTK_ICON_THEME="$ICON_THEME"

# Touch GTK config files to trigger reload
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    touch "$HOME/.config/gtk-3.0/settings.ini"
fi
if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
    touch "$HOME/.config/gtk-4.0/settings.ini"
fi

# Improved GTK4 theme application
echo "Applying GTK4 theme more thoroughly..."

# Ensure GTK4 settings directory exists
mkdir -p "$HOME/.config/gtk-4.0"

# Create or update settings.ini with theme information
cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=Adwaita
gtk-font-name=Cantarell 11
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-hint-font-metrics=1
EOF

cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=Adwaita
gtk-font-name=Cantarell 11
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-hint-font-metrics=1
EOF

# Prevent overwriting existing custom CSS, instead append our colors
# This ensures we don't lose existing customizations on subsequent runs
if [ -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
    # Check if our custom style is already present
    if ! grep -q "/* Custom button text colors - Added by colorgen */" "$HOME/.config/gtk-4.0/gtk.css"; then
        echo "Appending to existing GTK4 custom CSS..."
        cat >> "$HOME/.config/gtk-4.0/gtk.css" << EOF

/* Custom button text colors - Added by colorgen */
button {
  color: $BUTTON_FG_COLOR !important;
}

button:hover, button:active, button:checked {
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action, button.destructive-action {
  color: $BUTTON_FG_COLOR !important;
}

/* Custom accent color overrides */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
EOF
    else
        # Replace the existing colorgen section with updated values
        echo "Updating existing GTK4 custom CSS..."
        sed -i '/\/\* Custom button text colors - Added by colorgen \*\//,/@define-color accent_bg_color/c\
/* Custom button text colors - Added by colorgen */\
button {\
  color: '$BUTTON_FG_COLOR' !important;\
}\
\
button:hover, button:active, button:checked {\
  color: '$BUTTON_FG_COLOR' !important;\
}\
\
button.suggested-action, button.destructive-action {\
  color: '$BUTTON_FG_COLOR' !important;\
}\
\
/* Custom accent color overrides */\
@define-color accent_color #'$ACCENT';\
@define-color accent_bg_color #'$ACCENT';' "$HOME/.config/gtk-4.0/gtk.css"
    fi
else
    echo "Creating GTK4 custom CSS..."
    cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Custom button text colors - Added by colorgen */
button {
  color: $BUTTON_FG_COLOR !important;
}

button:hover, button:active, button:checked {
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action, button.destructive-action {
  color: $BUTTON_FG_COLOR !important;
}

/* Custom accent color overrides */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
EOF
fi

# Ensure gtk-4.0/assets and gtk-4.0/icons directories exist
mkdir -p "$HOME/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/icons"

# Create an empty CSS file for custom icons if it doesn't exist
if [ ! -f "$HOME/.config/gtk-4.0/icons.css" ]; then
    touch "$HOME/.config/gtk-4.0/icons.css"
fi

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting GTK environment variables via Hyprland..."
    hyprctl setcursor Adwaita 24
    hyprctl keyword env GTK_THEME=serial-design-V-dark
    hyprctl keyword env GTK_ICON_THEME="$ICON_THEME"
    hyprctl keyword env GTK2_RC_FILES="/usr/share/themes/serial-design-V-dark/gtk-2.0/gtkrc"
fi

# Create symbolic links to ensure GTK4 apps find the theme
mkdir -p "$HOME/.local/share/themes"
if [ ! -L "$HOME/.local/share/themes/serial-design-V-dark" ] && [ -d "$THEME_DIR" ]; then
    ln -sf "$THEME_DIR" "$HOME/.local/share/themes/serial-design-V-dark"
fi

# Update GTK icon cache to ensure everything is refreshed
echo "Refreshing GTK icon cache..."
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "/usr/share/icons/$ICON_THEME" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi
if command -v gtk4-update-icon-cache >/dev/null 2>&1; then
    gtk4-update-icon-cache -f -t "/usr/share/icons/$ICON_THEME" 2>/dev/null || true
    gtk4-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk4-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi

echo "Colors applied successfully!"
echo "Theme has been applied to Hyprland. Some applications may need to be restarted to see the changes."

echo "GTK SCRIPT END: $(date +%H:%M:%S)"
exit 0  