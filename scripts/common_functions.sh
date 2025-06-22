#!/bin/bash

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors & Formatting                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Reset
RESET='\033[0m'

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bright Colors
BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_PURPLE='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Banner Helper Functions                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Center text within a specified width
# Usage: center_text "text" [width] [padding_char]
center_text() {
    local text="${1}"
    local width="${2:-60}"  # Default inner width is 60 characters
    local padding_char="${3:- }"  # Default padding character is space
    
    # Remove ANSI color codes when calculating text length
    local text_without_colors="${text}"
    text_without_colors=$(echo -e "${text_without_colors}" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    
    local text_length=${#text_without_colors}
    
    # Handle special case where text is exactly the right width
    if [ $text_length -eq $width ]; then
        echo -e "${text}"
        return
    fi
    
    # Handle case where text is too long
    if [ $text_length -gt $width ]; then
        # Truncate or just return as is
        echo -e "${text}"
        return
    fi
    
    # Calculate padding needed on each side
    local total_padding=$(( width - text_length ))
    local left_padding=$(( total_padding / 2 ))
    local right_padding=$(( total_padding - left_padding ))
    
    # Create the padding strings
    local left_pad=$(printf "%${left_padding}s" "" | tr " " "${padding_char}")
    local right_pad=$(printf "%${right_padding}s" "" | tr " " "${padding_char}")
    
    # Return centered text
    echo -e "${left_pad}${text}${right_pad}"
}

# Get text length without ANSI color codes
get_text_length() {
    local text="${1}"
    # Remove ANSI color codes
    local text_without_colors=$(echo -e "${text}" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    echo ${#text_without_colors}
}

# Print centered banner with a title
# Usage: print_banner "Title" "Subtitle" [width]
print_banner() {
    local title="${1}"
    local subtitle="${2}"
    
    # Set up star decorations for success banners
    local prefix="" suffix=""
    if [[ "$3" == "success" || "$3" == "completion" ]]; then
        prefix="✨ "
        suffix=" ✨"
    fi
    
    # Add formatting to title and subtitle for display
    local formatted_title="${BOLD}${BRIGHT_YELLOW}${prefix}${title}${suffix}${RESET}"
    local formatted_subtitle="${BRIGHT_WHITE}${subtitle}${RESET}"
    
    # Choose color based on banner type
    local color="${BRIGHT_CYAN}"
    if [[ "$3" == "success" || "$3" == "completion" ]]; then
        color="${BRIGHT_GREEN}${BOLD}"
    fi
    
    # Print the simplified banner with just vertical bars
    echo
    if [[ "$3" == "success" || "$3" == "completion" ]]; then
        echo -e "${color}| ${formatted_title} |${RESET}"
    else
        echo -e "${color}| ${formatted_title} |${RESET}"
    fi
    
    if [ -n "${subtitle}" ]; then
        echo -e "${color}| ${formatted_subtitle} |${RESET}"
    fi
    echo
}

# Print completion banner
# Usage: print_completion_banner "message"
print_completion_banner() {
    local message="${1:-Operation completed successfully!}"
    print_banner "${message}" "" "completion"
}

# Print success banner (for component installations)
# Usage: print_success_banner "Component name has been installed successfully!"
print_success_banner() {
    local message="${1:-Installation completed successfully!}"
    print_banner "${message}" "" "success"
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Helper Functions                                        ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Print a section header
print_section() {
    echo -e "\n${BRIGHT_BLUE}${BOLD}⟪ $1 ⟫${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..64})${RESET}"
}

# Print a status message
print_status() {
    echo -e "${YELLOW}${BOLD}ℹ ${RESET}${YELLOW}$1${RESET}"
}

# Print an informational message
print_info() {
    echo -e "${BRIGHT_BLUE}${ITALIC}  ${RESET}${BRIGHT_WHITE}$1${RESET}"
}

# Print a success message
print_success() {
    echo -e "${GREEN}${BOLD}✓ ${RESET}${GREEN}$1${RESET}"
}

# Print an error message
print_error() {
    echo -e "${RED}${BOLD}✗ ${RESET}${RED}$1${RESET}"
}

# Print a warning message
print_warning() {
    echo -e "${BRIGHT_YELLOW}${BOLD}⚠ ${RESET}${BRIGHT_YELLOW}$1${RESET}"
}

# Ask the user for a yes/no answer
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [ "$default" = "y" ]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}${prompt}${RESET}"
    read -r response
    
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Press Enter to continue
press_enter() {
    echo
    echo -e -n "${BRIGHT_CYAN}${BOLD}► Press Enter to continue...${RESET}"
    read -r
    echo
}

# Ask the user for a choice from a list of options
ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local selection
    
    echo -e "${CYAN}${BOLD}? ${RESET}${CYAN}${prompt}${RESET}"
    
    for i in "${!options[@]}"; do
        echo -e "  ${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}. ${options[$i]}"
    done
    
    echo -e -n "${CYAN}Enter selection [1-${#options[@]}]: ${RESET}"
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
        echo "${options[$((selection-1))]}"
        return 0
    else
        print_error "Invalid selection."
        return 1
    fi
}

# Selection menu (returns the index via return code)
selection_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selection
    
    echo -e "${BRIGHT_BLUE}${BOLD}$title${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..64})${RESET}"
    
    for i in "${!options[@]}"; do
        echo -e "${BRIGHT_WHITE}${BOLD}$((i+1))${RESET}) ${options[$i]}"
    done
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter your choice [1-${#options[@]}]: ${RESET}"
    read -r selection
    
    # Validate input
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#options[@]}" ]; then
        print_error "Invalid selection"
        return 1
    fi
    
    return $((selection-1))
}

# Debug function to print paths and check if they exist
debug_path() {
    local path="$1"
    local description="$2"
    
    echo -e "${BRIGHT_BLACK}${DIM}DEBUG: Checking $description path: $path${RESET}"
    if [ -e "$path" ]; then
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✓ Path exists${RESET}"
    else
        echo -e "${BRIGHT_BLACK}${DIM}DEBUG: ✗ Path does not exist${RESET}"
    fi
}

# Generic help message function
# Usage: print_generic_help [script_name] [description]
print_generic_help() {
    local script_name="${1:-$(basename "$0")}"
    local description="${2:-A utility script for Serial Design V}"
    
    echo -e "${BRIGHT_WHITE}${BOLD}NAME${RESET}"
    echo -e "    ${script_name} - ${description}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}SYNOPSIS${RESET}"
    echo -e "    ${script_name} [OPTION]..."
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}DESCRIPTION${RESET}"
    echo -e "    ${description}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS${RESET}"
    echo -e "    ${BRIGHT_CYAN}--help, -h${RESET}"
    echo -e "        Display this help message and exit"
    echo
    echo -e "    ${BRIGHT_CYAN}--version, -v${RESET}"
    echo -e "        Display version information and exit"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}EXAMPLES${RESET}"
    echo -e "    ${script_name}"
    echo -e "        Run the script with default options"
    echo
    echo -e "    ${script_name} --help"
    echo -e "        Display this help message"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}AUTHOR${RESET}"
    echo -e "    Serial Design V Team"
    echo
}

# Function to handle errors with retry, cancel, and skip options
handle_error() {
    local error_message="$1"
    local retry_function="$2"
    local skip_message="${3:-Skipping this step.}"
    
    print_error "$error_message"
    
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}Options:${RESET}"
    echo -e "  ${BRIGHT_CYAN}1.${RESET} ${BRIGHT_WHITE}Retry${RESET} - Try the operation again"
    echo -e "  ${BRIGHT_CYAN}2.${RESET} ${BRIGHT_WHITE}Skip${RESET} - Skip this step and continue with installation"
    echo -e "  ${BRIGHT_CYAN}3.${RESET} ${BRIGHT_WHITE}Cancel${RESET} - Cancel the installation"
    
    echo
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Choose an option (1-3): ${RESET}"
    read -r choice
    
    case "$choice" in
        1)
            print_status "Retrying..."
            # Call the provided retry function
            $retry_function
            return $?
            ;;
        2)
            print_warning "$skip_message"
            return 2  # Special return code indicating skipped
            ;;
        3)
            print_error "Installation cancelled by user."
            exit 1
            ;;
        *)
            print_warning "Invalid choice. Assuming Skip."
            print_warning "$skip_message"
            return 2
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Nautilus Scripts
install_nautilus_scripts() {
    # Save current directory
    local original_dir="$(pwd)"
    
    print_section "Nautilus Scripts Installation"
    
    if ! ask_yes_no "Would you like to install Nautilus Scripts for enhanced file manager functionality?" "y"; then
        print_status "Skipping Nautilus Scripts installation."
        return
    fi
    
    print_status "Installing Nautilus Scripts..."
    
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Clone the repository
        cd /tmp || {
            print_error "Failed to change to /tmp directory"
            cd "$original_dir" || true
            return 1
        }
        
        rm -rf nautilus-scripts 2>/dev/null
        if ! git clone https://github.com/cfgnunes/nautilus-scripts.git; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Failed to clone repository. Retrying (attempt $retry_count of $max_retries)..."
                sleep 5
                continue
            else
                print_error "Failed to clone repository after $max_retries attempts."
                if ask_yes_no "Would you like to retry the installation?" "y"; then
                    retry_count=0
                    continue
                else
                    print_error "Nautilus Scripts installation failed. Please try again later."
                    cd "$original_dir" || true
                    return 1
                fi
            fi
        fi
        
        cd nautilus-scripts || {
            print_error "Failed to enter nautilus-scripts directory"
            cd "$original_dir" || true
            return 1
        }
        
        # Make installation script executable
        print_status "Making installation script executable..."
        if ! chmod +x ./install.sh; then
            print_error "Failed to make installation script executable"
            cd "$original_dir" || true
            return 1
        fi
        
        # Run the installation script
        print_status "Running installation script..."
        if ! ./install.sh; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Installation script failed. Retrying (attempt $retry_count of $max_retries)..."
                sleep 5
                continue
            else
                print_error "Installation script failed after $max_retries attempts."
                if ask_yes_no "Would you like to retry the installation?" "y"; then
                    retry_count=0
                    continue
                else
                    print_error "Nautilus Scripts installation failed. Please try again later."
                    cd "$original_dir" || true
                    return 1
                fi
            fi
        fi
        
        # Clean up
        cd "$original_dir" || {
            print_warning "Failed to return to original directory. Attempting to recover..."
            cd "$(dirname "$0")/.." || cd "$HOME"
        }
        rm -rf /tmp/nautilus-scripts
        
        print_success_banner "Nautilus Scripts have been installed successfully!"
        print_status "You can access these scripts by right-clicking on files/folders in Nautilus."
        return 0
    done
}

