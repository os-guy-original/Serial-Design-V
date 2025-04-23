#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                   Color Definitions                      │
# ╰──────────────────────────────────────────────────────────╯

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Text Formatting                                         ┃
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

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Colors                                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Bright Colors                                          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_PURPLE='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Background Colors                                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Common Functions                                       ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Print a section header
print_section() {
    echo -e "\n${BRIGHT_BLUE}${BOLD}⟪ $1 ⟫${RESET}"
    echo -e "${BRIGHT_BLACK}${DIM}$(printf '─%.0s' {1..60})${RESET}"
}

# Print a status message
print_status() {
    echo -e "${YELLOW}${BOLD}ℹ ${RESET}${YELLOW}$1${RESET}"
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