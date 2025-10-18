# Environment Variables Module
# Core environment configuration for Fish shell

# XDG Base Directory Specification
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_STATE_HOME "$HOME/.local/state"

# Default applications
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx BROWSER firefox
set -gx TERMINAL alacritty

# Shell behavior
set -g fish_greeting ""
set -gx TERM xterm-256color

# Locale settings
set -gx LANG "en_US.UTF-8"
set -gx LC_ALL "en_US.UTF-8"

# Less configuration
set -gx LESS "-R"
set -gx LESSHISTFILE "-"

# Colored man pages
set -gx LESS_TERMCAP_md (set_color --bold blue)
set -gx LESS_TERMCAP_me (set_color normal)
set -gx LESS_TERMCAP_se (set_color normal)
set -gx LESS_TERMCAP_so (set_color --background brblack white)
set -gx LESS_TERMCAP_ue (set_color normal)
set -gx LESS_TERMCAP_us (set_color --underline green)

# FZF configuration
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}'"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"

# GPG configuration
set -gx GPG_TTY (tty)

# Theme settings for Material Design
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