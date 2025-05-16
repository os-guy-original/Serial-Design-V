#!/bin/bash

# kitty.sh - Update Material You colors for kitty terminal
# Updates color settings directly in kitty.conf based on Material You color palette

# Colors source
COLORS_CONF="$HOME/.config/hypr/colorgen/colors.conf"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"

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

echo "Updating kitty colors..."

# Create a backup of the config if it doesn't exist
BACKUP_FILE="${KITTY_CONFIG}.original"
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$KITTY_CONFIG" "$BACKUP_FILE"
    echo "Created backup of kitty config at $BACKUP_FILE"
fi

# Read colors directly without sourcing - exactly like waybar.sh
primary=$(grep -E '^primary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent=$(grep -E '^accent =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_dark=$(grep -E '^accent_dark =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
accent_light=$(grep -E '^accent_light =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
secondary=$(grep -E '^secondary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
tertiary=$(grep -E '^tertiary =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color0=$(grep -E '^color0 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color1=$(grep -E '^color1 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color2=$(grep -E '^color2 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color3=$(grep -E '^color3 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color4=$(grep -E '^color4 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color5=$(grep -E '^color5 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color6=$(grep -E '^color6 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
color7=$(grep -E '^color7 =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')

# Set defaults for missing values - exactly like waybar.sh
[ -z "$primary" ] && primary="#808080"
[ -z "$accent" ] && accent="#808080"
[ -z "$accent_dark" ] && accent_dark="#606060"
[ -z "$accent_light" ] && accent_light="#a0a0a0"
[ -z "$secondary" ] && secondary="#707070"
[ -z "$tertiary" ] && tertiary="#909090"
[ -z "$color0" ] && color0="#000000"
[ -z "$color1" ] && color1="#202020"
[ -z "$color2" ] && color2="#404040"
[ -z "$color3" ] && color3="#606060"
[ -z "$color4" ] && color4="#808080"
[ -z "$color5" ] && color5="#a0a0a0"
[ -z "$color6" ] && color6="#c0c0c0"
[ -z "$color7" ] && color7="#e0e0e0"

# Get error colors if available
error=$(grep -E '^error =' "$COLORS_CONF" | cut -d'=' -f2 | tr -d ' ')
[ -z "$error" ] && error="#ff0000"

# Function to determine if text should be dark or light based on background color
get_contrast_color() {
    local bg_color="$1"
    # Extract RGB components
    local r=$(printf "%d" 0x${bg_color:1:2})
    local g=$(printf "%d" 0x${bg_color:3:2})
    local b=$(printf "%d" 0x${bg_color:5:2})
    
    # Calculate luminance (perceived brightness)
    # Formula: (0.299*R + 0.587*G + 0.114*B)
    local luminance=$(( (299*r + 587*g + 114*b) / 1000 ))
    
    # Return black for light backgrounds, white for dark backgrounds
    if [ "$luminance" -gt 128 ]; then
        echo "#000000"  # Dark text for light background
    else
        echo "#ffffff"  # Light text for dark background
    fi
}

# Create color variables for kitty
BACKGROUND_HEX="$color0"
FOREGROUND_HEX="$color7"
CURSOR_HEX="$primary"

# Create selection colors
SELECTION_BACKGROUND_HEX="$accent"
SELECTION_FOREGROUND_HEX="$(get_contrast_color "$accent")"

# URL color
URL_COLOR_HEX="$primary"

# Map Material You colors to the 16 terminal colors
COLOR0_HEX="$color0"
COLOR8_HEX="$color3"

# Make the error/command not found color more vibrant for fish shell
ERROR_COLOR_HEX="$error"
if [[ "$ERROR_COLOR_HEX" != "#"* ]]; then
    ERROR_COLOR_HEX="#ff5252"
fi
COLOR1_HEX="$ERROR_COLOR_HEX"
COLOR9_HEX="$accent_dark"

COLOR2_HEX="$secondary"
COLOR10_HEX="$accent"

COLOR3_HEX="$tertiary"
COLOR11_HEX="$accent_light"

# Make directory/path color more distinctive for fish shell
DIR_COLOR_HEX="$primary"
if [ "$(get_contrast_color "$BACKGROUND_HEX")" = "#ffffff" ]; then
    # Dark background needs brighter blue for paths
    DIR_COLOR_BRIGHTNESS=$(( ($(printf "%d" 0x${DIR_COLOR_HEX:1:2}) + 
                           $(printf "%d" 0x${DIR_COLOR_HEX:3:2}) + 
                           $(printf "%d" 0x${DIR_COLOR_HEX:5:2})) / 3 ))
    if [ "$DIR_COLOR_BRIGHTNESS" -lt 128 ]; then
        # If primary color is too dark, use a brighter blue
        DIR_COLOR_HEX="#5c9eff"
    fi
else
    # Light background needs darker blue for paths
    DIR_COLOR_HEX="#0057b7"
fi
COLOR4_HEX="$DIR_COLOR_HEX"
COLOR12_HEX="$color4"

COLOR5_HEX="$tertiary"
COLOR13_HEX="$color5"

COLOR6_HEX="$secondary"
COLOR14_HEX="$color6"

COLOR7_HEX="$color6"
COLOR15_HEX="$color7"

# Debug output to log what's happening
echo "Generated colors:"
echo "Background: $BACKGROUND_HEX"
echo "Foreground: $FOREGROUND_HEX"
echo "Cursor: $CURSOR_HEX"
echo "Command not found color: $COLOR1_HEX"
echo "Directory path color: $COLOR4_HEX"

# Create a color block in the kitty.conf
TEMP_FILE=$(mktemp)

# First, let's extract everything before '# Color scheme' if it exists
if grep -q "# Color scheme" "$KITTY_CONFIG"; then
    sed '/# Color scheme/,$d' "$KITTY_CONFIG" > "$TEMP_FILE"
else
    # If the marker doesn't exist, copy everything before color0
    if grep -q "^color0" "$KITTY_CONFIG"; then
        sed '/^color0/,$d' "$KITTY_CONFIG" > "$TEMP_FILE"
    else
        # If neither exists, just copy the whole file
        cp "$KITTY_CONFIG" "$TEMP_FILE"
    fi
fi

# Remove any existing shell configuration
if grep -q "^shell" "$TEMP_FILE"; then
    sed -i '/^shell/d' "$TEMP_FILE"
fi

# Check if fish shell is installed
FISH_PATH="/usr/bin/fish"
DEFAULT_SHELL="$SHELL"
if [ -x "$FISH_PATH" ]; then
    SHELL_TO_USE="$FISH_PATH"
    echo "Fish shell found, using it as default"
else
    SHELL_TO_USE="$DEFAULT_SHELL"
    echo "Fish shell not found, using system default: $DEFAULT_SHELL"
fi

# Append our color scheme to the end
cat >> "$TEMP_FILE" << EOF

# Set default shell
shell $SHELL_TO_USE

# Color scheme - Material You Colors
background_opacity 0.95
dynamic_background_opacity yes

# Basic colors
foreground $FOREGROUND_HEX
background $BACKGROUND_HEX
cursor $CURSOR_HEX
url_color $URL_COLOR_HEX

# Selection colors
selection_foreground $SELECTION_FOREGROUND_HEX
selection_background $SELECTION_BACKGROUND_HEX

# Terminal colors (16 color palette)
color0 $COLOR0_HEX
color8 $COLOR8_HEX

color1 $COLOR1_HEX
color9 $COLOR9_HEX

color2 $COLOR2_HEX
color10 $COLOR10_HEX

color3 $COLOR3_HEX
color11 $COLOR11_HEX

color4 $COLOR4_HEX
color12 $COLOR12_HEX

color5 $COLOR5_HEX
color13 $COLOR13_HEX

color6 $COLOR6_HEX
color14 $COLOR14_HEX

color7 $COLOR7_HEX
color15 $COLOR15_HEX
EOF

# Create/update fish config only if fish is installed 
if [ -x "$FISH_PATH" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/colors.fish" << 'FISHEOF'
# Set fish_color_command and fish_color_error from kitty colors
if status --is-interactive
    # Use color4 (blue) for valid commands and directories
    set -g fish_color_command brblue
    # Use color1 (red) for errors and invalid commands
    set -g fish_color_error brred
    # Use color2 (green) for parameters
    set -g fish_color_param green
    # Use colors for autosuggestions
    set -g fish_color_autosuggestion brblack
end
FISHEOF
    echo "Fish shell config updated"
fi

# Replace the original file with our modified version
mv "$TEMP_FILE" "$KITTY_CONFIG"

echo "Kitty colors updated successfully!"
echo "The new color values are:"
echo "Foreground: $FOREGROUND_HEX (should be light colored)"
echo "Background: $BACKGROUND_HEX (should be dark colored)"
echo "Error/Command not found: $COLOR1_HEX (should be bright)"
echo "Directory paths: $COLOR4_HEX (should be distinctive)"
echo "Default shell set to fish"

# Inform user about kitty reload
echo "To apply the new colors, restart kitty or reload the config with ctrl+shift+F5"

exit 0 