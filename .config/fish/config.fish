#!/usr/bin/env fish

# Fish shell configuration
# Restructured for better organization while preserving Material Design elements

# Load core configuration files first (suppress errors)
source ~/.config/fish/core/env.fish 2>/dev/null       # Environment variables
source ~/.config/fish/core/paths.fish 2>/dev/null     # Path configurations
source ~/.config/fish/core/aliases.fish 2>/dev/null   # Aliases and abbreviations
source ~/.config/fish/core/functions.fish 2>/dev/null # Core functions

# Load Material Design theme and components (preserved as-is)
for file in ~/.config/fish/conf.d/*.fish
    source $file 2>/dev/null
end

# Load all custom functions
for file in ~/.config/fish/functions/*.fish
    source $file 2>/dev/null
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
if type -q pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    fish_add_path $PYENV_ROOT/bin
    pyenv init - | source
end

# Want to use Conda? It makes this fish config load slow as hell. Just use ZSH or BASH if u want to use Conda.
# U can init conda with: "conda init <your_shell>"

# Initialize kiro only if it exists
if type -q kiro; and string match -q "$TERM_PROGRAM" "kiro"
    . (kiro --locate-shell-integration-path fish) 2>/dev/null
end

# Android SDK Environment Variables
set -gx ANDROID_HOME "/opt/android-sdk"
set -gx ANDROID_SDK_ROOT "/opt/android-sdk" # Some tools might look for ANDROID_SDK_ROOT
fish_add_path "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
fish_add_path "$ANDROID_SDK_ROOT/emulator"
fish_add_path "$ANDROID_SDK_ROOT/platform-tools"
