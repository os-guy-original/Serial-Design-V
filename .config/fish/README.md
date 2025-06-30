# Fish Shell Configuration

This is a restructured Fish shell configuration that maintains all Material Design elements while providing a cleaner, more modular organization.

## Directory Structure

```
~/.config/fish/
├── config.fish              # Main configuration file
├── fish_plugins             # Fisher plugins
├── fish_variables           # Fish variables
├── README.md                # This file
├── core/                    # Core configuration files
│   ├── aliases.fish         # Aliases and abbreviations
│   ├── env.fish             # Environment variables
│   ├── functions.fish       # Core utility functions
│   └── paths.fish           # PATH configuration
├── conf.d/                  # Material Design and plugin configurations
│   ├── abbr.fish            # Abbreviations
│   ├── autopair.fish        # Auto-pairing brackets
│   ├── colors.fish          # Material Design colors
│   ├── control_complete_binding.fish # Key bindings for control_complete
│   ├── dynamic_paths.fish   # Dynamic path handling
│   ├── env.fish             # Environment variables
│   ├── functions.fish       # Material Design functions
│   ├── theme.fish           # Theme configuration
│   ├── user_paths.fish      # User path configuration
│   └── z.fish               # Z directory jumping
└── functions/               # Fish functions
    ├── control_complete.fish # File selection with fzf
    ├── fc.fish              # File completion shortcut
    ├── file_manager.fish    # File manager
    ├── find_n_run.fish      # Find and run commands
    ├── fish_*.fish          # Fish core function overrides
    ├── md3_*.fish           # Material Design 3 functions
    └── ...                  # Other utility functions
```

## Features

- **Material Design 3 Theme**: Preserved all Material Design elements
- **Modular Configuration**: Separated into logical components
- **Enhanced File Navigation**: Using `control_complete` and `fc` commands
- **Custom Prompts**: Material Design inspired prompts
- **Utility Functions**: Various helper functions for daily tasks

## Key Bindings

- `Alt+C`: Open file selection menu (control_complete)
- `Ctrl+Alt+F`: Find and run commands

## Usage

You can also directly use the `fc` command after typing a command to select files:

```
gedit fc
```

This will open the file selection interface. Once you select a file, the command will execute automatically.

## Auto-execution

When you select a file using Alt+C or the `fc` command, the command will execute automatically after file selection.

## Customization

- Add personal aliases to `core/aliases.fish`
- Add environment variables to `core/env.fish`
- Add PATH entries to `core/paths.fish`
- Add utility functions to `core/functions.fish`

Material Design elements are preserved in the `conf.d/` directory. 