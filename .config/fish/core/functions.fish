# Core functions

# Create directory and cd into it
function mkcd
    mkdir -p $argv
    cd $argv
end

# Modern "take" command: create directory and cd into it
function take
    if count $argv > /dev/null
        mkdir -p $argv && cd $argv
    else
        echo "Usage: take <directory_name>"
        echo "Creates a directory and changes to it in one command."
        return 1
    end
end

# Extract various archive formats
function extract
    if test -f $argv
        switch $argv
            case '*.tar.bz2'
                tar xjf $argv
            case '*.tar.gz'
                tar xzf $argv
            case '*.bz2'
                bunzip2 $argv
            case '*.rar'
                unrar x $argv
            case '*.gz'
                gunzip $argv
            case '*.tar'
                tar xf $argv
            case '*.tbz2'
                tar xjf $argv
            case '*.tgz'
                tar xzf $argv
            case '*.zip'
                unzip $argv
            case '*.Z'
                uncompress $argv
            case '*.7z'
                7z x $argv
            case '*'
                echo "'$argv' cannot be extracted via extract"
        end
    else
        echo "'$argv' is not a valid file"
    end
end

# Colorized man pages
function man
    set -x LESS_TERMCAP_md (set_color --bold blue)
    set -x LESS_TERMCAP_me (set_color normal)
    set -x LESS_TERMCAP_se (set_color normal)
    set -x LESS_TERMCAP_so (set_color --background brblack white)
    set -x LESS_TERMCAP_ue (set_color normal)
    set -x LESS_TERMCAP_us (set_color --underline green)
    command man $argv
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