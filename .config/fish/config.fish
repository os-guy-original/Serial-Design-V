#!/usr/bin/env fish

# Fish shell configuration
# Restructured for better organization while preserving Material Design elements

# Load core configuration files first
source ~/.config/fish/core/env.fish       # Environment variables
source ~/.config/fish/core/paths.fish     # Path configurations
source ~/.config/fish/core/aliases.fish   # Aliases and abbreviations
source ~/.config/fish/core/functions.fish # Core functions

# Load Material Design theme and components (preserved as-is)
for file in ~/.config/fish/conf.d/*.fish
    source $file
end

# Load all custom functions
for file in ~/.config/fish/functions/*.fish
    source $file
end

# Set fish greeting, prompt, and right prompt
set -U fish_greeting fish_greeting
set -U fish_prompt fish_prompt
set -U fish_right_prompt fish_right_prompt

# Override command not found handler
function __fish_command_not_found_handler --on-event fish_command_not_found
    fish_command_not_found $argv
end

# Custom key bindings
bind \e\cf find_n_run  # Ctrl+Alt+F for find_n_run
# Alt+C binding for control_complete is defined in conf.d/control_complete_binding.fish
