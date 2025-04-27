# THIS IS A PART OF THE screenshot_shot-record.sh FILE

get_geometry() {
    slurp "$@"
}

geometry=$(get_geometry)
# Check if user canceled the selection
if [ -n "$geometry" ]; then
    grim -g "$geometry" - | wl-copy
    notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
fi
