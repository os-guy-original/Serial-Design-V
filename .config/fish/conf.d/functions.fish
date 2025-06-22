# Weather function - shows weather for a location
function weather
    set -l location $argv[1]
    if test -z "$location"
        set location "auto"
    end
    curl -s "wttr.in/$location?format=%l:+%c+%t,+%h,+%w"
    echo
end

# Create a cheatsheet function
function cheat
    set -l topic $argv[1]
    if test -z "$topic"
        echo "Usage: cheat <command>"
        return 1
    end
    curl -s "cheat.sh/$topic"
end

# Quick reminder function
function remind
    if test (count $argv) -lt 2
        echo "Usage: remind <time> <message>"
        return 1
    end
    
    set -l time $argv[1]
    set -l message (string join " " $argv[2..-1])
    
    # Schedule notification
    echo "notify-send 'Reminder' '$message'" | at $time 2>/dev/null
    echo "Reminder set for $time: $message"
end

# Find files and directories
function ff
    find . -type f -name "*$argv*"
end

function fd
    find . -type d -name "*$argv*"
end

# Process management
function psgrep
    ps aux | grep $argv | grep -v grep
end

function killgrep
    kill (pgrep $argv)
end

# Convert video to gif
function vid2gif
    if test (count $argv) -lt 2
        echo "Usage: vid2gif <input> <output.gif>"
        return 1
    end
    
    ffmpeg -i $argv[1] -vf "fps=10,scale=720:-1:flags=lanczos" -c:v gif $argv[2]
end

# Git find
function gf
    git ls-files | grep $argv
end

# Quick edit the fish config
function editfish
    $EDITOR ~/.config/fish/config.fish
end

# A function to backup a file
function backup
    cp $argv $argv.(date +%Y%m%d%H%M%S).bak
end

# Find and replace in all files in current directory
function find_replace
    if test (count $argv) -lt 2
        echo "Usage: find_replace <find_pattern> <replace_pattern>"
        return 1
    end
    
    find . -type f -exec grep -l "$argv[1]" {} \; | xargs sed -i "s/$argv[1]/$argv[2]/g"
end

# Check if running inside tmux
function is_tmux
    if set -q TMUX
        return 0
    else
        return 1
    end
end

# Print path components one per line
function path
    echo $PATH | tr : '\n'
end 

# Delete the frickin' pacman lock file
function pacman-unlock
    sudo rm -rf /var/lib/pacman/db.lck
end

# Material Design 3 styled command suggestions and auto-completion

# Smart command suggestions based on history and context
function suggest_command
    # Get the current command line
    set -l cmd (commandline)
    
    # Only suggest if we have some input
    if test -n "$cmd"
        # Search history for similar commands
        set -l suggestions (history | grep -i "^$cmd" | head -n 3)
        
        # If we found suggestions, show them
        if test -n "$suggestions"
            echo
            echo (set_color $md3_outline)"Suggestions:"(set_color normal)
            for suggestion in $suggestions
                echo (set_color $md3_primary_container)" → "(set_color $md3_on_primary_container)"$suggestion"(set_color normal)
            end
            echo
            commandline -f repaint
        end
    end
end

# Enhanced directory navigation with Material Design 3 style
function enhanced_cd
    # If no arguments, go home
    if test (count $argv) -eq 0
        cd ~
        return
    end
    
    # Regular cd behavior
    builtin cd $argv
    
    # Show directory contents with Material Design style
    echo
    echo (set_color $md3_secondary)"┌─── Directory Contents ───────────────────────────────┐"(set_color normal)
    
    # Get all items in the directory
    set -l items (ls -A)
    set -l dirs 0
    set -l files 0
    
    # Count directories and files
    for item in $items
        if test -d $item
            set dirs (math $dirs + 1)
        else
            set files (math $files + 1)
        end
    end
    
    # Show summary
    echo (set_color $md3_secondary)"│ "(set_color $md3_on_secondary_container)"$dirs directories, $files files"(set_color normal)
    echo (set_color $md3_secondary)"└───────────────────────────────────────────────────────┘"(set_color normal)
    
    # Show the actual directory contents
    ls -A --color=auto
end

# Override the cd command with our enhanced version
alias cd="enhanced_cd"

# Material Design 3 styled auto-completion menu
function md3_complete
    # Save current command line
    set -l cmd (commandline)
    
    # Only show completions if we have some input
    if test -n "$cmd"
        # Get completions
        set -l completions (complete -C "$cmd")
        
        # If we have completions, show them in a Material Design 3 style
        if test (count $completions) -gt 0
            echo
            echo (set_color $md3_tertiary)"┌─── Completions ────────────────────────────────────┐"(set_color normal)
            
            # Show at most 5 completions
            set -l max_completions 5
            set -l shown_completions 0
            
            for completion in $completions
                echo (set_color $md3_tertiary)"│ "(set_color $md3_on_tertiary_container)"$completion"(set_color normal)
                
                set shown_completions (math $shown_completions + 1)
                if test $shown_completions -ge $max_completions
                    break
                end
            end
            
            # If there are more completions than we showed, indicate that
            if test (count $completions) -gt $max_completions
                set -l remaining (math (count $completions) - $max_completions)
                echo (set_color $md3_tertiary)"│ "(set_color $md3_on_tertiary_container)"... and $remaining more"(set_color normal)
            end
            
            echo (set_color $md3_tertiary)"└───────────────────────────────────────────────────────┘"(set_color normal)
            
            commandline -f repaint
        end
    end
end

