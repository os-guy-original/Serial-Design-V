function fish_greeting
    # Only show the greeting if we're in an interactive shell
    if status is-interactive
        set_color cyan
        echo "┌─────────────────────────────────────────────────┐"
        echo "│ Welcome to fish, the friendly interactive shell │"
        echo "└─────────────────────────────────────────────────┘"
        set_color normal
        
        # System info with colors
        set_color brblue
        echo -n "󰌢 User: "
        set_color normal
        echo (whoami) 
        
        set_color brblue
        echo -n "󰇅 Host: "
        set_color normal
        # Use uname -n instead of hostname command which might not be available
        echo (uname -n)
        
        set_color brblue
        echo -n "󰍛 OS: "
        set_color normal
        echo (uname -rs)
        
        if command -sq uptime
            set_color brblue
            echo -n "󰔚 Uptime: "
            set_color normal
            echo (uptime -p | sed 's/up //')
        end
        
        if command -sq df
            set_color brblue
            echo -n "󰋊 Disk: "
            set_color normal
            echo (df -h / | grep / | awk '{print $3"/"$2" ("$5")";}')
        end
        
        if test -f /proc/meminfo
            set_color brblue
            echo -n "󰍛 Memory: "
            set_color normal
            set -l total (grep MemTotal /proc/meminfo | awk '{print $2}')
            set -l free (grep MemAvailable /proc/meminfo | awk '{print $2}')
            set -l used (math $total - $free)
            set -l percent (math -s 2 $used / $total \* 100)
            set -l total_gb (math -s 2 $total / 1024 / 1024)
            set -l used_gb (math -s 2 $used / 1024 / 1024)
            echo $used_gb"GB/"$total_gb"GB ("$percent"%)" 
        end
                
        echo
    end
end 