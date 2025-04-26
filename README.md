# HyprGraphite
A modern and elegant Hyprland configuration for **Arch Linux**.

> **Note:** This project is a work in progress. Please report any bugs you find.

## ⚠️ Important Note

This project now exclusively supports Arch Linux and its derivatives. Support for Fedora and other distributions has been removed due to package management complexity and maintenance challenges. 

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

- **Automatic setup** of Hyprland and all dependencies
- **One-click installation** with minimal user intervention
- **Automatic theme setup** with GTK and QT/KDE themes applied during installation
- **Complete theming system** with additional manual configuration options
- **Configuration management** with backup and restore options
- **Optimized for Arch Linux** and its derivatives
- **File managers** included: Nemo and Nautilus pre-installed
- **Flatpak support** with dedicated installation script

## Supported Distributions

- **Arch Linux** and derivatives (Endeavour OS, Manjaro, Garuda)

## Key Scripts

- `install.sh` - Main installation script
- `scripts/arch_install.sh` - Arch Linux specific installation
- `scripts/manage-config.sh` - Manage configuration files
- `scripts/setup-themes.sh` - Configure additional theme settings
- `scripts/install-gtk-theme.sh` - Install GTK theme
- `scripts/install-qt-theme.sh` - Install QT/KDE theme
- `scripts/install-cursors.sh` - Install Bibata cursors
- `scripts/install-flatpak.sh` - Install and configure Flatpak

All scripts support the `--help` flag for usage information.

## Recommendations

- **GDM** is highly recommended as the display manager

## Credits

- Graphite GTK, QT and Cursor themes by [vinceliuice](https://github.com/vinceliuice)

## Why We Removed Support for Other Distributions

We decided to focus exclusively on Arch Linux for several reasons:

1. **Package Management Complexity**: Each distribution has its own package management system and repositories, which made maintaining multiple installation paths increasingly complex.
2. **Dependency Issues**: Different distributions handle dependencies and versions differently, leading to inconsistent installation experiences.
3. **Testing Burden**: Properly testing the installer across multiple distributions required significant resources.
4. **Maintenance Overhead**: Supporting multiple distributions divided our attention and made it harder to provide a polished experience on any single platform.

By focusing on Arch Linux, we can provide a more reliable, stable, and feature-rich experience that takes full advantage of the AUR ecosystem and Arch's rolling release model.

If you're using another distribution and want to try HyprGraphite, consider:
1. Setting up Arch Linux in a virtual machine
2. Using an Arch-based distribution
3. Manually adapting the configuration files to your distribution
