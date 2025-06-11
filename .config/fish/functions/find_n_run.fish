function find_n_run
    # Ensure fzf is available
    if not type -q fzf
        pipe_line "fzf is not installed – cannot open picker"
        return 1
    end

    # Check if we're in interactive mode
    if not status is-interactive
        echo "This function must be run in interactive mode."
        return 1
    end

    # Create a temporary file for commands
    set -l tmp_file (mktemp)
    
    # Collect initial commands quickly
    for dir in (string split ':' $PATH)
        if test -d $dir
            find $dir -maxdepth 1 -type f -executable -not -path "*/\.*" -printf "%f\n" 2>/dev/null >> $tmp_file &
        end
    end
    
    # Wait briefly for initial results
    sleep 0.1
    
    # Ensure we have at least some commands
    if test ! -s $tmp_file
        # If file is empty, add some basic commands
        echo "ls" > $tmp_file
        echo "cd" >> $tmp_file
        echo "grep" >> $tmp_file
    end

    # Use fzf with a preview window that shows the first part of the man page (if any)
    set -lx MANPAGER cat
    set -l selected (
        sort -u $tmp_file | fzf \
            --prompt="run> " \
            --height=60% \
            --layout=reverse \
            --border \
            --preview="man {1} 2>/dev/null | col -bx | head -n 30 || echo 'Not found in Manual Page'" \
            --preview-window=down:60%
    )
    
    # Clean up temp file
    rm -f $tmp_file
    
    if test -z "$selected"
        return 0
    end

    # Insert chosen command and execute it
    commandline -t ""
    commandline -i "$selected "
    commandline -f execute
end 