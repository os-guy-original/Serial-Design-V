#!/bin/bash

# Define the directory where all scripts are located
CONFIG_DIR="$HOME/.config/hypr"

# Define a function to execute scripts
execute_script() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    echo "Executing $script_name..."
    
    if [ -f "$script_path" ]; then
        # Always make the script executable to be sure
        chmod +x "$script_path"
        
        # Execute the script with full path
        cd "$(dirname "$script_path")" && /bin/bash "$(basename "$script_path")" &
        execution_result=$?
        
        # Check if execution was successful
        if [ $execution_result -eq 0 ]; then
            echo "✅ $script_name executed successfully"
        else
            echo "❌ $script_name failed with exit code $execution_result"
        fi
    else
        echo "❌ ERROR: $script_name not found at $script_path"
    fi
}

# Apply colors to all other components first (except Waybar and Hyprland)
echo "Applying colors to components..."
# Apply colors to Rofi
ROFI_SCRIPT="$CONFIG_DIR/colorgen/configs/rofi.sh"
execute_script "$ROFI_SCRIPT"

# Apply colors to Kitty terminal
KITTY_SCRIPT="$CONFIG_DIR/colorgen/configs/kitty.sh"
execute_script "$KITTY_SCRIPT"

# Apply colors to Foot terminal
FOOT_SCRIPT="$CONFIG_DIR/colorgen/configs/foot.sh"
execute_script "$FOOT_SCRIPT"

# Apply colors to SwayNC notification center
SWAYNC_SCRIPT="$CONFIG_DIR/colorgen/configs/swaync.sh"
execute_script "$SWAYNC_SCRIPT"

# Run the GTK theme script
echo "Applying GTK colors..."
execute_script "$CONFIG_DIR/colorgen/configs/gtk.sh"

# Apply QT theme
echo "Applying QT/Kvantum theme..."
execute_script "$CONFIG_DIR/colorgen/configs/qt.sh"

# Apply KDE theme if available
echo "Applying KDE colors..."
execute_script "$CONFIG_DIR/colorgen/configs/kde.sh"

# Apply Chrome theme if available
echo "Applying Chrome colors..."
execute_script "$CONFIG_DIR/colorgen/configs/chrome.sh"

# Apply icon theme based on colors
ICON_SCRIPT="$CONFIG_DIR/colorgen/configs/icon-theme.sh"
execute_script "$ICON_SCRIPT"

# Apply Hyprland theme (background process since it's slow)
HYPRLAND_SCRIPT="$CONFIG_DIR/colorgen/configs/hyprland.sh"
if [ -f "$HYPRLAND_SCRIPT" ]; then
    chmod +x "$HYPRLAND_SCRIPT"
    # Run Hyprland script in background to not block waybar
    "$HYPRLAND_SCRIPT" &
    echo "✅ Hyprland script started in background"
else
    echo "❌ ERROR: Hyprland script not found"
fi

# Apply Hyprlock theme
HYPRLOCK_SCRIPT="$CONFIG_DIR/colorgen/configs/hyprlock.sh"
echo "Applying hyprlock colors..."
execute_script "$HYPRLOCK_SCRIPT"

# Apply GLava theme
GLAVA_SCRIPT="$CONFIG_DIR/colorgen/configs/glava.sh"
echo "Applying GLava colors..."
execute_script "$GLAVA_SCRIPT"

# Finally, run waybar.sh to apply colors and reload waybar
WAYBAR_SCRIPT="$CONFIG_DIR/colorgen/configs/waybar.sh"
echo "Applying waybar colors..."
if [ -f "$WAYBAR_SCRIPT" ]; then
    # Make sure script is executable
    chmod +x "$WAYBAR_SCRIPT"
    
    # Generate new CSS - waybar will detect changes automatically with reload_style_on_change
    cd "$(dirname "$WAYBAR_SCRIPT")" && /bin/bash "$(basename "$WAYBAR_SCRIPT")"
    echo "✅ Waybar CSS updated successfully"
else
    echo "❌ ERROR: Waybar script not found"
fi
