#!/bin/bash

# Script to apply custom colors from colorgen/colors.conf to the Libadwaita part of serial-design-V-dark theme

# Check if necessary variables are set from main script
if [ -z "$COLORGEN_CONF" ] || [ -z "$THEME_DIR" ]; then
    echo "Error: Required variables not set. This script should be called from gtk.sh."
    exit 1
fi

# Define theme paths
USER_THEME_DIR="$HOME/.themes/serial-design-V-dark"
LIBADWAITA_CSS="$USER_THEME_DIR/gtk-4.0/libadwaita.css"
LIBADWAITA_TWEAKS="$USER_THEME_DIR/gtk-4.0/libadwaita-tweaks.css"

# Create backup of original files if they don't exist
if [ ! -f "${LIBADWAITA_CSS}.original" ]; then
    echo "Creating original Libadwaita backups..."
    cp "$LIBADWAITA_CSS" "${LIBADWAITA_CSS}.original"
    cp "$LIBADWAITA_TWEAKS" "${LIBADWAITA_TWEAKS}.original"
fi

# First restore original files to ensure script always starts from a clean state
echo "Restoring original Libadwaita files..."
if [ -f "${LIBADWAITA_CSS}.original" ]; then
    cp "${LIBADWAITA_CSS}.original" "$LIBADWAITA_CSS"
    cp "${LIBADWAITA_TWEAKS}.original" "$LIBADWAITA_TWEAKS"
fi

# Create backup of current run
BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "Creating backups of Libadwaita files with timestamp $BACKUP_TIMESTAMP..."
cp "$LIBADWAITA_CSS" "${LIBADWAITA_CSS}.backup.${BACKUP_TIMESTAMP}"
cp "$LIBADWAITA_TWEAKS" "${LIBADWAITA_TWEAKS}.backup.${BACKUP_TIMESTAMP}"

# --- Libadwaita Color Variables Replacement ---
echo "Applying colors to libadwaita theme files..."

# Additional color replacement for any blue colors used for highlighting
echo "Adding extra color replacements for text highlight colors..."
# Replace common blue highlight colors with accent color
sed -i "s/#3584e4/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/#1c71d8/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/#62a0ea/#$ACCENT/g" "$LIBADWAITA_CSS"
# Replace semi-transparent blue selections
sed -i "s/rgba(52, 132, 228, 0.4)/rgba($ACCENT_RGB, 0.4)/g" "$LIBADWAITA_CSS"
sed -i "s/rgba(53, 132, 228, 0.15)/rgba($ACCENT_RGB, 0.15)/g" "$LIBADWAITA_CSS"
sed -i "s/rgba(53, 132, 228, 0.3)/rgba($ACCENT_RGB, 0.3)/g" "$LIBADWAITA_CSS"

# ==== CORE LIBADWAITA COLORS ====

# Replace accent colors
replace_color "$LIBADWAITA_CSS" 'accent_bg_color: #3584e4;' "accent_bg_color: #$ACCENT;"
replace_color "$LIBADWAITA_CSS" 'accent_color: #3584e4;' "accent_color: #$ACCENT;"
replace_color "$LIBADWAITA_CSS" 'accent_fg_color: #ffffff;' "accent_fg_color: #$PRIMARY_95;"

# Replace window background colors
replace_color "$LIBADWAITA_CSS" 'window_bg_color: #222226;' "window_bg_color: #$PRIMARY_20;"
replace_color "$LIBADWAITA_CSS" 'window_fg_color: #eeeeee;' "window_fg_color: #$PRIMARY_95;"

# Replace view background colors
replace_color "$LIBADWAITA_CSS" 'view_bg_color: #1d1d20;' "view_bg_color: #$PRIMARY_10;"
replace_color "$LIBADWAITA_CSS" 'view_fg_color: #eeeeee;' "view_fg_color: #$PRIMARY_95;"

# Replace card colors
replace_color "$LIBADWAITA_CSS" 'card_bg_color: #28282c;' "card_bg_color: #$PRIMARY_20;"
replace_color "$LIBADWAITA_CSS" 'card_fg_color: #eeeeee;' "card_fg_color: #$PRIMARY_95;"

# Replace headerbar colors
replace_color "$LIBADWAITA_CSS" 'headerbar_bg_color: #2e2e32;' "headerbar_bg_color: #$PRIMARY_30;"
replace_color "$LIBADWAITA_CSS" 'headerbar_fg_color: #eeeeee;' "headerbar_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'headerbar_border_color: transparent;' "headerbar_border_color: transparent;"
replace_color "$LIBADWAITA_CSS" 'headerbar_backdrop_color: #28282c;' "headerbar_backdrop_color: #$PRIMARY_25;"
replace_color "$LIBADWAITA_CSS" 'headerbar_shade_color: rgba(0, 0, 0, 0.36);' "headerbar_shade_color: rgba(0, 0, 0, 0.2);"

