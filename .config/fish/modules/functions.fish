# Core Functions Module
# Essential utility functions for Fish shell

# Directory operations
function mkcd --description "Create directory and cd into it"
    if test (count $argv) -eq 0
        echo "Usage: mkcd <directory_name>"
        return 1
    end
    mkdir -p $argv && cd $argv
end

function take --description "Create directory and cd into it (modern version)"
    if test (count $argv) -eq 0
        echo "Usage: take <directory_name>"
        return 1
    end
    mkdir -p $argv && cd $argv
end

# File operations
function backup --description "Create a timestamped backup of a file"
    if test (count $argv) -eq 0
        echo "Usage: backup <file>"
        return 1
    end
    cp $argv $argv.(date +%Y%m%d%H%M%S).bak
end

function extract --description "Extract various archive formats"
    if test (count $argv) -eq 0
        echo "Usage: extract <archive_file>"
        return 1
    end
    
    if not test -f $argv[1]
        echo "Error: '$argv[1]' is not a valid file"
        return 1
    end
    
    switch $argv[1]
        case '*.tar.bz2'
            tar xjf $argv[1]
        case '*.tar.gz'
            tar xzf $argv[1]
        case '*.bz2'
            bunzip2 $argv[1]
        case '*.rar'
            unrar x $argv[1]
        case '*.gz'
            gunzip $argv[1]
        case '*.tar'
            tar xf $argv[1]
        case '*.tbz2'
            tar xjf $argv[1]
        case '*.tgz'
            tar xzf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*.Z'
            uncompress $argv[1]
        case '*.7z'
            7z x $argv[1]
        case '*.xz'
            unxz $argv[1]
        case '*.exe'
            cabextract $argv[1]
        case '*'
            echo "Error: '$argv[1]' cannot be extracted via extract"
            return 1
    end
end

# Search functions
function ff --description "Find files by name"
    if test (count $argv) -eq 0
        echo "Usage: ff <pattern>"
        return 1
    end
    find . -type f -iname "*$argv*" 2>/dev/null
end

function fd --description "Find directories by name"
    if test (count $argv) -eq 0
        echo "Usage: fd <pattern>"
        return 1
    end
    find . -type d -iname "*$argv*" 2>/dev/null
end

function find_replace --description "Find and replace text in files"
    if test (count $argv) -lt 2
        echo "Usage: find_replace <find_pattern> <replace_pattern> [file_pattern]"
        return 1
    end
    
    set -l file_pattern "."
    if test (count $argv) -ge 3
        set file_pattern $argv[3]
    end
    
    find $file_pattern -type f -exec grep -l "$argv[1]" {} \; | xargs sed -i "s/$argv[1]/$argv[2]/g"
end

# Process management
function psgrep --description "Search for processes"
    if test (count $argv) -eq 0
        echo "Usage: psgrep <pattern>"
        return 1
    end
    ps aux | grep $argv | grep -v grep
end

function killgrep --description "Kill processes by name"
    if test (count $argv) -eq 0
        echo "Usage: killgrep <pattern>"
        return 1
    end
    
    set -l pids (pgrep $argv)
    if test -n "$pids"
        echo "Killing processes: $pids"
        kill $pids
    else
        echo "No processes found matching '$argv'"
    end
end

# System information
function path --description "Print PATH components one per line"
    echo $PATH | tr : '\n'
end

function is_tmux --description "Check if running inside tmux"
    test -n "$TMUX"
end

function weather --description "Get weather information"
    set -l location $argv[1]
    if test -z "$location"
        set location "auto"
    end
    curl -s "wttr.in/$location?format=%l:+%c+%t,+%h,+%w"
    echo
end

function cheat --description "Get command cheatsheet"
    if test (count $argv) -eq 0
        echo "Usage: cheat <command>"
        return 1
    end
    curl -s "cheat.sh/$argv[1]"
end

# Development utilities
function vid2gif --description "Convert video to gif"
    if test (count $argv) -lt 2
        echo "Usage: vid2gif <input> <output.gif>"
        return 1
    end
    
    ffmpeg -i $argv[1] -vf "fps=10,scale=720:-1:flags=lanczos" -c:v gif $argv[2]
end

function serve --description "Start a simple HTTP server"
    set -l port 8000
    if test (count $argv) -ge 1
        set port $argv[1]
    end
    
    echo "Starting HTTP server on port $port..."
    python -m http.server $port
end

function json_pretty --description "Pretty print JSON"
    if test (count $argv) -eq 0
        python -m json.tool
    else
        cat $argv[1] | python -m json.tool
    end
end

# Network utilities
function myip --description "Get external IP address"
    curl -s ifconfig.me
    echo
end

function localip --description "Get local IP address"
    ip route get 1.1.1.1 | awk '{print $7}' | head -1
end

# Quick reminders
function remind --description "Set a reminder notification"
    if test (count $argv) -lt 2
        echo "Usage: remind <time> <message>"
        echo "Example: remind 15m 'Take a break'"
        return 1
    end
    
    set -l time $argv[1]
    set -l message (string join " " $argv[2..-1])
    
    echo "notify-send 'Reminder' '$message'" | at $time 2>/dev/null
    if test $status -eq 0
        echo "Reminder set for $time: $message"
    else
        echo "Failed to set reminder. Make sure 'at' command is available."
    end
end