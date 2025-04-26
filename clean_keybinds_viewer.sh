#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │         Hyprland Keybinds Viewer Debug Cleaner           │
# │          Removes all keybinds viewer artifacts           │
# ╰──────────────────────────────────────────────────────────╯

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Helper functions for printing messages
print_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

print_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    print_warning "This script needs to be run as root to remove files from /usr/bin"
    print_info "Rerunning with sudo..."
    exec sudo "$0" "$@"
    exit $?
fi

# Display banner
echo -e "${CYAN}${BOLD}"
echo "┌───────────────────────────────────────────────┐"
echo "│         KEYBINDS VIEWER DEBUG CLEANER         │"
echo "└───────────────────────────────────────────────┘"
echo -e "${RESET}"

print_info "Starting cleanup process..."

# 1. Remove binary from /usr/bin
if [ -f "/usr/bin/hyprland-keybinds" ]; then
    print_info "Removing hyprland-keybinds binary from /usr/bin..."
    rm -f /usr/bin/hyprland-keybinds
    if [ $? -eq 0 ]; then
        print_success "Binary removed successfully"
    else
        print_error "Failed to remove binary"
    fi
else
    print_warning "Binary not found in /usr/bin"
fi

# 2. Clean Rust project directories
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)/show_keybinds"

if [ -d "$PROJECT_DIR" ]; then
    print_info "Cleaning Rust project build artifacts..."
    
    # Clean cargo build artifacts if cargo is available
    if command -v cargo &>/dev/null; then
        (cd "$PROJECT_DIR" && cargo clean)
        print_success "Cargo build artifacts cleaned"
    else
        print_warning "Cargo not found, removing target directory manually"
        rm -rf "${PROJECT_DIR}/target"
    fi
    
    # Remove Cargo.lock if requested
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Remove Cargo.lock file? [y/N]: ${RESET}"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        rm -f "${PROJECT_DIR}/Cargo.lock"
        print_success "Cargo.lock removed"
    fi
else
    print_warning "Rust project directory not found at $PROJECT_DIR"
fi

# 3. Check for any leftover processes
PROCESS_COUNT=$(ps aux | grep -i "hyprland-keybinds" | grep -v grep | grep -v "clean_keybinds_viewer.sh" | wc -l)
if [ "$PROCESS_COUNT" -gt 0 ]; then
    print_warning "Found $PROCESS_COUNT running processes related to hyprland-keybinds"
    echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Kill these processes? [y/N]: ${RESET}"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        pkill -f "hyprland-keybinds"
        print_success "Processes terminated"
    fi
else
    print_success "No running processes found"
fi

# 4. Remove GTK cache files that might be related
echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Clean GTK cache files (may affect other GTK apps)? [y/N]: ${RESET}"
read -r response
if [[ "$response" =~ ^[Yy] ]]; then
    print_info "Removing GTK cache files..."
    rm -rf ~/.cache/gtk-4.0
    print_success "GTK cache cleaned"
fi

# 5. Check keybinding in Hyprland config
KEYBIND_CONFIG="$HOME/.config/hypr/configs/keybinds.conf"
if [ -f "$KEYBIND_CONFIG" ]; then
    if grep -q "hyprland-keybinds" "$KEYBIND_CONFIG"; then
        print_warning "Found keybinding in $KEYBIND_CONFIG"
        echo -e -n "${CYAN}${BOLD}? ${RESET}${CYAN}Remove keybinding from config? [y/N]: ${RESET}"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            # Create backup
            cp "$KEYBIND_CONFIG" "$KEYBIND_CONFIG.bak"
            # Remove the line with hyprland-keybinds
            sed -i '/hyprland-keybinds/d' "$KEYBIND_CONFIG"
            print_success "Keybinding removed (backup created at $KEYBIND_CONFIG.bak)"
        fi
    else
        print_success "No keybinding found in Hyprland config"
    fi
else
    print_warning "Hyprland keybinds config not found at $KEYBIND_CONFIG"
fi

# Summary
echo
print_success "========== CLEANUP COMPLETE =========="
echo "The following actions were performed:"
echo " - Removed binary from /usr/bin (if present)"
echo " - Cleaned Rust project build artifacts"
echo " - Checked for and optionally killed related processes"
echo " - Optionally cleaned GTK cache files"
echo " - Optionally removed keybinding from Hyprland config"
echo

# Final message
print_info "If you want to completely remove the project code, you can also delete:"
print_info "  rm -rf ${PROJECT_DIR}"
print_info "  rm -f $(realpath "$0")"

exit 0 