# Replace sidebar colors
replace_color "$LIBADWAITA_CSS" 'sidebar_bg_color: #2e2e32;' "sidebar_bg_color: #$PRIMARY_30;"
replace_color "$LIBADWAITA_CSS" 'sidebar_fg_color: #eeeeee;' "sidebar_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'sidebar_backdrop_color: #28282c;' "sidebar_backdrop_color: #$PRIMARY_25;"
replace_color "$LIBADWAITA_CSS" 'sidebar_shade_color: rgba(0, 0, 0, 0.36);' "sidebar_shade_color: rgba(0, 0, 0, 0.2);"

# Replace dialog colors
replace_color "$LIBADWAITA_CSS" 'dialog_bg_color: #36363a;' "dialog_bg_color: #$PRIMARY_40;"
replace_color "$LIBADWAITA_CSS" 'dialog_fg_color: #eeeeee;' "dialog_fg_color: #$PRIMARY_95;"

# Replace popover colors
replace_color "$LIBADWAITA_CSS" 'popover_bg_color: #36363a;' "popover_bg_color: #$PRIMARY_40;"
replace_color "$LIBADWAITA_CSS" 'popover_fg_color: #eeeeee;' "popover_fg_color: #$PRIMARY_95;"

# ==== SPECIALIZED UI COLORS ====

# Button and interactive element colors - making text light for better contrast on dark buttons
replace_color "$LIBADWAITA_CSS" 'button_bg_color: transparent;' "button_bg_color: transparent;"
replace_color "$LIBADWAITA_CSS" 'button_fg_color: #eeeeee;' "button_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'button_active_color: #ffffff;' "button_active_color: #$PRIMARY_95;"

# Destructive/warning/success action colors
replace_color "$LIBADWAITA_CSS" 'destructive_color: #e01b24;' "destructive_color: #$ERROR;"
replace_color "$LIBADWAITA_CSS" 'destructive_bg_color: #c01c28;' "destructive_bg_color: #$ERROR;"
replace_color "$LIBADWAITA_CSS" 'destructive_fg_color: #ffffff;' "destructive_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'success_color: #2ec27e;' "success_color: #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" 'success_bg_color: #26a269;' "success_bg_color: #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" 'success_fg_color: #ffffff;' "success_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'warning_color: #e5a50a;' "warning_color: #$WARNING;"
replace_color "$LIBADWAITA_CSS" 'warning_bg_color: #cd9309;' "warning_bg_color: #$WARNING;"
replace_color "$LIBADWAITA_CSS" 'warning_fg_color: #ffffff;' "warning_fg_color: #$PRIMARY_95;"

# Selection related colors
replace_color "$LIBADWAITA_CSS" 'selected_bg_color: #3584e4;' "selected_bg_color: #$ACCENT;"
replace_color "$LIBADWAITA_CSS" 'selected_fg_color: #ffffff;' "selected_fg_color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" 'backdrop_selected_bg_color: #686868;' "backdrop_selected_bg_color: #$PRIMARY_60;"
replace_color "$LIBADWAITA_CSS" 'backdrop_selected_fg_color: #ffffff;' "backdrop_selected_fg_color: #$PRIMARY_95;"

# Text selection colors
replace_color "$LIBADWAITA_CSS" 'text_selection_color: rgba(52, 132, 228, 0.4);' "text_selection_color: rgba($ACCENT_RGB, 0.3);"
replace_color "$LIBADWAITA_CSS" 'stroke_color: rgba(0, 0, 0, 0.05);' "stroke_color: rgba(0, 0, 0, 0.05);"
replace_color "$LIBADWAITA_CSS" 'suggested_bg_color: #3584e4;' "suggested_bg_color: #$ACCENT;"
replace_color "$LIBADWAITA_CSS" 'suggested_fg_color: #ffffff;' "suggested_fg_color: #$PRIMARY_95;"

# Hover states
replace_color "$LIBADWAITA_CSS" 'hover_color: rgba(255, 255, 255, 0.07);' "hover_color: rgba($PRIMARY_RGB_95, 0.1);"
replace_color "$LIBADWAITA_CSS" 'active_color: rgba(255, 255, 255, 0.15);' "active_color: rgba($PRIMARY_RGB_95, 0.2);"

