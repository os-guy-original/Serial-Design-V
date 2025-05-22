#!/bin/bash

# Script to apply custom colors from colorgen/colors.conf to the GTK4 part of serial-design-V-dark theme

# Check if necessary variables are set from main script
if [ -z "$COLORGEN_CONF" ] || [ -z "$THEME_DIR" ]; then
    echo "Error: Required variables not set. This script should be called from gtk.sh."
    exit 1
fi

# Define theme paths for the user
USER_THEME_DIR="$HOME/.themes/serial-design-V-dark"
GTK4_CSS="$USER_THEME_DIR/gtk-4.0/gtk.css"
GTK4_DARK_CSS="$USER_THEME_DIR/gtk-4.0/gtk-dark.css"

# Create backup of original files if they don't exist
if [ ! -f "${GTK4_CSS}.original" ]; then
    echo "Creating original GTK4 backups..."
    cp "$GTK4_CSS" "${GTK4_CSS}.original"
    cp "$GTK4_DARK_CSS" "${GTK4_DARK_CSS}.original"
fi

# First restore original files to ensure script always starts from a clean state
echo "Restoring original GTK4 files..."
if [ -f "${GTK4_CSS}.original" ]; then
    cp "${GTK4_CSS}.original" "$GTK4_CSS"
    cp "${GTK4_DARK_CSS}.original" "$GTK4_DARK_CSS"
fi

# Create backup of current run
BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "Creating backups of GTK4 files with timestamp $BACKUP_TIMESTAMP..."
cp "$GTK4_CSS" "${GTK4_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$GTK4_DARK_CSS" "${GTK4_DARK_CSS}.backup.${BACKUP_TIMESTAMP}"

# Apply to GTK4
echo "Applying colors to GTK4 theme..."

# ==== CORE COLOR DEFINITIONS ====

# Update all basic color definitions
replace_color "$GTK4_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color accent_bg_color @blue_3;' "@define-color accent_bg_color #$ACCENT;"

replace_color "$GTK4_CSS" '@define-color accent_color @blue_3;' "@define-color accent_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color accent_color @blue_3;' "@define-color accent_color #$ACCENT;"

replace_color "$GTK4_CSS" '@define-color accent_fg_color white;' "@define-color accent_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color accent_fg_color white;' "@define-color accent_fg_color #$PRIMARY_95;"

# Update window bg/fg colors
replace_color "$GTK4_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color #$PRIMARY_20;"
replace_color "$GTK4_DARK_CSS" '@define-color window_bg_color #222226;' "@define-color window_bg_color #$PRIMARY_20;"

replace_color "$GTK4_CSS" '@define-color window_fg_color #eeeeee;' "@define-color window_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color window_fg_color #eeeeee;' "@define-color window_fg_color #$PRIMARY_95;"

# Update text colors
replace_color "$GTK4_CSS" '@define-color text_color @window_fg_color;' "@define-color text_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color text_color @window_fg_color;' "@define-color text_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color headerbar_text_color @window_fg_color;' "@define-color headerbar_text_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_text_color @window_fg_color;' "@define-color headerbar_text_color #$PRIMARY_95;"

# Update view bg/fg colors
replace_color "$GTK4_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color #$PRIMARY_10;"
replace_color "$GTK4_DARK_CSS" '@define-color view_bg_color #1d1d20;' "@define-color view_bg_color #$PRIMARY_10;"

replace_color "$GTK4_CSS" '@define-color view_fg_color @window_fg_color;' "@define-color view_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color view_fg_color @window_fg_color;' "@define-color view_fg_color #$PRIMARY_95;"

# ==== UI ELEMENT COLORS ====

# Update headerbar colors
replace_color "$GTK4_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color #$PRIMARY_30;"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_bg_color #2e2e32;' "@define-color headerbar_bg_color #$PRIMARY_30;"

replace_color "$GTK4_CSS" '@define-color headerbar_fg_color @window_fg_color;' "@define-color headerbar_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_fg_color @window_fg_color;' "@define-color headerbar_fg_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color headerbar_border_color @window_fg_color;' "@define-color headerbar_border_color #$PRIMARY_40;"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_border_color @window_fg_color;' "@define-color headerbar_border_color #$PRIMARY_40;"

replace_color "$GTK4_CSS" '@define-color headerbar_backdrop_color @backdrop_bg_color;' "@define-color headerbar_backdrop_color #$PRIMARY_25;"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_backdrop_color @backdrop_bg_color;' "@define-color headerbar_backdrop_color #$PRIMARY_25;"

