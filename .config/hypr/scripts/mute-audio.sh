#!/bin/bash

# Toggle mute
pamixer -t

# Get the current mute status
if pamixer --get-mute | grep -q "true"; then
    swayosd --mute
else
    swayosd --unmute
fi
