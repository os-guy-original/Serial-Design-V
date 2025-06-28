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
    if [[ "$output" =~ "error: failed to prepare transaction" ]] || [[ "$output" =~ "conflicting files" ]] || [[ "$output" =~ "are in conflict" ]]; then
        # Try to extract the conflicting packages
        while read -r line; do
            # Match patterns like "package1 and package2 are in conflict"
            if [[ "$line" =~ ([a-zA-Z0-9_\.\:-]+)[[:space:]]+(and|conflicts with)[[:space:]]+([a-zA-Z0-9_\.\:-]+)[[:space:]]+(are in conflict|conflicts) ]]; then
                conflicts+=("${BASH_REMATCH[1]}")
                conflicts+=("${BASH_REMATCH[3]}")
            fi
            
            # Match patterns like "package1-git conflicts with package1"
            if [[ "$line" =~ ([a-zA-Z0-9_\.\:-]+)[[:space:]]+conflicts[[:space:]]+with[[:space:]]+([a-zA-Z0-9_\.\:-]+) ]]; then
                conflicts+=("${BASH_REMATCH[1]}")
                conflicts+=("${BASH_REMATCH[2]}")
            fi
            
            # Match patterns like ":: rust-1:1.87.0-2 and rustup-1.28.2-2 are in conflict"
            if [[ "$line" =~ ::[[:space:]]+([a-zA-Z0-9_\.\:-]+)[[:space:]]+and[[:space:]]+([a-zA-Z0-9_\.\:-]+)[[:space:]]+are[[:space:]]+in[[:space:]]+conflict ]]; then
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
    
    # Extract base package names from version-specific packages
    local base_conflicts=()
    for pkg in "${conflicts[@]}"; do
        # Extract the base package name (before any version or epoch info)
        local base_pkg
        # Match patterns like "rust-1:1.87.0-2" -> "rust"
        if [[ "$pkg" =~ ^([a-zA-Z0-9_-]+)-[0-9]+: ]]; then
            base_pkg="${BASH_REMATCH[1]}"
        # Match patterns like "rustup-1.28.2-2" -> "rustup"
        elif [[ "$pkg" =~ ^([a-zA-Z0-9_-]+)-[0-9]+\. ]]; then
            base_pkg="${BASH_REMATCH[1]}"
        # Match patterns like "package-git" -> "package-git"
        else
            base_pkg="$pkg"
        fi
        base_conflicts+=("$base_pkg")
    done
    
    print_warning "Package conflicts detected:"
    for i in "${!conflicts[@]}"; do
        echo -e "  ${YELLOW}•${RESET} ${conflicts[$i]} (base: ${base_conflicts[$i]})"
    done
    
    echo
    echo -e "${BRIGHT_WHITE}${BOLD}Options:${RESET}"
    echo -e "  ${BRIGHT_CYAN}1.${RESET} ${BRIGHT_WHITE}Remove conflicting packages${RESET} - Remove the conflicting packages and continue"
    echo -e "  ${BRIGHT_CYAN}2.${RESET} ${BRIGHT_WHITE}Force remove conflicting packages${RESET} - Remove with --nodeps flag (may break dependencies)"
    echo -e "  ${BRIGHT_CYAN}3.${RESET} ${BRIGHT_WHITE}Skip conflicting packages${RESET} - Continue installation without the conflicting packages"
    echo -e "  ${BRIGHT_CYAN}4.${RESET} ${BRIGHT_WHITE}Retry without changes${RESET} - Try the installation again without changes"
    echo -e "  ${BRIGHT_CYAN}5.${RESET} ${BRIGHT_WHITE}Cancel installation${RESET} - Abort the installation process"
    
    echo
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Choose an option (1-5): ${RESET}"
    read -r choice
    
    case "$choice" in
        1)
            print_status "Removing conflicting packages..."
            # Use base package names for removal
            local removal_success=true
            local removal_output=""
            
            if [ "$AUR_HELPER" = "pacman" ]; then
                for pkg in "${base_conflicts[@]}"; do
                    print_status "Attempting to remove package: $pkg"
                    removal_output=$(sudo pacman -R --noconfirm "$pkg" 2>&1) || removal_success=false
                    
                    # Check if removal failed due to dependencies
                    if [[ "$removal_output" =~ "breaks dependency" ]]; then
                        echo -e "${RED}Error: Removing $pkg would break dependencies:${RESET}"
                        echo "$removal_output" | grep "breaks dependency"
                        echo
                        
                        if ask_yes_no "Would you like to force remove this package (may break system)?" "n"; then
                            print_warning "Force removing package: $pkg"
                            sudo pacman -Rdd --noconfirm "$pkg" || true
                        else
                            print_warning "Skipping removal of $pkg"
                        fi
                    elif [ "$removal_success" = false ]; then
                        echo -e "${RED}Failed to remove $pkg:${RESET}"
                        echo "$removal_output"
                    fi
                done
            else
                for pkg in "${base_conflicts[@]}"; do
                    print_status "Attempting to remove package: $pkg"
                    removal_output=$($AUR_HELPER -R --noconfirm "$pkg" 2>&1) || removal_success=false
                    
                    # Check if removal failed due to dependencies
                    if [[ "$removal_output" =~ "breaks dependency" ]]; then
                        echo -e "${RED}Error: Removing $pkg would break dependencies:${RESET}"
                        echo "$removal_output" | grep "breaks dependency"
                        echo
                        
                        if ask_yes_no "Would you like to force remove this package (may break system)?" "n"; then
                            print_warning "Force removing package: $pkg"
                            $AUR_HELPER -Rdd --noconfirm "$pkg" || true
                        else
                            print_warning "Skipping removal of $pkg"
                        fi
                    elif [ "$removal_success" = false ]; then
                        echo -e "${RED}Failed to remove $pkg:${RESET}"
                        echo "$removal_output"
                    fi
                done
            fi
            return 0  # Continue with installation
            ;;
        2)
            print_status "Force removing conflicting packages (ignoring dependencies)..."
            if [ "$AUR_HELPER" = "pacman" ]; then
                for pkg in "${base_conflicts[@]}"; do
                    print_status "Force removing package: $pkg"
                    sudo pacman -Rdd --noconfirm "$pkg" || true
                done
            else
                for pkg in "${base_conflicts[@]}"; do
                    print_status "Force removing package: $pkg"
                    $AUR_HELPER -Rdd --noconfirm "$pkg" || true
                done
            fi
            return 0  # Continue with installation
            ;;
        3)
            print_status "Skipping conflicting packages..."
            echo "${conflicts[@]}"
            return 2  # Skip conflicting packages
            ;;
        4)
            print_status "Retrying installation without changes..."
            return 0  # Retry without changes
            ;;
        5)
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
    
    # Display a concise message about the packages to be installed
    print_status "Installing ${#packages[@]} packages with $AUR_HELPER (--needed flag will skip installed packages)"
    
    while [ $retry_count -lt $max_retries ]; do
        # Create a temporary file to capture output
        local temp_output_file=$(mktemp)
        local exit_status=0
        
        case "$AUR_HELPER" in
            "yay")
                # Run the command and tee output to both terminal and file
                set -o pipefail  # Make sure pipe failures are captured
                yay -Sy --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
                exit_status=$?
                set +o pipefail
                ;;
            "paru")
                set -o pipefail
                paru -Sy --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
                exit_status=$?
                set +o pipefail
                ;;
            "pacman")
                set -o pipefail
                sudo pacman -Sy --needed --noconfirm "${packages[@]}" 2>&1 | tee "$temp_output_file"
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

