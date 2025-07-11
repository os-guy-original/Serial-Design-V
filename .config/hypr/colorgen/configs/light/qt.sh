#!/bin/bash

# ============================================================================
# QT Light Theme Application Script for Hyprland Colorgen
# 
# This script applies the Material You light theme settings to QT/Kvantum
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
TEMPLATE_DIR="$COLORGEN_DIR/templates/Kvantum"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR/generated/kvantum"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying QT/Kvantum light theme with Material You colors"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    log "ERROR" "Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Create MaterialAdw directory if it doesn't exist
KVANTUM_MATERIAL_DIR="$XDG_CONFIG_HOME/Kvantum/MaterialAdw"
mkdir -p "$KVANTUM_MATERIAL_DIR"

# Function to replace color in SVG file
replace_color() {
    local file=$1
    local old_color=$2
    local new_color=$3
    
    # Use sed to replace the color in the SVG file
    sed -i "s/$old_color/$new_color/gI" "$file"
}

# Function to replace color in kvconfig file
replace_kvconfig_color() {
    local file=$1
    local setting=$2
    local new_color=$3
    
    # Use sed to replace the color setting in the kvconfig file
    sed -i "s/^$setting=.*/$setting=$new_color/" "$file"
}

# Extract color variables from colors.json
if [ -f "$COLORGEN_DIR/colors.json" ]; then
    # Create a function to safely get color values with fallbacks
    get_color() {
        local palette=$1
        local color_name=$2
        local fallback=$3
        local value
        
        value=$(jq -r ".colors.$palette.$color_name" "$COLORGEN_DIR/colors.json")
        if [ "$value" = "null" ] || [ -z "$value" ]; then
            echo "$fallback"
        else
            echo "$value"
        fi
    }
    
    log "INFO" "Applying light theme for QT"
    
    # Copy the light Kvantum config
    cp "$TEMPLATE_DIR/Colloid/Colloid.kvconfig" "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Copy the SVG for modification
    cp "$TEMPLATE_DIR/Colloid/Colloid.svg" "$CACHE_DIR/generated/kvantum/MaterialAdw.svg"
    
    # Extract colors from light palette with fallbacks
    primary=$(get_color "light" "primary" "#884b6b")
    shadow=$(get_color "light" "shadow" "#000000")
    error=$(get_color "light" "error" "#ba1a1a")
    primary_fixed_dim=$(get_color "light" "primary_fixed_dim" "#fcb0d5")
    background=$(get_color "light" "background" "#fff8f8")
    on_primary_fixed=$(get_color "light" "on_primary_fixed" "#380726")
    inverse_surface=$(get_color "light" "inverse_surface" "#372e32")
    on_secondary_fixed=$(get_color "light" "on_secondary_fixed" "#291520")
    secondary_container=$(get_color "light" "secondary_container" "#fdd9e8")
    surface_container_highest=$(get_color "light" "surface_container_highest" "#eedfe3")
    on_background=$(get_color "light" "on_background" "#21191d")
    on_surface=$(get_color "light" "on_surface" "#21191d")
    on_primary=$(get_color "light" "on_primary" "#ffffff")
    surface_variant=$(get_color "light" "surface_variant" "#f1dee4")
    surface_container_lowest=$(get_color "light" "surface_container_lowest" "#ffffff")
    surface_container_low=$(get_color "light" "surface_container_low" "#fff0f4")
    
    # Replace colors in the SVG
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#3c84f7" "$primary"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#000000" "$shadow"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#f04a50" "$error"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#4285f4" "$primary_fixed_dim"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#f2f2f2" "$background"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#ffffff" "$background"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#1e1e1e" "$on_primary_fixed"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#333" "$inverse_surface"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#212121" "$on_secondary_fixed"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#5b9bf8" "$secondary_container"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#26272a" "$surface_container_highest"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#444444" "$on_background"
    replace_color "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "#333333" "$on_primary_fixed"
    
    # Update background color in the kvconfig file
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "bg.color" "$background"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "base.color" "$background"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "alt.base.color" "$surface_container_low"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "inactive.base.color" "$background"
    
    # Update highlight/selection colors
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "highlight.color" "$primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "highlight.text.color" "#000000"  # Dark text for selected items in light theme
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "inactive.highlight.color" "$primary_fixed_dim"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "view.hover.color" "$primary_fixed_dim"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "view.selected.color" "$primary"
    
    # Update text colors
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "text.color" "$on_background"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "window.text.color" "$on_background"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "button.text.color" "$on_background"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "inactive.text.color" "$surface_variant"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "view.text.color" "$on_background"
    
    # Update button colors
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "button.color" "$surface_container_low"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "button.focus.color" "$primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "button.focus.text.color" "#000000"  # Dark text on focused buttons for light theme
    
    # Update PanelButtonCommand text colors for better active button contrast
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "text.focus.color" "#FFFFFF"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "text.press.color" "#FFFFFF"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "text.toggle.color" "#FFFFFF"
    
    # Update PanelButtonTool text colors for better active button contrast
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "PanelButtonTool]" -e "s/text.focus.color=.*/text.focus.color=#FFFFFF/"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "PanelButtonTool]" -e "s/text.press.color=.*/text.press.color=#FFFFFF/"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "PanelButtonTool]" -e "s/text.toggle.color=.*/text.toggle.color=#FFFFFF/"
    
    # Update ToolbarButton text colors for better active button contrast
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "ToolbarButton]" -e "s/text.focus.color=.*/text.focus.color=#FFFFFF/"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "ToolbarButton]" -e "s/text.press.color=.*/text.press.color=#FFFFFF/"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "ToolbarButton]" -e "s/text.toggle.color=.*/text.toggle.color=#FFFFFF/"
    
    # Update progress bar colors
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.color" "$primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.text.color" "$on_primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.indicator.text.color" "$on_primary"
    
    # Update menu item hover colors for right-click menus
    log "INFO" "Updating menu item hover colors for right-click menus"
    # Create a more direct approach for menu hover colors
    log "INFO" "Using direct approach for menu hover colors in light theme"
    
    # Create a temporary file with our custom MenuItem section
    cat > /tmp/menuitem_section.txt << EOF
