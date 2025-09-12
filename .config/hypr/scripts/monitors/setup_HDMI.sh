#!/bin/bash

# ==============================================================================
# Hyprland Monitor Setup Script (Automated Version)
#
# This script dynamically detects connected monitors and their available modes.
# It requires `jq` to parse the JSON output from `hyprctl`.
# ==============================================================================

# ==============================================================================
# Dependency Check
# ==============================================================================

if ! command -v hyprctl &> /dev/null; then
    echo "Error: hyprctl is not found. Please ensure Hyprland is installed and in your PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not found. Please install it to proceed."
    echo "For Arch Linux, run: sudo pacman -S jq"
    exit 1
fi

# ==============================================================================
# Fetch and Process Monitor Data
# ==============================================================================

echo "Fetching monitor information from Hyprland..."
monitor_json=$(hyprctl monitors -j)

# Check if hyprctl returned valid JSON
if [ -z "$monitor_json" ]; then
    echo "Error: hyprctl returned no data. Is your Hyprland session running?"
    exit 1
fi

# ==============================================================================
# Interactive User Interface
# ==============================================================================

echo "----------------------------------------------------"
echo "Hyprland Monitor Configuration Tool"
echo "----------------------------------------------------"
echo ""

# Get the list of all connected monitors
monitors=$(echo "$monitor_json" | jq -r '.[].name')

if [ -z "$monitors" ]; then
    echo "No monitors detected. Exiting."
    exit 1
fi

# Display a numbered list of detected monitors
echo "Detected Monitors:"
IFS=$'\n' read -d '' -r -a monitor_array <<< "$monitors"
for i in "${!monitor_array[@]}"; do
    printf "[%2d] %s\n" "$((i+1))" "${monitor_array[$i]}"
done

# Prompt for monitor selection
read -rp "Enter the number of the monitor you want to configure: " monitor_choice

# Validate monitor input
if ! [[ "$monitor_choice" =~ ^[0-9]+$ ]] || [ "$monitor_choice" -le 0 ] || [ "$monitor_choice" -gt "${#monitor_array[@]}" ]; then
    echo "Invalid selection. Please run the script again and enter a valid number."
    exit 1
fi

SELECTED_MONITOR="${monitor_array[$((monitor_choice-1))]}"
echo ""
echo "You have selected monitor: $SELECTED_MONITOR"
echo ""

# Get the available modes for the selected monitor
available_modes=$(echo "$monitor_json" | jq -r --arg name "$SELECTED_MONITOR" '.[] | select(.name == $name) | .availableModes | join(" ")')

if [ -z "$available_modes" ]; then
    echo "No available modes found for this monitor. Exiting."
    exit 1
fi

# Display a numbered list of available modes
echo "Available resolutions and refresh rates for $SELECTED_MONITOR:"
IFS=$'\n' read -d '' -r -a modes_array < <(echo -e "${available_modes}" | tr ' ' '\n' | sort -u)
for i in "${!modes_array[@]}"; do
    printf "[%2d] %s\n" "$((i+1))" "${modes_array[$i]}"
done

# Prompt for mode selection
read -rp "Enter the number for your desired mode: " mode_choice

# Validate mode input
if ! [[ "$mode_choice" =~ ^[0-9]+$ ]] || [ "$mode_choice" -le 0 ] || [ "$mode_choice" -gt "${#modes_array[@]}" ]; then
    echo "Invalid selection. Please run the script again and enter a valid number."
    exit 1
fi

SELECTED_MODE="${modes_array[$((mode_choice-1))]}"

echo ""
read -rp "Enter the monitor position (e.g., 0x0) [auto]: " position
if [ -z "$position" ]; then
    position="auto"
fi

echo ""
read -rp "Enter the monitor scale (e.g., 1.0, 1.5) [1.0]: " scale
if [ -z "$scale" ]; then
    scale="1.0"
fi

echo ""
read -rp "Enter the workspace to assign to this monitor (e.g., 1, 2) [none]: " workspace
if [ -z "$workspace" ]; then
    workspace=""
else
    workspace=",workspace:${workspace}"
fi

# ==============================================================================
# Generate and Apply Command
# ==============================================================================

GENERATED_CONFIG="monitor=${SELECTED_MONITOR},${SELECTED_MODE},${position},${scale}${workspace}"
HYPRCTL_COMMAND="hyprctl --batch \"${GENERATED_CONFIG}\""

echo ""
echo "----------------------------------------------------"
echo "Generated Command to be executed:"
echo "----------------------------------------------------"
echo "$HYPRCTL_COMMAND"
echo "----------------------------------------------------"
echo ""

# Execute the command and check for success
read -rp "Apply this configuration? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    eval $HYPRCTL_COMMAND
    if [ $? -eq 0 ]; then
        echo ""
        echo "Configuration applied successfully."
        
        # Add a check to prevent accidentally writing to the config
        read -rp "Do you want to add this line to your ~/.config/hypr/hyprland.conf file? (y/n): " add_to_config
        if [[ "$add_to_config" =~ ^[Yy]$ ]]; then
            CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
            echo -e "\n# Added by monitor setup script" >> "$CONFIG_FILE"
            echo "$GENERATED_CONFIG" >> "$CONFIG_FILE"
            echo "Successfully added the configuration to $CONFIG_FILE."
        else
            echo "Configuration not added to ~/.config/hypr/hyprland.conf."
            echo "Here is the line you can add manually:"
            echo ""
            echo "$GENERATED_CONFIG"
            echo ""
        fi
    else
        echo ""
        echo "Failed to apply configuration. Please check your Hyprland log for errors."
    fi
else
    echo "Configuration not applied."
fi
