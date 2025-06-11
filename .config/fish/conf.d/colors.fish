# Set fish_color_command and fish_color_error from kitty colors
if status --is-interactive
    # Use color4 (blue) for valid commands and directories
    set -g fish_color_command brblue
    # Use color1 (red) for errors and invalid commands
    set -g fish_color_error brred
    # Use color2 (green) for parameters
    set -g fish_color_param green
    # Use colors for autosuggestions
    set -g fish_color_autosuggestion brblack
end
