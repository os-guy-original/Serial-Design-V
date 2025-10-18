# Path Configuration Module
# Dynamic path management for Fish shell

# Function to safely add paths
function _add_to_path
    set -l path_to_add $argv[1]
    if test -d "$path_to_add"
        fish_add_path "$path_to_add"
    end
end

# Core system paths
_add_to_path "$HOME/.local/bin"
_add_to_path "/usr/local/bin"

# Development tools paths
_add_to_path "$HOME/.cargo/bin"        # Rust
_add_to_path "$HOME/.npm/bin"          # Node.js global packages
_add_to_path "$HOME/.yarn/bin"         # Yarn global packages
_add_to_path "$HOME/go/bin"            # Go binaries

# Load dynamic paths if available
if functions -q dynamic_path
    dynamic_path
end

# Clean up the helper function
functions -e _add_to_path