# Aliases and abbreviations

# File and directory operations
alias ls="ls --color=auto"
alias ll="ls -la"
alias la="ls -A"
alias lt="ls --tree"

# Editor shortcuts
alias vi="nvim"
alias vim="nvim"

# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gst="git status"
alias gcl="git clone"
alias gco="git checkout"
alias gsw="git switch"
alias glog="git log --oneline --decorate --graph"

# Navigation shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# System shortcuts
alias pacman-unlock="sudo rm -rf /var/lib/pacman/db.lck"

# Fish configuration shortcuts
alias editfish="$EDITOR ~/.config/fish/config.fish" 