function fish_control_complete_tips --description "Show tips for using the control_complete feature"
    set_color $fish_color_command
    echo "Control Complete Tips"
    set_color normal
    echo "===================="
    echo
    
    set_color $fish_color_param
    echo "Basic Usage:"
    set_color normal
    echo "1. Type a command (e.g., 'gedit')"
    echo "2. Press Alt+C to open the file selector"
    echo "3. Navigate and select a file"
    echo "4. The command will execute automatically with the selected file"
    echo
    
    set_color $fish_color_param
    echo "Navigation:"
    set_color normal
    echo "- Arrow keys: Navigate up/down"
    echo "- Alt+j/Alt+k: Alternative navigation"
    echo "- Ctrl+n/Ctrl+p: Page down/up"
    echo "- /: Search for files"
    echo "- Tab: Multi-select files"
    echo
    
    set_color $fish_color_param
    echo "Directory Navigation:"
    set_color normal
    echo "- '..' at the top: Go to parent directory"
    echo "- '~' at the top: Go to home directory"
    echo "- '/' at the top: Go to root directory"
    echo "- Select any directory: Enter that directory"
    echo
    
    set_color $fish_color_param
    echo "Preview Panel:"
    set_color normal
    echo "- Ctrl+p: Toggle preview panel"
    echo "- Ctrl+u/Ctrl+d: Scroll preview up/down"
    echo
    
    set_color $fish_color_param
    echo "Environment Variables:"
    set_color normal
    echo "- Works with environment variables: ENV=value command Alt+C"
    echo "- Preserves all environment variables when selecting files"
    echo
    
    set_color $fish_color_param
    echo "Alternative Usage:"
    set_color normal
    echo "- Type 'command fc' to use the file selector (fc is an alias for control_complete)"
    echo
    
    set_color $fish_color_param
    echo "Examples:"
    set_color normal
    echo "- gedit Alt+C                  # Select a file to edit with gedit"
    echo "- LANG=en_US.UTF-8 less Alt+C  # View a file with specific locale"
    echo "- mpv Alt+C                    # Play a media file"
    echo "- cd Alt+C                     # Navigate to a directory"
    echo
end 