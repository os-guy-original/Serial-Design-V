#!/bin/bash
# Wallpaper picker script
# Updated to use centralized swww_manager.sh and theme selection

# Enable debugging
set -x

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
CACHE_DIR="$XDG_CONFIG_HOME/hypr/cache"
TEMP_DIR="$CACHE_DIR/temp"
THEME_TO_APPLY_FILE="$TEMP_DIR/theme-to-apply"
THEME_SELECTOR_PYTHON="$COLORGEN_DIR/theme-selectors/theme_selector_python.sh"
DARK_LIGHT_SWITCH="$COLORGEN_DIR/dark_light_switch.sh"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"
mkdir -p "$CACHE_DIR/logs"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$CACHE_DIR/logs/wallpaper_picker.log"
    echo "$1"
}

log "Starting wallpaper picker script"

# If script is run with --apply, apply the last selected wallpaper
if [ "$1" == "--apply" ]; then
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        if [ -f "$WALLPAPER" ]; then
            log "Applying wallpaper: $WALLPAPER"
            set_wallpaper "$WALLPAPER"
        else
            log "Wallpaper file not found: $WALLPAPER"
        fi
    else
        log "No saved wallpaper configuration found"
    fi
    exit 0
fi


# Step 1: Select a new wallpaper using KDialog
log "Opening wallpaper selection dialog (KDialog)"
WALLPAPER=$(kdialog --title "Wallpaper Picker" --getopenfilename "$HOME" "*.png *.jpg *.jpeg|Image files")

# If no wallpaper selected, exit
if [ -z "$WALLPAPER" ]; then
    log "No wallpaper selected, exiting"
    exit 1
fi

log "Wallpaper selected: $WALLPAPER"

# Step 2: Run the theme selector before applying the wallpaper
if [ -f "$THEME_SELECTOR_PYTHON" ]; then
    log "Running theme selector with wallpaper preview..."
    chmod +x "$THEME_SELECTOR_PYTHON"
    "$THEME_SELECTOR_PYTHON" --wallpaper "$WALLPAPER"
    selector_exit=$?
    log "Theme selector exit code: $selector_exit"
    
    # If the user cancelled theme selection, cancel the entire operation
    if [ $selector_exit -ne 0 ]; then
        log "Theme selection cancelled, cleaning up processes and aborting entire operation"
        bash "$COLORGEN_DIR/kill_empty_area_finder.sh" >/dev/null 2>&1
        bash "$COLORGEN_DIR/kill_colorgen_duplicates.sh" >/dev/null 2>&1
        exit 1
    fi
else
    log "Theme selector script not found at $THEME_SELECTOR_PYTHON"
fi

# Step 3: Set the wallpaper (only if theme selection was successful)
log "Setting wallpaper: $WALLPAPER"
change_wallpaper_with_transition "$WALLPAPER" "wave" "center"
wallpaper_exit=$?
log "Wallpaper set exit code: $wallpaper_exit"

# Step 4: Apply the theme if theme-to-apply file exists
THEME_ARG=""
if [ -f "$THEME_TO_APPLY_FILE" ]; then
    theme=$(cat "$THEME_TO_APPLY_FILE")
    log "Found theme-to-apply file with theme: $theme"
    
    # Apply the theme
    if [ "$theme" = "light" ] || [ "$theme" = "dark" ]; then
        log "Applying $theme theme"
        THEME_ARG="--force-$theme"
    else
        log "Invalid theme in theme-to-apply file: $theme"
    fi
else
    log "No theme-to-apply file found"
fi

# Step 5: Run material_extract.sh directly with the theme argument
if [ -f "$COLORGEN_DIR/material_extract.sh" ]; then
    log "Running material_extract.sh with theme: $THEME_ARG"
    cd "$COLORGEN_DIR" && bash ./material_extract.sh $THEME_ARG
    extract_exit=$?
    log "Material extract exit code: $extract_exit"
else
    log "Material extract script not found at $COLORGEN_DIR/material_extract.sh"
fi

log "Wallpaper picker script completed"

# Disable debugging
set +x