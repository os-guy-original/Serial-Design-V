# Kiro IDE Integration
# Initialize Kiro shell integration if available

if type -q kiro; and string match -q "$TERM_PROGRAM" "kiro"
    . (kiro --locate-shell-integration-path fish) 2>/dev/null
end