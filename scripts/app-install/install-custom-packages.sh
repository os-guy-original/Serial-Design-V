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
# Get the root directory of the project
ROOT_DIR="$(dirname "$(dirname "$0")")"

# Package list file - try multiple locations
PACKAGE_LIST_FILE=""
# Check possible locations for package-list.txt
for possible_path in \
    "${ROOT_DIR}/package-list.txt" \
    "$(dirname "${ROOT_DIR}")/package-list.txt" \
    "./package-list.txt" \
    "../package-list.txt" \
    "$(pwd)/package-list.txt"
do
    if [ -f "$possible_path" ]; then
        PACKAGE_LIST_FILE="$possible_path"
        break
    fi
done

print_section "Custom Packages Installation"
print_info "Checking for custom packages in package-list.txt"

# Check if the package list file exists
if [ ! -f "$PACKAGE_LIST_FILE" ]; then
    print_error "Package list file not found. Checked multiple locations."
    print_info "Please ensure package-list.txt exists in the project root directory."
    exit 1
fi

print_status "Using package list file: $PACKAGE_LIST_FILE"

# Extract custom packages from the package list
CUSTOM_PACKAGES=$(grep "^\[CUSTOM\]" "$PACKAGE_LIST_FILE" | sed 's/\[CUSTOM\] \(.*\) #.*/\1/' | sed 's/\[CUSTOM\] \(.*\)/\1/')

# Count the number of custom packages
PACKAGE_COUNT=$(echo "$CUSTOM_PACKAGES" | grep -v "^$" | wc -l)

if [ "$PACKAGE_COUNT" -eq 0 ]; then
    print_status "No custom packages found in package-list.txt. Skipping installation."
    exit 0
fi

print_status "Found $PACKAGE_COUNT custom package(s) to install."

# Ask user if they want to install the custom packages
if ! ask_yes_no "Would you like to install these custom packages?" "y"; then
    print_status "Skipping custom packages installation."
    exit 0
fi

# Display the packages that will be installed
echo -e "${BRIGHT_WHITE}${BOLD}Custom packages to install:${RESET}"
echo "$CUSTOM_PACKAGES" | while read -r package; do
    if [ -n "$package" ]; then
        echo -e "  ${BRIGHT_CYAN}• ${package}${RESET}"
    fi
done

# Determine which AUR helper to use
if [ -z "$AUR_HELPER" ]; then
    if command -v yay &>/dev/null; then
        export AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        export AUR_HELPER="paru"
    elif command -v trizen &>/dev/null; then
        export AUR_HELPER="trizen"
    elif command -v pikaur &>/dev/null; then
        export AUR_HELPER="pikaur"
    else
        export AUR_HELPER="pacman"
    fi
fi

print_status "Using $AUR_HELPER to install packages..."

# Install packages based on the AUR helper
case "$AUR_HELPER" in
    "yay")
        print_status "Installing with yay..."
        for package in $CUSTOM_PACKAGES; do
            if [ -n "$package" ]; then
                print_status "Installing $package..."
                yay -S --needed --noconfirm "$package"
            fi
        done
        ;;
    "paru")
        print_status "Installing with paru..."
        for package in $CUSTOM_PACKAGES; do
            if [ -n "$package" ]; then
                print_status "Installing $package..."
                paru -S --needed --noconfirm "$package"
            fi
        done
        ;;
    "trizen")
        print_status "Installing with trizen..."
        for package in $CUSTOM_PACKAGES; do
            if [ -n "$package" ]; then
                print_status "Installing $package..."
                trizen -S --needed --noconfirm "$package"
            fi
        done
        ;;
    "pikaur")
        print_status "Installing with pikaur..."
        for package in $CUSTOM_PACKAGES; do
            if [ -n "$package" ]; then
                print_status "Installing $package..."
                pikaur -S --needed --noconfirm "$package"
            fi
        done
        ;;
    "pacman")
        print_status "Installing with pacman (AUR packages will be skipped)..."
        for package in $CUSTOM_PACKAGES; do
            if [ -n "$package" ]; then
                print_status "Installing $package..."
                sudo pacman -S --needed --noconfirm "$package"
            fi
        done
        ;;
    *)
        print_error "Unknown AUR helper: $AUR_HELPER"
        exit 1
        ;;
esac

# Check if installation was successful
if [ $? -eq 0 ]; then
    print_success "Custom packages installed successfully!"
else
    print_warning "Some packages may have failed to install. Please check the output above."
fi

exit 0 