# Function to detect package conflicts
detect_conflicts() {
    local output="$1"
    local conflicts=()
    
    # Look for common conflict patterns in the output
    if [[ "$output" =~ "error: failed to prepare transaction" ]] || [[ "$output" =~ "conflicting files" ]]; then
        # Try to extract the conflicting packages
        while read -r line; do
            # Match patterns like "package1 and package2 are in conflict"
            if [[ "$line" =~ ([a-zA-Z0-9_-]+)[[:space:]]+(and|conflicts with)[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
                conflicts+=("${BASH_REMATCH[1]}")
                conflicts+=("${BASH_REMATCH[3]}")
            fi
            
            # Match patterns like "package1-git conflicts with package1"
            if [[ "$line" =~ ([a-zA-Z0-9_-]+)[[:space:]]+conflicts[[:space:]]+with[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
                conflicts+=("${BASH_REMATCH[1]}")
                conflicts+=("${BASH_REMATCH[2]}")
            fi
        done <<< "$output"
    fi
    
    # Return the unique conflicts
    if [ ${#conflicts[@]} -gt 0 ]; then
        echo "$(echo "${conflicts[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
        return 0
    else
        return 1
    fi
}

# Function to handle package conflicts
handle_conflicts() {
    local conflicts=("$@")
    local to_remove=()
    local to_skip=()
    
    print_warning "Package conflicts detected:"
    for pkg in "${conflicts[@]}"; do
        echo -e "  ${YELLOW}•${RESET} $pkg"
    done
    
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}Options:${RESET}"
    echo -e "  ${BRIGHT_CYAN}1.${RESET} ${BRIGHT_WHITE}Remove conflicting packages${RESET} - Remove the conflicting packages and continue"
    echo -e "  ${BRIGHT_CYAN}2.${RESET} ${BRIGHT_WHITE}Skip conflicting packages${RESET} - Continue installation without the conflicting packages"
    echo -e "  ${BRIGHT_CYAN}3.${RESET} ${BRIGHT_WHITE}Retry without changes${RESET} - Try the installation again without changes"
    echo -e "  ${BRIGHT_CYAN}4.${RESET} ${BRIGHT_WHITE}Cancel installation${RESET} - Abort the installation process"
    
    echo
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Choose an option (1-4): ${RESET}"
    read -r choice
    
    case "$choice" in
        1)
            print_status "Removing conflicting packages..."
            if [ "$AUR_HELPER" = "pacman" ]; then
                sudo pacman -R --noconfirm "${conflicts[@]}"
            else
                $AUR_HELPER -R --noconfirm "${conflicts[@]}"
            fi
            return 0  # Continue with installation
            ;;
        2)
            print_status "Skipping conflicting packages..."
            echo "${conflicts[@]}"
            return 2  # Skip conflicting packages
            ;;
        3)
            print_status "Retrying installation without changes..."
            return 0  # Retry without changes
            ;;
        4)
            print_error "Installation cancelled by user."
            exit 1
            ;;
        *)
            print_warning "Invalid choice. Retrying without changes..."
            return 0
            ;;
    esac
}

# Function to install packages with retry logic and conflict handling
install_packages() {
    local packages=("$@")
    local max_retries=3
    local retry_count=0
    local conflict_retry_count=0
    local max_conflict_retries=2
    local output=""
    local conflicts=()
    local skip_packages=()
    
    # Check if packages array is empty
    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages specified for installation."
        return 0
    fi
    
    # Auto-detect AUR helper if not set
    if [ -z "$AUR_HELPER" ]; then
        print_warning "No AUR helper selected. Auto-detecting..."
        if command -v yay &>/dev/null; then
            AUR_HELPER="yay"
            print_status "Using detected AUR helper: yay"
        elif command -v paru &>/dev/null; then
            AUR_HELPER="paru"
            print_status "Using detected AUR helper: paru"
        elif command -v trizen &>/dev/null; then
            AUR_HELPER="trizen"
            print_status "Using detected AUR helper: trizen"
        elif command -v pikaur &>/dev/null; then
            AUR_HELPER="pikaur"
            print_status "Using detected AUR helper: pikaur"
        else
            AUR_HELPER="pacman"
            print_status "No AUR helper found, using pacman (limited functionality)"
        fi
    fi
    
    # Debug output
    print_status "Packages to install: ${packages[*]}"
    
    # Filter out packages that should be skipped
    local filtered_packages=()
    for pkg in "${packages[@]}"; do
        if [[ ! " ${skip_packages[*]} " =~ " ${pkg} " ]]; then
            filtered_packages+=("$pkg")
        fi
    done
    
    # If all packages were filtered out, return success
    if [ ${#filtered_packages[@]} -eq 0 ]; then
        print_warning "All packages were filtered out. Nothing to install."
        return 0
    fi
    
    # Replace the original packages array with the filtered one
    packages=("${filtered_packages[@]}")
    
    # Skip checking if packages are already installed
    # Always attempt to install all packages
    print_status "Will install all packages (skipping installed check)"
    # The package manager will handle already installed packages
    print_status "Packages to be installed: ${packages[*]}"
    
    while [ $retry_count -lt $max_retries ]; do
        # Create a temporary file to capture output
        local temp_output_file=$(mktemp)
        local exit_status=0
        
        case "$AUR_HELPER" in
            "yay")
                print_status "Installing packages with yay..."
                # Run the command and tee output to both terminal and file
                set -o pipefail  # Make sure pipe failures are captured
                yay -S --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
                exit_status=$?
                set +o pipefail
                ;;
            "paru")
                print_status "Installing packages with paru..."
                set -o pipefail
                paru -S --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
                exit_status=$?
                set +o pipefail
                ;;
            "pacman")
                print_status "Installing packages with pacman..."
                set -o pipefail
                sudo pacman -S --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
                exit_status=$?
                set +o pipefail
                ;;
            *)
                print_error "Unknown AUR helper: $AUR_HELPER"
                print_status "Falling back to pacman..."
                AUR_HELPER="pacman"
                rm -f "$temp_output_file"
                continue
                ;;
        esac
        
        # Read the output from the temporary file
        output=$(cat "$temp_output_file")
        rm -f "$temp_output_file"
        
        # If the installation was successful, break the loop
        if [ $exit_status -eq 0 ]; then
            break
        fi
        
        # Check for conflicts
        conflicts=$(detect_conflicts "$output")
        if [ $? -eq 0 ] && [ -n "$conflicts" ]; then
            print_warning "Package conflicts detected."
            
            if [ $conflict_retry_count -lt $max_conflict_retries ]; then
                # Convert space-separated string to array
                IFS=' ' read -ra conflict_array <<< "$conflicts"
                
                # Handle conflicts
                handle_conflicts "${conflict_array[@]}"
                local conflict_result=$?
                
                if [ $conflict_result -eq 2 ]; then
                    # Skip conflicting packages
                    for conflict in "${conflict_array[@]}"; do
                        # Add conflicting packages to skip list
                        skip_packages+=("$conflict")
                        
                        # Remove conflicting packages from the packages array
                        local new_packages=()
                        for pkg in "${packages[@]}"; do
                            if [ "$pkg" != "$conflict" ]; then
                                new_packages+=("$pkg")
                            else
                                print_status "Skipping package: $pkg"
                            fi
                        done
                        packages=("${new_packages[@]}")
                    done
                    
                    # If all packages were filtered out, return success
                    if [ ${#packages[@]} -eq 0 ]; then
                        print_warning "All packages were filtered out. Nothing to install."
                        return 0
                    fi
                    
                    conflict_retry_count=$((conflict_retry_count + 1))
                    continue
                elif [ $conflict_result -eq 0 ]; then
                    # Retry with the same packages
                    conflict_retry_count=$((conflict_retry_count + 1))
                    continue
                fi
            else
                print_error "Maximum conflict resolution attempts reached."
                print_warning "Continuing without conflicting packages."
                
                # Filter out all conflicting packages
                IFS=' ' read -ra conflict_array <<< "$conflicts"
                for conflict in "${conflict_array[@]}"; do
                    local new_packages=()
                    for pkg in "${packages[@]}"; do
                        if [ "$pkg" != "$conflict" ]; then
                            new_packages+=("$pkg")
                        else
                            print_status "Skipping package: $pkg"
                        fi
                    done
                    packages=("${new_packages[@]}")
                done
                
                # If all packages were filtered out, return success
                if [ ${#packages[@]} -eq 0 ]; then
                    print_warning "All packages were filtered out. Nothing to install."
                    return 0
                fi
                
                # Reset conflict retry count and continue
                conflict_retry_count=0
                continue
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_warning "Package installation failed. This might be due to network issues."
            print_status "Retrying installation (attempt $retry_count of $max_retries)..."
            sleep 5
        else
            print_error "Failed to install packages after $max_retries attempts."
            print_warning "This might be due to network issues or slow mirrors."
            if ask_yes_no "Would you like to retry the installation?" "y"; then
                retry_count=0
                print_status "Retrying installation..."
            else
                print_error "Package installation failed. Please try again later."
                return 1
            fi
        fi
    done
    
    # Configure file manager after installation
    if [[ "${packages[*]}" =~ (nautilus|dolphin|nemo|thunar|pcmanfm) ]]; then
        print_status "File manager package(s) installed. Configuration will be done after copying config files."
        # Removed automatic configure-file-manager.sh call here
    fi
    
    return 0
}

# Function to install Flatpak browsers
install_flatpak_browsers() {
    # Check for existing Flatpak browsers
    existing_flatpak_browsers=()
    if flatpak list | grep -q "org.mozilla.firefox"; then
        existing_flatpak_browsers+=("Firefox")
    fi
    if flatpak list | grep -q "com.google.Chrome"; then
        existing_flatpak_browsers+=("Google Chrome")
    fi
    if flatpak list | grep -q "io.github.ungoogled_software.ungoogled_chromium"; then
        existing_flatpak_browsers+=("UnGoogled Chromium")
    fi
    if flatpak list | grep -q "org.gnome.Epiphany"; then
        existing_flatpak_browsers+=("Epiphany")
    fi
    
    if [ ${#existing_flatpak_browsers[@]} -gt 0 ]; then
        print_warning "The following Flatpak browsers are already installed:"
        for browser in "${existing_flatpak_browsers[@]}"; do
            echo -e "  ${YELLOW}•${RESET} $browser"
        done
        if ! ask_yes_no "Do you want to continue with installation?" "y"; then
            print_status "Skipping browser installation."
            return
        fi
    fi
    
    # List available Flatpak browsers
    echo -e "\n${BRIGHT_WHITE}${BOLD}Available Flatpak Browsers:${RESET}"
    echo -e "  ${BRIGHT_WHITE}1.${RESET} Zen Browser - A privacy-focused browser"
    echo -e "  ${BRIGHT_WHITE}2.${RESET} Firefox - Popular open-source browser"
    echo -e "  ${BRIGHT_WHITE}3.${RESET} Google Chrome - Google's web browser"
    echo -e "  ${BRIGHT_WHITE}4.${RESET} UnGoogled Chromium - Chromium without Google integration"
    echo -e "  ${BRIGHT_WHITE}5.${RESET} Epiphany (GNOME Web) - Lightweight web browser"
    echo -e "  ${BRIGHT_WHITE}6.${RESET} LibreWolf - A privacy-focused fork of Firefox"
    
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Enter browser numbers (comma-separated, e.g., 1,3,5): ${RESET}"
    read -r browser_choices
    
    if [[ -n "$browser_choices" ]]; then
        IFS=',' read -ra choices <<< "$browser_choices"
        
        for choice in "${choices[@]}"; do
            case "$choice" in
                1)
                    print_status "Installing Zen Browser..."
                    flatpak install -y flathub app.zen_browser.zen
                    ;;
                2)
                    print_status "Installing Firefox..."
                    flatpak install -y flathub org.mozilla.firefox
                    ;;
                3)
                    print_status "Installing Google Chrome..."
                    flatpak install -y flathub com.google.Chrome
                    ;;
                4)
                    print_status "Installing UnGoogled Chromium..."
                    flatpak install -y flathub io.github.ungoogled_software.ungoogled_chromium
                    ;;
                5)
                    print_status "Installing Epiphany..."
                    flatpak install -y flathub org.gnome.Epiphany
                    ;;
                6)
                    print_status "Installing LibreWolf..."
                    flatpak install -y flathub io.gitlab.librewolf-community
                    ;;
                *)
                    print_warning "Invalid selection: $choice. Skipping."
                    ;;
            esac
        done
    fi
}

# Function to setup theme files with system-specific handling
setup_theme() {
    # Save current directory
    local original_dir="$(pwd)"
    
    # Initialize GTK theme skip flag
    GTK_THEME_SKIPPED=false
    export GTK_THEME_SKIPPED
    
    # Note: We don't print the section header here because it's already printed in the main script
    print_status "Checking theme installations and offering components if needed..."
    
    # Use the dedicated functions for each theme component
    # Each of these functions already handles reinstallation prompts
    offer_gtk_theme
    offer_cursor_install
    offer_icon_theme_install
    
    # Offer QT theme installation for flatpak apps
    offer_qt_theme_install
    
    # Make sure we return to the original directory
    cd "$original_dir" || {
        print_warning "Failed to return to original directory after theme setup"
        # Try to get back to the script's directory 
        if [ -n "$ORIGINAL_INSTALL_DIR" ]; then
            cd "$ORIGINAL_INSTALL_DIR" || true
        else
            cd "$(dirname "$0")/.." || true
        fi
    }
}

# Function to setup configuration files
setup_configuration() {
    print_section "Configuration Setup"
    print_status "Running configuration script..."
    
    CONFIG_SCRIPT=$(get_script_path "copy-configs.sh")
    
    if [ -f "$CONFIG_SCRIPT" ]; then
        if [ ! -x "$CONFIG_SCRIPT" ]; then
            print_status "Making configuration script executable..."
            chmod +x "$CONFIG_SCRIPT"
        fi
        
        "$CONFIG_SCRIPT"
    else
        print_error "Configuration script not found at: $CONFIG_SCRIPT"
        print_warning "You will need to copy configuration files manually."
    fi
    
    # Also run file manager configuration
    FILE_MANAGER_CONFIG=$(get_script_path "configure-file-manager.sh")
    
    if [ -f "$FILE_MANAGER_CONFIG" ]; then
        if [ ! -x "$FILE_MANAGER_CONFIG" ]; then
            print_status "Making file manager configuration script executable..."
            chmod +x "$FILE_MANAGER_CONFIG"
        fi
        
        "$FILE_MANAGER_CONFIG"
    else
        print_error "File manager configuration script not found at: $FILE_MANAGER_CONFIG"
        print_warning "You will need to configure your file manager manually."
    fi
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Installation Helper Functions                           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Function to offer theme setup
offer_theme_setup() {
    echo
    print_section "Advanced Theme Configuration"
    
    # Get the appropriate script prefix
    SCRIPTS_PREFIX=$(get_script_prefix)
    
    if ask_yes_no "Would you like to manually configure additional theme settings?" "n"; then
        print_status "Launching the theme setup script..."
        
        # Check multiple possible locations for the script
        THEME_SETUP_SCRIPT=""
        for path in "${SCRIPTS_PREFIX}setup-themes.sh" "./scripts/setup-themes.sh" "./setup-themes.sh" "../scripts/setup-themes.sh"; do
            if [ -f "$path" ]; then
                THEME_SETUP_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$THEME_SETUP_SCRIPT" ]; then
            print_error "Could not find setup-themes.sh script in any known location."
            print_status "Expected locations checked: ${SCRIPTS_PREFIX}setup-themes.sh, ./scripts/setup-themes.sh, ./setup-themes.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$THEME_SETUP_SCRIPT" ]; then
            print_status "Making theme setup script executable: $THEME_SETUP_SCRIPT"
            chmod +x "$THEME_SETUP_SCRIPT"
        fi
        
        print_status "Running theme setup script from: $THEME_SETUP_SCRIPT"
        run_with_sudo "$THEME_SETUP_SCRIPT"
    else
        print_status "Skipping advanced theme configuration. You can run it later with: sudo ./scripts/setup-themes.sh"
    fi
}

# Function to offer config management
offer_config_management() {
    echo
    print_section "Configuration Management"
    
    # Get the appropriate script prefix
    SCRIPTS_PREFIX=$(get_script_prefix)
    
    if ask_yes_no "Would you like to manage your configuration files?" "y"; then
        print_status "Launching the configuration management script..."
        
        # Check multiple possible locations for the script
        CONFIG_MGMT_SCRIPT=""
        for path in "${SCRIPTS_PREFIX}manage-config.sh" "./scripts/manage-config.sh" "./manage-config.sh" "../scripts/manage-config.sh"; do
            if [ -f "$path" ]; then
                CONFIG_MGMT_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$CONFIG_MGMT_SCRIPT" ]; then
            print_error "Could not find manage-config.sh script in any known location."
            print_status "Expected locations checked: ${SCRIPTS_PREFIX}manage-config.sh, ./scripts/manage-config.sh, ./manage-config.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$CONFIG_MGMT_SCRIPT" ]; then
            print_status "Making configuration management script executable: $CONFIG_MGMT_SCRIPT"
            chmod +x "$CONFIG_MGMT_SCRIPT"
        fi
        
        print_status "Running configuration management script from: $CONFIG_MGMT_SCRIPT"
        run_with_sudo "$CONFIG_MGMT_SCRIPT"
    else
        print_status "Skipping configuration management. You can run it later with: sudo ./scripts/manage-config.sh"
    fi
}

