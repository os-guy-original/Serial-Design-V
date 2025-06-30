function fish_greeting
    # Only show the greeting if we're in an interactive shell
    if status is-interactive
        # Use our material box functions
        material_box_start cyan "Welcome to fish, the friendly shell"
        material_box_end cyan
        
        # System info with circular indicators and Material You style
        echo
        
        # User info with circular indicator
        set_color brblue
        echo -n "⬤ User: "
        set_color normal
        echo (whoami) 
        
        # Host info with circular indicator
        set_color brblue
        echo -n "⬤ Host: "
        set_color normal
        echo (uname -n)
        
        # OS info with circular indicator
        set_color brblue
        echo -n "⬤ OS: "
        set_color normal
        echo (uname -rs)
        
        # Uptime with circular indicator
        if command -sq uptime
            set_color brblue
            echo -n "⬤ Uptime: "
            set_color normal
            echo (uptime -p | sed 's/up //')
        end
        
        # Disk usage with circular indicator and progress bar
        if command -sq df
            set_color brblue
            echo -n "⬤ Disk: "
            set_color normal
            
            # Get disk usage percentage
            set -l disk_info (df -h / | grep / | awk '{print $3"/"$2" ("$5")"}')
            set -l disk_percent (df -h / | grep / | awk '{print $5}' | tr -d '%')
            echo -n $disk_info " "
            
            # Create a visual progress indicator using our function
            material_progress_bar brblue $disk_percent
            echo
        end
        
        # Memory usage with circular indicator and progress bar
        if test -f /proc/meminfo
            set_color brblue
            echo -n "⬤ Memory: "
            set_color normal
            
            # Calculate memory usage
            set -l total (grep MemTotal /proc/meminfo | awk '{print $2}')
            set -l free (grep MemAvailable /proc/meminfo | awk '{print $2}')
            set -l used (math $total - $free)
            set -l percent (math -s 2 $used / $total \* 100)
            set -l total_gb (math -s 2 $total / 1024 / 1024)
            set -l used_gb (math -s 2 $used / 1024 / 1024)
            
            # Display memory info
            echo -n $used_gb"GB/"$total_gb"GB ("$percent"%) "
            
            # Create a visual progress indicator using our function
            material_progress_bar brblue $percent
            echo
        end
        
        # Date with circular indicator
        set_color brblue
        echo -n "⬤ Date: "
        set_color normal
        echo (date "+%A, %B %d, %Y")
        
        # Time with circular indicator
        set_color brblue
        echo -n "⬤ Time: "
        set_color normal
        echo (date "+%H:%M:%S")
        
        echo
        
        # Random tip section with (i) formatting
        set_color yellow
        echo -n "(i) "
        set_color brmagenta
        echo -n "TIP: "
        set_color normal
        
        # Array of fish and kitty tips customized for the user's configuration
        set -l tips
        set -a tips "Press Alt+C after typing a command to select files with the interactive file selector"
        set -a tips "Use 'command fc' to select files with the interactive file selector"
        set -a tips "Type 'cct' to see all Control Complete tips and keyboard shortcuts"
        set -a tips "Control Complete (Alt+C) automatically executes commands after file selection"
        set -a tips "Control Complete preserves environment variables when selecting files"
        set -a tips "In the file selector (Alt+C), use Tab to select multiple files at once"
        set -a tips "When using Alt+C, select directories to navigate into them"
        set -a tips "Control Complete works with any command that accepts file paths"
        set -a tips "Press Ctrl+Alt+F to use the file_manager function for browsing files"
        set -a tips "Use the 'mkcd' function to create a directory and cd into it in one command"
        set -a tips "The 'extract' function can handle various archive formats automatically"
        set -a tips "Use 'take' as a shortcut to create and enter a directory in one step"
        set -a tips "Quick directory navigation: .. (one level up), ... (two levels), .... (three levels)"
        set -a tips "Your man pages are colorized for better readability"
        set -a tips "The 'cd' command automatically lists directory contents after changing directories"
        set -a tips "Use 'glog' to see a nicely formatted git log with graph"
        set -a tips "In kitty, press Ctrl+Shift+H to see a colorful shortcuts guide"
        set -a tips "Change kitty cursor appearance with Ctrl+Shift+A>C>1 (beam), 2 (block), or 3 (underline)"
        set -a tips "Adjust kitty opacity with Ctrl+Shift+A>M (increase) or Ctrl+Shift+A>L (decrease)"
        set -a tips "In kitty, use Ctrl+Shift+Plus/Minus to adjust font size"
        set -a tips "Your right prompt shows execution time for commands that take over 5 seconds"
        set -a tips "The right prompt shows background jobs with a yellow circle indicator"
        set -a tips "Your right prompt detects Python, Node, Ruby, Go, and Rust environments"
        set -a tips "You have JetBrains Mono configured as your terminal font"
        set -a tips "Use select_editor() in file_manager to choose from available text editors"
        set -a tips "Your fish config uses Material You design elements throughout the shell"
        
        # Select and display a random tip
        set -l random_index (random 1 (count $tips))
        echo $tips[$random_index]
        
        echo
        # Help hint is now shown by __md3_help_hint, so avoid duplicate line here
    end
end 