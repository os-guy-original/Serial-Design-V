# Aliases and Abbreviations Module
# Common shortcuts and command aliases

# File and directory operations
alias ls="ls --color=auto"
alias ll="ls -la"
alias la="ls -A"
alias lt="ls --tree"
alias l="ls -CF"

# Navigation shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
# Note: ~ and - are built-in fish shortcuts, no aliases needed

# Editor shortcuts removed - use your preferred editor

# Git shortcuts (using abbreviations for better completion)
abbr -a g git
abbr -a ga git add
abbr -a gaa git add --all
abbr -a gc git commit
abbr -a gcm git commit -m
abbr -a gp git push
abbr -a gpl git pull
abbr -a gst git status
abbr -a gss git status --short
abbr -a gcl git clone
abbr -a gco git checkout
abbr -a gsw git switch
abbr -a gb git branch
abbr -a glog git log --oneline --decorate --graph
abbr -a gd git diff
abbr -a gds git diff --staged

# System shortcuts
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"
alias df="df -h"
alias du="du -h"
alias free="free -h"
alias mkdir="mkdir -pv"
alias wget="wget -c"
alias curl="curl -L"

# Safety aliases
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Package manager shortcuts (Arch Linux)
alias pacman-unlock="sudo rm -rf /var/lib/pacman/db.lck"
alias pacman-update="sudo pacman -Syu"
alias pacman-search="pacman -Ss"
alias pacman-install="sudo pacman -S"
alias pacman-remove="sudo pacman -Rs"

# Fish configuration shortcuts
alias editfish="$EDITOR ~/.config/fish/config.fish"
alias reloadfish="source ~/.config/fish/config.fish"

# Quick system info
alias myip="curl -s ifconfig.me"
alias ports="netstat -tulanp"
alias meminfo="free -m -l -t"
alias psmem="ps auxf | sort -nr -k 4"
alias pscpu="ps auxf | sort -nr -k 3"

# Development shortcuts
alias serve="python -m http.server"
alias json="python -m json.tool"
alias urlencode="python -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))'"
alias urldecode="python -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))'"