# Function to show all available scripts
show_available_scripts() {
    echo
    print_section "Available Scripts"
    
    echo -e "${BRIGHT_WHITE}${BOLD}Serial Design V comes with several utility scripts:${RESET}"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Core Installation:${RESET}"
    echo -e "  ${CYAN}• install.sh${RESET} - Main installation script (current)"
    echo -e "  ${CYAN}• scripts/arch_install.sh${RESET} - Arch Linux specific installation"
    echo -e "  ${CYAN}• scripts/install-flatpak.sh${RESET} - Install and configure Flatpak"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Components:${RESET}"
    echo -e "  ${CYAN}• scripts/install-gtk-theme.sh${RESET} - Install serial-design-V GTK theme"
    echo -e "  ${CYAN}• scripts/install-cursors.sh${RESET} - Install Bibata cursors"
    echo -e "  ${CYAN}• scripts/install-qt-theme.sh${RESET} - Install QT/KDE theme for flatpak apps"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Theme Activation:${RESET}"
    echo -e "  ${CYAN}• scripts/setup-themes.sh${RESET} - Configure and activate installed themes"
    echo
    echo -e "${BRIGHT_GREEN}${BOLD}Configuration:${RESET}"
    echo -e "  ${CYAN}• scripts/manage-config.sh${RESET} - Manage Serial Design V configuration files"
    echo
    echo -e "${BRIGHT_WHITE}Run any script with: ${BRIGHT_CYAN}chmod +x <script-path> && ./<script-path>${RESET}"
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Theme Installation Check Functions                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Function to check if GTK theme is installed
check_gtk_theme_installed() {
    local theme_name="adw-gtk3-dark"
    local gtk_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking GTK theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in /usr/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in $HOME/.local/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    if [ -d "$HOME/.themes/$theme_name" ]; then
        print_status "Found GTK theme in $HOME/.themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/themes/$theme_name" ]; then
        print_status "Found GTK theme in /usr/local/share/themes/$theme_name"
        gtk_theme_found=true
    fi
    
    # Configuration check is only a secondary indicator, not primary
    if ! $gtk_theme_found; then
        # Check configuration only if theme files not found
        if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-theme-name=adw-gtk3" "$HOME/.config/gtk-3.0/settings.ini"; then
            print_status "Found adw-gtk3 theme configured in GTK3 settings, but theme files may be missing"
        fi
        
        if [ -f "$HOME/.config/gtk-4.0/settings.ini" ] && grep -q "gtk-theme-name=adw-gtk3" "$HOME/.config/gtk-4.0/settings.ini"; then
            print_status "Found adw-gtk3 theme configured in GTK4 settings, but theme files may be missing"
        fi
    fi
    
    if $gtk_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if QT theme is installed
check_qt_theme_installed() {
    local theme_name="Graphite-rimlessDark"
    local qt_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking QT theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in /usr/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in $HOME/.local/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    if [ -d "$HOME/.config/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in $HOME/.config/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/Kvantum/$theme_name" ]; then
        print_status "Found QT theme in /usr/local/share/Kvantum/$theme_name"
        qt_theme_found=true
    fi
    
    # Also check for Graphite-Dark as an alternative
    if [ -d "/usr/share/Kvantum/Graphite-Dark" ] || [ -d "$HOME/.local/share/Kvantum/Graphite-Dark" ] || [ -d "$HOME/.config/Kvantum/Graphite-Dark" ]; then
        print_status "Found alternative QT theme (Graphite-Dark)"
        qt_theme_found=true
    fi
    
    # Check for general Graphite Kvantum theme
    if [ -d "/usr/share/Kvantum/Graphite" ] || [ -d "$HOME/.local/share/Kvantum/Graphite" ] || [ -d "$HOME/.config/Kvantum/Graphite" ]; then
        print_status "Found general Graphite QT theme"
        qt_theme_found=true
    fi
    
    # Check if Kvantum config mentions the theme
    if [ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ] && grep -q "theme=Graphite\|theme=Graphite-Dark\|theme=Graphite-rimlessDark" "$HOME/.config/Kvantum/kvantum.kvconfig"; then
        print_status "Found Graphite theme configured in Kvantum settings"
        qt_theme_found=true
    fi
    
    if $qt_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if cursor theme is installed
check_cursor_theme_installed() {
    local theme_name="Graphite-dark-cursors"
    local cursor_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking cursor theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in /usr/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in $HOME/.local/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    if [ -d "$HOME/.icons/$theme_name" ]; then
        print_status "Found cursor theme in $HOME/.icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/icons/$theme_name" ]; then
        print_status "Found cursor theme in /usr/local/share/icons/$theme_name"
        cursor_theme_found=true
    fi
    
    # Check for different Graphite variants
    local graphite_variants=("Graphite-cursors" "Graphite-light-cursors" "Graphite-dark-cursors")
    for variant in "${graphite_variants[@]}"; do
        if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ]; then
            print_status "Found alternative Graphite cursor variant: $variant"
            cursor_theme_found=true
        fi
    done
    
    # Configuration check is only a secondary indicator, not primary
    if ! $cursor_theme_found; then
        # Check configuration only if theme files not found
        if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-cursor-theme-name=Graphite" "$HOME/.config/gtk-3.0/settings.ini"; then
            print_status "Found Graphite configured in GTK3 settings, but theme files may be missing"
        fi
        
        if [ -f "$HOME/.icons/default/index.theme" ] && grep -q "Inherits=Graphite" "$HOME/.icons/default/index.theme"; then
            print_status "Found Graphite configured in default cursor theme, but theme files may be missing"
        fi
    fi
    
    if $cursor_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to check if icon theme is installed
check_icon_theme_installed() {
    local theme_name="Fluent-grey"
    local icon_theme_found=false
    
    # Debug all possible theme paths for better diagnosis
    print_status "Checking icon theme installation locations..."
    
    # System-wide installations
    if [ -d "/usr/share/icons/$theme_name" ]; then
        print_status "Found icon theme in /usr/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    # User installations
    if [ -d "$HOME/.local/share/icons/$theme_name" ]; then
        print_status "Found icon theme in $HOME/.local/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    if [ -d "$HOME/.icons/$theme_name" ]; then
        print_status "Found icon theme in $HOME/.icons/$theme_name"
        icon_theme_found=true
    fi
    
    # Legacy or alternative paths
    if [ -d "/usr/local/share/icons/$theme_name" ]; then
        print_status "Found icon theme in /usr/local/share/icons/$theme_name"
        icon_theme_found=true
    fi
    
    # Check for Fluent icon themes
    local fluent_variants=("Fluent" "Fluent-dark" "Fluent-light" "Fluent-teal" "Fluent-teal-dark" "Fluent-purple" "Fluent-purple-dark" "Fluent-pink" "Fluent-pink-dark" "Fluent-orange" "Fluent-orange-dark" "Fluent-green" "Fluent-green-dark" "Fluent-cyan" "Fluent-cyan-dark" "Fluent-yellow" "Fluent-yellow-dark" "Fluent-red" "Fluent-red-dark")
    for variant in "${fluent_variants[@]}"; do
        if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ]; then
            print_status "Found Fluent icon theme variant: $variant"
            icon_theme_found=true
        fi
    done
    
    # Configuration check is only a secondary indicator, not primary
    if ! $icon_theme_found; then
        # Check configuration only if theme files not found
        if [ -f "$HOME/.config/gtk-3.0/settings.ini" ] && grep -q "gtk-icon-theme-name=Fluent" "$HOME/.config/gtk-3.0/settings.ini"; then
            print_status "Found Fluent theme configured in GTK3 settings, but theme files may be missing"
        fi
    fi
    
    if $icon_theme_found; then
        return 0  # Theme is installed
    else
        return 1  # Theme is not installed
    fi
}

