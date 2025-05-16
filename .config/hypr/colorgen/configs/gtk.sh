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

# Make borders transparent or very subtle
replace_color "$GTK3_CSS" '@define-color borders mix\(currentColor,@window_bg_color,0.85\);' "@define-color borders transparent;"
replace_color "$GTK3_DARK_CSS" '@define-color borders mix\(currentColor,@window_bg_color,0.85\);' "@define-color borders transparent;"

# Add direct CSS to remove GTK3 borders
cat >> "$GTK3_CSS" << EOF

/* Remove borders from GTK3 elements */
menu, 
.menu, 
.context-menu,
.popup,
popover {
  border: none;
  box-shadow: 0 1px 5px rgba(0, 0, 0, 0.2);
}

button,
.button {
  border: none;
}

menuitem,
.menuitem {
  border: none;
}

headerbar,
.titlebar,
.csd {
  border: none;
}

notebook > header > tabs > tab {
  border: none;
}

notebook > header > tabs > tab:checked {
  border-bottom: none;
}

popover > .arrow {
  border: none;
}
EOF

# Apply same to Dark CSS
cat >> "$GTK3_DARK_CSS" << EOF

/* Remove borders from GTK3 elements */
menu, 
.menu, 
.context-menu,
.popup,
popover {
  border: none;
  box-shadow: 0 1px 5px rgba(0, 0, 0, 0.2);
}

button,
.button {
  border: none;
}

menuitem,
.menuitem {
  border: none;
}

headerbar,
.titlebar,
.csd {
  border: none;
}

notebook > header > tabs > tab {
  border: none;
}

notebook > header > tabs > tab:checked {
  border-bottom: none;
}

popover > .arrow {
  border: none;
}
EOF

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

# --- GTK4 Theme Color Generation ---
echo "Applying colors to GTK4 theme with enhanced styling..."

