function md3_extract_colors
    # Check for required tools
    if not command -sq convert
        echo "ImageMagick is required for color extraction. Please install it first."
        return 1
    end
    
    # Define the output file
    set -l output_file "$HOME/.config/fish/conf.d/wallpaper_colors.fish"
    
    # Try to find the current wallpaper
    set -l wallpaper ""
    
    # Check common wallpaper locations based on desktop environment
    if test -n "$SWAYSOCK" # Sway
        set wallpaper (grep -oP 'output \* background \K[^ ]+' ~/.config/sway/config 2>/dev/null)
    else if test -n "$WAYLAND_DISPLAY" # Generic Wayland
        # Try to get from gsettings if GNOME
        if command -sq gsettings
            set wallpaper (gsettings get org.gnome.desktop.background picture-uri | string replace -a "'" "" | string replace "file://" "")
        end
    else # X11
        if command -sq gsettings # GNOME
            set wallpaper (gsettings get org.gnome.desktop.background picture-uri | string replace -a "'" "" | string replace "file://" "")
        else if command -sq xfconf-query # XFCE
            set wallpaper (xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image 2>/dev/null)
        else if command -sq plasma-apply-wallpaperimage # KDE
            # KDE stores wallpapers in config files, harder to extract
            echo "KDE wallpaper detection not implemented yet. Please provide wallpaper path manually."
        end
    end
    
    # If wallpaper not found, ask for manual input
    if test -z "$wallpaper" -o ! -f "$wallpaper"
        echo "Could not detect wallpaper automatically."
        echo -n "Please enter the path to your wallpaper: "
        read -l wallpaper
        
        if test -z "$wallpaper" -o ! -f "$wallpaper"
            echo "Invalid wallpaper path. Exiting."
            return 1
        end
    end
    
    echo "Extracting Material Design 3 colors from wallpaper: $wallpaper"
    
    # Extract dominant colors using ImageMagick
    # We'll extract 10 dominant colors and use them as a base for our Material Design 3 palette
    set -l temp_colors_file (mktemp)
    convert "$wallpaper" -resize 100x100 -colors 10 -unique-colors txt:- | tail -n +2 | awk '{print $3}' > $temp_colors_file
    
    # Read the extracted colors
    set -l colors (cat $temp_colors_file)
    rm $temp_colors_file
    
    # Make sure we have at least some colors
    if test (count $colors) -lt 3
        echo "Could not extract enough colors from the wallpaper. Using defaults."
        set colors "#6750a4" "#625b71" "#7d5260" "#b3261e"
    end
    
    # Generate Material Design 3 palette based on the first color (primary)
    set -l primary (echo $colors[1] | string replace -r '#' '0x')
    
    # Extract RGB components
    set -l r (math "($primary >> 16) & 0xFF")
    set -l g (math "($primary >> 8) & 0xFF")
    set -l b (math "$primary & 0xFF")
    
    # Generate Material Design 3 palette using color theory
    # This is a simplified version of Material You color generation
    # For a more accurate implementation, consider using material-color-utilities
    
    # Primary colors
    set -l md3_primary $colors[1]
    set -l md3_on_primary "#ffffff" # White text on primary
    
    # Calculate a lighter version for primary container
    set -l r_light (math "min(255, $r + 70)")
    set -l g_light (math "min(255, $g + 70)")
    set -l b_light (math "min(255, $b + 70)")
    set -l md3_primary_container (printf "#%02x%02x%02x" $r_light $g_light $b_light)
    set -l md3_on_primary_container "#000000" # Black text on light container
    
    # Secondary colors - use the second extracted color if available
    set -l secondary $colors[2]
    if test -z "$secondary"
        # Generate a complementary color if no second color
        set -l r_comp (math "255 - $r")
        set -l g_comp (math "255 - $g")
        set -l b_comp (math "255 - $b")
        set secondary (printf "#%02x%02x%02x" $r_comp $g_comp $b_comp)
    end
    set -l md3_secondary $secondary
    set -l md3_on_secondary "#ffffff" # White text on secondary
    
    # Calculate a lighter version for secondary container
    set -l sec_r (math "(0x"(echo $secondary | string sub -s 2 -l 2)")")
    set -l sec_g (math "(0x"(echo $secondary | string sub -s 4 -l 2)")")
    set -l sec_b (math "(0x"(echo $secondary | string sub -s 6 -l 2)")")
    
    set -l sec_r_light (math "min(255, $sec_r + 70)")
    set -l sec_g_light (math "min(255, $sec_g + 70)")
    set -l sec_b_light (math "min(255, $sec_b + 70)")
    set -l md3_secondary_container (printf "#%02x%02x%02x" $sec_r_light $sec_g_light $sec_b_light)
    set -l md3_on_secondary_container "#000000" # Black text on light container
    
    # Tertiary colors - use the third extracted color if available
    set -l tertiary $colors[3]
    if test -z "$tertiary"
        # Generate a tertiary color by mixing primary and secondary
        set -l r_tert (math "($r + $sec_r) / 2")
        set -l g_tert (math "($g + $sec_g) / 2")
        set -l b_tert (math "($b + $sec_b) / 2")
        set tertiary (printf "#%02x%02x%02x" $r_tert $g_tert $b_tert)
    end
    set -l md3_tertiary $tertiary
    set -l md3_on_tertiary "#ffffff" # White text on tertiary
    
    # Calculate a lighter version for tertiary container
    set -l tert_r (math "(0x"(echo $tertiary | string sub -s 2 -l 2)")")
    set -l tert_g (math "(0x"(echo $tertiary | string sub -s 4 -l 2)")")
    set -l tert_b (math "(0x"(echo $tertiary | string sub -s 6 -l 2)")")
    
    set -l tert_r_light (math "min(255, $tert_r + 70)")
    set -l tert_g_light (math "min(255, $tert_g + 70)")
    set -l tert_b_light (math "min(255, $tert_b + 70)")
    set -l md3_tertiary_container (printf "#%02x%02x%02x" $tert_r_light $tert_g_light $tert_b_light)
    set -l md3_on_tertiary_container "#000000" # Black text on light container
    
    # Error colors - keep standard Material Design error colors
    set -l md3_error "#b3261e"
    set -l md3_on_error "#ffffff"
    set -l md3_error_container "#f9dedc"
    set -l md3_on_error_container "#410e0b"
    
    # Surface colors
    set -l md3_surface "#fffbfe"
    set -l md3_on_surface "#1c1b1f"
    set -l md3_surface_variant "#e7e0ec"
    set -l md3_on_surface_variant "#49454f"
    
    # Background colors
    set -l md3_background "#fffbfe"
    set -l md3_on_background "#1c1b1f"
    
    # Outline
    set -l md3_outline "#79747e"
    set -l md3_outline_variant "#c4c7c5"
    
    # Generate the colors file
    echo "# Material Design 3 colors generated from wallpaper: $wallpaper" > $output_file
    echo "# Generated on "(date) >> $output_file
    echo "" >> $output_file
    echo "# Primary colors" >> $output_file
    echo "set -g md3_primary \"$md3_primary\"" >> $output_file
    echo "set -g md3_on_primary \"$md3_on_primary\"" >> $output_file
    echo "set -g md3_primary_container \"$md3_primary_container\"" >> $output_file
    echo "set -g md3_on_primary_container \"$md3_on_primary_container\"" >> $output_file
    echo "" >> $output_file
    echo "# Secondary colors" >> $output_file
    echo "set -g md3_secondary \"$md3_secondary\"" >> $output_file
    echo "set -g md3_on_secondary \"$md3_on_secondary\"" >> $output_file
    echo "set -g md3_secondary_container \"$md3_secondary_container\"" >> $output_file
    echo "set -g md3_on_secondary_container \"$md3_on_secondary_container\"" >> $output_file
    echo "" >> $output_file
    echo "# Tertiary colors" >> $output_file
    echo "set -g md3_tertiary \"$md3_tertiary\"" >> $output_file
    echo "set -g md3_on_tertiary \"$md3_on_tertiary\"" >> $output_file
    echo "set -g md3_tertiary_container \"$md3_tertiary_container\"" >> $output_file
    echo "set -g md3_on_tertiary_container \"$md3_on_tertiary_container\"" >> $output_file
    echo "" >> $output_file
    echo "# Error colors" >> $output_file
    echo "set -g md3_error \"$md3_error\"" >> $output_file
    echo "set -g md3_on_error \"$md3_on_error\"" >> $output_file
    echo "set -g md3_error_container \"$md3_error_container\"" >> $output_file
    echo "set -g md3_on_error_container \"$md3_on_error_container\"" >> $output_file
    echo "" >> $output_file
    echo "# Surface colors" >> $output_file
    echo "set -g md3_surface \"$md3_surface\"" >> $output_file
    echo "set -g md3_on_surface \"$md3_on_surface\"" >> $output_file
    echo "set -g md3_surface_variant \"$md3_surface_variant\"" >> $output_file
    echo "set -g md3_on_surface_variant \"$md3_on_surface_variant\"" >> $output_file
    echo "" >> $output_file
    echo "# Background colors" >> $output_file
    echo "set -g md3_background \"$md3_background\"" >> $output_file
    echo "set -g md3_on_background \"$md3_on_background\"" >> $output_file
    echo "" >> $output_file
    echo "# Outline" >> $output_file
    echo "set -g md3_outline \"$md3_outline\"" >> $output_file
    echo "set -g md3_outline_variant \"$md3_outline_variant\"" >> $output_file
    
    echo "Material Design 3 colors have been generated from your wallpaper and saved to $output_file"
    echo "Restart your fish shell or run 'source $output_file' to apply the new colors."
end 