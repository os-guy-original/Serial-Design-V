#!/bin/bash

# sound_test.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Sound Test Script - Demonstrates how to use the centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Initialize log with clear flag
init_log "clear"
log_message "Sound test script started"

# Print current sound theme information
echo "Current sound theme: $(get_sound_theme)"
echo "Sound directory: $(get_sound_dir)"
echo

# Function to test a specific sound
test_specific_sound() {
    local sound_name="$1"
    local volume="${2:-100}"
    
    echo "Testing sound: $sound_name (volume: $volume%)"
    
    local sound_file=$(get_sound_file "${sound_name}.ogg")
    if [[ -n "$sound_file" && -f "$sound_file" ]]; then
        echo "Found sound file: $sound_file"
        play_sound "${sound_name}.ogg" "$volume"
        sleep 2
    else
        echo "Sound file not found: ${sound_name}.ogg"
    fi
    echo
}

# List available themes
echo "Available sound themes:"
list_themes
echo

# Function to test all sounds in a theme
test_all_sounds() {
    local theme="${1:-$(get_sound_theme)}"
    local volume="${2:-80}"
    
    echo "Testing all sounds in theme: $theme (volume: $volume%)"
    echo
    
    # Get list of sounds
    local sounds=$(list_sounds "$theme")
    
    if [[ -z "$sounds" ]]; then
        echo "No sounds found in theme: $theme"
        return
    fi
    
    # Play each sound
    for sound_file in $sounds; do
        local sound_name="${sound_file%.ogg}"
        echo "Playing $sound_name..."
        play_sound "$sound_file" "$volume"
        sleep 1.5
    done
}

# Main menu
show_menu() {
    echo "Sound Test Menu"
    echo "---------------"
    echo "1. Test notification sound"
    echo "2. Test volume sounds"
    echo "3. Test all sounds (current theme)"
    echo "4. Test all sounds (default theme)"
    echo "5. Change sound theme"
    echo "6. Check required sounds"
    echo "q. Quit"
    echo
    read -p "Select an option: " choice
    
    case "$choice" in
        1)
            test_specific_sound "notification"
            ;;
        2)
            echo "Testing volume sounds sequence..."
            test_specific_sound "volume-up" 70
            sleep 1
            test_specific_sound "volume-down" 50
            sleep 1
            test_specific_sound "mute" 80
            sleep 1
            test_specific_sound "unmute" 80
            ;;
        3)
            test_all_sounds "$(get_sound_theme)" 70
            ;;
        4)
            test_all_sounds "default" 70
            ;;
        5)
            echo "Available themes:"
            list_themes
            echo
            read -p "Enter theme name: " theme_name
            if [[ -n "$theme_name" ]]; then
                set_sound_theme "$theme_name"
                echo "Theme set to: $theme_name"
            fi
            ;;
        6)
            check_required_sounds
            ;;
        q|Q)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    # Return to menu after action
    echo
    read -p "Press Enter to continue..."
    clear
    show_menu
}

# Start the menu
clear
show_menu 
