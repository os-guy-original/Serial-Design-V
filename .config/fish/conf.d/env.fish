# Environment variables for fish shell

# XDG Base Directory
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"

# Default programs
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx BROWSER firefox
set -gx TERMINAL alacritty

# Path additions
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.npm/bin
fish_add_path ~/.yarn/bin

# FZF configuration
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}'"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"

# Less options
set -gx LESS "-R"
set -gx LESSHISTFILE "-"

# Colored man pages
set -gx LESS_TERMCAP_md (set_color --bold blue)
set -gx LESS_TERMCAP_me (set_color normal)
set -gx LESS_TERMCAP_se (set_color normal)
set -gx LESS_TERMCAP_so (set_color --background brblack white)
set -gx LESS_TERMCAP_ue (set_color normal)
set -gx LESS_TERMCAP_us (set_color --underline green)

# Go configuration
set -gx GOPATH "$HOME/go"
fish_add_path "$GOPATH/bin"

# Rust configuration
set -gx RUSTUP_HOME "$HOME/.rustup"
set -gx CARGO_HOME "$HOME/.cargo"

# Node.js
set -gx NODE_OPTIONS "--max-old-space-size=4096"

# Python
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Java
set -gx _JAVA_OPTIONS "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"

# GPG
set -gx GPG_TTY (tty)

# Locale settings
set -gx LANG "en_US.UTF-8"
set -gx LC_ALL "en_US.UTF-8" 