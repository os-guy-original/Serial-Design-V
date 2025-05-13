#!/bin/bash

# User customizable options
BAR_STYLE="smooth"  # Options: "blocks", "dots", "smooth", "classic"
SHOW_PERCENTAGE=false  # Set to true to show percentage alongside the bar
BAR_LENGTH=12  # Length of the progress bar
NOTIFICATION_THRESHOLD=95  # Send notification when CPU+RAM average exceeds this percentage
NOTIFICATION_COOLDOWN=60  # Time in seconds before sending another notification

# Create user's waybar temp directory if it doesn't exist
USER_TEMP_DIR="$HOME/.cache/waybar"
mkdir -p "$USER_TEMP_DIR"

# Path to notification state file
NOTIFICATION_STATE_FILE="$USER_TEMP_DIR/system-monitor-notification"
DISPLAY_MODE_FILE="$USER_TEMP_DIR/system-monitor-mode"

# Check if a toggle was requested
if [ "$1" = "toggle" ]; then
    # Toggle display mode
    if [ -f "$DISPLAY_MODE_FILE" ] && [ "$(cat "$DISPLAY_MODE_FILE")" = "numbers" ]; then
        echo "bars" > "$DISPLAY_MODE_FILE"
    else
        echo "numbers" > "$DISPLAY_MODE_FILE"
    fi
    
    # Run the script again immediately to update the display
    $0
    exit 0
fi

# Check if display mode state file exists, if not create it
if [ ! -f "$DISPLAY_MODE_FILE" ]; then
    echo "numbers" > "$DISPLAY_MODE_FILE"
fi

# Function to get CPU usage
get_cpu_usage() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    printf "%.1f" $cpu_usage
}

# Function to get RAM usage
get_ram_usage() {
    mem_info=$(free -m | grep Mem)
    total_mem=$(echo $mem_info | awk '{print $2}')
    used_mem=$(echo $mem_info | awk '{print $3}')
    
    # Calculate percentage
    mem_percentage=$(awk "BEGIN {printf \"%.1f\", ($used_mem / $total_mem) * 100}")
    
    echo $mem_percentage
}

# Function to get storage usage
get_storage_usage() {
    storage_info=$(df -h / | grep -v Filesystem)
    storage_percentage=$(echo $storage_info | awk '{print $5}' | sed 's/%//')
    
    echo $storage_percentage
}

# Function to send notification if it hasn't been sent recently
send_notification_if_needed() {
    local cpu_ram_avg=$1
    
    # Check if notification was sent recently
    local current_time=$(date +%s)
    local can_send=true
    
    if [ -f "$NOTIFICATION_STATE_FILE" ]; then
        local last_notification_time=$(cat "$NOTIFICATION_STATE_FILE")
        local time_diff=$((current_time - last_notification_time))
        
        if [ $time_diff -lt $NOTIFICATION_COOLDOWN ]; then
            can_send=false
        fi
    fi
    
    if $can_send && [ $cpu_ram_avg -ge $NOTIFICATION_THRESHOLD ]; then
        notify-send -u critical "High System Usage Alert" "CPU and RAM usage average: ${cpu_ram_avg}%\nYour system is under heavy load!" -i dialog-warning
        echo "$current_time" > "$NOTIFICATION_STATE_FILE"
        return 0  # Notification was sent
    fi
    
    return 1  # No notification sent
}

