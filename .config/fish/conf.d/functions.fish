# Material Design 3 Theme Functions
# Theme-specific functions for Material Design integration
# Core functions are handled in modules/functions.fish

# Git find function (theme-specific)
function gf --description "Find files in git repository"
    if test (count $argv) -eq 0
        echo "Usage: gf <pattern>"
        return 1
    end
    git ls-files | grep $argv
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

# Note: cd function is defined in functions/core/cd.fish
# No need to override it here

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

# Material Design 3 styled command history search
function hh --description "Search command history with fzf"
    # Check if fzf is available
    if not type -q fzf
        echo "fzf is not installed"
        return 1
    end
    
    # Get unique history and let user select with fzf
    set -l selected_cmd (history | fzf --height 40% --reverse --border --prompt="Command History > " --preview-window=hidden)
    
    # If a command was selected, put it on the command line
    if test -n "$selected_cmd"
        commandline -r $selected_cmd
        commandline -f repaint
    end
end

# Material Design 3 styled help function
function md3_help
    echo
    echo (set_color $md3_primary_container)"┌─── Material Design 3 Fish Shell Help ───────────────┐"(set_color normal)
    echo (set_color $md3_primary_container)"│"(set_color normal)
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+s"(set_color normal)" - Show command suggestions"
    echo (set_color $md3_primary_container)"│ "(set_color $md3_on_primary_container)"Alt+c"(set_color normal)" - Show command completions"
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

# Bind Ctrl+Alt+C to the control_complete function
# Now moved to conf.d/control_complete_binding.fish
# bind \e\C-c control_complete
