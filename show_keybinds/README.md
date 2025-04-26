# Hyprland Keybinds Viewer

A GTK4 application that displays keybinds from your Hyprland configuration files.

## Features

- Automatically finds and parses Hyprland configuration files
- Displays keybinds in a searchable, filterable list
- Shows key combinations and their associated actions
- Modern GTK4 user interface

## Requirements

- Rust and Cargo
- GTK4 development libraries

## Installation

### Install Dependencies

On Arch Linux:
```bash
sudo pacman -S gtk4 rust
```

### Build & Run

```bash
# Clone the repository
git clone https://github.com/yourusername/hyprland-keybinds
cd hyprland-keybinds

# Build and run
cargo run
```

## Development

To debug with logging:
```bash
RUST_LOG=debug cargo run
```

## License

MIT 