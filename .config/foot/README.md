# Foot Terminal Configuration

This repository contains configuration files for the [foot](https://codeberg.org/dnkl/foot) terminal, a fast, lightweight Wayland terminal emulator.

## Installation

1. Clone or copy these files to `~/.config/foot/`
2. Make sure the directory structure is as follows:
   ```
   ~/.config/foot/
   ├── foot.ini
   ├── colors.ini
   └── themes/
       ├── catppuccin.ini
       └── dracula.ini
   ```

## Configuration

The main configuration is in `foot.ini`, which includes the centralized colors file `colors.ini`.

### Changing Color Schemes

To switch between different color schemes, you can:

1. **Edit the main configuration file**:
   - Open `~/.config/foot/foot.ini`
   - Change the include line to point to a specific theme:
     ```ini
     # Use the default colors
     include=~/.config/foot/colors.ini
     
     # OR use a specific theme
     # include=~/.config/foot/themes/dracula.ini
     # include=~/.config/foot/themes/catppuccin.ini
     ```

2. **Create your own theme**:
   - Copy one of the existing theme files to `~/.config/foot/themes/your-theme.ini`
   - Edit the colors to your preference
   - Update the include line in `foot.ini` to use your new theme

## Key Features

- **Centralized color management**: All colors are defined in separate files for easy customization
- **Multiple themes**: Switch between different color schemes by changing a single line
- **Well-documented**: Configuration options are commented for easy understanding
- **Sensible defaults**: Configured with reasonable defaults for font, padding, and behavior

## Keyboard Shortcuts

- `Ctrl+Shift+C`: Copy selected text
- `Ctrl+Shift+V`: Paste from clipboard
- `F11`: Toggle fullscreen

## Additional Resources

- [Foot Terminal Documentation](https://codeberg.org/dnkl/foot/wiki)
- [Foot Terminal Man Page](https://codeberg.org/dnkl/foot/src/branch/master/doc/foot.1.scd) 