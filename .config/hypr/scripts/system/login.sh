#!/bin/bash

# login.sh - Updated to use centralized sound manager

# Source the centralized sound manager
source "$HOME/.config/hypr/scripts/system/sound_manager.sh"

# Define login sound file
LOGIN_SOUND="login.ogg"

# Play login sound using sound manager
play_sound "$LOGIN_SOUND" 
