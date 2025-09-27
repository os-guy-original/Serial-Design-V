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
# │$(center_text "Flatpak QT Theme Application" 60)│
# │$(center_text "Apply QT Theme Settings to Flatpak Apps" 60)│
# ╰──────────────────────────────────────────────────────────╯

apply_qt_theme() {
    print_section "Flatpak QT Theme Application"
    print_info "Applying QT theme settings to Flatpak applications"

    print_status "Checking if Flatpak is installed..."
    if ! command -v flatpak &>/dev/null; then
        print_error "Flatpak is not installed. Exiting."
        return 1
    fi

    print_warning "!! QT Theme integration may not work for all applications !!"

    # Install KDE runtime for Flatpak
    print_status "Installing KDE runtime for Flatpak..."
    if ! flatpak install -y flathub org.kde.Platform; then
        print_warning "Failed to install KDE runtime. Some applications may not display correctly."
    else
        print_success "KDE runtime installed successfully!"
    fi

    # Reset previous QT theme settings
    print_status "Resetting previous QT theme settings..."
    sudo flatpak override --unset-env=QT_STYLE_OVERRIDE
    sudo flatpak override --unset-env=QT_QPA_PLATFORMTHEME
    sudo flatpak override --unset-env=QT_QPA_PLATFORM
    flatpak override --user --unset-env=QT_STYLE_OVERRIDE
    flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME
    flatpak override --user --unset-env=QT_QPA_PLATFORM

    # Configure Flatpak to use KDE platform theme and Wayland
    print_status "Configuring Flatpak to use KDE platform theme and Wayland..."
    if ! sudo flatpak override --env=QT_QPA_PLATFORM=wayland --env=QT_QPA_PLATFORMTHEME=kde --env=QT_STYLE_OVERRIDE=breeze --filesystem=~/.config/kdeglobals:ro; then
        print_error "Failed to configure Flatpak QT theme."
        return 1
    fi
    print_success "Flatpak QT theme configuration completed successfully!"
    
    return 0
}

# Execute the function if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    apply_qt_theme
    
    if [ $? -eq 0 ]; then
        print_section "Application Complete!"
        print_success_banner "Flatpak QT theme integration complete!"
        print_info "Flatpak applications will now use KDE platform theme with Wayland"
    else
        print_error "Failed to apply QT theme to Flatpak applications"
    fi
fi 