# Function to offer GTK theme installation
offer_gtk_theme() {
    echo
    print_section "GTK Theme Installation"
    
    # Initialize the GTK theme skip flag (default to false)
    GTK_THEME_SKIPPED=false
    
    if check_gtk_theme_installed; then
        print_success "GTK theme 'adw-gtk3-dark' is already installed."
        if ! ask_yes_no "Would you like to reinstall it?" "n"; then
            print_status "Skipping GTK theme installation."
            return
        fi
        print_status "Reinstalling GTK theme..."
    else
        print_warning "GTK theme is not installed. Your theme settings will be incomplete without it."
    fi
    
    # Get the appropriate script prefix
    SCRIPTS_PREFIX=$(get_script_prefix)
    
    if ask_yes_no "Would you like to install the adw-gtk3-dark GTK theme?" "y"; then
        print_status "Launching the GTK theme installer..."
        
        # Check multiple possible locations for the script
        GTK_THEME_SCRIPT=""
        for path in "${SCRIPTS_PREFIX}install-gtk-theme.sh" "./scripts/install-gtk-theme.sh" "./install-gtk-theme.sh" "../scripts/install-gtk-theme.sh"; do
            if [ -f "$path" ]; then
                GTK_THEME_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$GTK_THEME_SCRIPT" ]; then
            print_error "Could not find install-gtk-theme.sh script in any known location."
            print_status "Expected locations checked: ${SCRIPTS_PREFIX}install-gtk-theme.sh, ./scripts/install-gtk-theme.sh, ./install-gtk-theme.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$GTK_THEME_SCRIPT" ]; then
            print_status "Making GTK theme installer executable: $GTK_THEME_SCRIPT"
            chmod +x "$GTK_THEME_SCRIPT"
        fi
        
        print_status "Running GTK theme installer from: $GTK_THEME_SCRIPT"
        "$GTK_THEME_SCRIPT"
        
        # After the theme installer is done, handle Flatpak GTK theme integration
        if ask_yes_no "Would you like to apply the GTK theme to Flatpak applications?" "y"; then
            print_status "Setting up adw-gtk3-dark theme for Flatpak applications..."
            
            # Apply theme to Flatpak applications
            print_status "Enabling GTK theme access for Flatpak applications..."
            flatpak override --user --filesystem=~/.themes
            
            print_status "Setting adw-gtk3-dark as the default GTK theme for Flatpak applications..."
            flatpak override --user --env=GTK_THEME=adw-gtk3-dark
            
            print_success "Flatpak GTK theme integration complete!"
        else
            print_status "Skipping Flatpak GTK theme integration."
        fi
    else
        print_status "Skipping GTK theme installation. You can run it later with: ./scripts/install-gtk-theme.sh"
        GTK_THEME_SKIPPED=true
    fi
    
    # Export the GTK theme skip status
    export GTK_THEME_SKIPPED
}

