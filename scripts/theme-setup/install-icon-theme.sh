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

# ╭──────────────────────────────────────────────────────────╮
# │$(center_text "Icon Theme Installation" 60)│
# │$(center_text "Beautiful Icons for Desktop Environments" 60)│
# ╰──────────────────────────────────────────────────────────╯

# Process command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_generic_help "$(basename "$0")" "Install icon themes for desktop environments"
    echo -e "${BRIGHT_WHITE}${BOLD}DETAILS${RESET}"
    echo -e "    This script installs the Fluent icon theme for desktop environments."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE${RESET}"
    echo -e "    $(basename "$0")"
    echo
    exit 0
fi

#==================================================================
# Welcome Message
#==================================================================
clear
print_banner "Icon Theme Installation" "Beautiful and consistent icons for your applications"

#==================================================================
# Icon Theme Installation
#==================================================================
print_section "Installing Icon Theme"

# Check if any Fluent theme variants are already installed
fluent_installed=false

# Check in /usr/share/icons
if [ -d "/usr/share/icons" ]; then
    if ls /usr/share/icons/Fluent* >/dev/null 2>&1; then
        fluent_installed=true
    fi
fi

# Check in $HOME/.local/share/icons
if [ -d "$HOME/.local/share/icons" ]; then
    if ls $HOME/.local/share/icons/Fluent* >/dev/null 2>&1; then
        fluent_installed=true
    fi
fi

# Check in $HOME/.icons
if [ -d "$HOME/.icons" ]; then
    if ls $HOME/.icons/Fluent* >/dev/null 2>&1; then
        fluent_installed=true
    fi
fi

if [ "$fluent_installed" = true ]; then
    print_warning "Fluent icon theme is already installed."
    if ! ask_yes_no "Do you want to reinstall it?" "n"; then
        print_success_banner "Fluent icon theme is already installed!"
        exit 0
    fi
fi

# Install icon theme using the package list
print_status "Installing Fluent icon theme..."

if install_packages_by_category "ICON_THEME" true; then
    print_success "Fluent icon theme installed successfully!"
    print_success_banner "Fluent icon theme installation complete!"
    exit 0
else
    print_error "Installation failed."
    print_warning "Please try installing the icon theme manually with: $AUR_HELPER -S fluent-icon-theme-git"
    exit 1
fi 