# Adaptive colors for light and dark modes
replace_color "$LIBADWAITA_CSS" 'light_shadow_color: rgba(0, 0, 0, 0.05);' "light_shadow_color: rgba(0, 0, 0, 0.05);"
replace_color "$LIBADWAITA_CSS" 'shadow_color: rgba(0, 0, 0, 0.15);' "shadow_color: rgba(0, 0, 0, 0.15);"

# ==== UPDATE DIRECT COLOR DEFINITIONS ====

# Update direct Adwaita color definitions first
replace_color "$LIBADWAITA_CSS" '@define-color blue_1 #99c1f1;' "@define-color blue_1 #$PRIMARY_95;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_2 #62a0ea;' "@define-color blue_2 #$PRIMARY_90;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_3 #3584e4;' "@define-color blue_3 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_4 #1c71d8;' "@define-color blue_4 #$ACCENT_DARK;"
replace_color "$LIBADWAITA_CSS" '@define-color blue_5 #1a5fb4;' "@define-color blue_5 #$ACCENT_DARK;"

# Fix all green color variants
replace_color "$LIBADWAITA_CSS" '@define-color green_1 #8ff0a4;' "@define-color green_1 #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" '@define-color green_2 #57e389;' "@define-color green_2 #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" '@define-color green_3 #33d17a;' "@define-color green_3 #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" '@define-color green_4 #2ec27e;' "@define-color green_4 #$SUCCESS;"
replace_color "$LIBADWAITA_CSS" '@define-color green_5 #26a269;' "@define-color green_5 #$SUCCESS;"

# Fix all yellow/orange color variants
replace_color "$LIBADWAITA_CSS" '@define-color yellow_1 #f9f06b;' "@define-color yellow_1 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color yellow_2 #f8e45c;' "@define-color yellow_2 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color yellow_3 #f6d32d;' "@define-color yellow_3 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color yellow_4 #f5c211;' "@define-color yellow_4 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color yellow_5 #e5a50a;' "@define-color yellow_5 #$WARNING;"

replace_color "$LIBADWAITA_CSS" '@define-color orange_1 #ffbe6f;' "@define-color orange_1 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color orange_2 #ffa348;' "@define-color orange_2 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color orange_3 #ff7800;' "@define-color orange_3 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color orange_4 #e66100;' "@define-color orange_4 #$WARNING;"
replace_color "$LIBADWAITA_CSS" '@define-color orange_5 #c64600;' "@define-color orange_5 #$WARNING;"

# Fix all red color variants
replace_color "$LIBADWAITA_CSS" '@define-color red_1 #f66151;' "@define-color red_1 #$ERROR;"
replace_color "$LIBADWAITA_CSS" '@define-color red_2 #ed333b;' "@define-color red_2 #$ERROR;"
replace_color "$LIBADWAITA_CSS" '@define-color red_3 #e01b24;' "@define-color red_3 #$ERROR;"
replace_color "$LIBADWAITA_CSS" '@define-color red_4 #c01c28;' "@define-color red_4 #$ERROR;"
replace_color "$LIBADWAITA_CSS" '@define-color red_5 #a51d2d;' "@define-color red_5 #$ERROR;"

# Fix all purple color variants
replace_color "$LIBADWAITA_CSS" '@define-color purple_1 #dc8add;' "@define-color purple_1 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color purple_2 #c061cb;' "@define-color purple_2 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color purple_3 #9141ac;' "@define-color purple_3 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color purple_4 #813d9c;' "@define-color purple_4 #$ACCENT;"
replace_color "$LIBADWAITA_CSS" '@define-color purple_5 #613583;' "@define-color purple_5 #$ACCENT_DARK;"

# Direct CSS patterns replacement
sed -i "s/@accent_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS"
sed -i "s/@accent_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"
sed -i "s/@theme_selected_bg_color/#$ACCENT/g" "$LIBADWAITA_CSS" 
sed -i "s/@theme_selected_fg_color/#$PRIMARY_95/g" "$LIBADWAITA_CSS"

# ==== FIX FOCUS OUTLINE COLOR ====
# Replace the semi-transparent focus outlines with full solid accent color
echo "Fixing focus outline colors to use solid accent color..."
sed -i "s/outline-color: color-mix(in srgb, var(--accent-color) 50%, transparent);/outline-color: #$ACCENT;/g" "$LIBADWAITA_CSS"
sed -i "s/outline-color: color-mix(in srgb, var(--accent-bg-color) 50%, transparent);/outline-color: #$ACCENT;/g" "$LIBADWAITA_CSS"
sed -i "s/outline-color: color-mix(in srgb, RGB(255 255 255\/75%) 50%, transparent);/outline-color: #$ACCENT;/g" "$LIBADWAITA_CSS"
sed -i "s/outline: 2px solid color-mix(in srgb, var(--accent-color) 50%, transparent);/outline: 2px solid #$ACCENT;/g" "$LIBADWAITA_CSS"

