# Cool Fish Shell Configuration

A modern, feature-rich configuration for the Fish shell with a beautiful prompt, useful functions, and productivity enhancements.

## Features

- 🎨 Modern and colorful prompt with Git integration
- 📊 Informative right prompt with command execution time and clock
- 🔍 Useful abbreviations and functions for improved productivity
- 📈 System information display on startup
- 🛠️ Enhanced command completion
- 🎯 Organized configuration with modular files

## Structure

- `config.fish`: Main configuration file
- `functions/`: Custom functions
  - `fish_prompt.fish`: Custom prompt function
  - `fish_right_prompt.fish`: Right-side prompt
  - `fish_greeting.fish`: Greeting with system information
- `conf.d/`: Configuration modules (loaded automatically)
  - `abbr.fish`: Command abbreviations
  - `functions.fish`: Utility functions
  - `theme.fish`: Color theme settings
  - `env.fish`: Environment variables

## Key Bindings

- `Ctrl+F`: Find files using fzf
- `Alt+C`: Change directory using fzf
- `Ctrl+R`: Search command history
- `Alt+E`: Edit command in $EDITOR
- `Ctrl+L`: Clear screen

## Utility Functions

- `weather [location]`: Display weather information
- `cheat [command]`: Show cheatsheet for commands
- `remind [time] [message]`: Set a reminder
- `ff [pattern]`: Find files matching pattern
- `fd [pattern]`: Find directories matching pattern
- `backup [file]`: Create a backup copy of a file
- `extract [archive]`: Extract various archive formats
- `mkcd [directory]`: Create and change to directory

## Requirements

- Fish shell 3.0+
- Git (for prompt Git integration)
- curl (for weather function)

## Installation

1. Backup your existing configuration:
   ```fish
   cp -r ~/.config/fish ~/.config/fish.backup
   ```

2. Clone this repository:
   ```fish
   git clone https://github.com/yourusername/fish-config.git ~/.config/fish
   ```

3. Start a new fish shell or source the configuration:
   ```fish
   source ~/.config/fish/config.fish
   ```

## Customization

You can add your own custom settings by:

1. Editing the existing files
2. Adding new files to the `conf.d/` directory
3. Adding custom functions to the `functions/` directory

## Tips

- Use `abbr -a` to create your own abbreviations
- Add custom paths with `fish_add_path`
- Customize the prompt colors in `functions/fish_prompt.fish` 