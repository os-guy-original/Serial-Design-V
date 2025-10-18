# Python Environment Integration
# Pyenv configuration for Fish shell

if type -q pyenv
    set -gx PYENV_ROOT "$HOME/.pyenv"
    fish_add_path "$PYENV_ROOT/bin"
    
    # Initialize pyenv
    pyenv init - | source
    
    # Python configuration
    set -gx PYTHONDONTWRITEBYTECODE 1
    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
end