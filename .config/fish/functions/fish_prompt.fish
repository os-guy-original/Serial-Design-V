function fish_prompt
    # Save the status of the last command
    set -l last_status $status

    # Set color variables
    set -l normal (set_color normal)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l yellow (set_color yellow)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l brblack (set_color brblack)
    set -l brwhite (set_color brwhite)
    set -l brcyan (set_color brcyan)
    set -l brgreen (set_color brgreen)
    set -l brmagenta (set_color brmagenta)

    # Prompt parts
    set -l prompt_symbol "❯"
    set -l error_symbol "✗"
    set -l git_symbol ""
    
    # Show username and hostname if it's an SSH session
    if set -q SSH_TTY
        echo -n -s $brmagenta (whoami) $normal "@" $yellow (hostname) $normal " "
    end

    # Show current directory
    echo -n -s $blue (prompt_pwd) $normal

    # Show git status
    set -l git_info
    if command -sq git
        set -l git_branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -n "$git_branch"
            set git_info "$git_symbol $git_branch"
            
            # Check for uncommitted changes
            if not git diff --quiet --ignore-submodules HEAD
                set git_info "$git_info*"
            end
            
            # Check for untracked files
            if test -n (git ls-files --others --exclude-standard)
                set git_info "$git_info+"
            end
            
            if git rev-parse --verify refs/stash >/dev/null 2>&1
                set git_info "$git_info≡"
            end
            
            echo -n -s " " $cyan $git_info $normal
        end
    end

    # Add a new line for the command prompt
    echo

    # Show error status for last command
    if test $last_status -ne 0
        echo -n -s $red $error_symbol " " $last_status " " $normal
    end

    # Show the prompt symbol
    echo -n -s $green $prompt_symbol $normal " "
end 