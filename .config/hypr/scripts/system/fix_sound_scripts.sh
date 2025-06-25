#!/bin/bash

# fix_sound_scripts.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Get sound theme and directory
SOUND_THEME=$(get_sound_theme)
SOUNDS_DIR=$(get_sound_dir)


# Script to fix sound-related scripts to use the centralized sound_manager.sh

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
    
    # Skip if it's the sound manager itself
    if [[ "$script" == "$SOUND_MANAGER" ]]; then
        echo "Skipping sound manager itself"
        return
    fi
    
    # Skip if it's a backup file
    if [[ "$script" == *.bak ]]; then
        echo "Skipping backup file"
        return
    fi
    
    # Create backup
    backup_script "$script"
    
    # Create a temporary file
    local temp_file="${script}.tmp"
    
    # Start with the shebang line
    grep "^#!" "$script" > "$temp_file" || echo "#!/bin/bash" > "$temp_file"
    
    # Add a blank line and comments
    echo "" >> "$temp_file"
    echo "# $script_name - Updated to use centralized sound manager" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add the source line
    echo "# Source the centralized sound manager" >> "$temp_file"
    echo "source \"$SOUND_MANAGER\"" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add sound theme and directory variables
    echo "# Get sound theme and directory" >> "$temp_file"
    echo "SOUND_THEME=\$(get_sound_theme)" >> "$temp_file"
    echo "SOUNDS_DIR=\$(get_sound_dir)" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Extract the main content of the script, skipping shebang, comments at the beginning,
    # and any existing sound file handling code
    awk '
        BEGIN { printing = 0; }
        /^#!/ { next; }  # Skip shebang
        /^# Sound file paths/ { next; }  # Skip sound file path comments
        /^SOUNDS_BASE_DIR=/ { next; }    # Skip sound dir definition
        /^DEFAULT_SOUND_FILE=/ { next; } # Skip default sound file definition
        /if \[ -f "\$DEFAULT_SOUND_FILE" \]/,/fi/ { next; } # Skip sound theme reading block
        /^# Function to play sounds/,/^}/ { 
            if (/^}/) { printing = 1; }
            next; 
        }  # Skip play_sound function
        printing || !/^#/ { printing = 1; print; }  # Print once we get past initial comments
    ' "$script" | 
    # Replace direct references to sound files with play_sound calls
    sed -e 's|"$SOUNDS_DIR/\([^"]*\.ogg\)"|"\1"|g' \
        -e 's|mpv --no-terminal "\([^"]*\.ogg\)"|play_sound "\1"|g' \
        -e 's|mpv --no-terminal --volume=[0-9]* "\([^"]*\.ogg\)"|play_sound "\1"|g' \
        >> "$temp_file"
    
    # Replace the original file with the temporary file
    mv "$temp_file" "$script"
    chmod +x "$script"
    
    echo "Updated $script_name successfully"
}

# Update each script
for script in $SOUND_SCRIPTS; do
    update_script "$script"
    echo
done

echo "Script update complete. $TOTAL_SCRIPTS scripts were processed."
echo "Please test each script carefully to ensure it works correctly with the new sound manager."
echo
echo "To test the sound manager directly, run:"
echo "  $SOUND_MANAGER play notification.ogg" 
