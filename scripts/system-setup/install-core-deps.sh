#!/bin/bash

# Source common functions
# Check if common_functions.sh exists in the utils directory
if [ -f "$(dirname "$0")/../utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../utils/common_functions.sh"
# Check if common_functions.sh exists in the scripts/utils directory
elif [ -f "$(dirname "$0")/../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../scripts/utils/common_functions.sh"
# Check if it exists in the parent directory's scripts/utils directory
elif [ -f "$(dirname "$0")/../../../scripts/utils/common_functions.sh" ]; then
    source "$(dirname "$0")/../../../scripts/utils/common_functions.sh"
# As a last resort, try the scripts/utils directory relative to current directory
elif [ -f "scripts/utils/common_functions.sh" ]; then
    source "scripts/utils/common_functions.sh"
else
    echo "Error: common_functions.sh not found!"
    echo "Looked in: $(dirname "$0")/../utils/, $(dirname "$0")/../../scripts/utils/, $(dirname "$0")/../../../scripts/utils/, scripts/utils/"
    exit 1
fi

# Source common functions
# If called with --yes, skip confirmation prompt
AUTO_YES=false
if [ "$1" == "--yes" ]; then
  AUTO_YES=true
fi

# ╭──────────────────────────────────────────────────────────╮
# │      Serial Design V – Core Dependencies Installer       │
# ╰──────────────────────────────────────────────────────────╯

clear
print_banner "Core Dependencies Installation" "Essential packages for Serial Design V"

print_section "Core Dependencies Installation"
print_info "These packages are essential for Serial Design V to function properly"

if $AUTO_YES || ask_yes_no "Would you like to install core dependencies for Serial Design V?" "y"; then
    # Install necessary system packages
    print_status "Installing core system dependencies..."
    install_packages_by_category "SYSTEM" false || true

    # Install Hyprland and related packages
    print_status "Installing Hyprland and related packages..."
    install_packages_by_category "HYPRLAND" false || true

    # Install network and bluetooth packages
    print_status "Installing network and bluetooth packages..."
    install_packages_by_category "NETWORK" false || true

    # Install fonts
    print_status "Installing fonts..."
    install_packages_by_category "FONT" false || true

    # Install utilities
    print_status "Installing utilities..."
    install_packages_by_category "UTILITY" false || true

    # Install development packages
    print_status "Installing development packages..."
    install_packages_by_category "DEV" false || true

    print_success_banner "Core dependencies installed successfully!"

    # Optional utilities ----------------------------------------------------

    # Install keybinds viewer if requested
    if ask_yes_no "Would you like to install the keybinds viewer utility (shows all your Hyprland keybinds)?" "y"; then
        print_status "Installing keybinds viewer..."
        if ! find_and_execute_script "scripts/app-install/install_keybinds_viewer.sh" --sudo; then
            print_error "Failed to install keybinds viewer"
            print_warning "You can try installing it later with: sudo ./scripts/app-install/install_keybinds_viewer.sh"
        else
            print_success "Keybinds viewer installed successfully!"
            print_info "You can now view your keybinds by pressing Super+K"
        fi
    fi

    # Install Hyprland var viewer if requested
    if ask_yes_no "Would you like to install the Hyprland variable viewer utility (shows all your Hyprland settings)?" "y"; then
        print_status "Installing Hyprland variable viewer..."
        if ! find_and_execute_script "scripts/app-install/install_var_viewer.sh" --sudo; then
            print_error "Failed to install Hyprland variable viewer"
            print_warning "You can try installing it later with: sudo ./scripts/app-install/install_var_viewer.sh"
        else
            print_success "Hyprland variable viewer installed successfully!"
            print_info "You can now view your Hyprland settings by running 'hyprland-var-viewer'"
        fi
    fi

    # Install Main Center if requested
    if ask_yes_no "Would you like to install the Main Center utility (central control panel)?" "y"; then
        print_status "Installing Main Center..."
        if ! find_and_execute_script "scripts/app-install/install_main_center.sh" --sudo; then
            print_error "Failed to install Main Center"
            print_warning "You can try installing it later with: sudo ./scripts/app-install/install_main_center.sh"
        else
            print_success "Main Center installed successfully!"
            print_info "You can now access the Main Center by running 'main-center'"
            export MAIN_CENTER_INSTALLED=true
        fi
    fi

else
    print_status "Skipping core dependencies installation."
fi

exit 0 
