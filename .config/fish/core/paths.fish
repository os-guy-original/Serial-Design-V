# Path configuration

# Add user's local bin directory to PATH
fish_add_path ~/.local/bin

# Add any custom paths here
# Example: fish_add_path /opt/custom/bin

# Load dynamic paths if available
if functions -q dynamic_path
    dynamic_path
end 