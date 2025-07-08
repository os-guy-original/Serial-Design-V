function control_complete --description "Complete command with file selection using fzf"
    # Check if we're in interactive mode
    if not status --is-interactive
        echo "This function requires an interactive shell"
        return 1
    end
    
    # Save current command line buffer
    set -l cmd_buffer (commandline)
    
    if test -z "$cmd_buffer"
        echo "No command entered"
        commandline -f repaint
        return 1
    end
    
    # Extract the command part with any environment variables
    # This captures everything up to the last space, preserving env vars like ENV=value command
    set -l base_command $cmd_buffer
    
    # Find the position of the last space in the command using a more compatible approach
    set -l cmd_parts (string split " " -- "$cmd_buffer")
    
    if test (count $cmd_parts) -gt 1
        # There's at least one space in the command
        # Reconstruct the command up to the last part
        set -l last_part $cmd_parts[-1]
        set -l base_parts $cmd_parts[1..-2]
        set base_command (string join " " -- $base_parts)
        
        # If the last part is empty (command ends with a space), use the full command
        if test -z "$last_part"
            set base_command $cmd_buffer
        end
    end
    
    # Check if fzf is available
    if not type -q fzf
        pipe_line "fzf is not installed – cannot open file picker"
        return 1
    end
    
    # Create navigation options
    set -l parent_dir ".."
    set -l home_dir "~"
    set -l root_dir "/"
    
    # Get current directory files and folders
    set -l files_and_dirs (ls -a | grep -v '^\.$')
    
    # Prepare the selection list with navigation options at the top
    set -l selection_list $parent_dir $home_dir $root_dir $files_and_dirs
    
    # Create a simple preview script that works reliably in bash
    set -l preview_cmd 'if [ -d {} ]; then ls -la {}; elif [ -f {} ]; then echo "File: {}"; file -b {} 2>/dev/null; echo; echo "Stats:"; stat {} 2>/dev/null | head -n 5; echo; echo "Content:"; head -n 50 {} 2>/dev/null; else echo "Special item: {}"; fi'
    
    # Use fzf to select a file or directory
    set -l selection (printf "%s\n" $selection_list | fzf \
        --prompt="Select file> " \
        --header="↑/↓: navigate, Enter: select, Tab: multi-select, /: search, Ctrl-p: toggle preview" \
        --layout=reverse \
        --border \
        --height=40% \
        --preview="$preview_cmd" \
        --preview-window="right:50%" \
        --multi \
        --bind="ctrl-p:toggle-preview" \
        --bind="ctrl-u:preview-page-up" \
        --bind="ctrl-d:preview-page-down" \
        --bind="ctrl-n:page-down" \
        --bind="ctrl-b:page-up" \
        --bind="alt-j:down" \
        --bind="alt-k:up" \
        --color="hl:33,hl+:37,pointer:1,marker:2,bg+:234")
    
    # If selection was made
    if test $status -eq 0
        # Handle multiple selections
        set -l files_to_add ""
        set -l operation_succeeded false
        
        for item in $selection
            # Handle navigation options
            switch "$item"
                case ".."
                    cd ..
                    control_complete
                    return
                case "~"
                    cd ~
                    control_complete
                    return
                case "/"
                    cd /
                    control_complete
                    return
                case "*"
                    # Check if it's a directory
                    if test -d "$item"
                        cd "$item"
                        control_complete
                        return
                    end
                    
                    # Get absolute path for files
                    set -l abs_path (realpath "$item")
                    
                    # Escape spaces and special characters
                    set -l escaped_path (string escape "$abs_path")
                    
                    # Add to the list of files
                    set files_to_add "$files_to_add $escaped_path"
                    set operation_succeeded true
            end
        end
        
        # Append selection to command line if files were selected
        if test -n "$files_to_add"
            # Reset the command line to just the base command
            commandline -r $base_command
            
            # Append the selected files
            commandline -a "$files_to_add"
            
            # If operation succeeded, execute the command immediately
            if test "$operation_succeeded" = "true"
                commandline -f execute
            end
        end
    end
    
    # Repaint the command line
    commandline -f repaint
end 