# Function to apply GTK4 styling
apply_gtk4_styling() {
    local theme_file="$1"
    
    # 1. Core color variables
    replace_color "$theme_file" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"
    replace_color "$theme_file" '@define-color accent_fg_color white;' "@define-color accent_fg_color #$PRIMARY_95;" 
    replace_color "$theme_file" '@define-color accent_color @blue_3;' "@define-color accent_color #$ACCENT;"
    
    # 2. Background colors with subtle accent tint
    replace_color "$theme_file" '@define-color window_bg_color #222226;' "@define-color window_bg_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"
    replace_color "$theme_file" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color color-mix(in srgb, #$PRIMARY_10 92%, #$ACCENT 8%);"
    replace_color "$theme_file" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"
    replace_color "$theme_file" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color color-mix(in srgb, #$PRIMARY_30 85%, #$ACCENT 15%);"
    replace_color "$theme_file" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color color-mix(in srgb, #$PRIMARY_20 90%, #$ACCENT 10%);"
    replace_color "$theme_file" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"
    replace_color "$theme_file" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color color-mix(in srgb, #$PRIMARY_40 88%, #$ACCENT 12%);"
    replace_color "$theme_file" '@define-color thumbnail_bg_color #39393d;' "@define-color thumbnail_bg_color color-mix(in srgb, #$PRIMARY_40 85%, #$ACCENT 15%);"
    
    # 3. Selection colors
    replace_color "$theme_file" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
    replace_color "$theme_file" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"
    
    # 4. Text colors
    replace_color "$theme_file" '@define-color window_fg_color #eeeeee;' "@define-color window_fg_color #$PRIMARY_95;"
    replace_color "$theme_file" '@define-color view_fg_color #eeeeee;' "@define-color view_fg_color #$PRIMARY_95;"
    replace_color "$theme_file" '@define-color headerbar_fg_color #eeeeee;' "@define-color headerbar_fg_color #$PRIMARY_95;"
    
    # 5. Error/warning/success colors
    replace_color "$theme_file" '@define-color error_color #ff7b63;' "@define-color error_color #$SECONDARY;"
    replace_color "$theme_file" '@define-color warning_color #f8e45c;' "@define-color warning_color #$TERTIARY;"
    replace_color "$theme_file" '@define-color success_color #8ff0a4;' "@define-color success_color #$SECONDARY;"
    
    # 6. Update CSS variables
    replace_color "$theme_file" '--accent-blue: #3584e4;' "--accent-blue: #$ACCENT;"
    
    # 7. Update root variables
    replace_color "$theme_file" ':root \{ --blue-1: #99c1f1; --blue-2: #62a0ea; --blue-3: #3584e4; --blue-4: #1c71d8; --blue-5: #1a5fb4;' ":root { --blue-1: #$PRIMARY_95; --blue-2: #$PRIMARY_90; --blue-3: #$ACCENT; --blue-4: #$ACCENT_DARK; --blue-5: #$ACCENT_DARK;"
}

# Apply core styling to GTK4 and GTK4 Dark themes
apply_gtk4_styling "$GTK4_CSS"
apply_gtk4_styling "$GTK4_DARK_CSS"

# Enhanced selection styling for GTK4
cat > "$GTK4_CSS.selection" << EOF
/* Enhanced Selection styling for GTK4 */
selection {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
}

:selected {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
}

*:selected {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  border-color: #$ACCENT_DARK !important;
}

/* Selection style for text entry and views */
entry selection, 
textview selection, 
textview text selection {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  caret-color: #$PRIMARY_95 !important;
}

/* Selection style for lists */
list row:selected, 
row:selected {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  border-left: 4px solid #$ACCENT_DARK !important;
}

treeview.view:selected {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  border-left: 2px solid #$ACCENT_DARK !important;
}

listbox row:selected,
list box:selected {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  outline-color: #$ACCENT_DARK !important;
}

/* Themed selection variables */
@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$PRIMARY_95;
EOF

# Append the selection styles to both files
cat "$GTK4_CSS.selection" >> "$GTK4_CSS"
cat "$GTK4_CSS.selection" >> "$GTK4_DARK_CSS"
rm "$GTK4_CSS.selection"

# Apply the same to GTK4 Dark CSS
cat >> "$GTK4_DARK_CSS" << EOF

/* Explicit Selection styling for GTK4 */
selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

*:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border: 1px solid #$ACCENT;
}

/* Custom selection style for GTK4 elements */
entry selection, textview selection, textview text selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

list row:selected, row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 4px solid #$ACCENT_DARK;
}

treeview.view:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 2px solid #$ACCENT_DARK;
}

/* GtkListBox rows styling */
list box:selected, listbox row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

/* More direct overrides for selection */
@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$PRIMARY_95;
EOF

# Add explicit selection border styling for GTK4
cat >> "$GTK4_CSS" << EOF

/* Explicit Selection styling for GTK4 */
selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

*:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border: 1px solid #$ACCENT;
}

/* Custom selection style for GTK4 elements */
entry selection, textview selection, textview text selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

list row:selected, row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 4px solid #$ACCENT_DARK;
}

treeview.view:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 2px solid #$ACCENT_DARK;
}

/* GtkListBox rows styling */
list box:selected, listbox row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

/* More direct overrides for selection */
@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$PRIMARY_95;
EOF

# Apply the same to GTK4 Dark CSS
cat >> "$GTK4_DARK_CSS" << EOF

/* Explicit Selection styling for GTK4 */
selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

*:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border: 1px solid #$ACCENT;
}

/* Custom selection style for GTK4 elements */
entry selection, textview selection, textview text selection {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

list row:selected, row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 4px solid #$ACCENT_DARK;
}

treeview.view:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-left: 2px solid #$ACCENT_DARK;
}

/* GtkListBox rows styling */
list box:selected, listbox row:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

/* More direct overrides for selection */
@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$PRIMARY_95;
EOF

# --- Libadwaita/GTK4 Advanced UI Styling ---
echo "Applying advanced GTK4/Libadwaita UI element styling..."

