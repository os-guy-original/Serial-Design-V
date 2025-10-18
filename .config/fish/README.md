# Fish Shell Configuration

A modern, modular Fish shell configuration with Material Design 3 theme integration. Organized for better maintainability, performance, and extensibility.

## Directory Structure

```
~/.config/fish/
├── config.fish              # Main configuration file (modular loader)
├── fish_plugins             # Fisher plugins
├── fish_variables           # Fish variables
├── README.md                # This documentation
├── modules/                 # Core configuration modules
│   ├── env.fish             # Environment variables & XDG compliance
│   ├── paths.fish           # Dynamic PATH management
│   ├── aliases.fish         # Aliases and abbreviations
│   └── functions.fish       # Core utility functions
├── integrations/            # Development environment integrations
│   ├── pyenv.fish           # Python environment (pyenv)
│   ├── conda.fish           # Conda integration (optional)
│   ├── android.fish         # Android SDK configuration
│   ├── java.fish            # Java development tools
│   └── kiro.fish            # Kiro IDE integration
├── conf.d/                  # Plugin configurations & Material Design theme
│   ├── abbr.fish            # Abbreviations
│   ├── autopair.fish        # Auto-pairing brackets
│   ├── colors.fish          # Material Design 3 colors
│   ├── control_complete_binding.fish # Key bindings
│   ├── dynamic_paths.fish   # Dynamic path handling
│   ├── env.fish             # Plugin-specific environment
│   ├── functions.fish       # Theme-specific functions
│   ├── theme.fish           # Material Design theme
│   ├── user_paths.fish      # User path configuration
│   └── z.fish               # Z directory jumping
└── functions/               # Organized function groups
    ├── core/                # Core fish overrides & utilities
    │   ├── fish_prompt.fish
    │   ├── fish_greeting.fish
    │   ├── cd.fish
    │   └── ...
    ├── ui/                  # User interface functions
    │   ├── control_complete.fish
    │   ├── fc.fish
    │   ├── find_n_run.fish
    │   └── file_manager.fish
    ├── md3/                 # Material Design 3 functions
    │   ├── md3_fix.fish
    │   ├── material_box.fish
    │   └── pipe_line.fish
    └── plugins/             # Plugin-specific functions
        ├── z/               # Z directory jumping
        └── autopair/        # Auto-pairing brackets
```

## Features

### 🎨 Material Design 3 Theme
- Complete Material Design 3 color scheme
- Consistent visual elements across all components
- Dynamic color adaptation

### 🔧 Modular Architecture
- **Modules**: Core functionality separated into logical units
- **Integrations**: Development environment configurations
- **Plugins**: Theme and plugin-specific configurations
- **Functions**: Individual utility functions

### 🚀 Performance Optimized
- Lazy loading of development environments
- Conditional path additions
- Efficient module loading order

### 🛠️ Development Ready
- Python (pyenv) integration
- Android SDK support
- Java development tools
- Node.js, Rust, Go configurations
- Git abbreviations and shortcuts

## Key Bindings

- `Alt+C`: Open file selection menu (control_complete)
- `Ctrl+Alt+F`: Find and run commands

## Quick Commands

### File Operations
- `ff <pattern>` - Find files by name
- `fd <pattern>` - Find directories by name
- `extract <file>` - Extract various archive formats
- `backup <file>` - Create timestamped backup

### Development
- `serve [port]` - Start HTTP server (default: 8000)
- `json_pretty [file]` - Pretty print JSON
- `gf <pattern>` - Find files in git repository

### System
- `weather [location]` - Get weather information
- `cheat <command>` - Get command cheatsheet
- `myip` - Get external IP address
- `psgrep <pattern>` - Search for processes

## Customization

### Adding New Modules
Create new files in the `modules/` directory:
```fish
# modules/custom.fish
# Your custom configuration
```

### Adding Development Integrations
Create new files in the `integrations/` directory:
```fish
# integrations/docker.fish
if type -q docker
    # Docker-specific configuration
end
```

### Modifying Core Components
- **Environment**: Edit `modules/env.fish`
- **Paths**: Edit `modules/paths.fish`
- **Aliases**: Edit `modules/aliases.fish`
- **Functions**: Edit `modules/functions.fish`

### Plugin Configuration
Material Design theme and plugin configurations remain in `conf.d/` for compatibility.

## Installation Notes

The configuration automatically detects and configures:
- Development tools (pyenv, node, go, rust)
- Android SDK (if installed in `/opt/android-sdk`)
- Kiro IDE integration
- FZF with preview support

## Performance Tips

- Conda integration is disabled by default (slows startup)
- Development integrations load conditionally
- Paths are added only if directories exist
- Functions are loaded on-demand 