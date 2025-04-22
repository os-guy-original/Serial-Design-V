#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │              HyprGraphite Theme Activation               │
# │           Configure and Apply Installed Themes           │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bright Colors
BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_PURPLE='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Helper Functions                                        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print a section header
print_section() {
    echo -e "\n${BRIGHT_BLUE}${BOLD}⟪ $1 ⟫${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

# Print a status message
print_status() {
    echo -e "${YELLOW}${BOLD}ℹ ${RESET}${YELLOW}$1${RESET}"
}

# Print a success message
print_success() {
    echo -e "${GREEN}${BOLD}✓ ${RESET}${GREEN}$1${RESET}"
}

# Print an error message
print_error() {
    echo -e "${RED}${BOLD}✗ ${RESET}${RED}$1${RESET}"
}

# Print a warning message
print_warning() {
    echo -e "${BRIGHT_YELLOW}${BOLD}⚠ ${RESET}${BRIGHT_YELLOW}$1${RESET}"
}

# Ask the user for a yes/no answer
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [ "$default" = "y" ]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}${prompt}${RESET}"
    read -r response
    
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Selection menu
selection_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selection
    
    echo -e "${BRIGHT_BLUE}${BOLD}$title${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..60})${RESET}"
    
    for i in "${!options[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${options[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#options[@]}]: ${RESET}"
    read -r selection
    
    # Validate input
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#options[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    return $((selection-1))
}

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Environment Detection                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Debug function to print paths and check if they exist
debug_path() {
    local path="$1"
    local description="$2"
    
    echo -e "${BRIGHT_BLACK}${DIM}DEBUG: Checking $description path: $path${RESET}"
    if [ -e "$path" ]; then
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✓ Path exists${RESET}"
    else
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✗ Path does not exist${RESET}"
    fi
}

# Get the absolute home directory path
get_home_dir() {
    # Make sure HOME is set and not empty
    if [ -z "$HOME" ]; then
        # Try to get it from the passwd file
        HOME=$(getent passwd "$(id -un)" | cut -d: -f6)
        
        # If still empty, use a fallback
        if [ -z "$HOME" ]; then
            HOME="/home/$(id -un)"
            print_warning "HOME environment variable not set, using fallback: $HOME"
        fi
    fi
    
    # Make sure the home directory exists
    if [ ! -d "$HOME" ]; then
        print_error "Home directory not found: $HOME"
        print_status "Using current directory as fallback"
        HOME=$(pwd)
    fi
    
    print_status "Using home directory: $HOME"
}

