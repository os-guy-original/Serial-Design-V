#!/usr/bin/env fish

# Set variables
set -g fish_greeting ""  # Disable the welcome message
set -g theme_display_user yes
set -g theme_display_hostname yes
set -g theme_display_cmd_duration yes
set -g theme_title_display_process yes
set -g theme_title_display_path yes
set -g theme_title_use_abbreviated_path yes
set -g theme_color_scheme dark
set -g theme_display_git yes
set -g theme_display_git_dirty yes
set -g theme_display_git_untracked yes
set -g theme_nerd_fonts yes

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERM xterm-256color

# Custom prompt colors
set -g fish_color_normal normal
set -g fish_color_command blue
set -g fish_color_quote green
set -g fish_color_redirection cyan
set -g fish_color_end normal
set -g fish_color_error red
set -g fish_color_param normal
set -g fish_color_comment brblack
set -g fish_color_match --background=brblue
set -g fish_color_search_match --background=brblack
set -g fish_color_operator cyan
set -g fish_color_escape yellow
set -g fish_color_autosuggestion brblack

# Path additions
fish_add_path ~/.local/bin

# Aliases (using standard syntax instead of abbr)
alias ls="ls --color=auto"
alias ll="ls -la"
alias la="ls -A"
alias lt="ls --tree"
alias vi="nvim"
alias vim="nvim"
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gst="git status"
alias gcl="git clone"
alias gco="git checkout"
alias gsw="git switch"

# Useful functions
function mkcd
    mkdir -p $argv
    cd $argv
end

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

# Quick directory navigation
function .. 
    cd ..
end

function ... 
    cd ../..
end

function .... 
    cd ../../..
end

function .....
    cd ../../../..
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

# Enhanced cd command with directory listing
function cd
    if count $argv > /dev/null
        builtin cd $argv
    else
        builtin cd ~
    end
    
    # Store the current directory for the output message
    set -l from_dir $PWD
    
    # Get directory contents with ls
    set -l ls_output (ls -la)
    
    # Print a nicely formatted message
    echo "| Directory Changed"
    echo "| From: $from_dir"
    echo "| To: $PWD"
    echo "| "
    echo "| Directory Contents:"
    
    # Process each line of ls output to highlight just the filenames
    for line in $ls_output
        if string match -q "total*" $line
            # Print the total line as is
            echo "| $line"
        else
            # For file listings, split and highlight just the filename
            set -l parts (string split -r -m 8 " " $line)
            if test (count $parts) -gt 1
                set -l perms_and_info (string join " " $parts[1..-2])
                set -l filename $parts[-1]
                
                # Print permissions and info in normal color, filename in brighter color
                echo -n "| $perms_and_info "
                set_color brwhite
                echo $filename
                set_color normal
            else
                # Fallback for unexpected format
                echo "| $line"
            end
        end
    end
end

# Git helpers
function glog
    git log --oneline --decorate --graph
end

# Initialize starship prompt if it exists (an excellent alternative prompt)
if command -v starship > /dev/null
    starship init fish | source
end

# Check if fisher is installed
if not functions -q fisher
    echo "Installing fisher package manager..."
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
end

# Source additional config files if they exist
for file in ~/.config/fish/conf.d/*.fish
    source $file
end

# Material You Fish Shell Configuration
# This file loads all the Material You design elements for fish shell

# Source all function files
for file in ~/.config/fish/functions/*.fish
    source $file
end

# Set fish greeting to show on startup
set -U fish_greeting fish_greeting

# Set fish prompt
set -U fish_prompt fish_prompt

# Set fish right prompt
set -U fish_right_prompt fish_right_prompt

# Override command not found handler
function __fish_command_not_found_handler --on-event fish_command_not_found
    fish_command_not_found $argv
end

# Bind Ctrl+Alt+F to find_n_run
bind \e\cf find_n_run 