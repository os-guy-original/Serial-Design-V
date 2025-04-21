# Graphite Dark Kitty Terminal Theme

A stylish dark theme for the Kitty terminal with a graphite base and carefully selected colors for errors and warnings.

## Installation

1. Place the kitty configuration files in your kitty configuration directory:
   ```
   ~/.config/kitty/kitty.conf
   ~/.config/kitty/themes.conf
   ~/.config/kitty/shortcuts.md
   ```

2. The fish shell integration files are located at:
   ```
   ~/.config/fish/functions/kitty-shortcuts.fish
   ~/.config/fish/conf.d/kitty.fish
   ```

3. Restart Kitty or reload the configuration with `ctrl+shift+f5`

## Color Scheme

The theme uses a dark graphite base (blacks and greys) with specific accent colors for different purposes:

- **Base**: Dark graphite background with light grey text
- **Errors**: Red (#ff5555) - Clearly highlights error messages
- **Warnings**: Yellow (#f1fa8c) - Makes warnings stand out
- **Success**: Green (#50fa7b) - Indicates successful operations
- **Critical**: Magenta (#ff79c6) - Stands out for critical alerts
- **Info/Links**: Cyan (#8be9fd) - Used for URLs and information

This color scheme combines the minimalist aesthetic of a graphite theme with practical, purpose-oriented colors that make terminal work more efficient.

## Features

- Graphite Dark base with carefully selected accent colors
- Modern UI with powerline tab styling
- Semi-transparent background (adjustable with shortcuts)
- Cool cursor animations with customizable shapes and blink effects
- Fish shell integration with colorful shortcuts display
- Well-organized keyboard shortcuts
- Multiple theme options in themes.conf:
  - Deep Graphite (darker variant)
  - Soft Graphite (softer contrast)
  - High Contrast Graphite
  - Paper Graphite (light theme)
  - Dracula Fusion (Dracula-inspired dark theme)
- JetBrains Mono font (install separately if not already installed)

## Customization

### Changing Themes

1. Edit `kitty.conf` and uncomment the line `include themes.conf`
2. Open `themes.conf` and uncomment your preferred theme

### Font Customization

1. Edit `kitty.conf` and modify the font settings
2. If you don't have JetBrains Mono installed, replace with any monospace font you have

### Cursor Animations

Use the following shortcuts to customize your cursor on-the-fly:
- `ctrl+shift+a>c>1`: Beam cursor (vertical line)
- `ctrl+shift+a>c>2`: Block cursor (rectangle)
- `ctrl+shift+a>c>3`: Underline cursor
- `ctrl+shift+a>c>b`: Normal blinking
- `ctrl+shift+a>c>n`: No blinking
- `ctrl+shift+a>c>f`: Smooth fading animation

### Keyboard Shortcuts

View keyboard shortcuts anytime by typing `kitty-shortcuts` in your fish shell.

## Fish Shell Integration

The theme includes fish shell integration for a better terminal experience:

1. **Automatic Display of Shortcuts**:
   - Shortcuts are displayed automatically on every launch
   - You can also type `kitty-shortcuts` anytime to see the guide again

2. **Custom Welcome Message**:
   - Displays a welcome message with fish shell version
   - Followed by the colorful shortcuts guide

3. **Customizing Fish Integration**:
   - Edit `~/.config/fish/conf.d/kitty.fish` to customize the fish integration
   - Modify `~/.config/fish/functions/kitty-shortcuts.fish` to change the shortcuts display
   - To disable showing shortcuts at startup, edit the fish_greeting function in `~/.config/fish/conf.d/kitty.fish`

## Dependencies

- Kitty terminal: https://sw.kovidgoyal.net/kitty/
- Fish shell: https://fishshell.com/
- JetBrains Mono font (recommended): https://www.jetbrains.com/lp/mono/

## Tips and Tricks

- Use `ctrl+shift+f5` to reload the config without restarting Kitty
- Type `kitty-shortcuts` to view the colorful shortcuts guide anytime
- Adjust opacity on-the-fly with `ctrl+shift+a>m` (increase) and `ctrl+shift+a>l` (decrease)
- Modify window padding in kitty.conf if you prefer more/less space around text
- The cursor is configured for a smooth fading animation by default 