replace_color "$GTK4_CSS" '@define-color headerbar_shade_color rgba(0, 0, 0, 0.36);' "@define-color headerbar_shade_color rgba(0, 0, 0, 0.2);"
replace_color "$GTK4_DARK_CSS" '@define-color headerbar_shade_color rgba(0, 0, 0, 0.36);' "@define-color headerbar_shade_color rgba(0, 0, 0, 0.2);"

# Update card colors
replace_color "$GTK4_CSS" '@define-color card_bg_color #28282c;' "@define-color card_bg_color #$PRIMARY_20;"
replace_color "$GTK4_DARK_CSS" '@define-color card_bg_color #28282c;' "@define-color card_bg_color #$PRIMARY_20;"

replace_color "$GTK4_CSS" '@define-color card_fg_color @window_fg_color;' "@define-color card_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color card_fg_color @window_fg_color;' "@define-color card_fg_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color card_shade_color rgba(0, 0, 0, 0.36);' "@define-color card_shade_color rgba(0, 0, 0, 0.2);"
replace_color "$GTK4_DARK_CSS" '@define-color card_shade_color rgba(0, 0, 0, 0.36);' "@define-color card_shade_color rgba(0, 0, 0, 0.2);"

# Update sidebar colors
replace_color "$GTK4_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color #$PRIMARY_30;"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_bg_color #2e2e32;' "@define-color sidebar_bg_color #$PRIMARY_30;"

replace_color "$GTK4_CSS" '@define-color sidebar_fg_color @window_fg_color;' "@define-color sidebar_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_fg_color @window_fg_color;' "@define-color sidebar_fg_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color #$PRIMARY_20;"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_backdrop_color #28282c;' "@define-color sidebar_backdrop_color #$PRIMARY_20;"

replace_color "$GTK4_CSS" '@define-color sidebar_shade_color rgba(0, 0, 0, 0.36);' "@define-color sidebar_shade_color rgba(0, 0, 0, 0.2);"
replace_color "$GTK4_DARK_CSS" '@define-color sidebar_shade_color rgba(0, 0, 0, 0.36);' "@define-color sidebar_shade_color rgba(0, 0, 0, 0.2);"

# Update dialog and popover colors
replace_color "$GTK4_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color #$PRIMARY_40;"
replace_color "$GTK4_DARK_CSS" '@define-color dialog_bg_color #36363a;' "@define-color dialog_bg_color #$PRIMARY_40;"

replace_color "$GTK4_CSS" '@define-color dialog_fg_color @window_fg_color;' "@define-color dialog_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color dialog_fg_color @window_fg_color;' "@define-color dialog_fg_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color #$PRIMARY_40;"
replace_color "$GTK4_DARK_CSS" '@define-color popover_bg_color #36363a;' "@define-color popover_bg_color #$PRIMARY_40;"

replace_color "$GTK4_CSS" '@define-color popover_fg_color @window_fg_color;' "@define-color popover_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color popover_fg_color @window_fg_color;' "@define-color popover_fg_color #$PRIMARY_95;"

# ==== STATUS COLORS ====

# Define error/warning/success colors
replace_color "$GTK4_CSS" '@define-color error_color #f66151;' "@define-color error_color #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color error_color #f66151;' "@define-color error_color #$ERROR;"

replace_color "$GTK4_CSS" '@define-color error_bg_color #c01c28;' "@define-color error_bg_color #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color error_bg_color #c01c28;' "@define-color error_bg_color #$ERROR;"

replace_color "$GTK4_CSS" '@define-color warning_color #f5c211;' "@define-color warning_color #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color warning_color #f5c211;' "@define-color warning_color #$WARNING;"

replace_color "$GTK4_CSS" '@define-color warning_bg_color #cd9309;' "@define-color warning_bg_color #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color warning_bg_color #cd9309;' "@define-color warning_bg_color #$WARNING;"

replace_color "$GTK4_CSS" '@define-color success_color #8ff0a4;' "@define-color success_color #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color success_color #8ff0a4;' "@define-color success_color #$SUCCESS;"

replace_color "$GTK4_CSS" '@define-color success_bg_color #26a269;' "@define-color success_bg_color #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color success_bg_color #26a269;' "@define-color success_bg_color #$SUCCESS;"

# ==== SELECTION COLORS ====

# Update selection colors
replace_color "$GTK4_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color selected_bg_color @accent_bg_color;' "@define-color selected_bg_color #$ACCENT;"