# ==== FIX SCALE COLORS ====
# Change scale/slider background colors and value text colors
echo "Fixing scale/slider track backgrounds and value text..."
sed -i "s/background-color: alpha(currentColor, .15);/background-color: color-mix(in srgb, #$PRIMARY_30 90%, #$ACCENT 10%);/g" "$LIBADWAITA_CSS"
sed -i "s/color: alpha(currentColor, .7);/color: #$PRIMARY_95;/g" "$LIBADWAITA_CSS"
sed -i "s/color: alpha(currentColor, .3);/color: color-mix(in srgb, #$PRIMARY_95 60%, transparent);/g" "$LIBADWAITA_CSS"

# ==== LIBADWAITA-TWEAKS.CSS UPDATES ====

# Apply changes to libadwaita-tweaks.css
replace_color "$LIBADWAITA_TWEAKS" '--accent-bg-color: #3584e4;' "--accent-bg-color: #$ACCENT;"
replace_color "$LIBADWAITA_TWEAKS" '--accent-color: #3584e4;' "--accent-color: #$ACCENT;"
replace_color "$LIBADWAITA_TWEAKS" '--accent-fg-color: #ffffff;' "--accent-fg-color: #$PRIMARY_95;"

replace_color "$LIBADWAITA_TWEAKS" '--window-bg-color: #222226;' "--window-bg-color: #$PRIMARY_20;"
replace_color "$LIBADWAITA_TWEAKS" '--window-fg-color: #eeeeee;' "--window-fg-color: #$PRIMARY_95;"
replace_color "$LIBADWAITA_TWEAKS" '--view-bg-color: #1d1d20;' "--view-bg-color: #$PRIMARY_10;"
replace_color "$LIBADWAITA_TWEAKS" '--view-fg-color: #eeeeee;' "--view-fg-color: #$PRIMARY_95;"

replace_color "$LIBADWAITA_TWEAKS" '--card-bg-color: #28282c;' "--card-bg-color: #$PRIMARY_20;"
replace_color "$LIBADWAITA_TWEAKS" '--card-fg-color: #eeeeee;' "--card-fg-color: #$PRIMARY_95;"

replace_color "$LIBADWAITA_TWEAKS" '--popover-bg-color: #36363a;' "--popover-bg-color: #$PRIMARY_40;"
replace_color "$LIBADWAITA_TWEAKS" '--popover-fg-color: #eeeeee;' "--popover-fg-color: #$PRIMARY_95;"

# Update button text to light color
replace_color "$LIBADWAITA_TWEAKS" '--button-bg-color: transparent;' "--button-bg-color: transparent;"
replace_color "$LIBADWAITA_TWEAKS" '--button-fg-color: #eeeeee;' "--button-fg-color: #$PRIMARY_95;"

# --- Add comprehensive custom styling ---

# Use light text color for buttons to ensure proper contrast on dark backgrounds
BUTTON_FG_COLOR="#$PRIMARY_95"
echo "Using light text for UI elements to ensure contrast"

# Define selection border color variable
SELECTION_BORDER_COLOR="#$ACCENT"
KEYBOARD_FOCUS_COLOR="#$ACCENT" 
echo "Setting focus and selection border colors to #$ACCENT"

# Create comprehensive libadwaita styling
cat > "$USER_THEME_DIR/gtk-4.0/libadwaita-custom.css" << EOF
/* Comprehensive Libadwaita GTK4 Styling - Generated $(date) */

/* --- Core Theme Variables --- */
@define-color accent_color #$ACCENT;
@define-color accent_bg_color #$ACCENT;
@define-color accent_fg_color $BUTTON_FG_COLOR;
@define-color button_color $BUTTON_FG_COLOR;
@define-color focus_border_color #$ACCENT;
@define-color keyboard_focus_outline_color #$ACCENT;

@define-color theme_selected_bg_color #$ACCENT;
@define-color theme_selected_fg_color $BUTTON_FG_COLOR;
@define-color theme_unfocused_selected_bg_color color-mix(in srgb, #$ACCENT 80%, transparent);
@define-color theme_unfocused_selected_fg_color $BUTTON_FG_COLOR;

/* Selection border color */
@define-color selection_border_color $SELECTION_BORDER_COLOR;

/* Button specific colors */
@define-color button_fg_color $BUTTON_FG_COLOR;

/* --- Keyboard Navigation Focus Styling --- */

/* Override all focus-visible outlines with solid accent color */
*:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
  box-shadow: 0 0 0 1px rgba($ACCENT_RGB, 0.8) !important;
}

