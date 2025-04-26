# Hyprland Keybinds Viewer

A GTK4 utility to display all keybindings configured in your Hyprland configuration.

## Installation

### Automatic Installation (Recommended)

If you're using HyprGraphite, the keybinds viewer can be installed automatically during the setup process:

```bash
sudo ./scripts/install_keybinds_viewer.sh
```

### Manual Installation

If you want to install the keybinds viewer manually:

1. Ensure you have the required dependencies:
   ```bash
   sudo pacman -S --needed base-devel rust cargo gtk4 pkg-config
   ```

2. Clone the repository (if you haven't already):
   ```bash
   git clone https://github.com/yourusername/HyprGraphite.git
   cd HyprGraphite
   ```

3. Build and install:
   ```bash
   cd show_keybinds
   cargo build --release
   sudo install -Dm755 target/release/hyprland-keybinds /usr/bin/hyprland-keybinds
   ```

## Configuration

The keybinds viewer is bound to the `Super+K` key combination by default. This is configured in:

```
~/.config/hypr/configs/keybinds.conf
```

You can change this keybinding by modifying the line:

```
bind = $mainMod, K, exec, hyprland-keybinds # Show keybinds viewer
```

## Usage

1. Press `Super+K` to launch the keybinds viewer
2. Browse through the different categories to view all your configured keybindings
3. Press `Escape` to close the viewer

## Troubleshooting

If you encounter any issues:

1. Make sure GTK4 is properly installed
2. Check that the binary is correctly installed in `/usr/bin/hyprland-keybinds`
3. Verify your Hyprland configuration contains the keybinding

For more assistance, file an issue on the HyprGraphite repository. 