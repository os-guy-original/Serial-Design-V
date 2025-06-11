function fish_material_help
    # Use our material box functions
    material_box_start blue "Material Design 3 Fish Shell Help"
    
    material_box_line blue "⬤" yellow "Keyboard Shortcuts:"
    material_box_line blue "" normal "Alt+c - Show command completions"
    material_box_line blue "" normal "Alt+r - Show command history"
    material_box_line blue "" normal "Alt+d - Show directory navigation"
    material_box_line blue "" normal "help  - Show fish help"
    
    material_box_empty_line blue
    
    material_box_line blue "◉" red "Note: Press keys, don't type the shortcuts"
    
    material_box_end blue
end

# Override the help command
function help
    # If no arguments, show our Material You help
    if test (count $argv) -eq 0
        fish_material_help
    else
        # Otherwise, show the regular fish help
        command help $argv
    end
end 