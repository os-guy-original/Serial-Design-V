#!/bin/bash

# Usage: ./loading_overlay.sh [text] [duration]
# Shows a fullscreen overlay with loading animation and optional text
# Automatically closes after specified duration in seconds (default: 3)

TEXT="${1:-Loading...}"
DURATION="${2:-3}"

# Create a temporary file for our wlogout configuration
TEMP_CONFIG=$(mktemp)
TEMP_CSS=$(mktemp)

# Basic wlogout configuration
cat > "$TEMP_CONFIG" << EOF
{
    "label": "loading",
    "action": "sleep 0.1",
    "text": "$TEXT",
    "keybind": ""
}
EOF

# CSS styling for the loading screen
cat > "$TEMP_CSS" << EOF
* {
    background-image: none;
    font-family: "JetBrainsMono Nerd Font";
}

window {
    background-color: rgba(0, 0, 0, 0.8);
}

button {
    color: #ffffff;
    background-color: transparent;
    border-style: none;
    border-width: 0px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
    animation: rotate 1.5s linear infinite;
    margin: 5px;
    box-shadow: none;
    text-shadow: none;
    font-weight: bold;
    font-size: 25px;
}

button:focus {
    background-color: transparent;
    border-style: none;
}

@keyframes rotate {
    from {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzgiIGhlaWdodD0iMzgiIHZpZXdCb3g9IjAgMCAzOCAzOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiBzdHJva2U9IiNmZmYiPiAgICA8ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPiAgICAgICAgPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMSAxKSIgc3Ryb2tlLXdpZHRoPSIyIj4gICAgICAgICAgICA8Y2lyY2xlIHN0cm9rZS1vcGFjaXR5PSIuNSIgY3g9IjE4IiBjeT0iMTgiIHI9IjE4Ii8+ICAgICAgICAgICAgPHBhdGggZD0iTTM2IDE4YzAtOS45NC04LjA2LTE4LTE4LTE4Ij4gICAgICAgICAgICAgICAgPGFuaW1hdGVUcmFuc2Zvcm0gICAgICAgICAgICAgICAgICAgIGF0dHJpYnV0ZU5hbWU9InRyYW5zZm9ybSIgICAgICAgICAgICAgICAgICAgIHR5cGU9InJvdGF0ZSIgICAgICAgICAgICAgICAgICAgIGZyb209IjAgMTggMTgiICAgICAgICAgICAgICAgICAgICB0bz0iMzYwIDE4IDE4IiAgICAgICAgICAgICAgICAgICAgZHVyPSIxcyIgICAgICAgICAgICAgICAgICAgIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIi8+ICAgICAgICAgICAgPC9wYXRoPiAgICAgICAgPC9nPiAgICA8L2c+PC9zdmc+");
        transform: rotate(0deg);
    }
    to {
        background-image: url("data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzgiIGhlaWdodD0iMzgiIHZpZXdCb3g9IjAgMCAzOCAzOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiBzdHJva2U9IiNmZmYiPiAgICA8ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPiAgICAgICAgPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMSAxKSIgc3Ryb2tlLXdpZHRoPSIyIj4gICAgICAgICAgICA8Y2lyY2xlIHN0cm9rZS1vcGFjaXR5PSIuNSIgY3g9IjE4IiBjeT0iMTgiIHI9IjE4Ii8+ICAgICAgICAgICAgPHBhdGggZD0iTTM2IDE4YzAtOS45NC04LjA2LTE4LTE4LTE4Ij4gICAgICAgICAgICAgICAgPGFuaW1hdGVUcmFuc2Zvcm0gICAgICAgICAgICAgICAgICAgIGF0dHJpYnV0ZU5hbWU9InRyYW5zZm9ybSIgICAgICAgICAgICAgICAgICAgIHR5cGU9InJvdGF0ZSIgICAgICAgICAgICAgICAgICAgIGZyb209IjAgMTggMTgiICAgICAgICAgICAgICAgICAgICB0bz0iMzYwIDE4IDE4IiAgICAgICAgICAgICAgICAgICAgZHVyPSIxcyIgICAgICAgICAgICAgICAgICAgIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIi8+ICAgICAgICAgICAgPC9wYXRoPiAgICAgICAgPC9nPiAgICA8L2c+PC9zdmc+");
        transform: rotate(360deg);
    }
}
EOF

# Check if wlogout is installed
if ! command -v wlogout &> /dev/null; then
    echo "wlogout is not installed. Loading screen cannot be shown."
    exit 1
fi

# Launch wlogout with our configuration
wlogout --layout "$TEMP_CONFIG" --css "$TEMP_CSS" --protocol layer-shell &
WLOGOUT_PID=$!

# Kill wlogout after the duration
(sleep "$DURATION" && kill -9 "$WLOGOUT_PID" &>/dev/null) &

# Clean up temp files on exit
trap 'rm -f "$TEMP_CONFIG" "$TEMP_CSS"' EXIT
