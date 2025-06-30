#!/usr/bin/env fish

# Test script for control_complete function

echo "Testing control_complete functionality"
echo "======================================="
echo

echo "1. Checking if control_complete function exists..."
if functions -q control_complete
    echo "✓ control_complete function exists"
else
    echo "✗ control_complete function does not exist"
    echo "Please ensure the function is properly defined in ~/.config/fish/functions/control_complete.fish"
    exit 1
end

echo "2. Checking if fzf is installed..."
if type -q fzf
    echo "✓ fzf is installed"
else
    echo "✗ fzf is not installed"
    echo "Please install fzf using your package manager"
    exit 1
end

echo "3. Checking key bindings..."
echo "The following key bindings should be available:"
echo "- Alt+C"
echo "- Ctrl+Alt+C (multiple variants)"
echo "- Ctrl+F"
echo "- You can also type 'fc' after a command"

echo
echo "To test the function:"
echo "1. Start a new fish shell"
echo "2. Type a command (e.g., 'gedit')"
echo "3. Press Alt+C or Ctrl+F"
echo "4. Or type 'fc' after the command"
echo "5. Select a file using the fzf interface"

echo
echo "If the key bindings don't work, you can manually add them to your fish configuration:"
echo "bind \\ec control_complete     # Alt+C"
echo "bind \\cf control_complete     # Ctrl+F"
echo
echo "You can add these lines to ~/.config/fish/config.fish" 