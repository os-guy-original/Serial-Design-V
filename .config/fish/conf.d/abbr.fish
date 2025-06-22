# Fish abbreviations - similar to aliases but expand in the command line
# when you press Space or Enter, allowing for easier editing

# Using the correct -a syntax for all abbreviations
# All multi-word abbreviations are quoted

# System commands
abbr -a c "clear"
abbr -a e "$EDITOR"
abbr -a r "ranger"
abbr -a h "history"
abbr -a j "jobs"

# Directory navigation
abbr -a .. "cd .."
abbr -a ... "cd ../.."
abbr -a .... "cd ../../.."
abbr -a ..... "cd ../../../.."

# ls commands
abbr -a l "ls"
abbr -a ll "ls -l"
abbr -a lll "ls -la"
abbr -a la "ls -A"

# Git abbreviations
abbr -a g "git"
abbr -a ga "git add"
abbr -a gaa "git add --all"
abbr -a gb "git branch"
abbr -a gc "git commit -m"
abbr -a gca "git commit --amend"
abbr -a gcl "git clone"
abbr -a gco "git checkout"
abbr -a gd "git diff"
abbr -a gp "git push"
abbr -a gpl "git pull"
abbr -a grm "git rm"
abbr -a gst "git status"

# Package management
abbr -a pi "sudo pacman -S"
abbr -a pu "sudo pacman -Syu"
abbr -a pq "pacman -Q"
abbr -a pr "sudo pacman -R"
abbr -a yi "sudo yay -S"
abbr -a yu "sudo yay -Syu"

# System commands
abbr -a sf "source ~/.config/fish/config.fish"
abbr -a sc "systemctl"
abbr -a ssc "sudo systemctl"
abbr -a jc "journalctl"
abbr -a df "df -h"
abbr -a du "du -h"
abbr -a free "free -h"
abbr -a open "xdg-open"

# Docker abbreviations
abbr -a d "docker"
abbr -a dc "docker compose"
abbr -a dps "docker ps"
abbr -a di "docker images"

# Network commands
abbr -a myip "curl ifconfig.me"
abbr -a ports "netstat -tulanp" 