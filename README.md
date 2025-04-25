# HyprGraphite
A modern and elegant Hyprland configuration for **Your Operating System**.

> **Note:** This project is a work in progress. Please report any bugs you find.

## ⚠️ Important Note

Debian/Ubuntu installation is currently not supported. We can't build the hyprland dependencies due to C++ errors. Please consider using Arch Linux or Fedora for now.

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
- **Automatic theme setup** with GTK and QT/KDE themes applied during installation
- **Complete theming system** with additional manual configuration options
- **Configuration management** with backup and restore options
- **Support for multiple distros:** Arch and Fedora
- **File managers** included: Nemo and Nautilus pre-installed
- **Flatpak support** with dedicated installation script

## Supported Distributions

- **Arch Linux** and derivatives (Endeavour OS, Manjaro, Garuda)
- **Fedora Linux** (Fedora 37 or newer recommended) (Not tested the script yet)

## Key Scripts

- `install.sh` - Main installation script
- `scripts/manage-config.sh` - Manage configuration files
- `scripts/setup-themes.sh` - Configure additional theme settings
- `scripts/install-gtk-theme.sh` - Install GTK theme
- `scripts/install-qt-theme.sh` - Install QT/KDE theme
- `scripts/install-cursors.sh` - Install Bibata cursors
- `scripts/install-flatpak.sh` - Install and configure Flatpak

All scripts support the `--help` flag for usage information.

## Recommendations

- **GDM** is highly recommended as the display manager
- For **Fedora**, version 37 or newer is recommended

## Credits

- Graphite GTK and QT themes by [vinceliuice](https://github.com/vinceliuice)
- Bibata cursors by [ful1e5](https://github.com/ful1e5/Bibata_Cursor)

## Debian/Ubuntu Build Issues

⚠️ **Important**: There is a known issue with building Aquamarine on Debian/Ubuntu:

- The build process fails to detect OpenGL/GLES2 properly, even when all dependencies are installed
- This is a CMake configuration and C++ issue, not a compatibility problem

### Current Status
- All dependencies install successfully
- CMake fails to find OpenGL (missing: GLES2)
- Build process cannot proceed due to configuration error

### Workarounds
If you need Aquamarine functionality:
1. Try building Aquamarine manually with custom CMake flags
2. Check the [Hyprland Wiki](https://wiki.hyprland.org/) for alternative solutions
3. Consider using the pre-built packages available on Arch Linux or Fedora

We're actively investigating the root cause of this build issue.
