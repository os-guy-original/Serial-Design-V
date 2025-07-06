#!/usr/bin/env bash

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

# ╭────────────────────────────────────────────────────────────────╮
# │$(center_text "Graphite Cursor Theme Installer" 60)│
# │$(center_text "Simple installer for cursor theme" 60)│
# ╰────────────────────────────────────────────────────────────────╯

# Clear screen for better presentation
clear

# Print welcome banner
print_banner "Serial Design V Cursor Installer" "Beautiful cursors for your desktop environment"

#==================================================================
# Installation Process
#==================================================================
print_section "Installing Cursor Theme"

# Check if theme is already installed
if [ -d "/usr/share/icons/Graphite-dark-cursors" ] || \
   [ -d "$HOME/.local/share/icons/Graphite-dark-cursors" ] || \
   [ -d "$HOME/.icons/Graphite-dark-cursors" ]; then
    print_warning "Graphite cursor theme is already installed."
    if ! ask_yes_no "Do you want to reinstall it?" "n"; then
        print_success_banner "Graphite cursor theme is already installed!"
        exit 0
    fi
fi

# Install cursor theme package using install_packages_by_category function
print_status "Installing Graphite cursor theme..."

if install_packages_by_category "CURSOR_THEME" true; then
    print_success "Successfully installed Graphite cursor theme!"
    print_success_banner "Graphite cursor theme installation complete!"
    exit 0
else
    print_error "Installation failed."
    print_warning "Please try installing the cursor theme manually with: $AUR_HELPER -S graphite-cursor-theme"
    exit 1
fi 
