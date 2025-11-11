#!/usr/bin/env bash
# Check and optionally update /usr/share/xdg-desktop-portal/hyprland-portals.conf
# This script follows the project's script style and uses the repository's common functions

set -euo pipefail

# Resolve script dir and source common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_FUNCS="$REPO_ROOT/../scripts/utils/common_functions.sh"

if [ -f "$COMMON_FUNCS" ]; then
    # shellcheck source=/dev/null
    source "$COMMON_FUNCS"
else
    # Minimal fallbacks to avoid breaking when common_functions isn't available
    ask_yes_no() {
        local prompt="$1"
        local default="${2:-n}"
        read -r -p "$prompt [y/N]: " ans || return 1
        case "${ans:-$default}" in
            [Yy]*) return 0 ;;
            *) return 1 ;;
        esac
    }
    print_section() { printf "\n== %s ==\n" "$1"; }
    print_status() { printf "[..] %s\n" "$1"; }
    print_info() { printf "[i] %s\n" "$1"; }
    print_warning() { printf "[!] %s\n" "$1"; }
    print_error() { printf "[x] %s\n" "$1"; }
    print_success() { printf "[✓] %s\n" "$1"; }
fi

FILE="/usr/share/xdg-desktop-portal/hyprland-portals.conf"

print_section "Hyprland Portal Config Check"
print_info "Inspecting: $FILE"

if [ ! -f "$FILE" ]; then
    print_warning "File not found: $FILE"
    print_info "Skipping hyprland portal config check."
    exit 0
fi

# Always print file contents first as requested
print_status "Current contents of $FILE:"
echo "----------------------------------------"
if ! cat "$FILE"; then
    print_error "Unable to display $FILE"
    exit 1
fi
echo
echo "----------------------------------------"

# Extract the first matching default= line (if any)
DEFAULT_LINE="$(grep -m1 -E '^[[:space:]]*default=' "$FILE" || true)"

if [ -z "$DEFAULT_LINE" ]; then
    print_info "No 'default=' entry found in $FILE. No changes necessary."
    exit 0
fi

print_info "Detected: $DEFAULT_LINE"

if echo "$DEFAULT_LINE" | grep -qi 'hyprland'; then
    print_warning "The 'default=' entry references 'hyprland'. Changing this can alter portal behavior for applications."
    print_warning "Potential issues: some GTK or portal-using apps may lose expected behavior until you restart your session or portal services."

    if ask_yes_no "Would you like to change the 'default=' value to only 'kde' now? (a sudo backup will be made)" "n"; then
        TIMESTAMP="$(date +%Y%m%d%H%M%S)"
        BACKUP="${FILE}.bak-${TIMESTAMP}"

        print_status "Creating backup: $BACKUP"
        if ! sudo cp -- "$FILE" "$BACKUP"; then
            print_error "Failed to create backup: $BACKUP"
            exit 1
        fi

        print_status "Updating 'default=' line to 'default=kde' in $FILE"
        # Use sed to replace the default= line. Write to a temp file and move into place as root.
        TMPFILE="/tmp/$(basename "$FILE").tmp.$TIMESTAMP"
        if ! sed -E 's/^[[:space:]]*default=.*/default=kde/' "$FILE" > "$TMPFILE"; then
            print_error "Failed to write temporary file: $TMPFILE"
            exit 1
        fi

        if ! sudo mv "$TMPFILE" "$FILE"; then
            print_error "Failed to move $TMPFILE to $FILE"
            print_info "You can restore the backup with: sudo cp '$BACKUP' '$FILE'"
            exit 1
        fi

        print_success "Updated $FILE (backup at $BACKUP)."
        print_info "You may need to restart your session or restart xdg-desktop-portal services for changes to take effect."
        print_info "Suggested commands to run after logout/login or when appropriate:"
        printf "  systemctl --user restart xdg-desktop-portal || true\n"
        printf "  systemctl --user restart xdg-desktop-portal-hyprland || true\n"
    else
        print_status "User declined to modify $FILE. No changes made."
    fi
else
    print_info "The 'default=' line is currently set to 'kde' or does not reference 'hyprland'."
    
    if echo "$DEFAULT_LINE" | grep -qi 'kde'; then
        print_warning "Reverting to 'hyprland;gtk;' may cause issues with some applications."
        print_warning "This is typically only needed if you're experiencing problems with the current 'kde' setting."
        
        if ask_yes_no "Would you like to revert the 'default=' value back to 'hyprland;gtk;'? (a sudo backup will be made)" "n"; then
            TIMESTAMP="$(date +%Y%m%d%H%M%S)"
            BACKUP="${FILE}.bak-${TIMESTAMP}"

            print_status "Creating backup: $BACKUP"
            if ! sudo cp -- "$FILE" "$BACKUP"; then
                print_error "Failed to create backup: $BACKUP"
                exit 1
            fi

            print_status "Updating 'default=' line to 'default=hyprland;gtk;' in $FILE"
            TMPFILE="/tmp/$(basename "$FILE").tmp.$TIMESTAMP"
            if ! sed -E 's/^[[:space:]]*default=.*/default=hyprland;gtk;/' "$FILE" > "$TMPFILE"; then
                print_error "Failed to write temporary file: $TMPFILE"
                exit 1
            fi

            if ! sudo mv "$TMPFILE" "$FILE"; then
                print_error "Failed to move $TMPFILE to $FILE"
                print_info "You can restore the backup with: sudo cp '$BACKUP' '$FILE'"
                exit 1
            fi

            print_success "Reverted $FILE to 'hyprland;gtk;' (backup at $BACKUP)."
            print_info "You may need to restart your session or restart xdg-desktop-portal services for changes to take effect."
            print_info "Suggested commands to run after logout/login or when appropriate:"
            printf "  systemctl --user restart xdg-desktop-portal || true\n"
            printf "  systemctl --user restart xdg-desktop-portal-hyprland || true\n"
        else
            print_status "User declined to revert $FILE. No changes made."
        fi
    else
        print_info "No action required."
    fi
fi

exit 0
