# HyprGraphite
A modern and elegant Hyprland configuration for **Your Operating System**.

> **Note:** This project is a work in progress. Please report any bugs you find.

## Quick Start

1. Clone the repository:
```
git clone https://github.com/os-guy/HyprGraphite.git
cd HyprGraphite
```

2. Run the installer:
```
chmod +x install.sh
./install.sh
```

For help:
```
./install.sh --help
```

## Features

- **Automatic detection** of your Linux distribution
- **One-click installation** of Hyprland and all dependencies
- **Complete theming system** with GTK, QT/KDE themes and Bibata cursors
- **Configuration management** with backup and restore options
- **Support for multiple distros:** Arch, Debian/Ubuntu, and Fedora
- **File managers** included: Nemo and Nautilus pre-installed
- **Flatpak support** with dedicated installation script

## Supported Distributions

- **Arch Linux** and derivatives (Endeavour OS, Manjaro, Garuda)
- **Debian/Ubuntu** based distributions (Ubuntu, Pop!_OS, Linux Mint)
- **Fedora Linux** (Fedora 37 or newer recommended)

## Key Scripts

- `install.sh` - Main installation script
- `scripts/manage-config.sh` - Manage configuration files
- `scripts/setup-themes.sh` - Configure and activate themes
- `scripts/install-gtk-theme.sh` - Install GTK theme
- `scripts/install-qt-theme.sh` - Install QT/KDE theme
- `scripts/install-cursors.sh` - Install Bibata cursors
- `scripts/install-flatpak.sh` - Install and configure Flatpak

All scripts support the `--help` flag for usage information.

## Recommendations

- **GDM** is highly recommended as the display manager
- For **Debian/Ubuntu**, a recent version is recommended for best compatibility
- For **Fedora**, version 37 or newer is recommended

## Credits

- Graphite GTK and QT themes by [vinceliuice](https://github.com/vinceliuice)
- Bibata cursors by [ful1e5](https://github.com/ful1e5/Bibata_Cursor)