# Detect the distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
        OS_NAME=$PRETTY_NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        OS_VER=$(lsb_release -sr)
        OS_NAME=$(lsb_release -sd)
    else
        OS=$(uname -s)
        OS_VER=$(uname -r)
        OS_NAME="$OS $OS_VER"
    fi
    
    # Convert to lowercase for easier comparison
    OS=${OS,,}
    
    # Return for Arch-based distros
    if [[ "$OS" =~ ^(arch|endeavouros|manjaro|garuda)$ ]]; then
        DISTRO_TYPE="arch"
        return 0
    fi
    
    # Return for Debian-based distros
    if [[ "$OS" =~ ^(debian|ubuntu|pop|linuxmint|elementary)$ ]]; then
        DISTRO_TYPE="debian"
        return 0
    fi
    
    # Return for Fedora-based distros
    if [[ "$OS" =~ ^(fedora|centos|rhel)$ ]]; then
        DISTRO_TYPE="fedora"
        return 0
    fi
    
    # Unknown distro
    DISTRO_TYPE="unknown"
    return 1
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Theme Activation Functions                              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Activate GTK theme
activate_gtk_theme() {
    print_section "Activating Graphite GTK Theme"
    
    # Debug paths
    debug_path "/usr/share/themes/Graphite" "GTK theme (system)"
    debug_path "$HOME/.themes/Graphite" "GTK theme (user)"
    
    # Check if the theme is installed
    if [ ! -d "/usr/share/themes/Graphite" ] && [ ! -d "$HOME/.themes/Graphite" ] && [ ! -d "/usr/local/share/themes/Graphite" ]; then
        print_error "Graphite GTK theme is not installed."
        print_status "Please install the theme first using: ./scripts/install-gtk-theme.sh"
        press_enter
        return 1
    fi
    
    print_status "Setting Graphite-Dark as the default GTK theme..."
    
    # Create the necessary directories if they don't exist
    print_status "Creating GTK configuration directories..."
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    debug_path "$HOME/.config/gtk-3.0" "GTK3 config dir"
    debug_path "$HOME/.config/gtk-4.0" "GTK4 config dir"
    
    # Set GTK2 theme
    print_status "Configuring GTK2 theme..."
    if [ -f "$HOME/.gtkrc-2.0" ]; then
        # Backup the existing file
        cp "$HOME/.gtkrc-2.0" "$HOME/.gtkrc-2.0.backup-$(date +%Y%m%d%H%M%S)"
    fi
    
    cat > "$HOME/.gtkrc-2.0" << EOF
gtk-theme-name="Graphite-Dark"
gtk-icon-theme-name="Tela-circle-dark"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Bibata-Modern-Classic"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
EOF
    
    # Set GTK3 theme
    print_status "Configuring GTK3 theme..."
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=Tela-circle-dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    # Set GTK4 theme
    print_status "Configuring GTK4 theme..."
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=Tela-circle-dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    # Configure for Flatpak if available
    if command_exists flatpak; then
        print_status "Setting Graphite theme for Flatpak applications..."
        sudo flatpak override --env=GTK_THEME=Graphite-Dark
    fi
    
    print_success "Graphite GTK theme has been activated!"
    press_enter
    return 0
}

# Activate cursor theme
activate_cursor_theme() {
    print_section "Activating Bibata Cursors"
    
    # Debug paths
    debug_path "/usr/share/icons/Bibata-Modern-Classic" "Cursor theme (system)"
    debug_path "$HOME/.icons/Bibata-Modern-Classic" "Cursor theme (user)"
    debug_path "$HOME/.local/share/icons/Bibata-Modern-Classic" "Cursor theme (local)"
    
    # Check if the cursors are installed
    if [ ! -d "/usr/share/icons/Bibata-Modern-Classic" ] && [ ! -d "$HOME/.icons/Bibata-Modern-Classic" ] && [ ! -d "$HOME/.local/share/icons/Bibata-Modern-Classic" ]; then
        print_error "Bibata cursors are not installed."
        print_status "Please install the cursors first using: ./scripts/install-cursors.sh"
        press_enter
        return 1
    fi
    
    print_status "Setting Bibata-Modern-Classic as the default cursor theme..."
    
    # Create the necessary directories if they don't exist
    print_status "Creating cursor configuration directories..."
    mkdir -p "$HOME/.icons"
    mkdir -p "$HOME/.config/xsettingsd"
    
    debug_path "$HOME/.icons" "Icons dir"
    debug_path "$HOME/.config/xsettingsd" "Xsettings dir"
    
    # Set cursor theme in Xresources
    if [ -f "$HOME/.Xresources" ]; then
        # Backup the existing file
        cp "$HOME/.Xresources" "$HOME/.Xresources.backup-$(date +%Y%m%d%H%M%S)"
        
        # Remove existing cursor theme settings
        sed -i '/Xcursor.theme/d' "$HOME/.Xresources"
        sed -i '/Xcursor.size/d' "$HOME/.Xresources"
    fi
    
    # Append cursor theme settings
    echo "Xcursor.theme: Bibata-Modern-Classic" >> "$HOME/.Xresources"
    echo "Xcursor.size: 24" >> "$HOME/.Xresources"
    
    # Update cursor theme immediately
    xrdb -merge "$HOME/.Xresources" 2>/dev/null
    
    # Set cursor theme for Xsettings if xsettingsd is available
    if command_exists xsettingsd; then
        mkdir -p "$HOME/.config/xsettingsd"
        cat > "$HOME/.config/xsettingsd/xsettingsd.conf" << EOF
Net/CursorThemeName "Bibata-Modern-Classic"
Net/CursorBlinkTime 1200
Net/DoubleClickTime 400
Net/IconThemeName "Tela-circle-dark"
Net/ThemeName "Graphite-Dark"
EOF
        
        # Restart xsettingsd if it's running
        if pgrep xsettingsd >/dev/null; then
            killall xsettingsd
            xsettingsd &
        fi
    fi
    
    # Set cursor theme in index.theme
    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Bibata-Modern-Classic
EOF
    
    # Update cursor settings for Hyprland
    if [ -d "$HOME/.config/hypr" ]; then
        print_status "Updating Hyprland configuration for cursor theme..."
        
        local hypr_conf="$HOME/.config/hypr/hyprland.conf"
        debug_path "$hypr_conf" "Hyprland config"
        
        if [ -f "$hypr_conf" ]; then
            # Backup the existing file
            cp "$hypr_conf" "$hypr_conf.backup-$(date +%Y%m%d%H%M%S)"
            
            # Check if cursor settings already exist
            if grep -q "^exec-once = hyprctl setcursor" "$hypr_conf"; then
                # Update existing cursor settings
                sed -i 's/^exec-once = hyprctl setcursor.*/exec-once = hyprctl setcursor Bibata-Modern-Classic 24/' "$hypr_conf"
            else
                # Add cursor settings to the end of the file
                echo "" >> "$hypr_conf"
                echo "# Cursor settings" >> "$hypr_conf"
                echo "exec-once = hyprctl setcursor Bibata-Modern-Classic 24" >> "$hypr_conf"
            fi
        else
            print_warning "Hyprland configuration file not found: $hypr_conf"
        fi
    else
        print_status "Hyprland configuration directory not found, skipping cursor setup for Hyprland."
    fi
    
    print_success "Bibata cursor theme has been activated!"
    press_enter
    return 0
}

