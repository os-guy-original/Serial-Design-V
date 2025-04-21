# Fish color theme settings

# Base colors
set -g fish_color_normal normal
set -g fish_color_command blue
set -g fish_color_param cyan
set -g fish_color_redirection yellow
set -g fish_color_comment brblack
set -g fish_color_error red --bold
set -g fish_color_escape magenta
set -g fish_color_operator green
set -g fish_color_end brmagenta
set -g fish_color_quote green
set -g fish_color_autosuggestion brblack
set -g fish_color_valid_path --underline
set -g fish_color_match --background=blue
set -g fish_color_search_match --background=yellow

# Pager colors
set -g fish_pager_color_prefix white --bold
set -g fish_pager_color_completion normal
set -g fish_pager_color_description yellow
set -g fish_pager_color_progress brwhite --background=cyan
set -g fish_pager_color_selected_background --background=brblack

# Make the selection color more visible
set -g fish_color_search_match --background=yellow
set -g fish_color_selection --background=blue

# Directory colors
set -g fish_color_cwd green
set -g fish_color_cwd_root red

# Syntax highlighting colors
set -g fish_color_keyword magenta
set -g fish_color_negation red
set -g fish_color_option cyan

# Man page colors
set -g man_blink red --bold
set -g man_bold green --bold
set -g man_standout yellow --bold
set -g man_underline cyan --underline 