# Function to offer QT theme installation for flatpak apps
offer_qt_theme_install() {
    print_status "Checking QT theme installation for flatpak apps..."
    
    # Get the appropriate script prefix
    SCRIPTS_PREFIX=$(get_script_prefix)
    
    # Check if flatpak is installed
    if ! command_exists flatpak; then
        print_status "Flatpak is not installed. Skipping QT theme installation."
        return 0
    fi
    
    if ask_yes_no "Would you like to install QT/KDE theme for flatpak apps?" "y"; then
        print_status "Launching the QT theme installation script..."
        
        # Check multiple possible locations for the script
        QT_THEME_SCRIPT=""
        for path in "${SCRIPTS_PREFIX}install-qt-theme.sh" "./scripts/install-qt-theme.sh" "./install-qt-theme.sh" "../scripts/install-qt-theme.sh"; do
            if [ -f "$path" ]; then
                QT_THEME_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$QT_THEME_SCRIPT" ]; then
            print_error "Could not find install-qt-theme.sh script in any known location."
            print_status "Expected locations checked: ${SCRIPTS_PREFIX}install-qt-theme.sh, ./scripts/install-qt-theme.sh, ./install-qt-theme.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$QT_THEME_SCRIPT" ]; then
            print_status "Making QT theme installation script executable: $QT_THEME_SCRIPT"
            chmod +x "$QT_THEME_SCRIPT"
        fi
        
        print_status "Running QT theme installation script from: $QT_THEME_SCRIPT"
        "$QT_THEME_SCRIPT"
    else
        print_status "Skipping QT theme installation for flatpak apps. You can run it later with: ./scripts/install-qt-theme.sh"
    fi
}