[MenuItem]
inherits=PanelButtonCommand
frame=true
frame.element=menuitem
interior.element=menuitem
indicator.element=menuitem
text.normal.color=#000000
text.focus.color=#000000
text.margin.top=0
text.margin.bottom=0
text.margin.left=6
text.margin.right=6
frame.top=4
frame.bottom=4
frame.left=4
frame.right=4
text.bold=false
frame.expansion=0
interior.focus.color=$primary
EOF

    # Replace the entire MenuItem section in the kvconfig file
    sed -i '/\[MenuItem\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/menuitem_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Create a temporary file with our custom Menu section
    cat > /tmp/menu_section.txt << EOF
[Menu]
inherits=PanelButtonCommand
frame.top=10
frame.bottom=10
frame.left=10
frame.right=10
frame.element=menu
interior.element=menu
text.normal.color=#000000
text.shadow=false
frame.expansion=0
text.bold=false
EOF

    # Replace the entire Menu section in the kvconfig file
    sed -i '/\[Menu\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/menu_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Clean up temporary files
    rm -f /tmp/menuitem_section.txt /tmp/menu_section.txt
    
    # Ensure menu text color is dark for better readability in light theme
    sed -i '/\[MenuItem\]/,/\[/ s/text.normal.color=.*/text.normal.color=#000000/' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    sed -i '/\[Menu\]/,/\[/ s/text.normal.color=.*/text.normal.color=#000000/' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Create a temporary file with our custom MenuBarItem section
    cat > /tmp/menubaritem_section.txt << EOF
[MenuBarItem]
inherits=PanelButtonCommand
interior=true
interior.element=menubaritem
frame.element=menubaritem
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
text.margin.left=4
text.margin.right=4
text.margin.top=0
text.margin.bottom=0
text.normal.color=#000000
text.focus.color=#000000
text.press.color=#000000
text.toggle.color=#000000
interior.focus.color=$primary
text.bold=false
min_width=+0.3font
min_height=+0.3font
frame.expansion=0
EOF

    # Replace the entire MenuBarItem section in the kvconfig file
    sed -i '/\[MenuBarItem\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/menubaritem_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Clean up temporary file
    rm -f /tmp/menubaritem_section.txt
    
    # Create a temporary file with our custom PanelButtonCommand section
    cat > /tmp/panelbuttoncommand_section.txt << EOF
[PanelButtonCommand]
frame=true
frame.element=button
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
interior=true
interior.element=button
indicator.size=8
text.normal.color=#000000
text.focus.color=#000000
text.press.color=#000000
text.toggle.color=#000000
text.shadow=0
text.margin=4
text.iconspacing=4
indicator.element=arrow
frame.expansion=0
interior.focus.color=$primary
interior.press.color=$primary
interior.toggle.color=$primary
EOF

    # Replace the entire PanelButtonCommand section in the kvconfig file
    sed -i '/\[PanelButtonCommand\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/panelbuttoncommand_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Clean up temporary file
    rm -f /tmp/panelbuttoncommand_section.txt
    
    # Create a temporary file with our custom PanelButtonTool section
    cat > /tmp/panelbuttontool_section.txt << EOF