# Material Design 3 styled command not found handler
function __fish_command_not_found_handler --on-event fish_command_not_found
    set -l cmd $argv[1]
    
    echo (set_color $md3_error)"Command not found: $cmd"(set_color normal)
    
    # Try to find similar commands
    set -l suggestions (apropos -e $cmd 2>/dev/null | head -n 3)
    if test -n "$suggestions"
        echo
        echo (set_color $md3_error_container)"┌─── Suggestions ────────────────────────────────────┐"(set_color normal)
        for suggestion in $suggestions
            echo (set_color $md3_error_container)"│ "(set_color $md3_on_error_container)"$suggestion"(set_color normal)
        end
        echo (set_color $md3_error_container)"└───────────────────────────────────────────────────────┘"(set_color normal)
    end
    
    # Check if it's a typo and suggest corrections
    set -l all_commands (command -a)
    for command in $all_commands
        # Simple string distance check
        if string match -q -r ".*$cmd.*" $command
            echo (set_color $md3_primary)"Did you mean: "(set_color $md3_on_primary_container)"$command"(set_color normal)"?"
            break
        end
    end
    
    return 127
end

# Material Design 3 styled command execution feedback
function __fish_md3_command_status --on-event fish_postexec
    set -l last_status $status
    # Show a simple message for non-zero exit codes
    if test $last_status -ne 0
        set_color $md3_error
        pipe_line "Command failed (exit status $last_status)"
        set_color normal
    end
end

# Material Design 3 styled directory history navigation
function dirh
    # Get directory history
    set -l dir_history (dirs -p | uniq)
    
    echo
    echo (set_color $md3_primary)"┌─── Directory History ───────────────────────────────┐"(set_color normal)
    
    # Show directory history with indices
    set -l i 0
    for dir in $dir_history
        echo (set_color $md3_primary)"│ "(set_color $md3_on_primary)"$i: $dir"(set_color normal)
        set i (math $i + 1)
    end
    
    echo (set_color $md3_primary)"└───────────────────────────────────────────────────────┘"(set_color normal)
    
    # Prompt for selection
    set -l max_index (math $i - 1)
    echo -n (set_color $md3_secondary)"Select directory [0-$max_index]: "(set_color normal)
    read -l selection
    
    # If selection is valid, navigate to it
    if test -n "$selection" && test $selection -ge 0 && test $selection -lt $i
        cd (dirs -p | sed -n (math $selection + 1)"p")
    end
end

# Material Design 3 styled command history search
function hh
    # Get command history
    set -l cmd_history (history | uniq | head -n 15)
    
    echo
    echo (set_color $md3_secondary)"┌─── Command History ───────────────────────────────┐"(set_color normal)
    
    # Show command history with indices
    set -l i 0
    for cmd in $cmd_history
        echo (set_color $md3_secondary)"│ "(set_color $md3_on_secondary)"$i: $cmd"(set_color normal)
        set i (math $i + 1)
    end
    
    echo (set_color $md3_secondary)"└───────────────────────────────────────────────────────┘"(set_color normal)
    
    # Prompt for selection
    set -l max_index (math $i - 1)
    echo -n (set_color $md3_tertiary)"Select command [0-$max_index]: "(set_color normal)
    read -l selection
    
    # If selection is valid, execute it
    if test -n "$selection" && test $selection -ge 0 && test $selection -lt $i
        set -l selected_cmd (history | uniq | sed -n (math $selection + 1)"p")
        commandline $selected_cmd
        commandline -f execute
    end
end

# Material Design 3 styled help function
function md3_help
    echo
    echo (set_color $md3_primary_container)"┌─── Material Design 3 Fish Shell Help ───────────────┐"(set_color normal)
    echo (set_color $md3_primary_container)"│"(set_color normal)
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+s"(set_color normal)" - Show command suggestions"
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+c"(set_color normal)" - Show command completions"
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+h"(set_color normal)" - Show directory history"
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+r"(set_color normal)" - Show command history"
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"help"(set_color normal)" - Show fish help"
    echo (set_color $md3_primary_container)"│"(set_color normal)
    echo (set_color $md3_primary_container)"└───────────────────────────────────────────────────────┘"(set_color normal)
end

# Override the help command with our Material Design 3 styled help
function help
    # If no arguments, show our custom help
    if test (count $argv) -eq 0
        md3_help
    else
        # Otherwise, show the regular fish help
        command help $argv
    end
end

# Add the Material Design 3 help to the fish_greeting
function __md3_help_hint --on-event fish_prompt
    # Only show the hint once per session
    if not set -q __md3_help_hint_shown
        set -g __md3_help_hint_shown 1
        echo (set_color $md3_outline)"Type 'help' for Material Design 3 Fish Shell help"(set_color normal)
    end
end

# Material Design 3 styled command timer
function __md3_timer_start --on-event fish_preexec
    set -g __md3_cmd_start_time (date +%s)
end

function __md3_timer_end --on-event fish_postexec
    if set -q __md3_cmd_start_time
        set -l end_time (date +%s)
        set -l elapsed (math $end_time - $__md3_cmd_start_time)
        
        # Only show for commands that took more than 5 seconds
        if test $elapsed -gt 5
            echo
            echo (set_color $md3_tertiary_container)"Command took $elapsed seconds to complete"(set_color normal)
        end
        
        # Clean up
        set -e __md3_cmd_start_time
    end
end

# Load the Material Design 3 colors if available
function __load_md3_colors --on-event fish_prompt
    if not set -q __md3_colors_loaded
        # Try to load the colors from the colors.fish file
        if test -f "$__fish_config_dir/conf.d/colors.fish"
            source "$__fish_config_dir/conf.d/colors.fish"
            set -g __md3_colors_loaded 1
        end
    end
end

# Initialize Material Design 3 features
__load_md3_colors