# Function to offer cursor installation
offer_cursor_install() {
    # Save current directory
    local original_dir="$(pwd)"
    
    echo
    print_section "Cursor Installation"
    
    local reinstall=false
    
    if check_cursor_theme_installed; then
        print_success "Cursor theme 'Graphite-dark-cursors' is already installed."
        if ask_yes_no "Would you like to reinstall it?" "n"; then
            print_status "Reinstalling cursor theme..."
            reinstall=true
        else
            print_status "Skipping cursor theme installation."
            # Return to original directory before returning from function
            cd "$original_dir" || true
            return
        fi
    else
        print_warning "Cursor theme is not installed. Your system will use the default cursor theme."
        # No need to ask again if they want to install - we'll proceed directly
    fi
    
    # If reinstalling or not installed, proceed with installation
    if $reinstall || ! check_cursor_theme_installed; then
        # No need to ask again
        print_status "Installing Graphite cursors..."
        
        # Use the dedicated cursor installation function
        if install_cursor_theme; then
            # Show a main success banner after successful installation
            print_success_banner "Graphite cursor theme installed successfully!"
        else
            print_error "Failed to install Graphite cursor theme."
            
            # Fallback to running the script if it exists
            print_status "Trying alternative installation method..."
            
            # Check multiple possible locations for the script
            CURSOR_SCRIPT=""
            for path in "$(get_script_path "install-cursors.sh")" "./scripts/install-cursors.sh" "./install-cursors.sh" "../scripts/install-cursors.sh"; do
                if [ -f "$path" ]; then
                    CURSOR_SCRIPT="$path"
                    break
                fi
            done
            
            if [ -z "$CURSOR_SCRIPT" ]; then
                print_error "Could not find install-cursors.sh script in any known location."
                print_status "You can try installing manually with: yay -S graphite-cursor-theme"
                # Return to original directory before returning from function
                cd "$original_dir" || true
                return 1
            fi
            
            # Make executable if needed
            if [ ! -x "$CURSOR_SCRIPT" ]; then
                print_status "Making cursor installer executable: $CURSOR_SCRIPT"
                chmod +x "$CURSOR_SCRIPT"
            fi
            
            print_status "Running cursor installer from: $CURSOR_SCRIPT"
            if [ -t 0 ]; then
                # We have a terminal, use sudo normally
                run_with_sudo "$CURSOR_SCRIPT"
            else
                print_warning "Non-interactive environment detected for cursor installation."
                print_status "Please run the cursor installer manually with: sudo $CURSOR_SCRIPT"
                # Return to original directory before returning from function
                cd "$original_dir" || true
                return 1
            fi
        fi
    else
        print_status "Skipping cursor installation. You can run it later with: sudo ./scripts/install-cursors.sh"
    fi
    
    # Always return to original directory before exiting
    cd "$original_dir" || {
        print_warning "Failed to return to original directory after cursor installation"
        # Try to get back to the main installation directory if defined
        if [ -n "$ORIGINAL_INSTALL_DIR" ]; then
            cd "$ORIGINAL_INSTALL_DIR" || true
        fi
    }
}

# Function to offer icon theme installation
offer_icon_theme_install() {
    echo
    print_section "Icon Theme Installation"
    
    if check_icon_theme_installed; then
        print_success "Fluent icon theme already installed."
        if ! ask_yes_no "Would you like to reinstall it?" "n"; then
            print_status "Skipping icon theme installation."
            return
        fi
        print_status "Reinstalling icon theme..."
    else
        print_warning "Icon theme is not installed. Your system will use the default icon theme."
    fi
    
    # Set the default variant - no user choice
    FLUENT_VARIANT="Fluent-grey"
    
    # Ask if user wants to install the icon theme
    if ask_yes_no "Would you like to install the $FLUENT_VARIANT icon theme?" "y"; then
        print_status "Installing $FLUENT_VARIANT icon theme..."
        
        # Check multiple possible locations for the script
        ICON_SCRIPT=""
        for path in "$(get_script_path "install-icon-theme.sh")" "./scripts/install-icon-theme.sh" "./install-icon-theme.sh" "../scripts/install-icon-theme.sh"; do
            if [ -f "$path" ]; then
                ICON_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$ICON_SCRIPT" ]; then
            print_error "Could not find install-icon-theme.sh script in any known location."
            print_status "Expected locations checked: $(get_script_path "install-icon-theme.sh"), ./scripts/install-icon-theme.sh, ./install-icon-theme.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$ICON_SCRIPT" ]; then
            print_status "Making icon theme installer executable: $ICON_SCRIPT"
            chmod +x "$ICON_SCRIPT"
        fi
        
        print_status "Running icon theme installer from: $ICON_SCRIPT"
        run_with_sudo "$ICON_SCRIPT" "fluent" "$FLUENT_VARIANT"
    else
        print_status "Skipping icon theme installation. You can run it later with: sudo ./scripts/install-icon-theme.sh fluent Fluent-grey"
    fi
}