[PanelButtonTool]
inherits=PanelButtonCommand
text.normal.color=#000000
text.focus.color=#000000
text.press.color=#000000
text.toggle.color=#000000
text.bold=false
indicator.element=arrow
indicator.size=8
frame.expansion=0
EOF

    # Replace the entire PanelButtonTool section in the kvconfig file
    sed -i '/\[PanelButtonTool\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/panelbuttontool_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Clean up temporary file
    rm -f /tmp/panelbuttontool_section.txt
    
    # Create a temporary file with our custom ToolbarButton section
    cat > /tmp/toolbarbutton_section.txt << EOF
[ToolbarButton]
frame=true
frame.element=tbutton
interior.element=tbutton
frame.top=14
frame.bottom=14
frame.left=14
frame.right=14
indicator.element=tarrow
text.normal.color=#000000
text.focus.color=#000000
text.press.color=#000000
text.toggle.color=#000000
text.bold=false
frame.expansion=28
interior.focus.color=$primary
interior.press.color=$primary
interior.toggle.color=$primary
EOF

    # Replace the entire ToolbarButton section in the kvconfig file
    sed -i '/\[ToolbarButton\]/,/\[/c\\' "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    cat /tmp/toolbarbutton_section.txt >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    echo "" >> "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig"
    
    # Clean up temporary file
    rm -f /tmp/toolbarbutton_section.txt
    
    # Set style to kvantum (light)
    qt_style="kvantum"
    
    # Remove existing MaterialAdw files if they exist
    rm -f "$KVANTUM_MATERIAL_DIR/MaterialAdw.kvconfig" "$KVANTUM_MATERIAL_DIR/MaterialAdw.svg"
    
    # Copy the modified files to the Kvantum theme directory
    cp "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "$KVANTUM_MATERIAL_DIR/MaterialAdw.kvconfig"
    cp "$CACHE_DIR/generated/kvantum/MaterialAdw.svg" "$KVANTUM_MATERIAL_DIR/MaterialAdw.svg"
    
    # Set Kvantum theme
    echo "[General]
theme=MaterialAdw" > "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig"
    
    log "INFO" "QT/Kvantum light theme applied successfully"
    
    # Create QT color scheme directory
    mkdir -p "$CACHE_DIR/generated/qt"
    
    # Create QT color scheme file with dark text for selected items
    cat > "$CACHE_DIR/generated/qt/style-colors.conf" << EOF
[ColorScheme]
active_colors=#ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff000000, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${on_surface:1}, #ff${surface_container_lowest:1}, #ff${on_surface:1}, #ff${on_surface:1}
disabled_colors=#ff${surface_variant:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${surface_variant:1}, #ff${on_surface:1}, #ff${surface_variant:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff${background:1}, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${surface_variant:1}, #ff${surface_container_lowest:1}, #ff${surface_variant:1}, #ff${surface_variant:1}
inactive_colors=#ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff000000, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${on_surface:1}, #ff${surface_container_lowest:1}, #ff${on_surface:1}, #ff${on_surface:1}
EOF
    
    # Copy the color scheme to QT5 and QT6 directories
    mkdir -p "$XDG_CONFIG_HOME/qt5ct/colors"
    mkdir -p "$XDG_CONFIG_HOME/qt6ct/colors"
    cp "$CACHE_DIR/generated/qt/style-colors.conf" "$XDG_CONFIG_HOME/qt5ct/colors/material-you.conf"
    cp "$CACHE_DIR/generated/qt/style-colors.conf" "$XDG_CONFIG_HOME/qt6ct/colors/material-you.conf"
    
else
    log "ERROR" "colors.json not found: $COLORGEN_DIR/colors.json"
    exit 1
fi

# Get icon theme from file if it exists, otherwise use default for light theme
icon_theme="Fluent"  # Default to light icon theme
if [ -f "$COLORGEN_DIR/icon_theme.txt" ]; then
    icon_theme_from_file=$(head -n 1 "$COLORGEN_DIR/icon_theme.txt" | tr -d '\n')
    # If not empty, use the icon theme from file but ensure it's the light version
    if [ -n "$icon_theme_from_file" ]; then
        # Remove any "-dark" suffix and use the light version
        icon_theme=$(echo "$icon_theme_from_file" | sed 's/-dark$//')
    fi
