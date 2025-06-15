function cd
    # Save old directory
    set -l old_dir (pwd)
    
    # Call the built-in cd command
    builtin cd $argv
    
    # If directory changed successfully, show info
    if test $status -eq 0 && test "$old_dir" != (pwd)
        # Get current directory
        set -l current_dir (pwd)
        
        # Use our material box functions
        material_box_start green "Directory Changed"
        
        # Show from and to directories
        material_box_line green "⬤" yellow "From: $old_dir"
        material_box_line green "⬤" cyan "To: $current_dir"
        
        # Show directory contents
        set -l files (ls -la --color=never | head -n 8)
        
        if test (count $files) -gt 0
            material_box_empty_line green
            material_box_line green "◉" magenta "Directory Contents:"
            
            # Show first few files/directories
            for file in $files
                material_box_line green "" normal "$file"
            end
            
            # Show if there are more files
            if test (count (ls -la)) -gt 8
                material_box_line green "◉" yellow "(more files not shown)"
            end
        end
        
        material_box_end green
    end
end 