# Activate QT/KDE theme
activate_qt_theme() {
    print_section "Activating Graphite QT/KDE Theme"
    
    # Check if Kvantum is installed
    if ! command_exists kvantummanager; then
        print_warning "Kvantum is not installed. It's recommended for the best QT theme experience."
        if ask_yes_no "Continue without Kvantum? QT theming may not work properly." "n"; then
            print_status "Continuing without Kvantum..."
        else
            print_status "Please install Kvantum first using your package manager."
            press_enter
            return 1
        fi
    fi
    
    # Check if the theme is installed
    debug_path "/usr/share/Kvantum/Graphite" "Kvantum theme (system)"
    debug_path "$HOME/.config/Kvantum/Graphite" "Kvantum theme (user)"
    debug_path "$HOME/.local/share/Kvantum/Graphite" "Kvantum theme (local)"
    
    if [ -d "/usr/share/Kvantum/Graphite" ] || [ -d "$HOME/.config/Kvantum/Graphite" ] || [ -d "$HOME/.local/share/Kvantum/Graphite" ]; then
        print_status "Graphite Kvantum theme found. Activating..."
        
        # Create necessary directories
        print_status "Creating Kvantum configuration directory..."
        mkdir -p "$HOME/.config/Kvantum"
        debug_path "$HOME/.config/Kvantum" "Kvantum config dir"
        
        # Set Graphite as the active theme
        cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << EOF
[General]
theme=Graphite-Dark
EOF
        
        # Apply the theme immediately if Kvantum is available
        if command_exists kvantummanager; then
            print_status "Applying Kvantum theme..."
            kvantummanager --set Graphite-Dark
        fi
    else
        print_warning "Graphite Kvantum theme not found. QT theme may not work properly."
        print_status "Please install the QT theme first using: ./scripts/install-qt-theme.sh"
    fi
    
    # Configure global QT settings
    print_status "Configuring QT settings..."
    
    # Create QT5 settings directory
    print_status "Creating QT5 configuration directory..."
    mkdir -p "$HOME/.config/qt5ct"
    debug_path "$HOME/.config/qt5ct" "QT5 config dir"
    
    # Set QT5 configuration
    cat > "$HOME/.config/qt5ct/qt5ct.conf" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Tela-circle-dark
standard_dialogs=default
style=kvantum

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOF
    
    # Create QT6 settings directory
    print_status "Creating QT6 configuration directory..."
    mkdir -p "$HOME/.config/qt6ct"
    debug_path "$HOME/.config/qt6ct" "QT6 config dir"
    
    # Set QT6 configuration
    cat > "$HOME/.config/qt6ct/qt6ct.conf" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Tela-circle-dark
standard_dialogs=default
style=kvantum

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOF
    
    # Set environment variables for QT theme
    print_status "Setting environment variables for QT applications..."
    
    # Check if .profile exists, create it if not
    if [ ! -f "$HOME/.profile" ]; then
        touch "$HOME/.profile"
    else
        # Backup .profile
        cp "$HOME/.profile" "$HOME/.profile.backup-$(date +%Y%m%d%H%M%S)"
    fi
    
    # Remove existing QT environment variables
    sed -i '/export QT_QPA_PLATFORMTHEME/d' "$HOME/.profile"
    sed -i '/export QT_STYLE_OVERRIDE/d' "$HOME/.profile"
    
    # Add QT environment variables
    echo "" >> "$HOME/.profile"
    echo "# QT theme settings" >> "$HOME/.profile"
    echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> "$HOME/.profile"
    
    # Add to .bash_profile, .zprofile, or .bashrc if they exist
    for profile in "$HOME/.bash_profile" "$HOME/.zprofile" "$HOME/.bashrc"; do
        if [ -f "$profile" ]; then
            # Backup the file
            cp "$profile" "$profile.backup-$(date +%Y%m%d%H%M%S)"
            
            # Remove existing QT environment variables
            sed -i '/export QT_QPA_PLATFORMTHEME/d' "$profile"
            sed -i '/export QT_STYLE_OVERRIDE/d' "$profile"
            
            # Add QT environment variables
            echo "" >> "$profile"
            echo "# QT theme settings" >> "$profile"
            echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> "$profile"
        fi
    done
    
    print_success "Graphite QT/KDE theme has been activated!"
    print_warning "You may need to log out and log back in for all changes to take effect."
    press_enter
    return 0
}

