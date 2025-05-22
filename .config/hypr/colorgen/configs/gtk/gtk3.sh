#!/bin/bash

# Script to apply custom colors from colorgen/colors.conf to the GTK3 part of serial-design-V-dark theme

# Check if necessary variables are set from main script
if [ -z "$COLORGEN_CONF" ] || [ -z "$THEME_DIR" ]; then
    echo "Error: Required variables not set. This script should be called from gtk.sh."
    exit 1
fi

GTK3_CSS="$THEME_DIR/gtk-3.0/gtk.css"
GTK3_DARK_CSS="$THEME_DIR/gtk-3.0/gtk-dark.css"

# Create backup of original files if they don't exist
if [ ! -f "${GTK3_CSS}.original" ]; then
    echo "Creating original GTK3 backups..."
    cp "$GTK3_CSS" "${GTK3_CSS}.original"
    cp "$GTK3_DARK_CSS" "${GTK3_DARK_CSS}.original"
fi

# First restore original files to ensure script always starts from a clean state
echo "Restoring original GTK3 files..."
if [ -f "${GTK3_CSS}.original" ]; then
    cp "${GTK3_CSS}.original" "$GTK3_CSS"
    cp "${GTK3_DARK_CSS}.original" "$GTK3_DARK_CSS"
fi

# Create backup of current run
BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "Creating backups of GTK3 files with timestamp $BACKUP_TIMESTAMP..."
cp "$GTK3_CSS" "${GTK3_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$GTK3_DARK_CSS" "${GTK3_DARK_CSS}.backup.${BACKUP_TIMESTAMP}"

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
  color: #$PRIMARY_10 !important;
}

/* Ensure button text remains visible on hover/active states */
button:hover, button:active, button:checked, .button:hover, .button:active, .button:checked {
  color: #$PRIMARY_10 !important;
}

/* Accent buttons get special treatment to ensure readability */
button.accent, button.suggested-action, button.destructive-action {
  color: #$PRIMARY_10 !important;
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
  color: #$PRIMARY_10 !important;
}

/* Ensure button text remains visible on hover/active states */
button:hover, button:active, button:checked, .button:hover, .button:active, .button:checked {
  color: #$PRIMARY_10 !important;
}

/* Accent buttons get special treatment to ensure readability */
button.accent, button.suggested-action, button.destructive-action {
  color: #$PRIMARY_10 !important;
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

echo "GTK3 theme colors applied successfully!" 