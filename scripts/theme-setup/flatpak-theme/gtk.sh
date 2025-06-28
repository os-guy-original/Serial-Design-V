#!/bin/bash

# Source common functions
# Check if common_functions.sh exists in the utils directory
if [ -f "$(dirname "$0")/../../utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../utils/common_functions.sh"
# Check if common_functions.sh exists in the scripts/utils directory
elif [ -f "$(dirname "$0")/../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../scripts/utils/common_functions.sh"
# Check if it exists in the parent directory's scripts/utils directory
elif [ -f "$(dirname "$0")/../../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../../scripts/utils/common_functions.sh"
# As a last resort, try the scripts/utils directory relative to current directory
elif [ -f "scripts/utils/common_functions.sh" ]; then
    source "scripts/utils/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    echo "Looked in: $(dirname "$0")/../../utils/, $(dirname "$0")/../../../scripts/utils/, $(dirname "$0")/../../../../scripts/utils/, scripts/utils/"
    exit 1
fi

# ╭──────────────────────────────────────────────────────────╮
# │               Flatpak GTK Theme Application              │
# │         Apply GTK Theme Settings to Flatpak Apps         │
# ╰──────────────────────────────────────────────────────────╯

apply_gtk_theme() {
    print_section "Flatpak GTK Theme Application"
    print_info "Applying GTK theme settings to Flatpak applications"

    print_status "Checking if Flatpak is installed..."
    if ! command -v flatpak &>/dev/null; then
        print_error "Flatpak is not installed. Exiting."
        return 1
    fi

    print_section "1. Resetting Previous GTK Theme Settings"
    print_info "Clearing any existing Flatpak GTK theme overrides"

    # Reset all existing theme-related overrides
    print_status "Resetting user-level environment variables..."
    flatpak override --user --unset-env=GTK_THEME
    flatpak override --user --unset-env=ICON_THEME

    print_status "Resetting system-level environment variables..."
    sudo flatpak override --unset-env=GTK_THEME
    sudo flatpak override --unset-env=ICON_THEME

    print_status "Resetting theme filesystem access..."
    flatpak override --user --nofilesystem=$HOME/.themes
    sudo flatpak override --nofilesystem=/usr/share/themes
    sudo flatpak override --nofilesystem=$HOME/.themes

    print_success "Previous GTK theme settings have been reset"

    print_section "2. Applying New GTK Theme Settings"
    print_info "Setting up adw-gtk3-dark theme for Flatpak applications"

    # Apply new theme settings
    print_status "Enabling access to GTK configuration..."
    sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
    sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro

    print_status "Setting adw-gtk3-dark as the default GTK theme..."
    sudo flatpak override --env=GTK_THEME=adw-gtk3-dark

    print_status "Enabling access to user themes directory..."
    sudo flatpak override --filesystem=$HOME/.themes:ro

    print_success "Flatpak GTK theme settings have been applied"
    return 0
}

# Execute the function if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    apply_gtk_theme
    
    if [ $? -eq 0 ]; then
        print_section "Application Complete!"
        print_success_banner "Flatpak GTK theme integration complete!"
        print_info "Flatpak applications will now use the adw-gtk3-dark theme"
    else
        print_error "Failed to apply GTK theme to Flatpak applications"
    fi
fi 