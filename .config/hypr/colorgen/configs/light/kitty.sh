#!/bin/bash

# ============================================================================
# Advanced Kitty Terminal Light Theme Generator
# 
# Features:
# - Uses the same colors as dark mode but darkens them for light background
# - Preserves color identity but adjusts intensity for better visibility
# - Dynamic time-based adjustments
# - Maintains consistent color palette across themes
# ============================================================================

# Colors source
COLORS_CONF="$HOME/.config/hypr/colorgen/colors.conf"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"
CACHE_DIR="$HOME/.config/hypr/cache"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if colors file exists
if [ ! -f "$COLORS_CONF" ]; then
    echo "Error: $COLORS_CONF not found"
    exit 1
fi

# Check if kitty config exists
if [ ! -f "$KITTY_CONFIG" ]; then
    echo "Error: $KITTY_CONFIG not found. Is kitty installed?"
    mkdir -p "$(dirname "$KITTY_CONFIG")"
    touch "$KITTY_CONFIG"
    echo "Created empty kitty config at $KITTY_CONFIG"
fi

echo "🎨 Generating light theme for kitty terminal (with darker accent colors)..."

# Create a backup of the config if it doesn't exist
BACKUP_FILE="${KITTY_CONFIG}.original"
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$KITTY_CONFIG" "$BACKUP_FILE"
    echo "Created backup of kitty config at $BACKUP_FILE"
fi

