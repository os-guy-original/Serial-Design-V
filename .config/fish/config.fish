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
set -g fish_color_normal #f1dedc,#f1dedc,#f1dedc
set -g fish_color_command #ffdad6,#ffdad6,#ffdad6 --bold
set -g fish_color_quote #ffdad6,#ffdad6,#ffdad6
set -g fish_color_redirection #ffb4ac,#ffb4ac,#ffb4ac
set -g fish_color_end #e7bdb8,#e7bdb8,#e7bdb8
set -g fish_color_error #ffb4ab,#ffb4ab,#ffb4ab
set -g fish_color_param 
set -g fish_color_comment 
set -g fish_color_match  --background=#73332e,#73332e,#73332e
set -g fish_color_search_match  --background=#73332e,#73332e,#73332e
set -g fish_color_operator #ffdad6,#ffdad6,#ffdad6
set -g fish_color_escape #fedfa6,#fedfa6,#fedfa6
set -g fish_color_autosuggestion 

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
    mkdir -p $argv && cd $argv
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
    ls -A
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


# Material You colors - generated from current wallpaper
