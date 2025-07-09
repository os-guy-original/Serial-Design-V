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
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "highlight.text.color" "$on_primary"
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
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "button.focus.text.color" "$on_primary"
    
    # Update progress bar colors
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.color" "$primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.text.color" "$on_primary"
    replace_kvconfig_color "$CACHE_DIR/generated/kvantum/MaterialAdw.kvconfig" "progressbar.indicator.text.color" "$on_primary"
    
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
    
    # Create QT color scheme file
    cat > "$CACHE_DIR/generated/qt/style-colors.conf" << EOF
[ColorScheme]
active_colors=#ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff${on_primary:1}, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${on_surface:1}, #ff${surface_container_lowest:1}, #ff${on_surface:1}, #ff${on_surface:1}
disabled_colors=#ff${surface_variant:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${surface_variant:1}, #ff${on_surface:1}, #ff${surface_variant:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff${background:1}, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${surface_variant:1}, #ff${surface_container_lowest:1}, #ff${surface_variant:1}, #ff${surface_variant:1}
inactive_colors=#ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${surface_container_low:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${on_surface:1}, #ff${background:1}, #ff${background:1}, #ff${surface_container_lowest:1}, #ff${primary:1}, #ff${on_primary:1}, #ff${primary:1}, #ff${error:1}, #ff${background:1}, #ff${on_surface:1}, #ff${surface_container_lowest:1}, #ff${on_surface:1}, #ff${on_surface:1}
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