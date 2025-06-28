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
# │                Flatpak QT Theme Application              │
# │         Apply QT Theme Settings to Flatpak Apps          │
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

    # Install Kvantum runtime for Flatpak
    print_status "Installing Kvantum runtime for Flatpak..."
    if ! flatpak install -y flathub runtime/org.kde.KStyle.Kvantum/x86_64/6.6 runtime/org.kde.KStyle.Kvantum/x86_64/5.15-23.08; then
        print_error "Failed to install Kvantum runtime."
        return 1
    fi
    print_success "Kvantum runtime installed successfully!"

    # Install QGnomePlatform runtime for Flatpak
    print_status "Installing QGnomePlatform runtime for Flatpak..."
    if ! flatpak install -y runtime/org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-23.08 runtime/org.kde.PlatformTheme.QGnomePlatform/x86_64/6.6; then
        print_error "Failed to install QGnomePlatform runtime."
        return 1
    fi
    print_success "QGnomePlatform runtime installed successfully!"

    # Reset previous QT theme settings
    print_status "Resetting previous QT theme settings..."
    sudo flatpak override --unset-env=QT_STYLE_OVERRIDE
    sudo flatpak override --unset-env=QT_QPA_PLATFORMTHEME
    flatpak override --user --unset-env=QT_STYLE_OVERRIDE
    flatpak override --user --unset-env=QT_QPA_PLATFORMTHEME

    # Configure Flatpak to use Kvantum and qt5ct
    print_status "Configuring Flatpak to use Kvantum and qt5ct..."
    if ! sudo flatpak override --env=QT_STYLE_OVERRIDE=kvantum --env=QT_QPA_PLATFORMTHEME=qt5ct --filesystem=xdg-config/Kvantum:ro --filesystem=~/.config/qt5ct --filesystem=~/.config/qt6ct; then
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
        print_info "Flatpak applications will now use the Kvantum theme with qt5ct platform"
    else
        print_error "Failed to apply QT theme to Flatpak applications"
    fi
fi 