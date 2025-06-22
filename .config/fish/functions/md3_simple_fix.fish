function md3_simple_fix
    echo "Applying simple fixes to Material Design 3 Fish Shell..."
    
    # Disable animations
    set -g fish_md3_animations disabled
    
    # Set default colors directly
    set -g md3_primary "#6750a4"
    set -g md3_on_primary "#ffffff"
    set -g md3_primary_container "#eaddff"
    set -g md3_on_primary_container "#21005d"
    set -g md3_secondary "#625b71"
    set -g md3_on_secondary "#ffffff"
    set -g md3_secondary_container "#e8def8"
    set -g md3_on_secondary_container "#1d192b"
    set -g md3_tertiary "#7d5260"
    set -g md3_on_tertiary "#ffffff"
    set -g md3_tertiary_container "#ffd8e4"
    set -g md3_on_tertiary_container "#31111d"
    set -g md3_error "#b3261e"
    set -g md3_on_error "#ffffff"
    set -g md3_error_container "#f9dedc"
    set -g md3_on_error_container "#410e0b"
    set -g md3_surface "#fffbfe"
    set -g md3_on_surface "#1c1b1f"
    set -g md3_surface_variant "#e7e0ec"
    set -g md3_on_surface_variant "#49454f"
    set -g md3_background "#fffbfe"
    set -g md3_on_background "#1c1b1f"
    set -g md3_outline "#79747e"
    set -g md3_outline_variant "#c4c7c5"
    
    # Create a proper cd function that doesn't use the enhanced_cd
    function cd
        # If no arguments, go home
        if test (count $argv) -eq 0
            builtin cd ~
        else
            builtin cd $argv
        end
        
        # Show directory contents
        ls -A --color=auto
    end
    
    funcsave cd
    
    echo "Simple fixes applied. Please restart your fish shell with 'exec fish'."
end 