function fish_complete
    set -l cmd (commandline)
    set -l completions (complete -C "$cmd")
    if test (count $completions) -eq 0
        pipe_line "No completions available"
        return
    end

    set -l items
    for completion in $completions
        set -l item (echo $completion | awk '{print $1}')
        set items $items $item
    end

    # If fzf is available, let the user pick one interactively
    if type -q fzf
        set -l selection (printf "%s\n" $items | fzf --prompt="completion> " --height=40% --reverse)
        if test -n "$selection"
            # Delete the current token (up to whitespace) and insert the selection
            commandline -t ""
            commandline -i "$selection "
        end
    else
        # Fallback: just print the first few items
        set -l max 10
        set -l shown 0
        for item in $items
            if test $shown -ge $max
                pipe_line "(more completions available)"
                break
            end
            pipe_line $item
            set shown (math $shown + 1)
        end
    end

    # Redisplay the command line
    commandline -f repaint
end 