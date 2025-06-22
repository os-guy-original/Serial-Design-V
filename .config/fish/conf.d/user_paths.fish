# Ensure user paths use $HOME variable instead of hardcoded paths
# This file will run on shell startup and set the paths dynamically

# Clear existing fish_user_paths and set them with $HOME
set -U fish_user_paths "$HOME/.cargo/bin" "$HOME/.local/bin" 