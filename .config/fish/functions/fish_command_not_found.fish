function fish_command_not_found
    set -l cmd $argv[1]
    
    # If it looks like they typed a keyboard shortcut name
    if string match -q -r "Alt[\+\-].*|Ctrl[\+\-].*|Shift[\+\-].*" $cmd
        set_color yellow
        pipe_line "'$cmd' appears to be a keyboard shortcut, not a command. Press the keys instead of typing them."
        set_color normal
        return 127
    end

    set_color red
    pipe_line "Command not found: $cmd"
    
    # Try to find similar commands
    set -l suggestions
    
    # Check if it's a typo of a built-in command
    for c in (builtin --names)
        if string match -q -r ".*$cmd.*" $c
            set suggestions $suggestions $c
        end
    end
    
    # Check if it's a typo of an installed command
    for c in (command -a)
        if string match -q -r ".*$cmd.*" $c
            if not contains $c $suggestions
                set suggestions $suggestions $c
            end
        end
    end
    
    if test (count $suggestions) -gt 0
        set_color yellow
        pipe_line "Did you mean:"
        
        for s in (printf "%s\n" $suggestions | head -n 3)
            pipe_line "  $s"
        end
    end

    set_color magenta
    pipe_line "You can try installing it, e.g.:"
    pipe_line "  sudo pacman -S $cmd"
    pipe_line "  yay -S $cmd"
    set_color normal
    
    return 127
end 