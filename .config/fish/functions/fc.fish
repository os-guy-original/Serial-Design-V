function fc --description "File complete - select files with fzf"
    # If no arguments, show a brief help message
    if test (count $argv) -eq 0
        echo "Usage: command fc"
        echo "Opens file selector for the command."
        echo
        echo "For more help, type 'cct' to see Control Complete Tips."
        return 0
    end
    
    # Call the control_complete function
    control_complete
end 