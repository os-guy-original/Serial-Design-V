function fish_right_prompt
    set -l normal (set_color normal)
    set -l yellow (set_color yellow)
    set -l brblack (set_color brblack)

    # Show execution time for long-running commands
    if test $CMD_DURATION
        set -l duration (math $CMD_DURATION / 1000)
        if test $duration -ge 5
            set_color brblack
            echo -n "took "
            
            if test $duration -ge 60
                set_color magenta
                echo -n (math $duration / 60)"m "
            end
            
            if test (math $duration % 60) -gt 0
                set_color yellow
                echo -n (math $duration % 60)"s"
            end
            
            set_color normal
            echo -n " "
        end
    end
    
    # Current time
    echo -n $brblack(date "+%H:%M:%S")$normal
end 