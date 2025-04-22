# THIS IS A PART OF THE screenshot_shot-record.sh FILE

get_geometry() {
    slurp "$@"
}

geometry=$(get_geometry)
grim -g "$geometry" - | wl-copy
notify-send "Screenshot Copied" "Area screenshot copied to clipboard"
