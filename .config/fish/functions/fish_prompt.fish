function fish_prompt
    # Save the status of the last command
    set -l last_status $status

    # Set color variables
    set -l normal (set_color normal)
    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l yellow (set_color yellow)
    set -l magenta (set_color magenta)
    
    # Material You design with circular elements
    echo
    
    # Show username and hostname if it's an SSH session
    if set -q SSH_TTY
        echo -n -s $magenta "⬤ " (whoami) $normal "@" $yellow (hostname) $normal " "
    end

    # Current directory with circular indicator
    echo -n -s $blue "⬤ " (prompt_pwd) $normal

    # Git status with circular indicators
    if command -sq git
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            # Check if HEAD exists (has at least one commit)
            set -l has_head (git rev-parse --verify HEAD >/dev/null 2>&1; echo $status)
            
            if test $has_head -eq 0
                # Repository has commits, show branch info
                set -l git_branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
                if test -n "$git_branch"
                    echo -n -s " " $cyan "⬤ " $git_branch $normal
                    
                    # Check for uncommitted changes
                    if not git diff --quiet --ignore-submodules HEAD
                        echo -n -s " " $yellow "○" $normal
                    end
                    
                    # Check for untracked files
                    set -l untracked (git ls-files --others --exclude-standard)
                    if test -n "$untracked"
                        echo -n -s " " $yellow "◐" $normal
                    end
                    
                    # Check for stashed changes
                    if git rev-parse --verify refs/stash >/dev/null 2>&1
                        echo -n -s " " $yellow "◑" $normal
                    end
                end
            else
                # Repository has no commits yet
                echo -n -s " " $cyan "⬤ " "no commits yet" $normal
                
                # Check for untracked files
                set -l untracked (git ls-files --others --exclude-standard)
                if test -n "$untracked"
                    echo -n -s " " $yellow "◐" $normal
                end
            end
        end
    end

    # Add a new line for the command prompt with Material You elevation effect
    echo
    
    # Material You pill-shaped prompt
    echo -n -s $blue "╭────" $normal
    
    # Show error status for last command
    if test $last_status -ne 0
        echo -n -s $red "⬤ " $last_status " " $normal
    end
    
    # Show current time in prompt
    echo -n -s $cyan (date "+%H:%M:%S") $normal
    
    # Show the prompt symbol
    echo
    echo -n -s $blue "╰────" $green "⬤" $normal " "
end 