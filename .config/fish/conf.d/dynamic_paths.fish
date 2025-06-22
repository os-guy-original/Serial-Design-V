# Dynamic paths configuration
# This script ensures that paths are always set dynamically on startup
# by overriding any hardcoded paths with HOME-based paths

# Z-related paths
# Instead of modifying existing values, we'll just set them correctly on startup
set -U Z_DATA_DIR "$HOME/.local/share/z"
set -U Z_DATA "$HOME/.local/share/z/data"
set -U Z_EXCLUDE "^\$HOME\$"

# User paths - preserve any custom paths that might have been added
# but ensure the standard ones use $HOME
set -l has_cargo false
set -l has_local false
set -l custom_paths

# Check existing paths and keep track of custom ones
for path in $fish_user_paths
    switch $path
        case '/home/*/'.cargo/bin
            set has_cargo true
        case '/home/*/'.local/bin
            set has_local true
        case '*'
            # Keep any custom paths that don't match the standard ones
            set -a custom_paths $path
    end
end

# Build the new fish_user_paths with dynamic paths
set -l new_paths
# Add cargo bin if it was present
if $has_cargo
    set -a new_paths "$HOME/.cargo/bin"
end
# Add local bin if it was present
if $has_local
    set -a new_paths "$HOME/.local/bin"
end
# Add all custom paths
for path in $custom_paths
    set -a new_paths $path
end

# Set the updated paths
set -U fish_user_paths $new_paths

# Create directories if they don't exist
if test ! -e "$Z_DATA"
    if test ! -e "$Z_DATA_DIR"
        mkdir -p -m 700 "$Z_DATA_DIR"
    end
    touch "$Z_DATA"
end 