/* Make focus indicators more noticeable on dark backgrounds */
.is-keyboard-focus,
.keyboard-focus,
.keyboard-activatable:focus-visible,
.keyboard-activatable.keyboard-focus, 
.has-focus {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
  box-shadow: 0 0 0 1px rgba($ACCENT_RGB, 0.8) !important;
}

/* Focus indicators for tabs and lists during keyboard navigation */
tab:focus-visible,
row:focus-visible,
treeview.view:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 0px !important;
}

entry:focus-visible,
button:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 0px !important;
  border-color: #$ACCENT !important;
}

/* --- Scale/Slider Styling --- */
scale {
  color: #$PRIMARY_95;
}

scale trough {
  background-color: #$PRIMARY_40;
  border-radius: 10px;
  min-height: 6px;
  min-width: 6px;
  transition: background-color 0.2s ease;
}

scale.horizontal trough {
  min-height: 6px;
}

scale.vertical trough {
  min-width: 6px; 
}

scale trough highlight {
  background-color: #$ACCENT;
  border-radius: 10px;
}

scale:hover trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 60%, #$ACCENT 40%);
}

scale:hover trough highlight {
  background-color: #$ACCENT;
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

scale marks,
scale value {
  color: #$PRIMARY_95;
}

/* Fix OSD (on-screen display) scales */
scale.osd {
  color: #$PRIMARY_95;
}

scale.osd trough {
  background-color: color-mix(in srgb, #$PRIMARY_20 70%, transparent);
}

scale.osd trough highlight {
  background-color: #$ACCENT;
}

scale.osd marks,
scale.osd value {
  color: #$PRIMARY_95;
}

/* --- Selection Styling --- */
selection {
  background-color: color-mix(in srgb, #$ACCENT 35%, transparent);
  color: $BUTTON_FG_COLOR;
  border: 1px solid color-mix(in srgb, #$ACCENT 60%, transparent);
}

:selected {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR;
  border: 1px solid $SELECTION_BORDER_COLOR;
  outline: 1px solid $SELECTION_BORDER_COLOR;
}

selection:focus-within {
  background-color: color-mix(in srgb, #$ACCENT 50%, transparent);
  color: $BUTTON_FG_COLOR;
  border: 1px solid $SELECTION_BORDER_COLOR;
  outline: 1px solid $SELECTION_BORDER_COLOR;
}

/* Text selection */
entry selection, 
textview selection,
text selection {
  background-color: color-mix(in srgb, #$ACCENT 35%, transparent);
  color: currentColor;
  border: none;
}

/* Selection in lists, trees, and menus */
list row:selected,
treeview.view:selected,
row:selected,
calendar:selected,
flowbox flowboxchild:selected {
  border: 1px solid $SELECTION_BORDER_COLOR;
  outline: 1px solid $SELECTION_BORDER_COLOR;
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR;
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

/* Ensure buttons have proper text contrast and no borders */
button {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
  box-shadow: none !important;
}

button:hover, button:active, button:checked {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}

button label, button box {
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action, button.destructive-action {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}

/* Special styling for buttons with dark backgrounds */
button.osd, 
button.dark,
menubutton.osd > button,
.dark button,
.background.dark button,
button.background.dark,
filechooser #pathbarbox button {
  background-color: #$PRIMARY_30 !important;
  color: #$PRIMARY_95 !important;
}

button.osd:hover, 
button.dark:hover,
menubutton.osd > button:hover,
.dark button:hover,
.background.dark button:hover,
button.background.dark:hover,
filechooser #pathbarbox button:hover {
  background-color: color-mix(in srgb, #$PRIMARY_30 70%, #$ACCENT 30%) !important;
}

button.osd:active, 
button.dark:active,
menubutton.osd > button:active,
.dark button:active,
.background.dark button:active,
button.background.dark:active,
filechooser #pathbarbox button:active {
  background-color: color-mix(in srgb, #$PRIMARY_30 60%, #$ACCENT 40%) !important;
}

button.suggested-action, button.destructive-action {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}
EOF

# Add enhanced GTK4 selection and UI elements styling - replaces previous similar section
cat >> "$LIBADWAITA_CSS" << EOF

/* Enhanced styling for GTK4 UI elements - Added by colorgen */

/* Direct override of all focus-visible outlines with solid accent color */ 
:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
  border-color: #$ACCENT !important;
}

*:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
}

/* Override specific focus-visible elements */
button:focus-visible, 
.button:focus-visible,
modelbutton:focus-visible,
.model-button:focus-visible,
menuitem:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
}

checkbutton:focus-visible,
radiobutton:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
}

/* Ensure all focusable elements have visible focus indicators */
entry:focus-visible, 
textview:focus-visible,
switch:focus-visible,
scale:focus-visible,
spinbutton:focus-visible,
calendar:focus-visible,
tabs tab:focus-visible,
list row:focus-visible,
flowbox flowboxchild:focus-visible {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 0px !important;
}

/* Force high contrast focus for keyboard navigation */
.keyboard-focus, 
.keyboard-activatable:focus, 
.has-focus,
.is-keyboard-focused {
  outline: 3px solid #$ACCENT !important;
  outline-offset: 1px !important;
}

/* Enhanced scale/slider styling */
scale {
  color: #$PRIMARY_95;
  background-color: transparent;
}

scale trough {
  background-color: #$PRIMARY_40;
  border-radius: 6px;
  transition: background-color 0.2s ease;
}

scale trough highlight {
  background-color: #$ACCENT;
}

scale:hover trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 60%, #$ACCENT 40%);
}

scale:active trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 50%, #$ACCENT 50%);
}

scale value, scale marks {
  color: #$PRIMARY_95 !important;
}

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

/* Selection styling with borders */
:selected {
  border: 1px solid #$ACCENT_DARK;
  outline: 1px solid #$ACCENT;
}

list row:selected,
row:selected, 
entry selection,
textview selection,
flowbox flowboxchild:selected {
  border: 1px solid #$ACCENT_DARK;
  outline: 1px solid #$ACCENT;
}

/* Focus styling for inputs */
entry:focus,
textview:focus {
  border: 1px solid #$ACCENT;
  outline: 1px solid #$ACCENT;
}

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

/* Button styling with consistent colors and proper text contrast */
button {
  color: $BUTTON_FG_COLOR !important;
}

button.flat {
  background-color: transparent;
  color: $BUTTON_FG_COLOR !important;
}

button label, button box, button * {
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action {
  background-color: #$ACCENT;
  color: $BUTTON_FG_COLOR !important;
}

button.suggested-action:hover {
  background-color: color-mix(in srgb, #$ACCENT 90%, white);
}

button.destructive-action {
  background-color: #$ERROR;
  color: $BUTTON_FG_COLOR !important;
}

button.destructive-action:hover {
  background-color: color-mix(in srgb, #$ERROR 90%, white);
}

/* Ensure consistent button text color in all states */
button:hover, button:active, button:checked, button:focus, button:disabled {
  color: $BUTTON_FG_COLOR !important;
}

buttonbox, button box, button image, button label {
  color: $BUTTON_FG_COLOR !important;
}

/* Menu and popover styling - no borders */
popover, 
menu, 
.menu, 
.context-menu, 
.popup, 
contextmenu {
  border: none !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3) !important;
}

menuitem:hover, 
.menuitem:hover {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border: 1px solid #$ACCENT_DARK;
}

/* Notebook tabs */
notebook > header > tabs > tab:checked {
  border-bottom: 3px solid #$ACCENT;
}

/* Calendar styling */
calendar:selected {
  background-color: #$ACCENT;
  color: #$PRIMARY_95;
  border-radius: 8px;
  border: 1px solid #$ACCENT_DARK;
}

/* InfoBar styling */
infobar {
  border: 1px solid #$ACCENT;
}

infobar.error {
  background-color: color-mix(in srgb, #$ERROR 30%, #$PRIMARY_20);
  border-color: #$ERROR;
}

infobar.warning {
  background-color: color-mix(in srgb, #$WARNING 30%, #$PRIMARY_20);
  border-color: #$WARNING;
}

infobar.info {
  background-color: color-mix(in srgb, #$ACCENT 30%, #$PRIMARY_20);
  border-color: #$ACCENT;
}
EOF

# Include the custom css file in the main libadwaita.css if not already included
if ! grep -q "@import url('libadwaita-custom.css');" "$LIBADWAITA_CSS"; then
  sed -i '1s/^/@import url("libadwaita-custom.css");\n/' "$LIBADWAITA_CSS"
fi

# Add additional button fixes directly to libadwaita.css
cat >> "$LIBADWAITA_CSS" << EOF

/* Additional button text color fixes */
button, .button {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}

button label, button image, button box, .button label, .button image, .button box {
  color: $BUTTON_FG_COLOR !important;
}

button:hover, button:active, button:checked, button:focus, button:disabled,
.button:hover, .button:active, .button:checked, .button:focus, .button:disabled {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}

button.suggested-action, button.destructive-action, button.accent, headerbar button, actionbar button {
  color: $BUTTON_FG_COLOR !important;
  border: none !important;
}

/* Force light text on any dark buttons */
*:not(.text-button) > button {
  color: $BUTTON_FG_COLOR !important;
}

.titlebar button, .headerbar button {
  color: $BUTTON_FG_COLOR !important;
}

/* Force solid accent color for keyboard navigation focus */
*:focus-visible,
button:focus-visible,
entry:focus-visible,
row:focus-visible,
.keyboard-focus,
.is-keyboard-focused {
  outline-color: #$ACCENT !important;
  outline-width: 3px !important;
  outline-style: solid !important;
  outline-offset: 1px !important;
}

/* Additional scale/slider value text color fixes */
scale {
  color: #$PRIMARY_95 !important;
}

scale value {
  color: #$PRIMARY_95 !important;
  font-weight: bold !important;
}

scale marks label {
  color: #$PRIMARY_95 !important;
}

scale.horizontal value {
  color: #$PRIMARY_95 !important;
}

scale.horizontal marks label {
  color: #$PRIMARY_95 !important;
}

scale.horizontal.marks-after {
  color: #$PRIMARY_95 !important;
}

scale.horizontal.marks-before {
  color: #$PRIMARY_95 !important;
}

scale.vertical value {
  color: #$PRIMARY_95 !important;
}

scale.vertical marks label {
  color: #$PRIMARY_95 !important;
}

scale.osd {
  color: #$PRIMARY_95 !important;
}

scale.osd value {
  color: #$PRIMARY_95 !important;
}
EOF

# Create a direct CSS override file that will be loaded last
cat > "$USER_THEME_DIR/gtk-4.0/focus-fix.css" << EOF
/* Focus outline fixes - will be loaded last to override all other styles */

*:focus-visible {
  outline-color: #$ACCENT !important;
  outline-width: 3px !important;
  outline-style: solid !important;
  outline-offset: 1px !important;
}

.keyboard-focus, 
.keyboard-activatable:focus, 
.has-focus {
  outline-color: #$ACCENT !important;
  outline-width: 3px !important;
  outline-style: solid !important;
}

/* Remove all button borders */
button, 
.button,
button:hover,
button:active,
button:checked,
button:focus,
button:focus-visible,
.button:hover,
.button:active,
.button:checked,
.button:focus,
.button:focus-visible {
  border: none !important;
  box-shadow: none !important;
}

/* Scale/slider value color overrides */
scale,
scale value,
scale marks label {
  color: #$PRIMARY_95 !important;
}

scale trough {
  background-color: #$PRIMARY_40 !important;
}

scale trough highlight {
  background-color: #$ACCENT !important;
}

/* Enhanced Scale hover effects with more visible color change */
scale trough:hover {
  background-color: color-mix(in srgb, #$PRIMARY_40 60%, #$ACCENT 40%) !important;
  transition: background-color 0.2s ease;
}

scale:hover trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 60%, #$ACCENT 40%) !important;
  transition: background-color 0.2s ease;
}

scale:hover trough highlight {
  background-color: #$ACCENT !important;
}

scale:active trough {
  background-color: color-mix(in srgb, #$PRIMARY_40 50%, #$ACCENT 50%) !important;
}

/* Text selection styling with more subtle highlight */
::selection,
::-moz-selection {
  background-color: color-mix(in srgb, #$ACCENT 35%, transparent) !important;
  color: currentColor !important;
}

entry selection, 
textview text selection,
label selection,
.view text selection,
textview:selected,
.selection {
  background-color: color-mix(in srgb, #$ACCENT 35%, transparent) !important;
  color: inherit !important;
  border: none !important;
}

text:selected,
text selection {
  background-color: color-mix(in srgb, #$ACCENT 35%, transparent) !important;
  color: inherit !important;
}

/* Path bar styling */
.path-bar,
.nautilus-path-bar,
.path-bar button,
.location-bar,
.location-entry,
.breadcrumb,
.breadcrumb-button,
filechooser .path-bar button,
.file-chooser-path-bar,
headerbar .path-bar-box,
headerbar pathbar {
  background-color: color-mix(in srgb, #$PRIMARY_20 80%, #$PRIMARY_10 20%) !important;
  color: #$PRIMARY_90 !important;
  border: none !important;
  box-shadow: none !important;
}

/* Special hover styling for dark background elements */
button.osd:hover, 
button.dark:hover,
.dark button:hover,
menubutton.osd > button:hover,
filechooser #pathbarbox button:hover,
.background.dark button:hover,
button.background.dark:hover,
filechooser #pathbarbox > stack > box > button:hover,
filechooser #pathbarbox > stack > box > box > button:hover {
  background: color-mix(in srgb, #$ACCENT 25%, transparent) !important;
}

/* Special active styling for dark background elements */
button.osd:active, 
button.dark:active,
.dark button:active,
menubutton.osd > button:active,
filechooser #pathbarbox button:active,
.background.dark button:active,
button.background.dark:active,
filechooser #pathbarbox > stack > box > button:active,
filechooser #pathbarbox > stack > box > box > button:active {
  background: color-mix(in srgb, #$ACCENT 40%, transparent) !important;
}

.path-bar button,
.nautilus-path-bar button,
pathbar button,
.breadcrumb button,
.file-chooser-path-bar button,
headerbar .path-bar-box button {
  background-color: transparent !important;
  color: #$PRIMARY_90 !important;
  border: none !important;
  box-shadow: none !important;
}

.path-bar button:hover,
pathbar button:hover,
.nautilus-path-bar button:hover,
.breadcrumb button:hover {
  background-color: color-mix(in srgb, #$PRIMARY_30 70%, #$ACCENT 30%) !important;
  color: #$PRIMARY_95 !important;
}
EOF

# Include the focus-fix.css file in the main libadwaita.css if not already included
if ! grep -q "@import url('focus-fix.css');" "$LIBADWAITA_CSS"; then
  echo '@import url("focus-fix.css");' >> "$LIBADWAITA_CSS"
fi

# Create dedicated terminal text styling for system info display
cat > "$USER_THEME_DIR/gtk-4.0/terminal-fixes.css" << EOF
/* Terminal and system info text selection fixes for arch-btw hostname display */

/* Direct terminal selection styling */
terminal::selection,
terminal::-moz-selection,
vte-terminal::selection,
.terminal-window *::selection,
.terminal *::selection {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
  opacity: 0.9 !important;
}

/* System info highlighting - specifically for neofetch/screenfetch type displays */
.system-info .host,
.system-info .hostname,
.terminal-output .hostname,
.neofetch .host,
pre.monospace .highlight,
.host-highlight,
code .highlight,
.highlight-text,
.highlight {
  color: #$PRIMARY_95 !important;
  background-color: #$ACCENT !important;
  font-weight: bold !important;
}

/* More aggressive global selection styling */
*:selected,
*::selection {
  background-color: #$ACCENT !important;
}
EOF

# Include the terminal-fixes.css file in the main libadwaita.css if not already included
if ! grep -q "@import url('terminal-fixes.css');" "$LIBADWAITA_CSS"; then
  echo '@import url("terminal-fixes.css");' >> "$LIBADWAITA_CSS"
fi

# Create dedicated file for terminal-specific colors that will be included by the terminal app
echo "Creating terminal-specific color overrides..."
TERM_COLORS_DIR="$HOME/.config/gtk-4.0"
mkdir -p "$TERM_COLORS_DIR"

# Create a GTK4 CSS file specifically for terminal applications
cat > "$TERM_COLORS_DIR/terminal-colors.css" << EOF
/* Terminal color overrides for text selection and system info highlights */

/* Force text selection in terminal to use accent color */
@define-color terminal_selection_bg #$ACCENT;
@define-color terminal_highlight_bg #$ACCENT;
@define-color terminal_highlight_fg #$PRIMARY_95;

* {
  -terminal-selection-background-color: #$ACCENT;
  -terminal-selection-color: #$PRIMARY_95;
}

terminal selection,
vte-terminal selection,
terminal::selection,
vte-terminal::selection,
terminal::-moz-selection,
vte-terminal::-moz-selection {
  background-color: #$ACCENT !important;
  color: #$PRIMARY_95 !important;
}

/* Specifically target the hostname or other highlighted content in system info displays */
.terminal *::selection,
.terminal-window *::selection {
  background-color: #$ACCENT !important; 
  color: #$PRIMARY_95 !important;
}
EOF

echo "Created terminal color override file at $TERM_COLORS_DIR/terminal-colors.css"
echo "To ensure it's loaded, you may need to add '@import url(\"$TERM_COLORS_DIR/terminal-colors.css\");' to your GTK4 application CSS"

# Create a theme directory link to make sure themes can access terminal overrides
mkdir -p "$USER_THEME_DIR/gtk-4.0/apps"
ln -sf "$TERM_COLORS_DIR/terminal-colors.css" "$USER_THEME_DIR/gtk-4.0/apps/terminal.css"

echo "Libadwaita theme colors applied successfully with improved button text contrast, solid keyboard focus indicators, scale/slider styling, and selection borders!"

# Force all gtk::Button label text to use the darkest extracted color
cat >> "$LIBADWAITA_CSS" << EOF

/* Force all gtk::Button label text to use the darkest extracted color */
button, button label, button * {
    color: #$PRIMARY_0 !important;
}
EOF 