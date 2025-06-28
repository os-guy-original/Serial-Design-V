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
# │                Flatpak Theme Application                 │
# │         Apply Theme Settings to Flatpak Apps             │
# ╰──────────────────────────────────────────────────────────╯

# Define paths to the component scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
GTK_SCRIPT="${SCRIPT_DIR}/flatpak-theme/gtk.sh"
QT_SCRIPT="${SCRIPT_DIR}/flatpak-theme/qt.sh"

# Make sure the component scripts are executable
chmod +x "${GTK_SCRIPT}" 2>/dev/null
chmod +x "${QT_SCRIPT}" 2>/dev/null

# Function to display help
show_help() {
    echo -e "${BRIGHT_WHITE}${BOLD}NAME${RESET}"
    echo -e "    $(basename "$0") - Apply theme settings to Flatpak applications"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SYNOPSIS${RESET}"
    echo -e "    $(basename "$0") [OPTION]..."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION${RESET}"
    echo -e "    Apply GTK and QT theme settings to Flatpak applications"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS${RESET}"
    echo -e "    ${BRIGHT_CYAN}--only-gtk${RESET}"
    echo -e "        Apply only GTK theme settings"
    echo
    echo -e "    ${BRIGHT_CYAN}--only-qt${RESET}"
    echo -e "        Apply only QT theme settings"
    echo
    echo -e "    ${BRIGHT_CYAN}--help, -h${RESET}"
    echo -e "        Display this help message and exit"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}EXAMPLES${RESET}"
    echo -e "    $(basename "$0")"
    echo -e "        Apply both GTK and QT theme settings"
    echo
    echo -e "    $(basename "$0") --only-gtk"
    echo -e "        Apply only GTK theme settings"
    echo
}

# Process command line arguments
APPLY_GTK=true
APPLY_QT=true

for arg in "$@"; do
    case "$arg" in
        --only-gtk)
            APPLY_GTK=true
            APPLY_QT=false
            ;;
        --only-qt)
            APPLY_GTK=false
            APPLY_QT=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

print_banner "Flatpak Theme Application" "Apply Theme Settings to Flatpak Apps"

# Check if Flatpak is installed
print_status "Checking if Flatpak is installed..."
if ! command -v flatpak &>/dev/null; then
    print_error "Flatpak is not installed. Exiting."
    exit 1
fi

# Apply GTK theme if requested
if [ "$APPLY_GTK" = true ]; then
    print_status "Applying GTK theme settings..."
    
    # Source the GTK script to get access to its functions
    source "${GTK_SCRIPT}"
    
    # Call the apply_gtk_theme function
    apply_gtk_theme
    
    if [ $? -eq 0 ]; then
        print_success "GTK theme settings applied successfully"
    else
        print_error "Failed to apply GTK theme settings"
    fi
fi

# Apply QT theme if requested
if [ "$APPLY_QT" = true ]; then
    print_status "Applying QT theme settings..."
    
    # Source the QT script to get access to its functions
    source "${QT_SCRIPT}"
    
    # Call the apply_qt_theme function
    apply_qt_theme
    
    if [ $? -eq 0 ]; then
        print_success "QT theme settings applied successfully"
    else
        print_error "Failed to apply QT theme settings"
    fi
fi

# Final success message
if [ "$APPLY_GTK" = true ] && [ "$APPLY_QT" = true ]; then
    print_success_banner "Flatpak theme integration complete!"
    print_info "Both GTK and QT theme settings have been applied to Flatpak applications"
elif [ "$APPLY_GTK" = true ]; then
    print_success_banner "Flatpak GTK theme integration complete!"
    print_info "GTK theme settings have been applied to Flatpak applications"
elif [ "$APPLY_QT" = true ]; then
    print_success_banner "Flatpak QT theme integration complete!"
    print_info "QT theme settings have been applied to Flatpak applications"
fi

exit 0 
