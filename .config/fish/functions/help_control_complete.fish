function help_control_complete --description "Display help for control_complete"
    set_color $fish_color_command
    echo "control_complete - File selection with fzf"
    set_color normal
    echo
    
    echo "The control_complete function provides an interactive file selection interface"
    echo "using fzf. It allows you to easily select files for commands."
    echo
    
    set_color $fish_color_param
    echo "Binding:"
    set_color normal
    echo "Alt+C"
    echo
    
    set_color $fish_color_param
    echo "Usage:"
    set_color normal
    echo "1. Type a command (e.g., 'gedit')"
    echo "2. Press Alt+C to open the file selector"
    echo "3. Select a file and it will be appended to your command"
    echo "4. The command will execute automatically"
    echo
    
    set_color $fish_color_param
    echo "Alternative:"
    set_color normal
    echo "command fc"
    echo
    
    set_color $fish_color_param
    echo "Tips:"
    set_color normal
    echo "Type 'cct' for detailed usage tips"
    echo
    
    set_color $fish_color_param
    echo "Examples:"
    set_color normal
    echo "gedit Alt+C"
    echo "ENV=value command Alt+C"
    echo "mpv fc"
    echo
end 