# Function to offer Flatpak installation
offer_flatpak_install() {
    echo
    print_section "Flatpak Installation"
    
    # Get the appropriate script prefix
    SCRIPTS_PREFIX=$(get_script_prefix)
    
    if ask_yes_no "Would you like to install Flatpak and set it up?" "y"; then
        print_status "Launching the Flatpak installer..."
        
        # Check multiple possible locations for the script
        FLATPAK_SCRIPT=""
        for path in "${SCRIPTS_PREFIX}install-flatpak.sh" "./scripts/install-flatpak.sh" "./install-flatpak.sh" "../scripts/install-flatpak.sh"; do
            if [ -f "$path" ]; then
                FLATPAK_SCRIPT="$path"
                break
            fi
        done
        
        if [ -z "$FLATPAK_SCRIPT" ]; then
            print_error "Could not find install-flatpak.sh script in any known location."
            print_status "Expected locations checked: ${SCRIPTS_PREFIX}install-flatpak.sh, ./scripts/install-flatpak.sh, ./install-flatpak.sh"
            print_status "Current directory: $(pwd)"
            return 1
        fi
        
        # Make executable if needed
        if [ ! -x "$FLATPAK_SCRIPT" ]; then
            print_status "Making Flatpak installer executable: $FLATPAK_SCRIPT"
            chmod +x "$FLATPAK_SCRIPT"
        fi
        
        print_status "Running Flatpak installer from: $FLATPAK_SCRIPT"
        run_with_sudo "$FLATPAK_SCRIPT"
    else
        print_status "Skipping Flatpak installation. You can run it later with: sudo ./scripts/install-flatpak.sh"
    fi
}

# Function to automatically set up themes
auto_setup_themes() {
    print_section "Automatic Theme Activation"
    print_status "Automatically applying themes..."
    
    # Detect icon theme first
    ICON_THEME="Fluent-grey"  # Default
    
    # Check for Fluent variants - if Fluent-grey not found, switch to another Fluent variant
    if [ ! -d "/usr/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.local/share/icons/$ICON_THEME" ] && [ ! -d "$HOME/.icons/$ICON_THEME" ]; then
        local fluent_variants=("Fluent-dark" "Fluent" "Fluent-light")
        for variant in "${fluent_variants[@]}"; do
            if [ -d "/usr/share/icons/$variant" ] || [ -d "$HOME/.local/share/icons/$variant" ] || [ -d "$HOME/.icons/$variant" ]; then
                print_status "Fluent-grey not found, using alternative Fluent variant: $variant"
                ICON_THEME="$variant"
                break
            fi
        done
    fi
    
    # Configure GTK theme
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # Set GTK3 theme
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    # Set GTK4 theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Graphite-Dark
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Graphite-dark-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    
    print_success_banner "Themes have been automatically applied!"
    print_status "You can still manually configure themes with: ./scripts/setup-themes.sh"
}

# Function to print help message
print_help() {
    echo -e "${BRIGHT_CYAN}${BOLD}╭────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                                        ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_GREEN}${BOLD}                 Serial Design V Help                 ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}  ${BRIGHT_YELLOW}${ITALIC}          A Nice Hyprland Rice Install Helper      ${RESET}  ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}│${RESET}                                                        ${BRIGHT_CYAN}${BOLD}│${RESET}"
    echo -e "${BRIGHT_CYAN}${BOLD}╰────────────────────────────────────────────────────────────╯${RESET}"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}USAGE:${RESET}"
    echo -e "  ${CYAN}./install.sh${RESET} [options]"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}OPTIONS:${RESET}"
    echo -e "  ${CYAN}--help${RESET}    Display this help message"
    echo
    
    # Show available scripts
    show_available_scripts
    
    # Show installation options
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}INSTALLATION PROCESS:${RESET}"
    echo -e "  1. The installer will auto-detect your Linux distribution"
    echo -e "  2. It will run the appropriate installation script for your distribution"
    echo -e "  3. You will be prompted to install theme components"
    echo -e "  4. Configuration files will be managed and installed"
    echo -e "  5. Themes will be activated if desired"
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}NOTE:${RESET}"
    echo -e "  You can run any of the scripts individually as needed"
    echo -e "  All scripts have good defaults for a quick installation"
}

# Function to determine the scripts directory path reliably
get_scripts_dir() {
    # Try to find the scripts directory using various methods
    
    # Method 1: Check if we're in the scripts directory
    if [ "$(basename "$(pwd)")" = "scripts" ]; then
        echo "."
        return 0
    fi
    
    # Method 2: Check if scripts directory is in current directory
    if [ -d "./scripts" ]; then
        echo "./scripts"
        return 0
    fi
    
    # Method 3: Check if we're in a subdirectory of the main project
    if [ -d "../scripts" ]; then
        echo "../scripts"
        return 0
    fi
    
    # Method 4: Check absolute repository path if we can determine it
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/scripts" ]; then
        echo "$REPO_ROOT/scripts"
        return 0
    fi
    
    # If we can't determine the scripts directory, use a default
    echo "./scripts"
    return 1
}

# Function to get the full path to a script
get_script_path() {
    local script_name="$1"
    local scripts_dir=$(get_scripts_dir)
    
    # Check if the script exists in the determined scripts directory
    if [ -f "$scripts_dir/$script_name" ]; then
        echo "$scripts_dir/$script_name"
        return 0
    fi
    
    # Try alternative locations
    for dir in "." "../scripts" "./scripts"; do
        if [ -f "$dir/$script_name" ]; then
            echo "$dir/$script_name"
            return 0
        fi
    done
    
    # Return the expected path even if not found
    echo "$scripts_dir/$script_name"
    return 1
}

# Helper function to get the script path prefix
get_script_prefix() {
    # Determine if being run from a script in the scripts directory
    local current_dir=$(pwd)
    local script_name=$(basename "${BASH_SOURCE[1]}")
    local dir_name=$(basename "$current_dir")
    
    # First try to use get_scripts_dir which is more reliable
    local scripts_dir=$(get_scripts_dir)
    if [ -n "$scripts_dir" ]; then
        echo "$scripts_dir/"
        return 0
    fi
    
    # Fallback to the old method but with better detection
    if [ "$dir_name" = "scripts" ]; then
        # We're inside the scripts directory
        echo "./"
    elif [ -d "./scripts" ]; then
        # We're in the root directory
        echo "./scripts/"
    elif [ -d "../scripts" ]; then
        # We're in a subdirectory
        echo "../scripts/"
    else
        # Default case, assume scripts directory is relative to current location
        echo "./scripts/"
    fi
}

# Function to run a script with sudo if needed
run_with_sudo() {
    local script_path="$1"
    shift
    local script_args=("$@")
    
    if [ "$EUID" -ne 0 ]; then
        print_status "This script requires root privileges. Running with sudo..."
        if command_exists sudo; then
            # First, check if we're in an interactive terminal
            if [ -t 0 ]; then
                # Interactive terminal exists, use normal sudo
                sudo "$script_path" "${script_args[@]}"
                return $?
            else
                # Try to setup an askpass helper if possible
                if [ -n "$SUDO_ASKPASS" ] && [ -x "$SUDO_ASKPASS" ]; then
                    # Use the configured askpass program
                    print_status "Using configured askpass program: $SUDO_ASKPASS"
                    sudo -A "$script_path" "${script_args[@]}"
                    return $?
                elif command_exists ssh-askpass; then
                    # Use ssh-askpass if available
                    print_status "Using ssh-askpass for password prompt"
                    SUDO_ASKPASS=ssh-askpass sudo -A "$script_path" "${script_args[@]}"
                    return $?
                elif command_exists zenity; then
                    # Create a temporary askpass script using zenity
                    local tmp_askpass=$(mktemp)
                    cat > "$tmp_askpass" << 'EOF'
#!/bin/sh
zenity --password --title="Sudo Password Required" --text="Enter your password for sudo:"
EOF
                    chmod +x "$tmp_askpass"
                    print_status "Using zenity for password prompt"
                    SUDO_ASKPASS="$tmp_askpass" sudo -A "$script_path" "${script_args[@]}"
                    ret=$?
                    rm -f "$tmp_askpass"
                    return $ret
                else
                    # No askpass helper available, inform the user
                    print_error "Cannot prompt for sudo password in non-interactive mode."
                    print_error "Please run the script directly with sudo: sudo $script_path ${script_args[*]}"
                    return 1
                fi
            fi
        else
            print_error "sudo command not found. Please run this script as root."
            return 1
        fi
    else
        # Already running as root
        "$script_path" "${script_args[@]}"
        return $?
    fi
}

