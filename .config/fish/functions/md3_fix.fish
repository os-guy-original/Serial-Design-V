function md3_fix
    echo "Fixing Material Design 3 Fish Shell configuration..."
    
    # Check if the colors are properly loaded
    if not set -q md3_primary
        echo "Material Design 3 colors not loaded. Setting default colors..."
        
        # Set default colors
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
    end
    
    # Check if fisher is installed
    if not functions -q fisher
        echo "Fisher not installed. Installing fisher..."
        curl -sL https://git.io/fisher | source
    end
    
    # Make sure the cd command is properly overridden
    if functions -q enhanced_cd
        # Remove the alias if it exists to avoid conflicts
        if alias | grep -q "alias cd='enhanced_cd'"
            functions --erase cd
        end
        
        # Create a proper cd function
        function cd
            enhanced_cd $argv
        end
        
        funcsave cd
    end
    
    # Fix any issues with the greeting
    if functions -q fish_greeting
        # Make sure the card function inside fish_greeting is fixed
        set -l greeting_file "$__fish_config_dir/functions/fish_greeting.fish"
        if test -f $greeting_file
            # Check if there are any string repeat issues
            if grep -q "string repeat.*math" $greeting_file
                echo "Fixing string repeat issues in fish_greeting..."
                sed -i 's/string repeat "─" (math 50 - (string length $title) - 6)/string repeat "─" 40/g' $greeting_file
                sed -i 's/string repeat " " (math 50 - (string length $content) - 2)/string repeat " " 40/g' $greeting_file
            end
        end
    end
    
    # Fix any animation issues
    set -g fish_md3_animations disabled
    
    echo "All fixes applied. Restarting fish shell..."
    echo "Please run 'exec fish' to apply all changes."
end 