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

# Function to install an AUR helper
install_aur_helper() {
    local helper_name="$1"
    print_status "Installing $helper_name from AUR..."
    
    # Create a temporary directory for building
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || {
        print_error "Failed to create temporary directory"
        return 1
    }
    
    # Clone the AUR package
    if ! git clone "https://aur.archlinux.org/${helper_name}.git"; then
        print_error "Failed to clone ${helper_name} repository"
        return 1
    fi
    
    # Enter the directory and build
    cd "${helper_name}" || {
        print_error "Failed to enter ${helper_name} directory"
        return 1
    }
    
    # Build and install
    if ! makepkg -si --noconfirm; then
        print_error "Failed to build and install ${helper_name}"
        return 1
    fi
    
    # Clean up
    cd / || true
    rm -rf "$tmp_dir"
    
    print_success "${helper_name} installed successfully"
    return 0
}

print_section "AUR Helper Detection"
print_info "Checking for available AUR helpers on your system"

# Detect available AUR helpers
AUR_HELPERS=()
if command_exists yay; then
    AUR_HELPERS+=("yay")
fi
if command_exists paru; then
    AUR_HELPERS+=("paru")
fi
if command_exists trizen; then
    AUR_HELPERS+=("trizen")
fi
if command_exists pikaur; then
    AUR_HELPERS+=("pikaur")
fi

# Set default AUR helper
export AUR_HELPER=""

# Choose AUR Helper
if [ ${#AUR_HELPERS[@]} -gt 0 ]; then
    # Display detected AUR helpers
    echo -e "\n${BRIGHT_PURPLE}${BOLD}AUR Helpers Detected:${RESET}"
    for helper in "${AUR_HELPERS[@]}"; do
        echo -e "  ${GREEN}✓${RESET} ${helper}"
    done
    
    # If we have multiple helpers, let the user choose
    if [ ${#AUR_HELPERS[@]} -gt 1 ]; then
        echo
        print_status "Multiple AUR helpers detected. Please choose your preferred one:"
        
        # Add the options for the user to choose
        options=("${AUR_HELPERS[@]}" "pacman (no AUR support)")
        
        # Display options with numbers
        for ((i=0; i<${#options[@]}; i++)); do
            echo -e "  ${BRIGHT_WHITE}$((i+1)).${RESET} ${options[$i]}"
        done
        
        # Ask user to choose
        selected=0
        while [ $selected -lt 1 ] || [ $selected -gt ${#options[@]} ]; do
            echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select AUR helper [1-${#options[@]}]: ${RESET}"
            read -r selected
            
            # Default to first option if empty
            if [ -z "$selected" ]; then
                selected=1
            fi
            
            # Validate input
            if ! [[ "$selected" =~ ^[0-9]+$ ]] || [ $selected -lt 1 ] || [ $selected -gt ${#options[@]} ]; then
                echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#options[@]}.${RESET}"
                selected=0
            fi
        done
        
        # Set the selected AUR helper
        selected_option=${options[$((selected-1))]}
        if [[ "$selected_option" == "pacman (no AUR support)" ]]; then
            AUR_HELPER="pacman"
        else
            AUR_HELPER="$selected_option"
        fi
        
        print_success "Selected AUR helper: $AUR_HELPER"
    else
        # Only one helper detected, use it
        AUR_HELPER="${AUR_HELPERS[0]}"
        print_success "Detected and using ${AUR_HELPER} as the AUR helper."
    fi
else
    # No AUR helper detected, install one
    print_warning "No AUR helper detected."
    
    # Ask which AUR helper to install
    echo -e "\n${BRIGHT_WHITE}${BOLD}Available AUR Helpers:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} yay   - Yet Another Yogurt - AUR Helper in Go"
    echo -e "  ${BRIGHT_WHITE}2.${RESET} paru  - AUR helper written in Rust"
    echo -e "  ${BRIGHT_WHITE}3.${RESET} trizen - Lightweight AUR helper"
    echo -e "  ${BRIGHT_WHITE}4.${RESET} pikaur - AUR helper with minimal dependencies"
    echo -e "  ${BRIGHT_WHITE}5.${RESET} None  - Use pacman only (no AUR support)"
    
    # Ask user to choose
    selected=0
    while [ $selected -lt 1 ] || [ $selected -gt 5 ]; do
        echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Select AUR helper to install [1-5] (default: 1): ${RESET}"
        read -r selected
        
        # Default to yay if no input
        if [ -z "$selected" ]; then
            selected=1
        fi
        
        # Validate input
        if ! [[ "$selected" =~ ^[0-9]+$ ]] || [ $selected -lt 1 ] || [ $selected -gt 5 ]; then
            echo -e "${RED}Invalid selection. Please enter a number between 1 and 5.${RESET}"
            selected=0
        fi
    done
    
    case "$selected" in
        1)
            if install_aur_helper "yay"; then
                AUR_HELPER="yay"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        2)
            if install_aur_helper "paru"; then
                AUR_HELPER="paru"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        3)
            if install_aur_helper "trizen"; then
                AUR_HELPER="trizen"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        4)
            if install_aur_helper "pikaur"; then
                AUR_HELPER="pikaur"
            else
                print_warning "Falling back to pacman (no AUR support)"
                AUR_HELPER="pacman"
            fi
            ;;
        5)
            print_status "Skipping AUR helper installation."
            AUR_HELPER="pacman"
            ;;
    esac
fi

# Export AUR_HELPER for use in other scripts
export AUR_HELPER
echo "export AUR_HELPER=$AUR_HELPER"

# Add a pause to ensure the user sees the selection
sleep 1 