replace_color "$GTK4_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color selected_fg_color white;' "@define-color selected_fg_color #$PRIMARY_95;"

# Update backdrop and insensitive colors
replace_color "$GTK4_CSS" '@define-color backdrop_bg_color mix(@window_bg_color, @window_fg_color, 0.95);' "@define-color backdrop_bg_color #$PRIMARY_25;"
replace_color "$GTK4_DARK_CSS" '@define-color backdrop_bg_color mix(@window_bg_color, @window_fg_color, 0.95);' "@define-color backdrop_bg_color #$PRIMARY_25;"

replace_color "$GTK4_CSS" '@define-color backdrop_fg_color mix(@window_fg_color, @window_bg_color, 0.5);' "@define-color backdrop_fg_color #$PRIMARY_70;"
replace_color "$GTK4_DARK_CSS" '@define-color backdrop_fg_color mix(@window_fg_color, @window_bg_color, 0.5);' "@define-color backdrop_fg_color #$PRIMARY_70;"

replace_color "$GTK4_CSS" '@define-color backdrop_selected_bg_color mix(@selected_bg_color, @window_bg_color, 0.66);' "@define-color backdrop_selected_bg_color mix(#$ACCENT, #$PRIMARY_20, 0.66);"
replace_color "$GTK4_DARK_CSS" '@define-color backdrop_selected_bg_color mix(@selected_bg_color, @window_bg_color, 0.66);' "@define-color backdrop_selected_bg_color mix(#$ACCENT, #$PRIMARY_20, 0.66);"

replace_color "$GTK4_CSS" '@define-color backdrop_selected_fg_color @selected_fg_color;' "@define-color backdrop_selected_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color backdrop_selected_fg_color @selected_fg_color;' "@define-color backdrop_selected_fg_color #$PRIMARY_95;"

replace_color "$GTK4_CSS" '@define-color unfocused_selected_bg_color @selected_bg_color;' "@define-color unfocused_selected_bg_color #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color unfocused_selected_bg_color @selected_bg_color;' "@define-color unfocused_selected_bg_color #$ACCENT;"

replace_color "$GTK4_CSS" '@define-color unfocused_selected_fg_color @selected_fg_color;' "@define-color unfocused_selected_fg_color #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color unfocused_selected_fg_color @selected_fg_color;' "@define-color unfocused_selected_fg_color #$PRIMARY_95;"

# ==== COLOR PALETTE UPDATES ====

# Fix all blue color variants
replace_color "$GTK4_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$GTK4_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$GTK4_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$GTK4_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

replace_color "$GTK4_DARK_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$GTK4_DARK_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$GTK4_DARK_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$GTK4_DARK_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

# Fix all green color variants
replace_color "$GTK4_CSS" '@define-color green_1 #8ff0a4;' "@define-color green_1 #$SUCCESS;"
replace_color "$GTK4_CSS" '@define-color green_2 #57e389;' "@define-color green_2 #$SUCCESS;"
replace_color "$GTK4_CSS" '@define-color green_3 #33d17a;' "@define-color green_3 #$SUCCESS;"
replace_color "$GTK4_CSS" '@define-color green_4 #2ec27e;' "@define-color green_4 #$SUCCESS;"
replace_color "$GTK4_CSS" '@define-color green_5 #26a269;' "@define-color green_5 #$SUCCESS;"

replace_color "$GTK4_DARK_CSS" '@define-color green_1 #8ff0a4;' "@define-color green_1 #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color green_2 #57e389;' "@define-color green_2 #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color green_3 #33d17a;' "@define-color green_3 #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color green_4 #2ec27e;' "@define-color green_4 #$SUCCESS;"
replace_color "$GTK4_DARK_CSS" '@define-color green_5 #26a269;' "@define-color green_5 #$SUCCESS;"

# Fix all yellow/orange color variants
replace_color "$GTK4_CSS" '@define-color yellow_1 #f9f06b;' "@define-color yellow_1 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color yellow_2 #f8e45c;' "@define-color yellow_2 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color yellow_3 #f6d32d;' "@define-color yellow_3 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color yellow_4 #f5c211;' "@define-color yellow_4 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color yellow_5 #e5a50a;' "@define-color yellow_5 #$WARNING;"