# Restart pipewire services
restart_pipewire() {
    print_section "Restarting Audio Services"
    
    print_status "Restarting pipewire services at user level..."
    
    # Check if pipewire is available
    if ! systemctl --user list-unit-files | grep -q pipewire; then
        print_warning "Pipewire services not found at user level."
        
        # Try checking if the service exists but is masked or disabled
        if systemctl --user list-unit-files --all | grep -q pipewire; then
            print_status "Pipewire units exist but may be disabled or masked."
        fi
        
        # Check if pipewire is running through another method
        if pgrep -x pipewire >/dev/null; then
            print_status "Pipewire process is running, but not managed by systemd user units."
        fi
        
        press_enter
        return 1
    fi
    
    # Check the status of each service before restarting
    print_status "Checking pipewire service status..."
    
    # Function to restart a service with status checking
    restart_service() {
        local service="$1"
        
        if systemctl --user list-unit-files "$service" >/dev/null 2>&1; then
            print_status "Restarting $service..."
            
            # Get initial status
            local initial_status
            initial_status=$(systemctl --user is-active "$service" 2>/dev/null)
            print_status "$service initial status: $initial_status"
            
            # Restart service
            systemctl --user restart "$service" >/dev/null 2>&1
            local restart_status=$?
            
            # Check status after restart
            local final_status
            final_status=$(systemctl --user is-active "$service" 2>/dev/null)
            
            if [ $restart_status -eq 0 ] && [ "$final_status" = "active" ]; then
                print_success "$service restarted successfully"
                return 0
            else
                print_warning "Failed to restart $service. Status: $final_status"
                return 1
            fi
        else
            print_status "$service not found, skipping"
            return 2
        fi
    }
    
    # Restart pipewire and related services
    restart_service "pipewire.service"
    restart_service "pipewire-pulse.service"
    restart_service "wireplumber.service"
    
    # Verify audio services are running
    if pgrep -x pipewire >/dev/null; then
        print_success "Pipewire process is running"
    else
        print_warning "Pipewire process not found after restart"
    fi
    
    if pgrep -x wireplumber >/dev/null; then
        print_success "Wireplumber process is running"
    else
        print_warning "Wireplumber process not found after restart"
    fi
    
    print_success "Audio services restart attempted!"
    press_enter
}