# Read colors from colors.conf - same as dark mode
primary=$(grep -E '^primary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent=$(grep -E '^accent =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_dark=$(grep -E '^accent_dark =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_light=$(grep -E '^accent_light =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
secondary=$(grep -E '^secondary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
tertiary=$(grep -E '^tertiary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
error=$(grep -E '^error =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color0=$(grep -E '^color0 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color1=$(grep -E '^color1 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color2=$(grep -E '^color2 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color3=$(grep -E '^color3 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color4=$(grep -E '^color4 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color5=$(grep -E '^color5 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color6=$(grep -E '^color6 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color7=$(grep -E '^color7 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# Set defaults if not found
[ -z "$primary" ] && primary="#ff00ff"
[ -z "$accent" ] && accent="#ff00aa"
[ -z "$accent_dark" ] && accent_dark="#cc0088"
[ -z "$accent_light" ] && accent_light="#ff55cc"
[ -z "$secondary" ] && secondary="#00aaff"
[ -z "$tertiary" ] && tertiary="#00ffaa"
[ -z "$error" ] && error="#ff0000"
[ -z "$color0" ] && color0="#000000"
[ -z "$color1" ] && color1="#202020"
[ -z "$color2" ] && color2="#404040"
[ -z "$color3" ] && color3="#606060"
[ -z "$color4" ] && color4="#808080"
[ -z "$color5" ] && color5="#a0a0a0"
[ -z "$color6" ] && color6="#c0c0c0"
[ -z "$color7" ] && color7="#e0e0e0"

# ============================================================================
# Color Manipulation Functions
# ============================================================================

# Function to convert hex to RGB
hex_to_rgb() {
    local hex=$1
    # Remove leading # if present
    hex="${hex#\#}"
    
    local r=$(printf "%d" 0x${hex:0:2})
    local g=$(printf "%d" 0x${hex:2:2})
    local b=$(printf "%d" 0x${hex:4:2})
    
    echo "$r $g $b"
}

# Function to convert RGB to hex
rgb_to_hex() {
    local r=$1
    local g=$2
    local b=$3
    
    # Ensure values are in range
    r=$(( r > 255 ? 255 : (r < 0 ? 0 : r) ))
    g=$(( g > 255 ? 255 : (g < 0 ? 0 : g) ))
    b=$(( b > 255 ? 255 : (b < 0 ? 0 : b) ))
    
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Function to darken a color (make it more intense)
darken_color() {
    local hex=$1
    local percent=$2
    
    # Get RGB values
    local rgb=($(hex_to_rgb "$hex"))
    local r=${rgb[0]}
    local g=${rgb[1]}
    local b=${rgb[2]}
    
    # Darken by percentage
    r=$(( r * (100 - percent) / 100 ))
    g=$(( g * (100 - percent) / 100 ))
    b=$(( b * (100 - percent) / 100 ))
    
    rgb_to_hex $r $g $b
}

# Function to increase saturation
increase_saturation() {
    local hex=$1
    local percent=$2
    
    # Get RGB values
    local rgb=($(hex_to_rgb "$hex"))
    local r=${rgb[0]}
    local g=${rgb[1]}
    local b=${rgb[2]}
    
    # Calculate average
    local avg=$(( (r + g + b) / 3 ))
    
    # Increase difference from average to boost saturation
    r=$(( r + (r - avg) * percent / 100 ))
    g=$(( g + (g - avg) * percent / 100 ))
    b=$(( b + (b - avg) * percent / 100 ))
    
    # Ensure values are in range
    rgb_to_hex $r $g $b
}

# Function to calculate perceived brightness (0-255)
calculate_brightness() {
    local hex=$1
    
    # Get RGB values
    local rgb=($(hex_to_rgb "$hex"))
    local r=${rgb[0]}
    local g=${rgb[1]}
    local b=${rgb[2]}
    
    # Calculate perceived brightness (0-255)
    local brightness=$(( (299*r + 587*g + 114*b) / 1000 ))
    
    echo "$brightness"
}

# ============================================================================
# Time-based Adjustments
# ============================================================================

# Get current hour (24-hour format)
HOUR=$(date +%H)
HOUR_NUM=$((10#$HOUR))  # Force decimal interpretation

# Determine color temperature based on time of day
if [ $HOUR_NUM -ge 6 ] && [ $HOUR_NUM -lt 12 ]; then
    # Morning - cooler light
    COLOR_TEMP="cool"
    DARKEN_FACTOR=35  # Darken colors more in the morning
elif [ $HOUR_NUM -ge 12 ] && [ $HOUR_NUM -lt 16 ]; then
    # Midday - neutral
    COLOR_TEMP="neutral"
    DARKEN_FACTOR=30  # Standard darkening
elif [ $HOUR_NUM -ge 16 ] && [ $HOUR_NUM -lt 20 ]; then
    # Afternoon - warmer
    COLOR_TEMP="warm"
    DARKEN_FACTOR=25  # Less darkening in the afternoon
else
    # Evening/Night - very warm
    COLOR_TEMP="very-warm"
    DARKEN_FACTOR=20  # Even less darkening at night
fi

echo "🕒 Time-based adjustments: $COLOR_TEMP mode (darkening factor: $DARKEN_FACTOR%)"

# ============================================================================
# Generate Theme Colors
# ============================================================================

# Light theme - white background with transparency
BACKGROUND_HEX="#f0f0f0"
FOREGROUND_HEX="#000000"  # Black text for contrast

# Determine appropriate opacity based on time of day
if [ $HOUR_NUM -ge 6 ] && [ $HOUR_NUM -lt 20 ]; then
    # Daytime - more transparent
    OPACITY="0.85"
else
    # Nighttime - slightly less transparent
    OPACITY="0.90"
fi

# Process all colors to make them darker but keep their identity
# This maintains the same color palette but makes colors more visible on light background
DARK_PRIMARY=$(darken_color "$primary" $DARKEN_FACTOR)
DARK_ACCENT=$(darken_color "$accent" $DARKEN_FACTOR)
DARK_ACCENT_DARK=$(darken_color "$accent_dark" $DARKEN_FACTOR)
DARK_ACCENT_LIGHT=$(darken_color "$accent_light" $DARKEN_FACTOR)
DARK_SECONDARY=$(darken_color "$secondary" $DARKEN_FACTOR)
DARK_TERTIARY=$(darken_color "$tertiary" $DARKEN_FACTOR)
DARK_ERROR=$(darken_color "$error" $DARKEN_FACTOR)

# Make error color more intense for better visibility
DARK_ERROR=$(increase_saturation "$DARK_ERROR" 20)

# Ensure directory color is dark enough to be visible
DIR_COLOR=$(darken_color "$color4" 60)
DIR_BRIGHTNESS=$(calculate_brightness "$DIR_COLOR")
if [ "$DIR_BRIGHTNESS" -gt 128 ]; then
    # If still too bright, make it darker blue
    DIR_COLOR="#0057b7"
fi

# Debug output
echo "🎨 Generated color palette with darker accent colors:"
echo "  Background: $BACKGROUND_HEX (opacity: $OPACITY)"
echo "  Foreground: $FOREGROUND_HEX"
echo "  Primary: $primary → $DARK_PRIMARY"
echo "  Accent: $accent → $DARK_ACCENT"
echo "  Secondary: $secondary → $DARK_SECONDARY"
echo "  Error: $error → $DARK_ERROR"
echo "  Directory: $DIR_COLOR"

# ============================================================================
# Apply Theme to Kitty Config
# ============================================================================

# Create a temporary file for the new config
TEMP_FILE=$(mktemp)

# Copy the original config
cp "$KITTY_CONFIG" "$TEMP_FILE"

# Function to update or add a setting
update_setting() {
    local setting=$1
    local value=$2
    local file=$3
    
    if grep -q "^$setting " "$file"; then
        sed -i "s/^$setting .*$/$setting $value/" "$file"
    else
        echo "$setting $value" >> "$file"
    fi
}

# Update basic colors
update_setting "background" "$BACKGROUND_HEX" "$TEMP_FILE"
update_setting "foreground" "$FOREGROUND_HEX" "$TEMP_FILE"
update_setting "cursor" "$DARK_PRIMARY" "$TEMP_FILE"
update_setting "url_color" "$DARK_SECONDARY" "$TEMP_FILE"

# Update opacity settings
update_setting "background_opacity" "$OPACITY" "$TEMP_FILE"
update_setting "dynamic_background_opacity" "yes" "$TEMP_FILE"

# Update selection colors
update_setting "selection_foreground" "#ffffff" "$TEMP_FILE"
update_setting "selection_background" "$DARK_ACCENT" "$TEMP_FILE"

# Update terminal colors - use darker versions of the same colors
update_setting "color0" "$BACKGROUND_HEX" "$TEMP_FILE"
update_setting "color1" "$DARK_ERROR" "$TEMP_FILE"
update_setting "color2" "$DARK_SECONDARY" "$TEMP_FILE"
update_setting "color3" "$DARK_TERTIARY" "$TEMP_FILE"
update_setting "color4" "$DIR_COLOR" "$TEMP_FILE"
update_setting "color5" "$DARK_ACCENT" "$TEMP_FILE"
update_setting "color6" "$DARK_ACCENT_DARK" "$TEMP_FILE"
update_setting "color7" "#404040" "$TEMP_FILE"
update_setting "color8" "#e0e0e0" "$TEMP_FILE"
update_setting "color9" "$(darken_color "$DARK_ERROR" 15)" "$TEMP_FILE"
update_setting "color10" "$(darken_color "$DARK_SECONDARY" 15)" "$TEMP_FILE"
update_setting "color11" "$(darken_color "$DARK_TERTIARY" 15)" "$TEMP_FILE"
update_setting "color12" "$(darken_color "$DIR_COLOR" 15)" "$TEMP_FILE"
update_setting "color13" "$(darken_color "$DARK_ACCENT" 15)" "$TEMP_FILE"
update_setting "color14" "$(darken_color "$DARK_ACCENT_DARK" 15)" "$TEMP_FILE"
update_setting "color15" "#202020" "$TEMP_FILE"

# Add a timestamp comment
echo "# Light theme with darker accent colors - generated on $(date)" >> "$TEMP_FILE"

# Replace the original file with our temporary one
mv "$TEMP_FILE" "$KITTY_CONFIG"
echo "✅ Kitty config updated with light theme (darker accent colors)"

# Save the generated theme to cache for future reference
THEME_CACHE="$CACHE_DIR/kitty_light_theme.conf"
cat > "$THEME_CACHE" << EOF
# Kitty Light Theme - Generated on $(date)
# Time-based temperature: $COLOR_TEMP

background $BACKGROUND_HEX
foreground $FOREGROUND_HEX
cursor $DARK_PRIMARY
url_color $DARK_SECONDARY
background_opacity $OPACITY
dynamic_background_opacity yes
selection_foreground #ffffff
selection_background $DARK_ACCENT
color0 $BACKGROUND_HEX
color1 $DARK_ERROR
color2 $DARK_SECONDARY
color3 $DARK_TERTIARY
color4 $DIR_COLOR
color5 $DARK_ACCENT
color6 $DARK_ACCENT_DARK
color7 #404040
color8 #e0e0e0
color9 $(darken_color "$DARK_ERROR" 15)
color10 $(darken_color "$DARK_SECONDARY" 15)
color11 $(darken_color "$DARK_TERTIARY" 15)
color12 $(darken_color "$DIR_COLOR" 15)
color13 $(darken_color "$DARK_ACCENT" 15)
color14 $(darken_color "$DARK_ACCENT_DARK" 15)
color15 #202020
EOF

echo "✨ Kitty light theme applied successfully!"
echo "🎨 Theme features:"
echo "  • Same colors as dark mode but darkened for light background"
echo "  • Time-based adjustments ($COLOR_TEMP mode)"
echo "  • Dynamic transparency (opacity: $OPACITY)"
echo "  • Saved theme to cache: $THEME_CACHE"

# Inform user about kitty reload
echo "🔄 To apply the new colors, restart kitty or reload the config with ctrl+shift+F5"

# Create/update fish config only if fish is installed 
if [ -x "/usr/bin/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    
    # Light theme fish colors
    cat > "$HOME/.config/fish/conf.d/colors.fish" << 'FISHEOF'
# Set fish_color_command and fish_color_error from kitty colors (light theme)
if status --is-interactive
    # Use color4 (blue) for valid commands and directories
    set -g fish_color_command blue
    # Use color1 (red) for errors and invalid commands
    set -g fish_color_error red
    # Use color2 (green) for parameters
    set -g fish_color_param green
    # Use colors for autosuggestions
    set -g fish_color_autosuggestion grey
end
FISHEOF
    
    echo "Fish shell config updated for light theme"
fi

exit 0 