# Function to create progress bar
create_bar() {
    local percentage=$1
    local bar_length=$BAR_LENGTH
    local filled_length=$(awk "BEGIN {printf \"%.0f\", $percentage * $bar_length / 100}")
    
    local bar=""
    
    # Different bar styles
    case $BAR_STYLE in
        "blocks")
            # Full blocks style
            for ((i=0; i<$filled_length; i++)); do
                bar="${bar}█"
            done
            
            for ((i=$filled_length; i<$bar_length; i++)); do
                bar="${bar}░"
            done
            ;;
            
        "dots")
            # Dots style
            for ((i=0; i<$filled_length; i++)); do
                bar="${bar}●"
            done
            
            for ((i=$filled_length; i<$bar_length; i++)); do
                bar="${bar}○"
            done
            ;;
            
        "smooth")
            # Smooth gradient blocks style
            local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
            local percentage_int=$(printf "%.0f" "$percentage")
            
            # Calculate exact position for each segment
            for ((i=0; i<$bar_length; i++)); do
                local segment_threshold=$((100 * i / bar_length))
                local next_threshold=$((100 * (i+1) / bar_length))
                
                if [ $percentage_int -ge $next_threshold ]; then
                    # Fully filled segment
                    bar="${bar}█"
                elif [ $percentage_int -ge $segment_threshold ]; then
                    # Partially filled segment - calculate which character to use
                    local level_within_segment=$(awk "BEGIN {printf \"%.0f\", ($percentage - $segment_threshold) * 8 / ($next_threshold - $segment_threshold)}")
                    if [ $level_within_segment -ge 8 ]; then
                        level_within_segment=7
                    fi
                    bar="${bar}${chars[$level_within_segment]}"
                else
                    # Empty segment
                    bar="${bar} "
                fi
            done
            ;;
            
        "classic")
            # Classic pipe-like bar
            bar="|"
            for ((i=0; i<$bar_length; i++)); do
                if ((i < filled_length)); then
                    bar="${bar}="
                else
                    bar="${bar} "
                fi
            done
            bar="${bar}|"
            ;;
    esac
    
    # Add percentage if enabled
    if $SHOW_PERCENTAGE; then
        bar="${bar} ${percentage}%"
    fi
    
    echo "$bar"
}

# Get all values
cpu=$(get_cpu_usage)
ram=$(get_ram_usage)
storage=$(get_storage_usage)

# Create progress bars
cpu_bar=$(create_bar $cpu)
ram_bar=$(create_bar $ram)
storage_bar=$(create_bar $storage)

# Define icons
cpu_icon="󰻠"    # CPU icon
ram_icon="󰍛"    # RAM icon
ssd_icon="󰋊"    # Storage icon

# Calculate resource usage
cpu_float=$(echo $cpu | awk '{print int($1)}')
ram_float=$(echo $ram | awk '{print int($1)}')
storage_float=$(echo $storage | awk '{print int($1)}')
average_usage=$(( (cpu_float + ram_float + storage_float) / 3 ))

# Calculate CPU+RAM average for notification
cpu_ram_avg=$(( (cpu_float + ram_float) / 2 ))

# Send notification if CPU+RAM average exceeds threshold
panic_mode=false
if send_notification_if_needed $cpu_ram_avg; then
    panic_mode=true
fi

# Get current display mode
display_mode=$(cat "$DISPLAY_MODE_FILE")

# Format text output based on display mode
if [ $cpu_ram_avg -ge $NOTIFICATION_THRESHOLD ]; then
    # Show a more dramatic warning in panic mode
    if [ "$display_mode" = "numbers" ]; then
        text_output="⚠️ ${cpu_icon} ${cpu}% ⚠️ ${ram_icon} ${ram}% ⚠️"
    else
        text_output="⚠️ ${cpu_icon} ${cpu_bar} ⚠️ ${ram_icon} ${ram_bar} ⚠️"
    fi
else
    if [ "$display_mode" = "numbers" ]; then
        text_output="${cpu_icon} ${cpu}% | ${ram_icon} ${ram}% | ${ssd_icon} ${storage}%"
    else
        text_output="${cpu_icon} ${cpu_bar} | ${ram_icon} ${ram_bar} | ${ssd_icon} ${storage_bar}"
    fi
fi

# Determine class for color coding based on average
if [ $cpu_ram_avg -ge $NOTIFICATION_THRESHOLD ]; then
    class="critical panic"
elif [ $average_usage -gt 80 ]; then
    class="critical"
elif [ $average_usage -gt 50 ]; then
    class="warning"
else
    class="normal"
fi

# Create more detailed tooltip with percentages
tooltip="System Resources\\n${cpu_icon} CPU: ${cpu}%\\n${ram_icon} RAM: ${ram}%\\n${ssd_icon} Storage: ${storage}%\\nAverage: ${average_usage}%\\nCPU+RAM Avg: ${cpu_ram_avg}%\\n\\nClick to toggle view"

# Add warning to tooltip if in panic mode
if [ $cpu_ram_avg -ge $NOTIFICATION_THRESHOLD ]; then
    tooltip="${tooltip}\\n\\n⚠️ SYSTEM UNDER HEAVY LOAD ⚠️\\nConsider closing some applications"
fi

# Output JSON for Waybar - ensuring proper JSON formatting
printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text_output" "$tooltip" "$class" 