# Function to setup theme files with system-specific handling
setup_theme() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "Theme setup should now be handled directly in install.sh"
    return 1
}

# Function to setup configuration files
setup_configuration() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "Configuration setup should now be handled directly in install.sh"
    return 1
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
    else
        print_status "Skipping GTK theme installation. You can run it later with: ./scripts/install-gtk-theme.sh"
        GTK_THEME_SKIPPED=true
    fi
    
    # Export the GTK theme skip status
    export GTK_THEME_SKIPPED
}

# Function to offer QT theme installation for flatpak apps
offer_qt_theme_install() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "QT theme installation should now be handled directly in install.sh"
    return 1
}

# Function to offer cursor installation
offer_cursor_install() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "Cursor installation should now be handled directly in install.sh"
    return 1
}

# Function to offer icon theme installation
offer_icon_theme_install() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "Icon theme installation should now be handled directly in install.sh"
    return 1
}

# Function to offer Flatpak installation
offer_flatpak_install() {
    # This function has been moved directly to install.sh for better organization
    print_status "DEPRECATED: This function has been moved to install.sh"
    print_warning "Flatpak installation should now be handled directly in install.sh"
    return 1
}

# Function to automatically set up themes - Function removed as it's now handled by individual scripts
auto_setup_themes() {
    print_status "This function is deprecated. Theme setup is now handled by individual theme scripts."
    print_status "Please use the specific theme installation scripts in the scripts directory."
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

# Function to install cursor theme - DEPRECATED
# This function has been replaced by direct handling in install.sh
# and the install-cursors.sh script
install_cursor_theme() {
    print_status "DEPRECATED: Cursor theme installation is now handled by install-cursors.sh"
    print_warning "This function is only kept for backward compatibility"
    
    # For backward compatibility, try using the script directly
    local CURSOR_SCRIPT="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/scripts/install-cursors.sh"
    
    if [ -f "$CURSOR_SCRIPT" ]; then
        if [ ! -x "$CURSOR_SCRIPT" ]; then
            chmod +x "$CURSOR_SCRIPT"
        fi
        
        print_status "Running cursor installer: $CURSOR_SCRIPT"
        "$CURSOR_SCRIPT"
        return $?
    else
        print_error "Cursor installer script not found"
        return 1
    fi
}

# Debug function to test banner width and alignment
# This is only used during development and not part of the main installation flow
debug_banner() {
    print_warning "This is a development/debug function and not meant for regular use"
    return 0
}

# Function to read package list from package-list.txt
get_packages_by_category() {
    local category="$1"
    local subcategory="$2"  # Optional subcategory parameter
    
    # Try to find the package list file in various locations
    local package_list_file=""
    for path in \
        "${PROJECT_ROOT:-$(dirname "$(dirname "$(realpath "$0")")")}/package-list.txt" \
        "$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")/package-list.txt" \
        "$(dirname "$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")")/package-list.txt" \
        "./package-list.txt" \
        "../package-list.txt"
    do
        if [ -f "$path" ]; then
            package_list_file="$path"
            break
        fi
    done
    
    if [ ! -f "$package_list_file" ]; then
        print_error "Package list file not found. Tried multiple locations."
        print_error "Please ensure package-list.txt exists in the project root directory."
        return 1
    fi
    
    # Debug output to show which file is being used
    print_status "Using package list file: $package_list_file" >&2
    
    # Extract packages matching the category/subcategory
    local packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        
        if [ -n "$subcategory" ]; then
            # Look for packages with specific subcategory
            if [[ "$line" =~ ^\[${category}[[:space:]]*\|[[:space:]]*${subcategory}\][[:space:]]+([^[:space:]#]+) ]]; then
                packages+=("${BASH_REMATCH[1]}")
            fi
        else
            # If no subcategory specified, match both direct category and any subcategory
        if [[ "$line" =~ ^\[${category}\][[:space:]]+([^[:space:]#]+) ]]; then
                # Direct category match
                packages+=("${BASH_REMATCH[1]}")
            elif [[ "$line" =~ ^\[${category}[[:space:]]*\|[[:space:]]*[^]]+\][[:space:]]+([^[:space:]#]+) ]]; then
                # Any subcategory match
            packages+=("${BASH_REMATCH[1]}")
            fi
        fi
    done < "$package_list_file"
    
    # Check if any packages were found
    if [ ${#packages[@]} -eq 0 ]; then
        if [ -n "$subcategory" ]; then
            print_warning "No packages found for category: $category, subcategory: $subcategory"
        else
        print_warning "No packages found for category: $category"
        fi
        return 1
    fi
    
    # Print the packages (for debugging) to stderr so it doesn't affect command substitution
    if [ -n "$subcategory" ]; then
        print_status "Found ${#packages[@]} packages for category: $category, subcategory: $subcategory" >&2
    else
    print_status "Found ${#packages[@]} packages for category: $category" >&2
    fi
    
    # Return just the package names without any status messages
    echo "${packages[@]}"
}

# Function to install packages by category
install_packages_by_category() {
    local category="$1"
    local verbose="${2:-false}"  # Optional parameter to control verbosity
    local subcategory="$3"       # Optional subcategory parameter
    
    # Use a safer approach to capture the output of get_packages_by_category
    local package_output
    package_output=$(get_packages_by_category "$category" "$subcategory")
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$package_output" ]; then
        if [ -n "$subcategory" ]; then
            print_warning "No packages to install for category: $category, subcategory: $subcategory"
        else
        print_warning "No packages to install for category: $category"
        fi
        return 1
    fi
    
    # Convert the output string to an array
    read -ra packages <<< "$package_output"
    
    if [ ${#packages[@]} -eq 0 ]; then
        if [ -n "$subcategory" ]; then
            print_warning "No packages to install for category: $category, subcategory: $subcategory"
        else
        print_warning "No packages to install for category: $category"
        fi
        return 1
    fi
    
    if [ -n "$subcategory" ]; then
        print_status "Installing ${#packages[@]} packages for category: $category, subcategory: $subcategory"
    else
        print_status "Installing ${#packages[@]} packages for category: $category"
    fi
    
    # Only show package list in verbose mode or if there are few packages
    if [ "$verbose" = "true" ] || [ ${#packages[@]} -lt 6 ]; then
        print_info "Packages: ${packages[*]}"
    fi
    
    install_packages "${packages[@]}"
}

# Function to find, make executable, and execute a script
# Usage: find_and_execute_script <script_name> [--sudo] [--silent] [arg1 arg2 ...]
find_and_execute_script() {
    local script_name="$1"
    shift  # Remove the script name from the arguments list
    
    # Initialize flags
    local use_sudo=false
    local silent=false
    
    # Process flags
    while [[ $# -gt 0 && "$1" == "--"* ]]; do
        case "$1" in
            --sudo)
                use_sudo=true
                shift
                ;;
            --silent)
                silent=true
                shift
                ;;
            *)
                # Unknown flag, move on
                shift
                ;;
        esac
    done
    
    # Remaining arguments are script arguments
    local script_args=("$@")
    
    # Get the script directory
    local scripts_dir="$(dirname "$0")"
    if [[ "$(basename "$(pwd)")" == "scripts" ]]; then
        scripts_dir="."
    elif [[ -d "./scripts" ]]; then
        scripts_dir="./scripts"
    elif [[ -d "../scripts" ]]; then
        scripts_dir="../scripts"
    fi
    
    # Try to find the script in various locations
    local script_path=""
    for path in \
        "${scripts_dir}/${script_name}" \
        "$(dirname "${scripts_dir}")/${script_name}" \
        "${scripts_dir}/$(basename "${script_name}")" \
        "./scripts/${script_name}" \
        "../scripts/${script_name}" \
        "./${script_name}" \
        "../${script_name}"
    do
        if [[ -f "${path}" ]]; then
            script_path="${path}"
            break
        fi
    done
    
    # If script wasn't found, try once more with script directory detection
    if [[ -z "${script_path}" ]]; then
        local detected_scripts_dir=$(get_script_path "${script_name}")
        if [[ -f "${detected_scripts_dir}" ]]; then
            script_path="${detected_scripts_dir}"
        fi
    fi
    
    # Check if we found the script
    if [[ -z "${script_path}" ]]; then
        print_error "Script not found: ${script_name}"
        print_error "Looked in: ${scripts_dir}, ./scripts, ../scripts, current and parent directories"
        return 1
    fi
    
    # Make the script executable if needed
    if [[ ! -x "${script_path}" ]]; then
        if ! $silent; then
            print_status "Making script executable: ${script_path}"
        fi
        chmod +x "${script_path}"
    fi
    
    # Execute the script, with or without sudo
    if ! $silent; then
        print_status "Running script: ${script_path}"
    fi
    
    if $use_sudo; then
        if $silent; then
            run_with_sudo "${script_path}" "${script_args[@]}" > /dev/null 2>&1
        else
            run_with_sudo "${script_path}" "${script_args[@]}"
        fi
    else
        if $silent; then
            "${script_path}" "${script_args[@]}" > /dev/null 2>&1
        else
            "${script_path}" "${script_args[@]}"
        fi
    fi
    
    return $?
} 