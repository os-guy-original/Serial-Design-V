#!/bin/bash

# gtk.sh - Update Material You colors for GTK themes
# Updates the colors in .themes/serial-design-V* GTK themes

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

# Colors sources
COLORS_CSS="$CONFIG_DIR/colorgen/colors.css"
COLORS_CONF="$CONFIG_DIR/colorgen/colors.conf"

# Check if colors files exist
if [ ! -f "$COLORS_CSS" ]; then
    echo "Error: $COLORS_CSS not found"
    exit 1
fi

if [ ! -f "$COLORS_CONF" ]; then
    echo "Error: $COLORS_CONF not found"
    exit 1
fi

# Find all serial-design theme directories
THEME_DIRS=$(find "$HOME/.themes" -maxdepth 1 -type d -name "serial-design-V*" 2>/dev/null)

if [ -z "$THEME_DIRS" ]; then
    echo "Error: No serial-design-V* themes found in $HOME/.themes"
    exit 1
fi

echo "Updating GTK theme colors..."

# Function to update a GTK CSS file with Material You colors
update_gtk_css() {
    local gtk_file="$1"
    
    # Create backup if it doesn't exist
    local backup_file="${gtk_file}.original"
    if [ ! -f "$backup_file" ]; then
        cp "$gtk_file" "$backup_file"
    fi
    
    # Extract the colors from colors.css
    local PRIMARY=$(grep -E '^\s*--primary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local PRIMARY_CONTAINER=$(grep -E '^\s*--primary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_PRIMARY=$(grep -E '^\s*--on_primary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_PRIMARY_CONTAINER=$(grep -E '^\s*--on_primary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SECONDARY=$(grep -E '^\s*--secondary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SECONDARY_CONTAINER=$(grep -E '^\s*--secondary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_SECONDARY=$(grep -E '^\s*--on_secondary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_SECONDARY_CONTAINER=$(grep -E '^\s*--on_secondary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local TERTIARY=$(grep -E '^\s*--tertiary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local TERTIARY_CONTAINER=$(grep -E '^\s*--tertiary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_TERTIARY=$(grep -E '^\s*--on_tertiary:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_TERTIARY_CONTAINER=$(grep -E '^\s*--on_tertiary_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SURFACE=$(grep -E '^\s*--surface:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SURFACE_VARIANT=$(grep -E '^\s*--surface_variant:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local BACKGROUND=$(grep -E '^\s*--background:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_SURFACE=$(grep -E '^\s*--on_surface:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_SURFACE_VARIANT=$(grep -E '^\s*--on_surface_variant:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_BACKGROUND=$(grep -E '^\s*--on_background:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ERROR=$(grep -E '^\s*--error:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ON_ERROR=$(grep -E '^\s*--on_error:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local ERROR_CONTAINER=$(grep -E '^\s*--error_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local OUTLINE=$(grep -E '^\s*--outline:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local OUTLINE_VARIANT=$(grep -E '^\s*--outline_variant:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SURFACE_CONTAINER=$(grep -E '^\s*--surface_container:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SURFACE_CONTAINER_LOW=$(grep -E '^\s*--surface_container_low:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    local SURFACE_CONTAINER_HIGH=$(grep -E '^\s*--surface_container_high:' "$COLORS_CSS" | sed 's/.*: \(.*\);/\1/')
    
    # Extract accent color from colors.conf (for bright waybar-like styling) - same method as waybar.sh
    local ACCENT=$(grep -E '^accent =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
    # If accent not found in colors.conf, use PRIMARY as fallback
    [ -z "$ACCENT" ] && ACCENT="$PRIMARY"
    
    # For dark/light versions
    local is_dark=false
    if [[ "$gtk_file" == *"-dark.css" ]]; then
        is_dark=true
    fi
    
    # Create custom shade and border colors based on Material You palette
    local SHADE_COLOR="rgba(0, 0, 0, 0.25)"
    if $is_dark; then
        SHADE_COLOR="rgba(0, 0, 0, 0.36)"
    else
        SHADE_COLOR="rgba(0, 0, 0, 0.07)"
    fi
    
    # Define menu-specific colors
    local MENU_BG_COLOR=$SURFACE
    local MENU_FG_COLOR=$ON_SURFACE
    
    # Update the CSS file with the new colors
    # Use temporary file approach to handle large files
    local temp_file=$(mktemp)
    
    # First, do a direct string replacement for context-menu backgrounds
    if $is_dark; then
        # In dark themes, make menus stand out more with slightly lighter BG
        sed -e "s|background-color: @popover_bg_color;|background-color: $SURFACE_CONTAINER_HIGH;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
        
        temp_file=$(mktemp)
        sed -e "s|menu {.*background-color: @popover_bg_color;|menu { background-color: $SURFACE_CONTAINER_HIGH;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
        
        temp_file=$(mktemp)
        sed -e "s|.context-menu {.*background-color: @popover_bg_color;|.context-menu { background-color: $SURFACE_CONTAINER_HIGH;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
    else
        # For light themes
        sed -e "s|background-color: @popover_bg_color;|background-color: $SURFACE;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
        
        temp_file=$(mktemp)
        sed -e "s|menu {.*background-color: @popover_bg_color;|menu { background-color: $SURFACE;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
        
        temp_file=$(mktemp)
        sed -e "s|.context-menu {.*background-color: @popover_bg_color;|.context-menu { background-color: $SURFACE;|g" \
            "$gtk_file" > "$temp_file"
        mv "$temp_file" "$gtk_file"
    fi
    
    # GTK-3 uses straightforward color definitions
    # GTK-4 may use more complex syntax like oklab functions
    temp_file=$(mktemp)
    if [[ "$gtk_file" == *"gtk-3.0"* ]]; then
        # Replace for GTK-3
        sed -e "s|@define-color accent_bg_color .*|@define-color accent_bg_color $PRIMARY;|g" \
            -e "s|@define-color accent_fg_color .*|@define-color accent_fg_color $ON_PRIMARY;|g" \
            -e "s|@define-color accent_color .*|@define-color accent_color $PRIMARY;|g" \
            -e "s|@define-color headerbar_bg_color .*|@define-color headerbar_bg_color $SURFACE;|g" \
            -e "s|@define-color headerbar_fg_color .*|@define-color headerbar_fg_color $ON_SURFACE;|g" \
            -e "s|@define-color headerbar_border_color .*|@define-color headerbar_border_color $OUTLINE;|g" \
            -e "s|@define-color headerbar_shade_color .*|@define-color headerbar_shade_color $SHADE_COLOR;|g" \
            -e "s|@define-color headerbar_backdrop_color .*|@define-color headerbar_backdrop_color $SURFACE_CONTAINER;|g" \
            -e "s|@define-color headerbar_darker_shade_color .*|@define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.4);|g" \
            -e "s|@define-color window_bg_color .*|@define-color window_bg_color $BACKGROUND;|g" \
            -e "s|@define-color window_fg_color .*|@define-color window_fg_color $ON_BACKGROUND;|g" \
            -e "s|@define-color view_bg_color .*|@define-color view_bg_color $SURFACE;|g" \
            -e "s|@define-color view_fg_color .*|@define-color view_fg_color $ON_SURFACE;|g" \
            -e "s|@define-color error_bg_color .*|@define-color error_bg_color $ERROR;|g" \
            -e "s|@define-color error_fg_color .*|@define-color error_fg_color $ON_ERROR;|g" \
            -e "s|@define-color error_color .*|@define-color error_color $ERROR;|g" \
            -e "s|@define-color warning_bg_color .*|@define-color warning_bg_color $TERTIARY;|g" \
            -e "s|@define-color warning_fg_color .*|@define-color warning_fg_color $ON_TERTIARY;|g" \
            -e "s|@define-color warning_color .*|@define-color warning_color $TERTIARY;|g" \
            -e "s|@define-color success_bg_color .*|@define-color success_bg_color $SECONDARY;|g" \
            -e "s|@define-color success_fg_color .*|@define-color success_fg_color $ON_SECONDARY;|g" \
            -e "s|@define-color success_color .*|@define-color success_color $SECONDARY;|g" \
            -e "s|@define-color destructive_bg_color .*|@define-color destructive_bg_color $ERROR;|g" \
            -e "s|@define-color destructive_fg_color .*|@define-color destructive_fg_color $ON_ERROR;|g" \
            -e "s|@define-color destructive_color .*|@define-color destructive_color $ERROR;|g" \
            -e "s|@define-color sidebar_bg_color .*|@define-color sidebar_bg_color $SURFACE_CONTAINER;|g" \
            -e "s|@define-color sidebar_fg_color .*|@define-color sidebar_fg_color $ON_SURFACE;|g" \
            -e "s|@define-color sidebar_backdrop_color .*|@define-color sidebar_backdrop_color $SURFACE_CONTAINER_LOW;|g" \
            -e "s|@define-color sidebar_shade_color .*|@define-color sidebar_shade_color $SHADE_COLOR;|g" \
            -e "s|@define-color sidebar_border_color .*|@define-color sidebar_border_color $OUTLINE;|g" \
            -e "s|@define-color card_bg_color .*|@define-color card_bg_color $SURFACE_VARIANT;|g" \
            -e "s|@define-color card_fg_color .*|@define-color card_fg_color $ON_SURFACE_VARIANT;|g" \
            -e "s|@define-color card_shade_color .*|@define-color card_shade_color $SHADE_COLOR;|g" \
            -e "s|@define-color dialog_bg_color .*|@define-color dialog_bg_color $SURFACE;|g" \
            -e "s|@define-color dialog_fg_color .*|@define-color dialog_fg_color $ON_SURFACE;|g" \
            -e "s|@define-color popover_bg_color .*|@define-color popover_bg_color $SURFACE;|g" \
            -e "s|@define-color popover_fg_color .*|@define-color popover_fg_color $ON_SURFACE;|g" \
            -e "s|@define-color popover_shade_color .*|@define-color popover_shade_color $SHADE_COLOR;|g" \
            -e "s|@define-color shade_color .*|@define-color shade_color $SHADE_COLOR;|g" \
            -e "s|@define-color borders .*|@define-color borders $OUTLINE;|g" \
            -e "s|@define-color unfocused_borders .*|@define-color unfocused_borders $OUTLINE_VARIANT;|g" \
            -e "s|@define-color blue_3 .*|@define-color blue_3 $PRIMARY;|g" \
            -e "s|@define-color blue_4 .*|@define-color blue_4 $PRIMARY_CONTAINER;|g" \
            -e "s|@define-color red_4 .*|@define-color red_4 $ERROR;|g" \
            "$gtk_file" > "$temp_file"
    else
        # Replace for GTK-4
        # For GTK-4, we need to handle the oklab syntax for accent_color
        if $is_dark; then
            # Dark theme
            sed -e "s|@define-color accent_bg_color .*|@define-color accent_bg_color $PRIMARY;|g" \
                -e "s|@define-color accent_fg_color .*|@define-color accent_fg_color $ON_PRIMARY;|g" \
                -e "s|@define-color accent_color .*|@define-color accent_color $PRIMARY;|g" \
                -e "s|@define-color headerbar_bg_color .*|@define-color headerbar_bg_color $SURFACE;|g" \
                -e "s|@define-color headerbar_fg_color .*|@define-color headerbar_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color headerbar_border_color .*|@define-color headerbar_border_color $OUTLINE;|g" \
                -e "s|@define-color headerbar_shade_color .*|@define-color headerbar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color headerbar_backdrop_color .*|@define-color headerbar_backdrop_color $SURFACE_CONTAINER;|g" \
                -e "s|@define-color headerbar_darker_shade_color .*|@define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.4);|g" \
                -e "s|@define-color window_bg_color .*|@define-color window_bg_color $BACKGROUND;|g" \
                -e "s|@define-color window_fg_color .*|@define-color window_fg_color $ON_BACKGROUND;|g" \
                -e "s|@define-color view_bg_color .*|@define-color view_bg_color $SURFACE;|g" \
                -e "s|@define-color view_fg_color .*|@define-color view_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color error_bg_color .*|@define-color error_bg_color $ERROR;|g" \
                -e "s|@define-color error_fg_color .*|@define-color error_fg_color $ON_ERROR;|g" \
                -e "s|@define-color error_color .*|@define-color error_color $ERROR;|g" \
                -e "s|@define-color warning_bg_color .*|@define-color warning_bg_color $TERTIARY;|g" \
                -e "s|@define-color warning_fg_color .*|@define-color warning_fg_color $ON_TERTIARY;|g" \
                -e "s|@define-color warning_color .*|@define-color warning_color $TERTIARY;|g" \
                -e "s|@define-color success_bg_color .*|@define-color success_bg_color $SECONDARY;|g" \
                -e "s|@define-color success_fg_color .*|@define-color success_fg_color $ON_SECONDARY;|g" \
                -e "s|@define-color success_color .*|@define-color success_color $SECONDARY;|g" \
                -e "s|@define-color destructive_bg_color .*|@define-color destructive_bg_color $ERROR;|g" \
                -e "s|@define-color destructive_fg_color .*|@define-color destructive_fg_color $ON_ERROR;|g" \
                -e "s|@define-color destructive_color .*|@define-color destructive_color $ERROR;|g" \
                -e "s|@define-color sidebar_bg_color .*|@define-color sidebar_bg_color $SURFACE_CONTAINER;|g" \
                -e "s|@define-color sidebar_fg_color .*|@define-color sidebar_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color sidebar_backdrop_color .*|@define-color sidebar_backdrop_color $SURFACE_CONTAINER_LOW;|g" \
                -e "s|@define-color sidebar_shade_color .*|@define-color sidebar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color sidebar_border_color .*|@define-color sidebar_border_color $OUTLINE;|g" \
                -e "s|@define-color secondary_sidebar_shade_color .*|@define-color secondary_sidebar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color secondary_sidebar_border_color .*|@define-color secondary_sidebar_border_color $OUTLINE;|g" \
                -e "s|@define-color card_bg_color .*|@define-color card_bg_color $SURFACE_VARIANT;|g" \
                -e "s|@define-color card_fg_color .*|@define-color card_fg_color $ON_SURFACE_VARIANT;|g" \
                -e "s|@define-color card_shade_color .*|@define-color card_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color dialog_bg_color .*|@define-color dialog_bg_color $SURFACE;|g" \
                -e "s|@define-color dialog_fg_color .*|@define-color dialog_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color popover_bg_color .*|@define-color popover_bg_color $SURFACE_CONTAINER_HIGH;|g" \
                -e "s|@define-color popover_fg_color .*|@define-color popover_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color popover_shade_color .*|@define-color popover_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color shade_color .*|@define-color shade_color $SHADE_COLOR;|g" \
                -e "s|--border-opacity: 15%;|--border-opacity: 35%;|g" \
                -e "s|--border-color: color-mix(in srgb, currentColor var(--border-opacity), transparent);|--border-color: $OUTLINE;|g" \
                "$gtk_file" > "$temp_file"
        else
            # Light theme
            sed -e "s|@define-color accent_bg_color .*|@define-color accent_bg_color $PRIMARY;|g" \
                -e "s|@define-color accent_fg_color .*|@define-color accent_fg_color $ON_PRIMARY;|g" \
                -e "s|@define-color accent_color .*|@define-color accent_color oklab(from $PRIMARY min(l, 0.5) a b);|g" \
                -e "s|@define-color headerbar_bg_color .*|@define-color headerbar_bg_color $SURFACE;|g" \
                -e "s|@define-color headerbar_fg_color .*|@define-color headerbar_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color headerbar_border_color .*|@define-color headerbar_border_color $OUTLINE;|g" \
                -e "s|@define-color headerbar_shade_color .*|@define-color headerbar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color headerbar_backdrop_color .*|@define-color headerbar_backdrop_color $SURFACE_CONTAINER;|g" \
                -e "s|@define-color headerbar_darker_shade_color .*|@define-color headerbar_darker_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color window_bg_color .*|@define-color window_bg_color $BACKGROUND;|g" \
                -e "s|@define-color window_fg_color .*|@define-color window_fg_color $ON_BACKGROUND;|g" \
                -e "s|@define-color view_bg_color .*|@define-color view_bg_color $SURFACE;|g" \
                -e "s|@define-color view_fg_color .*|@define-color view_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color error_bg_color .*|@define-color error_bg_color $ERROR;|g" \
                -e "s|@define-color error_fg_color .*|@define-color error_fg_color $ON_ERROR;|g" \
                -e "s|@define-color error_color .*|@define-color error_color $ERROR;|g" \
                -e "s|@define-color warning_bg_color .*|@define-color warning_bg_color $TERTIARY;|g" \
                -e "s|@define-color warning_fg_color .*|@define-color warning_fg_color $ON_TERTIARY;|g" \
                -e "s|@define-color warning_color .*|@define-color warning_color $TERTIARY;|g" \
                -e "s|@define-color success_bg_color .*|@define-color success_bg_color $SECONDARY;|g" \
                -e "s|@define-color success_fg_color .*|@define-color success_fg_color $ON_SECONDARY;|g" \
                -e "s|@define-color success_color .*|@define-color success_color $SECONDARY;|g" \
                -e "s|@define-color destructive_bg_color .*|@define-color destructive_bg_color $ERROR;|g" \
                -e "s|@define-color destructive_fg_color .*|@define-color destructive_fg_color $ON_ERROR;|g" \
                -e "s|@define-color destructive_color .*|@define-color destructive_color $ERROR;|g" \
                -e "s|@define-color sidebar_bg_color .*|@define-color sidebar_bg_color $SURFACE_CONTAINER;|g" \
                -e "s|@define-color sidebar_fg_color .*|@define-color sidebar_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color sidebar_backdrop_color .*|@define-color sidebar_backdrop_color $SURFACE_CONTAINER_LOW;|g" \
                -e "s|@define-color sidebar_shade_color .*|@define-color sidebar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color sidebar_border_color .*|@define-color sidebar_border_color $OUTLINE;|g" \
                -e "s|@define-color secondary_sidebar_shade_color .*|@define-color secondary_sidebar_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color secondary_sidebar_border_color .*|@define-color secondary_sidebar_border_color $OUTLINE;|g" \
                -e "s|@define-color card_bg_color .*|@define-color card_bg_color $SURFACE_VARIANT;|g" \
                -e "s|@define-color card_fg_color .*|@define-color card_fg_color $ON_SURFACE_VARIANT;|g" \
                -e "s|@define-color card_shade_color .*|@define-color card_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color dialog_bg_color .*|@define-color dialog_bg_color $SURFACE;|g" \
                -e "s|@define-color dialog_fg_color .*|@define-color dialog_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color popover_bg_color .*|@define-color popover_bg_color $SURFACE;|g" \
                -e "s|@define-color popover_fg_color .*|@define-color popover_fg_color $ON_SURFACE;|g" \
                -e "s|@define-color popover_shade_color .*|@define-color popover_shade_color $SHADE_COLOR;|g" \
                -e "s|@define-color shade_color .*|@define-color shade_color $SHADE_COLOR;|g" \
                -e "s|--border-opacity: 15%;|--border-opacity: 35%;|g" \
                -e "s|--border-color: color-mix(in srgb, currentColor var(--border-opacity), transparent);|--border-color: $OUTLINE;|g" \
                "$gtk_file" > "$temp_file"
        fi
    fi
    
    # Apply the variable changes
    mv "$temp_file" "$gtk_file"
    
    # Now let's directly manipulate the menu CSS for context menus and dropdown menus
    # This is a more direct approach for the actual menu elements that might not use the color variables
    
    # For dark theme with better contrast
    if $is_dark; then
        # Apply direct CSS modifications for menu elements
        temp_file=$(mktemp)
        
        # Set background-color directly for context menus and dropdown menus
        sed -e "/\.context-menu {/,/}/ s/background-color: .*/background-color: $SURFACE_CONTAINER_HIGH;/" \
            -e "/menu {/,/}/ s/background-color: .*/background-color: $SURFACE_CONTAINER_HIGH;/" \
            -e "/popover.menu {/,/}/ s/background-color: .*/background-color: $SURFACE_CONTAINER_HIGH;/" \
            -e "/dropdown.menu {/,/}/ s/background-color: .*/background-color: $SURFACE_CONTAINER_HIGH;/" \
            -e "/combobox menu {/,/}/ s/background-color: .*/background-color: $SURFACE_CONTAINER_HIGH;/" \
            "$gtk_file" > "$temp_file"
        
        mv "$temp_file" "$gtk_file"
    else
        # For light theme
        temp_file=$(mktemp)
        
        # Set background-color directly for context menus and dropdown menus
        sed -e "/\.context-menu {/,/}/ s/background-color: .*/background-color: $SURFACE;/" \
            -e "/menu {/,/}/ s/background-color: .*/background-color: $SURFACE;/" \
            -e "/popover.menu {/,/}/ s/background-color: .*/background-color: $SURFACE;/" \
            -e "/dropdown.menu {/,/}/ s/background-color: .*/background-color: $SURFACE;/" \
            -e "/combobox menu {/,/}/ s/background-color: .*/background-color: $SURFACE;/" \
            "$gtk_file" > "$temp_file"
        
        mv "$temp_file" "$gtk_file"
    fi
    
    # Let's also add a direct override for the places sidebar
    temp_file=$(mktemp)
    echo "
/* Direct override for places sidebar */
.places-sidebar,
.navigation-sidebar,
.sidebar,
placessidebar,
placessidebar list,
placessidebar row,
.sidebar-pane,
.sidebar-pane list,
.sidebar-pane row {
    background-color: $SURFACE_CONTAINER;
    color: $ON_SURFACE;
}
" >> "$gtk_file"
    
    # Special handling for placessidebar in nautilus
    echo "
/* Specific fixes for nautilus placessidebar */
placessidebar {
    background-color: $SURFACE_CONTAINER;
}

placessidebar > viewport.frame {
    background-color: $SURFACE_CONTAINER;
}

placessidebar scrolledwindow {
    background-color: $SURFACE_CONTAINER;
}

placessidebar row {
    background-color: $SURFACE_CONTAINER;
    color: $ON_SURFACE;
}

placessidebar row:selected {
    background-color: alpha($PRIMARY, 0.7);
    color: $ON_PRIMARY;
}
" >> "$gtk_file"

    # If this is a GTK4 CSS file, add specific entries for text entry borders and buttons
    if [[ "$gtk_file" == *"gtk-4.0"* ]]; then
        echo "
/* GTK4 specific overrides for entry borders and buttons */
entry, spinbutton {
    outline: 1px solid $OUTLINE !important;
    background-color: color-mix(in srgb, $SURFACE 95%, transparent) !important;
    border-color: $OUTLINE !important;
}

entry:focus-within, spinbutton:focus-within {
    outline: 2px solid $ACCENT !important;
    border-color: $ACCENT !important;
}

button.suggested-action {
    color: $ON_PRIMARY !important;
    background-color: $ACCENT !important;
    border: 1px solid shade($ACCENT, 0.8) !important;
}

button.suggested-action:hover {
    background-color: shade($ACCENT, 1.1) !important;
}

button.suggested-action:active {
    background-color: shade($ACCENT, 0.9) !important;
}

button.destructive-action {
    color: $ON_ERROR !important;
    background-color: $ERROR !important;
    border: 1px solid color-mix(in srgb, $ERROR 80%, black) !important;
}

button.destructive-action:hover {
    background-color: color-mix(in srgb, $ERROR 90%, white) !important;
}

button.destructive-action:active {
    background-color: color-mix(in srgb, $ERROR 80%, black) !important;
}

button {
    color: $ON_SURFACE !important;
    background-color: $ACCENT !important;
    border: 1px solid color-mix(in srgb, $ACCENT 80%, black) !important;
}

button:hover {
    background-color: color-mix(in srgb, $ACCENT 90%, white) !important;
}

button:active {
    background-color: color-mix(in srgb, $ACCENT 80%, black) !important;
}

/* Ensure text area and input fields have proper borders */
textview > border {
    border: 1px solid $OUTLINE !important;
}

textview > text {
    background-color: color-mix(in srgb, $SURFACE 90%, transparent) !important;
}

textview:focus-within > border {
    border: 2px solid $ACCENT !important;
}

/* Style dialog buttons and default action buttons */
button.suggested-action {
    color: $ON_PRIMARY !important;
    background-color: $ACCENT !important;
    border: 1px solid shade($ACCENT, 0.8) !important;
}

button.suggested-action:hover {
    background-color: shade($ACCENT, 1.1) !important;
}

button.suggested-action:active {
    background-color: shade($ACCENT, 0.9) !important;
}

button.default-action {
    color: $ON_PRIMARY !important;
    background-color: $ACCENT !important;
    border: 1px solid shade($ACCENT, 0.8) !important;
}

button.default-action:hover {
    background-color: shade($ACCENT, 1.1) !important;
}

button.default-action:active {
    background-color: shade($ACCENT, 0.9) !important;
}

/* Ensure dialog default buttons in Nautilus get the accent color */
dialog button:default {
    color: $ON_PRIMARY !important;
    background-color: $ACCENT !important;
    border: 1px solid shade($ACCENT, 0.8) !important;
}

dialog button:default:hover {
    background-color: shade($ACCENT, 1.1) !important;
}

dialog button:default:active {
    background-color: shade($ACCENT, 0.9) !important;
}

/* Destructive action buttons */
button.destructive-action {
    color: $ON_ERROR !important;
    background-color: $ERROR !important;
    border: 1px solid color-mix(in srgb, $ERROR 80%, black) !important;
}

button.destructive-action:hover {
    background-color: color-mix(in srgb, $ERROR 90%, white) !important;
}

button.destructive-action:active {
    background-color: color-mix(in srgb, $ERROR 80%, black) !important;
}

/* Update hardcoded blue color references */
:root {
    --blue-1: $ACCENT !important;
    --blue-2: $ACCENT !important;
    --blue-3: $ACCENT !important;
    --accent-blue: $ACCENT !important;
}

@define-color blue_1 $ACCENT;
@define-color blue_2 $ACCENT;
@define-color blue_3 $ACCENT;
@define-color blue_4 $ACCENT;
@define-color blue_5 color-mix(in srgb, $ACCENT 95%, black);
" >> "$gtk_file"
    fi
    
    echo "  Updated: $gtk_file"
}

# Process each theme directory
for theme_dir in $THEME_DIRS; do
    echo "Processing theme: $(basename "$theme_dir")"
    
    # Find all GTK CSS files
    gtk_files=$(find "$theme_dir" -type f -name "gtk*.css")
    
    for gtk_file in $gtk_files; do
        update_gtk_css "$gtk_file"
    done
done

echo "GTK theme colors updated successfully!"

# Force immediate theme reload
echo "Forcing immediate theme reload..."

# Get current theme name
CURRENT_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
if [ $? -eq 0 ]; then
    # If gsettings is available, toggle the theme
    CURRENT_THEME=$(echo "$CURRENT_THEME" | tr -d "'")
    
    # Try to find an alternate theme to switch to temporarily
    if [ "$CURRENT_THEME" = "serial-design-V" ]; then
        ALT_THEME="serial-design-V-dark"
    elif [ "$CURRENT_THEME" = "serial-design-V-dark" ]; then
        ALT_THEME="serial-design-V"
    else
        # If we can't determine, try to set Adwaita and then back
        ALT_THEME="Adwaita"
    fi
    
    # Toggle between themes to force a reload
    gsettings set org.gnome.desktop.interface gtk-theme "$ALT_THEME" 2>/dev/null
    sleep 0.2
    gsettings set org.gnome.desktop.interface gtk-theme "$CURRENT_THEME" 2>/dev/null
    
    # Explicitly set GTK3 theme for compatibility
    gsettings set org.gnome.desktop.interface gtk3-theme "$CURRENT_THEME" 2>/dev/null
    
    # Also try with xfconf if available (for XFCE)
    if command -v xfconf-query >/dev/null 2>&1; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "$ALT_THEME" 2>/dev/null
        sleep 0.2
        xfconf-query -c xsettings -p /Net/ThemeName -s "$CURRENT_THEME" 2>/dev/null
    fi
fi

# Touch the GTK CSS cache files to force reload
find ~/.cache -name "*.css" -type f -exec touch {} \; 2>/dev/null
find ~/.cache -name "gtk-3.0" -type d -exec touch {} \; 2>/dev/null
find ~/.cache -name "gtk-4.0" -type d -exec touch {} \; 2>/dev/null

# Clear GTK3 immodules cache to force reload
rm -f ~/.cache/immodules/immodules.cache 2>/dev/null

# Send signal to GTK apps to reload themes (for GTK3)
kill -HUP $(pidof gsd-xsettings) 2>/dev/null
killall -HUP gtk-update-icon-cache 2>/dev/null

# Alternative method - touch the theme directory timestamps to signal changes
find ~/.themes -name "serial-design-V*" -type d -exec touch {} \; 2>/dev/null
find ~/.themes -name "gtk-3.0" -type d -exec touch {} \; 2>/dev/null
find ~/.local/share/themes -name "serial-design-V*" -type d -exec touch {} \; 2>/dev/null

# Try system-wide theme directories as well
if [ -d /usr/share/themes ]; then
    sudo find /usr/share/themes -name "serial-design-V*" -type d -exec touch {} \; 2>/dev/null
fi

exit 0 