# Fish Configuration Structure

This document explains the organization of the fish shell configuration.

## Directory Organization

### 📁 modules/
Core configuration modules loaded first for essential functionality.

- **env.fish** - Environment variables, XDG compliance, theme settings
- **paths.fish** - Dynamic PATH management with safe additions
- **aliases.fish** - Command aliases and abbreviations
- **functions.fish** - Core utility functions (mkcd, extract, backup, etc.)

### 📁 integrations/
Development environment integrations loaded conditionally.

- **pyenv.fish** - Python environment management
- **conda.fish** - Conda integration (disabled by default for performance)
- **android.fish** - Android SDK configuration
- **java.fish** - Java, Go, Rust, Node.js configurations
- **kiro.fish** - Kiro IDE shell integration

### 📁 conf.d/
Plugin configurations and Material Design theme (auto-loaded by fish).

- **colors.fish** - Material Design 3 color scheme
- **theme.fish** - Fish color theme settings
- **functions.fish** - Theme-specific functions
- **autopair.fish** - Auto-pairing configuration
- **z.fish** - Z directory jumping configuration
- **dynamic_paths.fish** - Dynamic path handling
- **control_complete_binding.fish** - Key bindings

### 📁 functions/
Organized function groups for better maintainability.

#### functions/core/
Core fish shell overrides and essential utilities.

- `fish_prompt.fish` - Custom prompt with Material Design
- `fish_right_prompt.fish` - Right-side prompt
- `fish_greeting.fish` - Custom greeting message
- `fish_command_not_found.fish` - Command not found handler
- `cd.fish` - Enhanced cd with directory preview
- `dynamic_path.fish` - Dynamic path management
- `cct.fish` - Custom completion tool

#### functions/ui/
User interface and interactive functions.

- `control_complete.fish` - File selection with fzf
- `fc.fish` - File completion shortcut
- `find_n_run.fish` - Find and run commands interactively
- `file_manager.fish` - File manager integration
- `help_control_complete.fish` - Help for control complete

#### functions/md3/
Material Design 3 theme functions and utilities.

- `md3_fix.fish` - Fix Material Design colors
- `md3_simple_fix.fish` - Simple color fix
- `md3_reset.fish` - Reset Material Design settings
- `md3_extract_colors.fish` - Extract color scheme
- `material_box.fish` - Draw Material Design boxes
- `pipe_line.fish` - Styled output lines

#### functions/plugins/
Plugin-specific function groups.

**plugins/z/** - Z directory jumping plugin
- `__z.fish` - Main z function
- `__z_add.fish` - Add directory to z database
- `__z_clean.fish` - Clean z database
- `__z_complete.fish` - Z completions

**plugins/autopair/** - Auto-pairing brackets plugin
- `_autopair_insert_left.fish` - Insert left bracket
- `_autopair_insert_right.fish` - Insert right bracket
- `_autopair_insert_same.fish` - Insert same character
- `_autopair_backspace.fish` - Smart backspace
- `_autopair_tab.fish` - Tab handling

### 📁 scripts/
Utility scripts for configuration management.

- `validate_config.fish` - Validate configuration structure and performance

## Loading Order

1. **Modules** (core functionality)
   - env.fish
   - paths.fish
   - aliases.fish
   - functions.fish

2. **conf.d/** (plugins and theme)
   - Auto-loaded by fish in alphabetical order

3. **Functions** (grouped by category)
   - core/
   - ui/
   - md3/
   - plugins/z/
   - plugins/autopair/

4. **Integrations** (development environments)
   - pyenv.fish
   - conda.fish
   - android.fish
   - java.fish
   - kiro.fish

## Adding New Components

### New Module
Create `modules/mymodule.fish` and add to config.fish:
```fish
for module in env paths aliases functions mymodule
    # ...
end
```

### New Integration
Create `integrations/mytool.fish`:
```fish
if type -q mytool
    # Configuration here
end
```

### New Function Group
Create `functions/mygroup/` directory and add to config.fish:
```fish
for func_group in core ui md3 plugins/z plugins/autopair mygroup
    # ...
end
```

## Performance Considerations

- **Modules** load first for essential functionality
- **Integrations** use conditional loading (only if tool exists)
- **Functions** are organized for easy maintenance
- **Plugins** in conf.d/ are auto-loaded by fish

## Customization Tips

1. **Personal aliases**: Add to `modules/aliases.fish`
2. **Environment variables**: Add to `modules/env.fish`
3. **Custom paths**: Add to `modules/paths.fish`
4. **Utility functions**: Add to `modules/functions.fish`
5. **New tools**: Create integration in `integrations/`
6. **Theme tweaks**: Modify files in `conf.d/`

## Maintenance

Run the validator to check configuration health:
```fish
fish scripts/validate_config.fish
```

This will check:
- Directory structure
- Required files
- Configuration load time
- Performance metrics