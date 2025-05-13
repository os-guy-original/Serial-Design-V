#!/bin/bash

# auto_colorgen.sh - No dependencies version
# Automatically runs color generation by modifying the wallpaper picker script

# Define config directory path for better portability
CONFIG_DIR="$HOME/.config/hypr"

# Path to color extraction script
COLORGEN_SCRIPT="$CONFIG_DIR/colorgen/material_extract.sh"

# Create the log directory
mkdir -p "$CONFIG_DIR/colorgen"

echo "Setting up automatic color generation..."

# Path to the wallpaper picker script
PICKER_SCRIPT="$CONFIG_DIR/scripts/wallpaper_picker.sh"

# Check if wallpaper picker script exists
if [ ! -f "$PICKER_SCRIPT" ]; then
    echo "Error: wallpaper_picker.sh not found"
    exit 1
fi

# Make a backup of the original script if not already done
if [ ! -f "${PICKER_SCRIPT}.original" ]; then
    cp "$PICKER_SCRIPT" "${PICKER_SCRIPT}.original"
    echo "Created backup of wallpaper_picker.sh at ${PICKER_SCRIPT}.original"
fi

# Check if color generation is already in the script
if grep -q "extract_colors.sh" "$PICKER_SCRIPT"; then
    echo "Color generation already set up in wallpaper_picker.sh"
else
    # Add color generation to the script - check for both swww img patterns
    if grep -q "swww img.*--transition-type" "$PICKER_SCRIPT"; then
        # Pattern for when wallpaper is selected with transition
        sed -i '/swww img.*--transition-type/a\
    # Generate colors from wallpaper\
    '"$COLORGEN_SCRIPT" "$PICKER_SCRIPT"
        echo "Added color generation after wallpaper selection with transition effect"
    elif grep -q "swww img" "$PICKER_SCRIPT"; then
        # Simpler pattern for just swww img
        sed -i '/swww img/a\
    # Generate colors from wallpaper\
    '"$COLORGEN_SCRIPT" "$PICKER_SCRIPT"
        echo "Added color generation after wallpaper selection"
    else
        echo "Warning: Could not find pattern to inject color generation"
    fi
fi

# Also run once for the current wallpaper
echo "Generating colors for current wallpaper..."
"$COLORGEN_SCRIPT"

echo "Setup complete! Colors will be generated automatically when wallpaper changes."
echo "To restore original wallpaper_picker.sh: cp ${PICKER_SCRIPT}.original ${PICKER_SCRIPT}" 