#!/bin/bash

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Get the root directory of the project
ROOT_DIR="$(dirname "$(dirname "$0")")"

# Package list file
PACKAGE_LIST_FILE="${ROOT_DIR}/package-list.txt"

print_section "Custom Packages Installation"
print_info "Checking for custom packages in package-list.txt"

# Check if the package list file exists
if [ ! -f "$PACKAGE_LIST_FILE" ]; then
    print_error "Package list file not found at: $PACKAGE_LIST_FILE"
    exit 1
fi

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