# Function to install cursor theme with proper handling for package managers
install_cursor_theme() {
    # Skip the section header since it's already shown in the calling function
    
    # Don't show a root privileges warning if we're reinstalling
    # The pacman commands will use sudo when needed
    
    print_status "Installing Graphite cursor theme..."
    
    # Detect package manager
    if command_exists pacman; then
        # Arch-based system
        
        # Try to install from official repositories first
        if sudo pacman -Sy --needed --noconfirm graphite-cursor-theme 2>/dev/null; then
            print_success "Installed graphite-cursor-theme from official repositories."
            return 0
        fi
        
        # If not in official repos, try AUR
        if command_exists yay; then
            print_status "Installing from AUR with yay..."
            
            # Using direct command with interactive TTY for password prompt
            if [ -t 0 ]; then
                # Interactive terminal exists, use normal yay
                yay -S --needed --noconfirm graphite-cursor-theme
                return $?
            else
                # Try running with a visible terminal
                if command_exists x-terminal-emulator; then
                    print_status "Launching terminal for installation..."
                    x-terminal-emulator -e "yay -S --needed --noconfirm graphite-cursor-theme"
                    return $?
                elif command_exists gnome-terminal; then
                    print_status "Launching GNOME terminal for installation..."
                    gnome-terminal -- bash -c "yay -S --needed --noconfirm graphite-cursor-theme; echo 'Press Enter to close'; read"
                    return $?
                elif command_exists konsole; then
                    print_status "Launching KDE Konsole for installation..."
                    konsole --noclose -e bash -c "yay -S --needed --noconfirm graphite-cursor-theme; echo 'Press Enter to close'; read"
                    return $?
                elif command_exists xterm; then
                    print_status "Launching xterm for installation..."
                    xterm -e "yay -S --needed --noconfirm graphite-cursor-theme; echo 'Press Enter to close'; read"
                    return $?
                else
                    print_error "No suitable terminal emulator found for interactive installation."
                    print_status "Please run the command manually: yay -S graphite-cursor-theme"
                    return 1
                fi
            fi
        elif command_exists paru; then
            print_status "Installing from AUR with paru..."
            paru -S --needed --noconfirm graphite-cursor-theme
            return $?
        else
            print_error "No AUR helper found. Please install yay or paru first."
            return 1
        fi
        
    elif command_exists apt; then
        # Debian-based system
        print_status "Downloading and installing Graphite cursors manually..."
        
        # Create temporary directory
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || {
            print_error "Failed to create temporary directory"
            return 1
        }
        
        # Download latest release
        print_status "Downloading Graphite cursors..."
        if command_exists curl; then
            curl -LO "https://github.com/vinceliuice/Graphite-cursor-theme/archive/refs/heads/main.zip"
        elif command_exists wget; then
            wget "https://github.com/vinceliuice/Graphite-cursor-theme/archive/refs/heads/main.zip"
        else
            print_error "Neither curl nor wget found. Cannot download theme."
            return 1
        fi
        
        # Extract and install
        print_status "Extracting and installing..."
        
        # Install unzip if needed
        if ! command_exists unzip; then
            print_status "Installing unzip..."
            sudo apt-get update && sudo apt-get install -y unzip
        fi
        
        unzip -q main.zip
        cd Graphite-cursor-theme-main || {
            print_error "Failed to enter extracted directory"
            return 1
        }
        
        # Make install script executable and run it
        chmod +x install.sh
        ./install.sh
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$tmp_dir"
        
        print_success "Graphite cursor theme installed successfully!"
        return 0
        
    # Add other package managers as needed
    else
        print_error "Unsupported package manager. Installing manually..."
        
        # Fall back to manual installation
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir" || {
            print_error "Failed to create temporary directory"
            return 1
        }
        
        # Download latest release
        print_status "Downloading Graphite cursors..."
        if command_exists curl; then
            curl -LO "https://github.com/vinceliuice/Graphite-cursor-theme/archive/refs/heads/main.zip"
        elif command_exists wget; then
            wget "https://github.com/vinceliuice/Graphite-cursor-theme/archive/refs/heads/main.zip"
        else
            print_error "Neither curl nor wget found. Cannot download theme."
            return 1
        fi
        
        # Extract and install
        print_status "Extracting and installing..."
        
        # Install unzip if needed
        if ! command_exists unzip; then
            if command_exists apt; then
                sudo apt-get update && sudo apt-get install -y unzip
            elif command_exists dnf; then
                sudo dnf install -y unzip
            elif command_exists zypper; then
                sudo zypper install -y unzip
            else
                print_error "Cannot install unzip. Please install it manually."
                return 1
            fi
        fi
        
        unzip -q main.zip
        cd Graphite-cursor-theme-main || {
            print_error "Failed to enter extracted directory"
            return 1
        }
        
        # Make install script executable and run it
        chmod +x install.sh
        ./install.sh
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$tmp_dir"
        
        print_success "Graphite cursor theme installed successfully!"
        return 0
    fi
}

# Debug function to test banner width and alignment
debug_banner() {
    local message="${1:-Test Banner Message}"
    local width="${2:-60}"
    
    echo
    echo "Banner test with inner width $width"
    echo "Message: '$message'"
    echo "Message length (without colors): $(get_text_length "$message")"
    echo "Top/bottom row should be exactly $width chars wide, plus 2 border chars:"
    
    local inner_line=$(printf '─%.0s' $(seq 1 ${width}))
    echo -e "╭${inner_line}╮"
    echo -e "│$(center_text "${message}" ${width})│"
    echo -e "╰${inner_line}╯"
    echo "Actual width check: $(( $(get_text_length "${inner_line}") + 2 )) chars"
    echo
}

# Function to read package list from package-list.txt
get_packages_by_category() {
    local category="$1"
    local package_list_file="${PROJECT_ROOT:-$(dirname "$(dirname "$(realpath "$0")")")}/package-list.txt"
    
    if [ ! -f "$package_list_file" ]; then
        print_error "Package list file not found: $package_list_file"
        return 1
    fi
    
    # Extract packages matching the category
    local packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        # Check if line matches the category
        if [[ "$line" =~ ^\[${category}\][[:space:]]+([^[:space:]#]+) ]]; then
            packages+=("${BASH_REMATCH[1]}")
        fi
    done < "$package_list_file"
    
    # Check if any packages were found
    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages found for category: $category"
        return 1
    fi
    
    # Print the packages (for debugging) to stderr so it doesn't affect command substitution
    print_status "Found ${#packages[@]} packages for category: $category" >&2
    
    # Return just the package names without any status messages
    echo "${packages[@]}"
}

# Function to install packages by category
install_packages_by_category() {
    local category="$1"
    
    # Use a safer approach to capture the output of get_packages_by_category
    local package_output
    package_output=$(get_packages_by_category "$category")
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$package_output" ]; then
        print_warning "No packages to install for category: $category"
        return 1
    fi
    
    # Convert the output string to an array
    read -ra packages <<< "$package_output"
    
    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages to install for category: $category"
        return 1
    fi
    
    print_status "Installing packages for category: $category"
    print_status "Packages: ${packages[*]}"
    
    install_packages "${packages[@]}"
} 