replace_color "$GTK4_DARK_CSS" '@define-color yellow_1 #f9f06b;' "@define-color yellow_1 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color yellow_2 #f8e45c;' "@define-color yellow_2 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color yellow_3 #f6d32d;' "@define-color yellow_3 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color yellow_4 #f5c211;' "@define-color yellow_4 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color yellow_5 #e5a50a;' "@define-color yellow_5 #$WARNING;"

replace_color "$GTK4_CSS" '@define-color orange_1 #ffbe6f;' "@define-color orange_1 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color orange_2 #ffa348;' "@define-color orange_2 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color orange_3 #ff7800;' "@define-color orange_3 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color orange_4 #e66100;' "@define-color orange_4 #$WARNING;"
replace_color "$GTK4_CSS" '@define-color orange_5 #c64600;' "@define-color orange_5 #$WARNING;"

replace_color "$GTK4_DARK_CSS" '@define-color orange_1 #ffbe6f;' "@define-color orange_1 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color orange_2 #ffa348;' "@define-color orange_2 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color orange_3 #ff7800;' "@define-color orange_3 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color orange_4 #e66100;' "@define-color orange_4 #$WARNING;"
replace_color "$GTK4_DARK_CSS" '@define-color orange_5 #c64600;' "@define-color orange_5 #$WARNING;"

# Fix all red color variants
replace_color "$GTK4_CSS" '@define-color red_1 #f66151;' "@define-color red_1 #$ERROR;"
replace_color "$GTK4_CSS" '@define-color red_2 #ed333b;' "@define-color red_2 #$ERROR;"
replace_color "$GTK4_CSS" '@define-color red_3 #e01b24;' "@define-color red_3 #$ERROR;"
replace_color "$GTK4_CSS" '@define-color red_4 #c01c28;' "@define-color red_4 #$ERROR;"
replace_color "$GTK4_CSS" '@define-color red_5 #a51d2d;' "@define-color red_5 #$ERROR;"

replace_color "$GTK4_DARK_CSS" '@define-color red_1 #f66151;' "@define-color red_1 #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color red_2 #ed333b;' "@define-color red_2 #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color red_3 #e01b24;' "@define-color red_3 #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color red_4 #c01c28;' "@define-color red_4 #$ERROR;"
replace_color "$GTK4_DARK_CSS" '@define-color red_5 #a51d2d;' "@define-color red_5 #$ERROR;"

# Fix all purple color variants
replace_color "$GTK4_CSS" '@define-color purple_1 #dc8add;' "@define-color purple_1 #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color purple_2 #c061cb;' "@define-color purple_2 #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color purple_3 #9141ac;' "@define-color purple_3 #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color purple_4 #813d9c;' "@define-color purple_4 #$ACCENT;"
replace_color "$GTK4_CSS" '@define-color purple_5 #613583;' "@define-color purple_5 #$ACCENT_DARK;"

replace_color "$GTK4_DARK_CSS" '@define-color purple_1 #dc8add;' "@define-color purple_1 #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color purple_2 #c061cb;' "@define-color purple_2 #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color purple_3 #9141ac;' "@define-color purple_3 #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color purple_4 #813d9c;' "@define-color purple_4 #$ACCENT;"
replace_color "$GTK4_DARK_CSS" '@define-color purple_5 #613583;' "@define-color purple_5 #$ACCENT_DARK;"

# Fix borders and other remaining variables
replace_color "$GTK4_CSS" '@define-color borders rgba(255, 255, 255, 0.12);' "@define-color borders rgba(0, 0, 0, 0.15);"
replace_color "$GTK4_DARK_CSS" '@define-color borders rgba(255, 255, 255, 0.12);' "@define-color borders rgba(0, 0, 0, 0.15);"

replace_color "$GTK4_CSS" '@define-color shade_color rgba(0, 0, 0, 0.36);' "@define-color shade_color rgba(0, 0, 0, 0.2);"
replace_color "$GTK4_DARK_CSS" '@define-color shade_color rgba(0, 0, 0, 0.36);' "@define-color shade_color rgba(0, 0, 0, 0.2);"

# Add CSS rule to force all gtk::Button label text to use the darkest extracted color
cat >> "$GTK4_CSS" << EOF

/* Force all gtk::Button label text to use the darkest extracted color */
button, button label, button * {
    color: #$PRIMARY_0 !important;
}
EOF

cat >> "$GTK4_DARK_CSS" << EOF

/* Force all gtk::Button label text to use the darkest extracted color */
button, button label, button * {
    color: #$PRIMARY_0 !important;
}
EOF

echo "GTK4 theme colors applied successfully!"
