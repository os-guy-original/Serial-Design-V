#!/bin/bash

# Check if wf-recorder is running
if pgrep -x "wf-recorder" >/dev/null; then
    echo '{"text": "⚫ Recording", "class": "recording"}'
else
    echo '{"text": "", "class": ""}'
fi 