# Environment variables configuration

# Core environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERM xterm-256color

# Disable fish greeting (handled by custom greeting function)
set -g fish_greeting ""

# Theme settings
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

# FZF configuration
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always --line-range :500 {}'"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git" 