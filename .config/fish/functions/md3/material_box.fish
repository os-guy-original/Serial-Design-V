function material_box_start -a _box_color title
    # Simply print the title if provided, no framing
    if test -n "$title"
        pipe_line "$title"
    end
end

function material_box_line -a _box_color _icon _icon_color text
    # Print just the text
    pipe_line "$text"
end

function material_box_empty_line -a _box_color
    # Blank line separator
    pipe_line ""
end

function material_box_end -a _box_color
    # Nothing to do
end

function material_box -a box_color title
    material_box_start $box_color "$title"
    material_box_end $box_color
end

function material_progress_bar -a box_color percent
    # Default box width
    set -l bar_width 10
    
    # Calculate filled and empty parts
    set -l filled (math "round($percent / 10)")
    set -l empty (math "$bar_width - $filled")
    
    # Start progress bar
    set_color $box_color
    echo -n "["
    
    # Draw filled circles
    for i in (seq 1 $filled)
        echo -n "⬤"
    end
    
    # Draw empty circles
    set_color brblack
    for i in (seq 1 $empty)
        echo -n "⬤"
    end
    
    # End progress bar
    set_color $box_color
    echo -n "]"
    set_color normal
end 