# Update direct Adwaita color definitions first
replace_color "$LIBADWAITA_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

# Replace any variable references directly
sed -i "s/@accent_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/@accent_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"
sed -i "s/@theme_selected_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS" 
sed -i "s/@theme_selected_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"

# Check if the accent color is bright and determine text color
BUTTON_FG_COLOR="#$PRIMARY_95"
if is_color_bright "$ACCENT"; then
    echo "Accent color #$ACCENT is bright, using dark text for UI elements"
    BUTTON_FG_COLOR="#$PRIMARY_10"
fi

# Create comprehensive libadwaita styling
cat > "$THEME_DIR/gtk-4.0/libadwaita-custom.css" << EOF
/* Comprehensive Libadwaita GTK4 Styling - Generated $(date) */

/* --- Core Theme Variables --- */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
@define-color accent_fg_color #$BUTTON_FG_COLOR;

@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$BUTTON_FG_COLOR;
@define-color theme_unfocused_selected_bg_color color-mix(in srgb, #$ACCENT 80%, transparent);
@define-color theme_unfocused_selected_fg_color #$BUTTON_FG_COLOR;

/* --- Selection Styling --- */
selection {
  background-color: color-mix(in srgb, #$ACCENT 60%, transparent);
  color: #$BUTTON_FG_COLOR;
}

:selected {
  background-color: #$ACCENT;
  color: #$BUTTON_FG_COLOR;
}

selection:focus-within {
  background-color: color-mix(in srgb, #$ACCENT 80%, transparent);
  color: #$BUTTON_FG_COLOR;
}

/* Text selection */
entry selection, 
textview selection,
text selection {
  background-color: color-mix(in srgb, #$ACCENT 60%, transparent);
  color: #$BUTTON_FG_COLOR;
}

/* --- UI Control Elements --- */

/* Scrollbars */
scrollbar slider {
  background-color: color-mix(in srgb, #$ACCENT 70%, transparent);
  border-radius: 8px;
  min-width: 8px;
  min-height: 8px;
}

scrollbar slider:hover {
  background-color: #$ACCENT;
  min-width: 10px;
  min-height: 10px;
}

scrollbar slider:active {
  background-color: #$ACCENT_DARK;
  min-width: 10px;
  min-height: 10px;
}

/* Sliders and scales */
scale trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 90%, #$ACCENT 10%);
  border-radius: 10px;
  min-height: 6px;
  min-width: 6px;
}

scale trough highlight {
  background-color: #$ACCENT;
  border-radius: 10px;
}

scale slider {
  background-color: #$ACCENT;
  border-radius: 50%;
  min-height: 16px;
  min-width: 16px;
}

scale slider:hover {
  background-color: color-mix(in srgb, #$ACCENT 90%, white);
  transform: scale(1.1);
}

scale slider:active {
  background-color: #$ACCENT_DARK;
  transform: scale(1.15);
}

/* Switches */
switch {
  background-color: color-mix(in srgb, #$PRIMARY_40 90%, #$ACCENT 10%);
  border-radius: 16px;
  min-height: 22px;
  min-width: 40px;
}

switch:checked {
  background-color: #$ACCENT;
}

switch slider {
  background-color: #$PRIMARY_95;
  border-radius: 50%;
  min-height: 18px;
  min-width: 18px;
  margin: 1px;
}

switch:hover slider {
  background-color: #$PRIMARY_99;
  transform: scale(1.05);
}

/* Spinbuttons */
spinbutton button {
  color: $BUTTON_FG_COLOR !important;
}

spinbutton button:hover {
  background-color: color-mix(in srgb, #$ACCENT 25%, transparent);
}

/* Progress bars */
progressbar trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 90%, #$ACCENT 10%);
  border-radius: 6px;
  min-height: 6px;
}

progressbar progress {
  background-color: #$ACCENT;
  border-radius: 6px;
}

/* --- Containers and Windows --- */

/* Popover/Menu styling */
popover, menu, .menu {
  background-color: color-mix(in srgb, #$PRIMARY_20 95%, #$ACCENT 5%);
  border-radius: 8px;
  padding: 6px;
}

menuitem:hover, .menuitem:hover {
  background-color: color-mix(in srgb, #$ACCENT 80%, transparent);
  color: #$BUTTON_FG_COLOR;
  border-radius: 6px;
}

/* Lists */
list row:selected, row:selected {
  background-color: #$ACCENT;
  color: #$BUTTON_FG_COLOR;
  border-radius: 6px;
}

list row:hover, row:hover {
  background-color: color-mix(in srgb, #$ACCENT 20%, transparent);
  border-radius: 6px;
}

/* InfoBars */
infobar {
  border-radius: 8px;
  padding: 6px;
}

infobar.info {
  background-color: color-mix(in srgb, #$ACCENT 30%, transparent);
}

infobar.warning {
  background-color: color-mix(in srgb, #$TERTIARY 30%, transparent);
}

infobar.error {
  background-color: color-mix(in srgb, #$SECONDARY 30%, transparent);
}

/* Notebook/Tab styling */
notebook > header > tabs > tab {
  padding: 6px 10px;
  border-radius: 6px 6px 0 0;
}

notebook > header > tabs > tab:checked {
  background-color: color-mix(in srgb, #$ACCENT 10%, transparent);
}

notebook > header > tabs > tab:hover:not(:checked) {
  background-color: color-mix(in srgb, #$ACCENT 5%, transparent);
}

/* Button styling */
button {
  border-radius: ${BORDER_RADIUS};
  background-color: color-mix(in srgb, #$ACCENT 10%, transparent);
  padding: 6px 12px;
  color: inherit;
}

button:hover {
  background-color: color-mix(in srgb, #$ACCENT 20%, transparent);
}

button:active {
  background-color: color-mix(in srgb, #$ACCENT 30%, transparent);
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.2);
}

button.suggested-action {
  background-color: #$ACCENT;
  color: #$BUTTON_FG_COLOR;
}

button.destructive-action {
  background-color: #$SECONDARY;
  color: #$BUTTON_FG_COLOR;
}

/* Calendar styling */
calendar {
  background-color: transparent;
  border-radius: 8px;
}

calendar:selected {
  background-color: #$ACCENT;
  color: #$BUTTON_FG_COLOR;
  border-radius: 6px;
}

calendar.header {
  background-color: color-mix(in srgb, #$ACCENT 10%, transparent);
}

/* Touchscreen/Mobile styling enhancements */
@media (pointer: coarse) {
  button {
    padding: 8px 14px;
    min-height: 44px;
  }
  
  scale slider {
    min-height: 20px;
    min-width: 20px;
  }
  
  switch {
    min-height: 26px;
    min-width: 46px;
  }
  
  switch slider {
    min-height: 22px;
    min-width: 22px;
  }
}
EOF

# Append our custom styles to libadwaita.css
cat "$THEME_DIR/gtk-4.0/libadwaita-custom.css" >> "$LIBADWAITA_CSS"

# Update libadwaita-tweaks.css with hardcoded values but remove borders
replace_color "$LIBADWAITA_TWEAKS" '--accent-blue: #3584e4;' "--accent-blue: #$ACCENT;"
replace_color "$LIBADWAITA_TWEAKS" '#3584e4' "#$ACCENT"
replace_color "$LIBADWAITA_TWEAKS" '#1c71d8' "#$ACCENT_DARK"
replace_color "$LIBADWAITA_TWEAKS" '#1a5fb4' "#$ACCENT_DARK"
replace_color "$LIBADWAITA_TWEAKS" '#ffb4ac' "#$ACCENT"

# Remove border styling from context menus and buttons
cat >> "$LIBADWAITA_CSS" << EOF

/* Remove unnecessary borders */
popover,
menu,
menubar,
.menu,
.menubar,
.popup,
.context-menu,
.dropdown menu,
dropdown box {
  border: none !important;
}

.menu-button-container,
.menu-button,
.menu-item,
.menuitem {
  border: none !important;
}

button,
button.text-button,
button.flat,
button.image-button,
.button {
  border: none !important;
}

menu > arrow,
.menu > arrow {
  border: none !important;
}

contextmenu {
  border: none !important;
}

menuitem > arrow,
.menuitem > arrow {
  border: none !important;
}

/* Override other border styles */
.csd,
.titlebar,
headerbar {
  border: none !important;
}

.context-menu separator {
  margin: 2px 0;
}

popover contents {
  border: none !important;
}

/* Fix right click menus */
.popup decoration {
  box-shadow: 0 1px 5px rgba(0, 0, 0, 0.3) !important;
  border: none !important;
}

/* GTK4 right-click menu specific fixes */
window.popup,
window.popup.menu,
window.popup.background,
window.context-menu,
.popup,
.context-menu,
.popup .contents,
.context-menu .contents,
popover.menu contents,
popover > contents,
window.popup box,
window.popup frame,
window.popup separator,
window.popup scrolledwindow,
window.popup viewport,
contextmenu,
menu,
menubar,
menuitem,
.menu,
.menubar,
.menuitem,
window.popup * {
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
  border-image: none !important;
  border-style: none !important;
  border-width: 0 !important;
  border-color: transparent !important;
}

/* Outer decoration for right-click menus - only shadow, no border */
window.popup.background > decoration,
window.popup > decoration,
window.context-menu > decoration,
popover > decoration {
  border: none !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

/* GTK4 popover decorations override */
popover,
popover decoration, 
popover widget,
popover box,
popover grid,
popover contents,
popover arrow {
  border: none !important;
  border-width: 0px !important;
  border-color: transparent !important;
  outline: none !important;
  box-shadow: none !important;
}

/* Comprehensive Nautilus and file manager fixes */
window.nautilus-window popover.menu,
window.nautilus-window popover.menu *,
window.nautilus-window .context-menu,
window.nautilus-window .context-menu *,
nautilus-window popover.menu,
nautilus-window popover.menu *,
nautilus-window .context-menu,
nautilus-window .context-menu *,
@namespace nautilus "http://www.gnome.org/nautilus",
nautilus-window,
nautilus-window popover,
nautilus-window popover *,
@host nautilus-window > popover,
@host nautilus-window > popover *,
nautilus-menu,
.nautilus-menu,
#nautilus-menu,
.nautilus-canvas-item {
  border: none !important;
  box-shadow: none !important;
  outline: none !important;
  border-image: none !important;
  border-style: none !important;
  border-width: 0 !important;
  border-color: transparent !important;
  text-shadow: none !important;
}

/* For Nautilus popovers - highest specificity */
window.nautilus-window widget > popover, 
window.nautilus-window widget > popover box, 
window.nautilus-window widget > popover frame, 
window.nautilus-window widget > popover separator, 
window.nautilus-window widget > popover contents,
window.nautilus-window widget > popover scrolledwindow,
window.nautilus-window widget > popover viewport {
  border: none !important;
  outline: none !important;
  margin: 0 !important;
  padding: 0 !important;
}

/* Popover outer shell fix with shadow but no border */
window.nautilus-window popover.menu,
window.nautilus-window popover.menu.background,
popover.background {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
  border: none !important;
  outline: none !important;
}

/* Popup menu with arrow fixes */
popover arrow,
popover contents,
popover > .contents,
.popover arrow,
.popover contents,
.popover > .contents {
  border: none !important;
  margin: 0 !important;
}

/* General context menu fixes */
menuitem box,
menuitem image,
menuitem label,
.menuitem box,
.menuitem image,
.menuitem label,
modelbutton box,
modelbutton label,
modelbutton image {
  border: none !important;
  margin: 0 !important;
}

/* Highest specificity override for popovers */
*:not(decoration) > popover,
popover.background,
.popover,
.menu-popover,
*:not(decoration) > popover *,
popover.background *,
.popover *,
.menu-popover * {
  border: none !important;
}

/* File manager list view fixes */
treeview.view,
treeview.view *,
list row,
list row * {
  border: none !important;
}

/* Any other element potentially having borders */
decoration,
headerbar decoration,
menu decoration,
popover decoration,
.menu decoration,
.popup decoration {
  border: none !important;
  box-shadow: 0 1px 5px rgba(0, 0, 0, 0.3) !important;
}
EOF



# --- User-wide GTK4 Configuration ---
echo "Setting up user-wide GTK4 configuration with accent colors..."

# Create comprehensive GTK4 user configuration
cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* User-wide GTK4 accent theme - Generated by gtk.sh $(date +%Y-%m-%d) */

/* Border Fix for GTK4 Right-Click Menus */
window.popup,
window.popup.background,
window.context-menu,
popover,
popover contents,
popover arrow,
popover > *,
menu,
.menu,
.context-menu,
.popup,
.dropdown menu,
dropdown box,
window.popup *,
window.context-menu * {
  border: none !important;
  box-shadow: none !important;
  outline: none !important;
  border-color: transparent !important;
  border-image: none !important;
  border-style: none !important;
  border-width: 0 !important;
}

/* Only keep outer shadow */
window.popup > decoration,
window.context-menu > decoration,
popover decoration {
  border: none !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

/* --- Core Theme Variables --- */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
@define-color accent_fg_color #$BUTTON_FG_COLOR;

@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color #$BUTTON_FG_COLOR;

/* --- Selection Styling --- */
selection {
  background-color: color-mix(in srgb, #$ACCENT 60%, transparent) !important;
  color: #$BUTTON_FG_COLOR !important;
}

:selected {
  background-color: #$ACCENT !important;
  color: #$BUTTON_FG_COLOR !important;
}

*:selected {
  background-color: #$ACCENT !important;
  color: #$BUTTON_FG_COLOR !important;
}

/* --- UI Elements --- */

/* Buttons */
button {
  color: inherit !important;
}

button:hover, button:active, button:checked {
  color: inherit !important;
}

button.suggested-action, button.destructive-action {
  color: #$BUTTON_FG_COLOR !important;
}

/* Scrollbars */
scrollbar slider {
  background-color: color-mix(in srgb, #$ACCENT 70%, transparent) !important;
  border-radius: 8px !important;
}

scrollbar slider:hover {
  background-color: #$ACCENT !important;
}

/* Scales */
scale trough highlight {
  background-color: #$ACCENT !important;
  border-radius: 10px !important;
}

scale slider {
  background-color: #$ACCENT !important;
}

/* Switches */
switch:checked {
  background-color: #$ACCENT !important;
}

/* Progress bars */
progressbar progress {
  background-color: #$ACCENT !important;
}

/* Checkboxes and radio buttons */
check:checked, radio:checked {
  background-color: #$ACCENT !important;
  color: #$BUTTON_FG_COLOR !important;
}

EOF

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
    # Set cursor theme to Graphite-dark-cursors
    gsettings set org.gnome.desktop.interface cursor-theme "Graphite-dark-cursors"
fi

# Update GTK_THEME environment variable for current session
export GTK_THEME="serial-design-V-dark"
export GTK_ICON_THEME="$ICON_THEME"
export XCURSOR_THEME="Graphite-dark-cursors"

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
gtk-cursor-theme-name=Graphite-dark-cursors
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
gtk-cursor-theme-name=Graphite-dark-cursors
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

# Check for existing customizations and preserve them
if [ -f "$HOME/.config/gtk-4.0/gtk.css" ] && grep -q "/* User custom styles - DO NOT REMOVE */" "$HOME/.config/gtk-4.0/gtk.css"; then
    echo "Preserving user's custom GTK4 CSS styles..."
    # Extract user's custom styles
    USER_STYLES=$(sed -n '/\/\* User custom styles - DO NOT REMOVE \*\//,/\/\* End user custom styles \*\//p' "$HOME/.config/gtk-4.0/gtk.css")
    
    # Append to our new CSS
    echo "$USER_STYLES" >> "$HOME/.config/gtk-4.0/gtk.css"
fi

# Ensure gtk-4.0/assets and gtk-4.0/icons directories exist
mkdir -p "$HOME/.config/gtk-4.0/assets" "$HOME/.config/gtk-4.0/icons"

# Create an empty CSS file for custom icons if it doesn't exist
if [ ! -f "$HOME/.config/gtk-4.0/icons.css" ]; then
    touch "$HOME/.config/gtk-4.0/icons.css"
fi

# Add enhanced GTK4 selection and UI elements styling
cat >> "$LIBADWAITA_CSS" << EOF

/* Enhanced styling for GTK4 UI elements */

/* Scrollbar styling with accent color */
scrollbar slider {
  background-color: color-mix(in srgb, #$ACCENT 70%, transparent);
  border-radius: 6px;
  min-width: 12px;
  min-height: 12px;
  border: 1px solid color-mix(in srgb, #$ACCENT 90%, transparent);
}

scrollbar slider:hover {
  background-color: #$ACCENT;
}

scrollbar slider:active {
  background-color: #$ACCENT_DARK;
}

/* Scale (slider) styling */
scale slider {
  background-color: #$ACCENT;
  border: 1px solid #$ACCENT_DARK;
}

scale slider:hover {
  background-color: color-mix(in srgb, #$ACCENT 90%, white);
}

scale slider:active {
  background-color: #$ACCENT_DARK;
}

scale trough highlight {
  background-color: #$ACCENT;
}

/* Spinbutton styling */
spinbutton button {
  color: $BUTTON_FG_COLOR !important;
  border: 1px solid #$ACCENT;
}

spinbutton button:hover {
  background-color: color-mix(in srgb, #$ACCENT 25%, transparent);
}

/* Menu styling - no borders */
menu, .menu, popover, .context-menu, .popup, contextmenu {
  border: none !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

menuitem:hover, .menuitem:hover {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
}

/* Notebook tabs */
notebook > header > tabs > tab:checked {
  border-bottom: 3px solid #$ACCENT;
}

/* Switch styling */
switch {
  background-color: color-mix(in srgb, #$PRIMARY_40 90%, #$ACCENT 10%);
  border: 1px solid #$ACCENT;
}

switch:checked {
  background-color: #$ACCENT;
}

switch slider {
  background-color: #$PRIMARY_95;
}

/* Calendar styling */
calendar:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-radius: 8px;
}

/* InfoBar styling */
infobar {
  border: 1px solid #$ACCENT;
}

infobar.info {
  background-color: color-mix(in srgb, #$ACCENT 30%, transparent);
}

infobar.warning {
  background-color: color-mix(in srgb, #$TERTIARY 30%, transparent);
}

infobar.error {
  background-color: color-mix(in srgb, #$SECONDARY 30%, transparent);
}

/* Progressive bars */
progressbar trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 90%, #$ACCENT 10%);
}

progressbar progress {
  background-color: #$ACCENT;
}

/* Additional GTK4 Right-Click Menu Border Fixes */
popover contents,
popover scrolledwindow,
popover arrow,
popover frame,
popover button,
popover box,
popover modelbutton,
popover *,
menu *,
.menu *,
.context-menu *,
window.popup *,
window.popup.background *,
window.context-menu *,
window.menu * {
  border-color: transparent !important;
  border: none !important;
  outline: none !important;
}

/* Ensure no border in dropdown and combo boxes */
dropdown,
dropdown *,
combobox,
combobox *,
popover decoration,
popover > arrow,
popover > contents,
.dropdown,
.dropdown * {
  border: none !important;
}
EOF

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting GTK environment variables via Hyprland..."
    hyprctl setcursor Graphite-dark-cursors 24
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