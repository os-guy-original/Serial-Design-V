#!/bin/bash

# update_sound_scripts.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Script to update all sound-related scripts to use the centralized sound_manager.sh

# Base directory
BASE_DIR="$HOME/.config/hypr"
SCRIPTS_DIR="$BASE_DIR/scripts"
SOUND_MANAGER="$BASE_DIR/scripts/system/sound_manager.sh"

# Make sure sound manager exists
if [[ ! -f "$SOUND_MANAGER" ]]; then
    echo "Error: Sound manager script not found at $SOUND_MANAGER"
    exit 1
fi

# Make sure sound manager is executable
chmod +x "$SOUND_MANAGER"

# Find all scripts that use sound files
echo "Searching for scripts that use sound files..."
SOUND_SCRIPTS=$(grep -l "default-sound\|\.ogg" "$SCRIPTS_DIR" --include="*.sh" -r)

# Count of scripts to update
TOTAL_SCRIPTS=$(echo "$SOUND_SCRIPTS" | wc -l)
echo "Found $TOTAL_SCRIPTS scripts to update"

# Function to backup a script
backup_script() {
    local script="$1"
    local backup="${script}.bak"
    
    # Create backup if it doesn't exist
    if [[ ! -f "$backup" ]]; then
        cp "$script" "$backup"
        echo "Created backup: $backup"
    fi
}

# Function to update a script
update_script() {
    local script="$1"
    local script_name=$(basename "$script")
    
    echo "Updating $script_name..."
    
    # Create backup
    backup_script "$script"
    
    # Add source line at the beginning after shebang
    if ! grep -q "source.*sound_manager.sh" "$script"; then
        # Find the line number of the first non-comment, non-empty line after shebang
        local insert_line=$(awk '
            BEGIN { found_shebang=0; insert_line=1 }
            /^#!/ { found_shebang=1; next }
            found_shebang && !/^[[:space:]]*($|#)/ { insert_line=NR; exit }
            END { print insert_line }
        ' "$script")
        
        # Insert the source line
        sed -i "${insert_line}i# Source the centralized sound manager\nsource \"$SOUND_MANAGER\"" "$script"
        echo "  Added source line to $script_name"
    fi
    
    # Replace direct sound file handling with sound_manager functions
    
    # 1. Replace DEFAULT_SOUND_FILE definition
        echo "  Removed DEFAULT_SOUND_FILE definition"
    fi
    
    # 2. Replace sound theme reading code
    if grep -q "if \[ -f \"\$DEFAULT_SOUND_FILE\" \]" "$script"; then
        # Find the block that reads the default sound file
        sed -i '/if \[ -f "\$DEFAULT_SOUND_FILE" \]/,/fi/c\
# Get sound theme from sound manager\
SOUND_THEME=$(get_sound_theme)\
SOUNDS_DIR=$(get_sound_dir)' "$script"
        echo "  Updated sound theme reading code"
    fi
    
    # 3. Replace play_sound function if it exists
# Use sound manager play_sound function
play_sound_local() {
    local sound_name="$1"
    play_sound "$sound_name"
}
        echo "  Updated play_sound function"
    fi
    
    # 4. Replace direct sound file references
    for sound in notification device-added device-removed screenshot volume-up volume-down mute unmute record-start record-stop error warning critical info login logout charging toggle_performance; do
        if grep -q "\".*${sound}\.ogg\"" "$script"; then
            sed -i "s|\".*${sound}\.ogg\"|$(get_sound_file \"${sound}.ogg\")|g" "$script"
            echo "  Updated references to $sound.ogg"
        fi
    done
    
    echo "Updated $script_name successfully"
}

# Update each script
for script in $SOUND_SCRIPTS; do
    # Skip the sound manager itself
    if [[ "$script" == "$SOUND_MANAGER" ]]; then
        continue
    fi
    
    # Skip backup files
    if [[ "$script" == *.bak ]]; then
        continue
    fi
    
    update_script "$script"
    echo
done

echo "Script update complete. $TOTAL_SCRIPTS scripts were processed."
echo "Please test each script carefully to ensure it works correctly with the new sound manager."
echo
echo "To test the sound manager directly, run:"
echo  