# Main function
main() {
    # Clear the screen
    clear
    
    # Get home directory
    get_home_dir
    
    # Detect distro
    detect_distro
    
    # Print banner
    echo
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}      HyprGraphite Theme Activation          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}    Configure and apply installed themes    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    
    # Theme activation selection menu
    while true; do
        print_section "Theme Activation Options"
        
        options=(
            "Activate Graphite GTK Theme"
            "Activate Bibata Cursors"
            "Activate Graphite QT/KDE Theme"
            "Activate All Themes"
            "Restart Audio Services"
            "Exit"
        )
        
        selection_menu "Select an action:" "${options[@]}"
        choice=$?
        
        case $choice in
            0) # Activate Graphite GTK Theme
                activate_gtk_theme
                ;;
            1) # Activate Bibata Cursors
                activate_cursor_theme
                ;;
            2) # Activate Graphite QT/KDE Theme
                activate_qt_theme
                ;;
            3) # Activate All Themes
                print_section "Activating All Themes"
                
                print_status "Activating Graphite GTK Theme..."
                activate_gtk_theme
                
                print_status "Activating Bibata Cursors..."
                activate_cursor_theme
                
                print_status "Activating Graphite QT/KDE Theme..."
                activate_qt_theme
                
                print_status "Restarting audio services..."
                restart_pipewire
                
                print_success "All themes have been activated!"
                print_warning "You may need to log out and log back in for all changes to take effect."
                press_enter
                ;;
            4) # Restart Audio Services
                restart_pipewire
                ;;
            5) # Exit
                echo
                print_success "Theme activation complete!"
                exit 0
                ;;
            *)
                print_error "Invalid selection"
                ;;
        esac
        
        # Clear screen for next iteration
        clear
        
        # Print banner again
        echo
        echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
        echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
        echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}      HyprGraphite Theme Activation          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
        echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}    Configure and apply installed themes    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
        echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
        echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
        echo
    done
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭───────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}      HyprGraphite Theme Activation          ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}    Configure and apply installed themes    ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                               ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰───────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./scripts/setup-themes.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help, -h${RESET}    Display this help message"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION:${RESET}"
    echo -e "  This script helps you configure and activate the HyprGraphite themes."
    echo -e "  It provides an interactive menu to:"
    echo
    echo -e "  • Activate Graphite GTK Theme"
    echo -e "  • Activate Bibata Cursors"
    echo -e "  • Activate Graphite QT/KDE Theme"
    echo -e "  • Activate All Themes at once"
    echo -e "  • Restart Audio Services (PipeWire)"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTES:${RESET}"
    echo -e "  Before activating, make sure you've installed the themes using:"
    echo -e "  • ${CYAN}./scripts/install-gtk-theme.sh${RESET}"
    echo -e "  • ${CYAN}./scripts/install-qt-theme.sh${RESET}"
    echo -e "  • ${CYAN}./scripts/install-cursors.sh${RESET}"
    
    exit 0
}

# Make sure script is not run as root
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should NOT be run as root!"
    exit 1
fi

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_help
fi

# Run the main function
main 