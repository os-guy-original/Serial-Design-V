# Serial Design V Script Structure

This document outlines the execution flow of scripts and functions in the Serial Design V project, detailing which files and functions are called in which order during the installation and theme setup process.

## Main Installation Flow

### 1. `install.sh` - Entry Point

The main installation process begins with `install.sh`, which is the entry point for setting up the Serial Design V environment.

#### Execution Flow:
1. Sources common functions from `scripts/utils/common_functions.sh`
2. Sets `ORIGINAL_INSTALL_DIR` to store the starting directory
3. Detects AUR helpers using `scripts/system-setup/detect-aur-helper.sh`
4. Performs prerequisite checks
   - Verifies that pacman is available (exits if not on Arch Linux)
5. Offers Chaotic-AUR setup via `scripts/system-setup/install-chaotic-aur.sh`

### 2. File Manager Installation

File manager installation is handled by:
1. In `install.sh`: Executes `scripts/app-install/install-file-manager.sh --install-only`
2. Configuration is done later after copying config files

### 3. Flatpak Setup

Flatpak setup is handled directly in install.sh:

1. In `install.sh`: Directly asks if user wants to install Flatpak
2. If user agrees, executes `scripts/system-setup/install-flatpak.sh`
3. In `install-flatpak.sh`: Installs Flatpak, adds Flathub repository, and offers to install apps

### 4. Core Dependencies Installation

Core dependencies installation:
1. In `install.sh`: Asks if user wants to install core dependencies
2. If user agrees, executes `scripts/system-setup/install-core-deps.sh`

### 5. Theme Setup

Theme setup is organized by component:

#### GTK Theme Installation:
1. Handled directly in `install.sh`:
   - Checks if GTK theme is already installed using `check_gtk_theme_installed()`
   - If not installed or reinstall requested, executes `scripts/theme-setup/install-gtk-theme.sh --install-only`
2. In `install-gtk-theme.sh`:
   - Installs the GTK theme packages
   - Configures GTK3/GTK4 settings for the user
   - Updates Hyprland environment configuration

#### Cursor Theme Installation:
1. Handled directly in `install.sh`:
   - Checks if cursor theme is already installed using `check_cursor_theme_installed()`
   - If not installed or reinstall requested, executes `scripts/theme-setup/install-cursors.sh`

#### Icon Theme Installation:
1. Handled directly in `install.sh`:
   - Checks if icon theme is already installed using `check_icon_theme_installed()`
   - If not installed or reinstall requested, executes `scripts/theme-setup/install-icon-theme.sh`

#### QT Theme Installation:
1. Handled directly in `install.sh`:
   - Checks if Flatpak is installed
   - If user agrees, executes `scripts/theme-setup/apply-flatpak-theme.sh --only-qt`

#### Flatpak Theme Application:
In `scripts/theme-setup/apply-flatpak-theme.sh`:
1. Main script that can apply both GTK and QT themes
   - Uses `--only-gtk` or `--only-qt` flags to apply specific themes
   - Sources modular scripts from `flatpak-theme/` directory:
     - `gtk.sh` - Handles GTK theme application
     - `qt.sh` - Handles QT theme application

### 6. Evolve-Core Installation

In `install.sh`: Offers to install Evolve-Core theme manager by executing `scripts/app-install/install-evolve-core.sh`

### 7. Configuration Setup

Now handled directly in `install.sh`:
1. Executes `scripts/config/copy-configs.sh --skip-prompt` to copy configuration files
2. Executes `scripts/app-install/install-file-manager.sh --configure-only` to set up the file manager
3. Executes `scripts/theme-setup/install-gtk-theme.sh --configure-only` to configure GTK theme

### 8. Additional Theme Configuration

In `install.sh`: Offers additional manual theme configuration by executing `scripts/theme-setup/setup-themes.sh`

### 9. Custom Packages Installation

In `install.sh`: Executes `scripts/app-install/install-custom-packages.sh` for any additional custom packages

### 10. Final Steps

In `install.sh`:
1. Checks if GTK theme installation was skipped
2. If so, runs `scripts/theme-setup/set-to-default-gtk.sh` silently to set default theme

## Default GTK Theme Setting

When GTK theme installation is skipped, a default GTK theme is set via:

1. In `set-to-default-gtk.sh`: Sets GTK3/GTK4 theme settings silently without user interaction

## Function Call Hierarchy

```
install.sh
├── source scripts/utils/common_functions.sh
├── source scripts/system-setup/detect-aur-helper.sh (if needed)
├── scripts/system-setup/install-chaotic-aur.sh (if user agrees)
├── scripts/app-install/install-file-manager.sh --install-only
├── scripts/system-setup/install-flatpak.sh (if user agrees)
├── scripts/system-setup/install-core-deps.sh (if user agrees)
├── scripts/theme-setup/install-gtk-theme.sh --install-only (if user agrees)
├── scripts/theme-setup/install-cursors.sh (if user agrees)
├── scripts/theme-setup/install-icon-theme.sh (if user agrees)
├── scripts/theme-setup/apply-flatpak-theme.sh --only-qt (if user agrees)
│   └── scripts/theme-setup/flatpak-theme/qt.sh
├── scripts/theme-setup/apply-flatpak-theme.sh --only-gtk (if user agrees)
│   └── scripts/theme-setup/flatpak-theme/gtk.sh
├── scripts/app-install/install-evolve-core.sh (if user agrees)
├── scripts/config/copy-configs.sh --skip-prompt
├── scripts/app-install/install-file-manager.sh --configure-only
├── scripts/theme-setup/install-gtk-theme.sh --configure-only
├── scripts/theme-setup/setup-themes.sh (optional)
├── scripts/app-install/install-custom-packages.sh
└── scripts/theme-setup/set-to-default-gtk.sh (if GTK theme was skipped)
```

## Script Directory Structure

```
scripts/
├── app-install/
│   ├── install-custom-packages.sh
│   ├── install-evolve-core.sh
│   ├── install-file-manager.sh
│   ├── install_keybinds_viewer.sh
│   ├── install_main_center.sh
│   └── install_var_viewer.sh
├── config/
│   ├── copy-configs.sh
│   └── manage-config.sh
├── system-setup/
│   ├── detect-aur-helper.sh
│   ├── install-chaotic-aur.sh
│   ├── install-core-deps.sh
│   └── install-flatpak.sh
├── theme-setup/
│   ├── apply-flatpak-theme.sh
│   ├── install-cursors.sh
│   ├── install-gtk-theme.sh
│   ├── install-icon-theme.sh
│   ├── install-qt-theme.sh
│   ├── set-to-default-gtk.sh
│   └── setup-themes.sh
└── utils/
    └── common_functions.sh
```

## Common Utility Functions

`scripts/utils/common_functions.sh` provides various utility functions used throughout the installation:

- Formatting and output: `print_section()`, `print_status()`, `print_info()`, etc.
- Dialog helpers: `ask_yes_no()`, `press_enter()`, `selection_menu()`
- Package installation: `install_packages()`, `install_packages_by_category()`
- Theme detection: `check_gtk_theme_installed()`, `check_qt_theme_installed()`, etc.
- Script path utilities: `get_script_path()`, `get_script_prefix()`, `find_and_execute_script()`
- Error handling: `handle_error()`, `handle_conflicts()`

These functions are used by multiple scripts to provide a consistent interface and avoid code duplication.