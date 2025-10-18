# Key binding for the control_complete function
# Use Alt+C for file selection (different from Ctrl+C which cancels)

# Ensure Ctrl+C works normally (cancel/interrupt)
bind \cc __fish_cancel_commandline

# Alt+C binding for control_complete (Meta+C, not Ctrl+C)
bind \ec control_complete

# Alt+R binding for command history (hh)
bind \er hh 