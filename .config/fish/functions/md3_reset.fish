function md3_reset
    echo "Resetting Fish Shell configuration to basic settings..."
    
    # Reset cd function to default
    if functions -q cd
        functions -e cd
    end
    
    # Restore original config if available
    if test -f "$__fish_config_dir/config.fish.original"
        echo "Restoring original config.fish..."
        cp "$__fish_config_dir/config.fish.original" "$__fish_config_dir/config.fish"
    end
    
    # Remove Material Design 3 specific variables
    set -e fish_md3_theme
    set -e fish_md3_animations
    set -e md3_primary
    set -e md3_on_primary
    set -e md3_primary_container
    set -e md3_on_primary_container
    set -e md3_secondary
    set -e md3_on_secondary
    set -e md3_secondary_container
    set -e md3_on_secondary_container
    set -e md3_tertiary
    set -e md3_on_tertiary
    set -e md3_tertiary_container
    set -e md3_on_tertiary_container
    set -e md3_error
    set -e md3_on_error
    set -e md3_error_container
    set -e md3_on_error_container
    set -e md3_surface
    set -e md3_on_surface
    set -e md3_surface_variant
    set -e md3_on_surface_variant
    set -e md3_background
    set -e md3_on_background
    set -e md3_outline
    set -e md3_outline_variant
    
    # Reset fish colors to defaults
    set -g fish_color_normal normal
    set -g fish_color_command blue
    set -g fish_color_param cyan
    set -g fish_color_quote yellow
    set -g fish_color_redirection magenta
    set -g fish_color_end green
    set -g fish_color_error red
    set -g fish_color_comment brblack
    set -g fish_color_match --background=blue
    set -g fish_color_search_match --background=blue
    set -g fish_color_operator blue
    set -g fish_color_escape green
    set -g fish_color_autosuggestion brblack
    
    echo "Reset complete. Please restart your fish shell with 'exec fish'."
end 