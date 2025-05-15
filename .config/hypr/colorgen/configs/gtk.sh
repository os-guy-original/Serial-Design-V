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

# Update button classes - use more intense background color
perl -i -0777 -pe "s/button \{\n.*?min-height: 24px;.*?min-width: 16px;.*?padding: 5px 10px;.*?border-radius: ${BORDER_RADIUS};.*?font-weight: bold;.*?border: 1px solid transparent;.*?background-color: color-mix\(in srgb, #$ACCENT 8%, transparent\);.*?\}/button \{\n  min-height: 24px;\n  min-width: 16px;\n  padding: 5px 10px;\n  border-radius: ${BORDER_RADIUS};\n  font-weight: bold;\n  border: 1px solid #$ACCENT;\n  background-color: color-mix(in srgb, #$ACCENT 15%, transparent);\n}/gs" "$LIBADWAITA_CSS" || true

# Fix button hover colors - more vibrant
perl -i -0777 -pe "s/button:hover \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 12%, transparent\);.*?border: 1px solid #$ACCENT;.*?\}/button:hover \{\n  background-color: color-mix(in srgb, #$ACCENT 25%, transparent);\n  border: 2px solid #$ACCENT;\n}/gs" "$LIBADWAITA_CSS" || true

# Fix button active/checked colors - more vibrant
perl -i -0777 -pe "s/button.keyboard-activating, button:active \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 20%, transparent\);.*?border: 1px solid #$ACCENT;.*?\}/button.keyboard-activating, button:active \{\n  background-color: color-mix(in srgb, #$ACCENT 35%, transparent);\n  border: 2px solid #$ACCENT;\n  box-shadow: inset 0 0 3px rgba(0, 0, 0, 0.3);\n}/gs" "$LIBADWAITA_CSS" || true

perl -i -0777 -pe "s/button:checked \{\n.*?background-color: color-mix\(in srgb, #$ACCENT 20%, transparent\);.*?border: ${BORDER_WIDTH} solid #$ACCENT;.*?\}/button:checked \{\n  background-color: color-mix(in srgb, #$ACCENT 40%, transparent);\n  border: ${BORDER_WIDTH} solid #$ACCENT;\n  box-shadow: inset 0 0 3px rgba(0, 0, 0, 0.3);\n}/gs" "$LIBADWAITA_CSS" || true

# Enhance checks and radio buttons - more vibrant
replace_color "$LIBADWAITA_CSS" 'check:checked, radio:checked, .check:checked, .radio:checked' "check:checked, radio:checked, .check:checked, .radio:checked { background-color: #$ACCENT; box-shadow: 0 0 3px #$ACCENT; }"

# Fix focus outline - make more visible
replace_color "$LIBADWAITA_CSS" 'outline-color: color-mix\(in srgb, #$ACCENT 40%, transparent\);' "outline-color: color-mix(in srgb, #$ACCENT 70%, transparent);"

# Fix general accent colors - Essential section to fix remaining blue colors
echo "Fixing remaining blue accent colors with more comprehensive approach..."

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

# Set the GTK theme system-wide
if command -v gsettings >/dev/null 2>&1; then
    echo "Setting GTK theme via gsettings..."
    gsettings set org.gnome.desktop.interface gtk-theme "serial-design-V-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
fi

# Update GTK_THEME environment variable for current session
export GTK_THEME="serial-design-V-dark"

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
cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=serial-design-V-dark
gtk-application-prefer-dark-theme=1
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

# Apply theme to specific GTK4 configuration file
if [ -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
    echo "Updating GTK4 custom CSS..."
    cat >> "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Custom accent color overrides */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
window, dialog, popover { 
    border-color: #$ACCENT;
}
selection {
    background-color: alpha(#$ACCENT, 0.5);
}
EOF
else
    echo "Creating GTK4 custom CSS..."
    cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
/* Custom accent color overrides */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
window, dialog, popover { 
    border-color: #$ACCENT;
}
selection {
    background-color: alpha(#$ACCENT, 0.5);
}
EOF
fi

# Update environment variables for current session and Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    echo "Setting GTK environment variables via Hyprland..."
    hyprctl setcursor Adwaita 24
    hyprctl keyword env GTK_THEME=serial-design-V-dark
    hyprctl keyword env GTK2_RC_FILES="/usr/share/themes/serial-design-V-dark/gtk-2.0/gtkrc"
fi

# Update GTK icon cache to ensure everything is refreshed
echo "Refreshing GTK icon cache..."
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi
if command -v gtk4-update-icon-cache >/dev/null 2>&1; then
    gtk4-update-icon-cache -f -t "$HOME/.icons" 2>/dev/null || true
    gtk4-update-icon-cache -f -t "/usr/share/icons/hicolor" 2>/dev/null || true
fi

# Reload Hyprland to apply changes - COMMENTED OUT to prevent issues
# if command -v hyprctl >/dev/null 2>&1; then
#    echo "Reloading Hyprland configuration..."
#    hyprctl dispatch exec "sh -c 'sleep 1 && hyprctl reload'" &>/dev/null
# fi

# Create a notification if notify-send is available
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Theme Updated" "The GTK theme has been updated with your custom colors." -i preferences-desktop-theme
fi

echo "Colors applied successfully!"
echo "Theme has been applied to Hyprland. Some applications may need to be restarted to see the changes."

echo "GTK SCRIPT END: $(date +%H:%M:%S)"
exit 0  