fi

# Configure QT5 settings
mkdir -p "$XDG_CONFIG_HOME/qt5ct"
cat > "$XDG_CONFIG_HOME/qt5ct/qt5ct.conf" << EOF
[Appearance]
color_scheme_path=$XDG_CONFIG_HOME/qt5ct/colors/material-you.conf
custom_palette=true
icon_theme=$icon_theme
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="Noto Sans,10,-1,5,50,0,0,0,0,0"
general="Noto Sans,10,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
EOF

# Configure QT6 settings
mkdir -p "$XDG_CONFIG_HOME/qt6ct"
cat > "$XDG_CONFIG_HOME/qt6ct/qt6ct.conf" << EOF
[Appearance]
color_scheme_path=$XDG_CONFIG_HOME/qt6ct/colors/material-you.conf
custom_palette=true
icon_theme=$icon_theme
standard_dialogs=default
style=$qt_style

[Fonts]
fixed="Noto Sans,10,-1,5,50,0,0,0,0,0,0,0,0,0,0,1,Regular"
general="Noto Sans,10,-1,5,50,0,0,0,0,0,0,0,0,0,0,1,Regular"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
EOF

# Update Dolphin configuration for progress bars and selection rectangles
DOLPHIN_CONFIG="$XDG_CONFIG_HOME/dolphinrc"
if [ -f "$DOLPHIN_CONFIG" ]; then
    log "INFO" "Updating Dolphin configuration"
    
    # Create a backup of the original config
    cp "$DOLPHIN_CONFIG" "$DOLPHIN_CONFIG.bak"
    
    # Update or add the [Colors] section
    if grep -q "\[Colors\]" "$DOLPHIN_CONFIG"; then
        # Section exists, update values
        sed -i "/\[Colors\]/,/\[.*\]/ s/^HighlightedText=.*/HighlightedText=$on_primary/" "$DOLPHIN_CONFIG"
        sed -i "/\[Colors\]/,/\[.*\]/ s/^Highlight=.*/Highlight=$primary/" "$DOLPHIN_CONFIG"
        sed -i "/\[Colors\]/,/\[.*\]/ s/^VisitedLink=.*/VisitedLink=$primary_fixed_dim/" "$DOLPHIN_CONFIG"
        sed -i "/\[Colors\]/,/\[.*\]/ s/^Link=.*/Link=$primary/" "$DOLPHIN_CONFIG"
    else
        # Section doesn't exist, add it
        echo -e "\n[Colors]" >> "$DOLPHIN_CONFIG"
        echo "Highlight=$primary" >> "$DOLPHIN_CONFIG"
        echo "HighlightedText=$on_primary" >> "$DOLPHIN_CONFIG"
        echo "Link=$primary" >> "$DOLPHIN_CONFIG"
        echo "VisitedLink=$primary_fixed_dim" >> "$DOLPHIN_CONFIG"
    fi
    
    # Update or add the [PreviewSettings] section for usage indicators
    if grep -q "\[PreviewSettings\]" "$DOLPHIN_CONFIG"; then
        # Section exists, update values
        sed -i "/\[PreviewSettings\]/,/\[.*\]/ s/^UseCustomColors=.*/UseCustomColors=true/" "$DOLPHIN_CONFIG"
        sed -i "/\[PreviewSettings\]/,/\[.*\]/ s/^UsedCapacityColor=.*/UsedCapacityColor=$primary/" "$DOLPHIN_CONFIG"
        sed -i "/\[PreviewSettings\]/,/\[.*\]/ s/^FreeSpaceColor=.*/FreeSpaceColor=$surface_variant/" "$DOLPHIN_CONFIG"
    else
        # Section doesn't exist, add it
        echo -e "\n[PreviewSettings]" >> "$DOLPHIN_CONFIG"
        echo "UseCustomColors=true" >> "$DOLPHIN_CONFIG"
        echo "UsedCapacityColor=$primary" >> "$DOLPHIN_CONFIG"
        echo "FreeSpaceColor=$surface_variant" >> "$DOLPHIN_CONFIG"
    fi
    
    log "INFO" "Dolphin configuration updated"
fi

# Apply icon theme using environment variables
if command -v hyprctl >/dev/null 2>&1; then
    log "INFO" "Setting QT_ICON_THEME via Hyprland environment variable"
    hyprctl keyword env QT_ICON_THEME="$icon_theme"
fi

# Set environment variable for current session
export QT_ICON_THEME="$icon_theme"

log "INFO" "QT light theme configuration completed" 