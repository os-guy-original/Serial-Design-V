#!/bin/bash

# ╭──────────────────────────────────────────────────────────╮
# │                Evolve-Core Installer                      │
# │          GTK Theme Manager Utility for GNU/Linux          │
# ╰──────────────────────────────────────────────────────────╯

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Check if AUR_HELPER is set (debug only)
print_status "Using AUR helper: ${AUR_HELPER:-pacman}"

print_banner "Evolve-Core Installer" "GTK Theme Manager Utility Installation"

#==================================================================
# Check Dependencies
#==================================================================
print_section "1. Checking Dependencies"
print_info "Verifying required tools for download and extraction"

MISSING_DEPS=()

# Check for curl or wget
if ! command_exists curl && ! command_exists wget; then
    MISSING_DEPS+=("curl or wget")
fi

# Check for unzip
if ! command_exists unzip; then
    MISSING_DEPS+=("unzip")
fi

# Check for jq (to parse GitHub API response)
if ! command_exists jq; then
    MISSING_DEPS+=("jq")
fi

# If any dependencies are missing, inform the user
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    print_warning "The following dependencies are required but missing:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo " - $dep"
    done
    
    # Install missing dependencies using the global AUR_HELPER variable
    print_status "Installing missing dependencies using ${AUR_HELPER:-pacman}..."
    install_packages curl unzip jq
    
    # Verify installation
    STILL_MISSING=()
    if ! command_exists curl && ! command_exists wget; then
        STILL_MISSING+=("curl or wget")
    fi
    if ! command_exists unzip; then
        STILL_MISSING+=("unzip")
    fi
    if ! command_exists jq; then
        STILL_MISSING+=("jq")
    fi
    
    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        print_error "Failed to install all required dependencies."
        print_status "Please install the following manually: ${STILL_MISSING[*]}"
        exit 1
    fi
fi

print_success "All required dependencies are installed."

#==================================================================
# Fetch Latest Release Info
#==================================================================
print_section "2. Checking for Latest Evolve-Core Version"
print_info "Fetching latest release information from GitHub"

GITHUB_API_URL="https://api.github.com/repos/arcnations-united/evolve-core/releases/latest"
DOWNLOAD_DIR="$HOME/Desktop"

# Get latest release info
print_status "Querying GitHub API for latest release..."

if command_exists curl; then
    RELEASE_INFO=$(curl -s "$GITHUB_API_URL")
elif command_exists wget; then
    RELEASE_INFO=$(wget -q -O - "$GITHUB_API_URL")
fi

# Check if API call was successful
if [ -z "$RELEASE_INFO" ] || echo "$RELEASE_INFO" | grep -q "API rate limit exceeded"; then
    print_error "Failed to fetch release information from GitHub."
    print_status "This could be due to rate limiting or network issues."
    exit 1
fi

# Extract latest version tag and download URL using jq
VERSION=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url' | head -n 1)

# Fallback method if jq parsing fails
if [ -z "$VERSION" ] || [ "$VERSION" = "null" ] || [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    print_warning "Could not parse JSON response with jq. Trying fallback method..."
    
    # Fallback to grep/sed for extracting info
    VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name":"[^"]*' | sed 's/"tag_name":"//g')
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url":"[^"]*\.zip' | sed 's/"browser_download_url":"//g' | head -n 1)
    
    if [ -z "$VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
        print_error "Failed to extract version or download URL from GitHub API response."
        exit 1
    fi
fi

print_success "Latest Evolve-Core version: $VERSION"
print_status "Download URL: $DOWNLOAD_URL"

#==================================================================
# Download and Install
#==================================================================
print_section "3. Downloading and Installing Evolve-Core"
print_info "Downloading and extracting the latest version"

# Create destination directory
INSTALL_DIR="$DOWNLOAD_DIR/Evolve-Core"
mkdir -p "$INSTALL_DIR"

# Download the zip file
TEMP_ZIP="/tmp/evolve-core-$VERSION.zip"
print_status "Downloading Evolve-Core $VERSION..."

if command_exists curl; then
    curl -L -o "$TEMP_ZIP" "$DOWNLOAD_URL"
    DOWNLOAD_SUCCESS=$?
elif command_exists wget; then
    wget -O "$TEMP_ZIP" "$DOWNLOAD_URL"
    DOWNLOAD_SUCCESS=$?
fi

if [ $DOWNLOAD_SUCCESS -ne 0 ]; then
    print_error "Failed to download Evolve-Core."
    exit 1
fi

print_success "Download completed successfully."

# Extract the zip file
print_status "Extracting files to $INSTALL_DIR..."
unzip -q -o "$TEMP_ZIP" -d "$INSTALL_DIR"
EXTRACT_SUCCESS=$?

if [ $EXTRACT_SUCCESS -ne 0 ]; then
    print_error "Failed to extract Evolve-Core."
    rm -f "$TEMP_ZIP"
    exit 1
fi

# Clean up
rm -f "$TEMP_ZIP"

# Find the AppImage file
APPIMAGE_FILE=$(find "$INSTALL_DIR" -name "*.AppImage" -type f | head -n 1)

if [ -z "$APPIMAGE_FILE" ]; then
    print_warning "Could not find AppImage file in the extracted package."
    print_status "You may need to manually run the application from $INSTALL_DIR"
else
    # Make the AppImage executable
    chmod +x "$APPIMAGE_FILE"
    print_success "Made AppImage executable: $(basename "$APPIMAGE_FILE")"
fi

#==================================================================
# Create Desktop Entry
#==================================================================
print_section "4. Finalizing Installation"
print_info "Completing the Evolve-Core setup"

if [ -n "$APPIMAGE_FILE" ]; then
    # Make sure the AppImage is executable
    chmod +x "$APPIMAGE_FILE"
    print_success "Made AppImage executable: $(basename "$APPIMAGE_FILE")"
fi

#==================================================================
# Completion
#==================================================================
print_section "Installation Complete"

print_success_banner "Evolve-Core has been successfully installed!"

echo -e "${BRIGHT_WHITE}${BOLD}Details:${RESET}"
echo -e "  ${BRIGHT_WHITE}•${RESET} Evolve-Core version: ${BRIGHT_CYAN}$VERSION${RESET}"
echo -e "  ${BRIGHT_WHITE}•${RESET} Installed to: ${BRIGHT_CYAN}$INSTALL_DIR${RESET}"

if [ -n "$APPIMAGE_FILE" ]; then
    echo -e "  ${BRIGHT_WHITE}•${RESET} AppImage: ${BRIGHT_CYAN}$(basename "$APPIMAGE_FILE")${RESET}"
    echo -e "  ${BRIGHT_WHITE}•${RESET} You can run Evolve-Core by executing:"
    echo -e "    ${BRIGHT_CYAN}\"$APPIMAGE_FILE\"${RESET}"
fi

echo
echo -e "${BRIGHT_WHITE}${BOLD}If you encounter issues applying themes:${RESET}"
echo -e "  You can use Evolve-Core from your Desktop to manage and apply themes."
echo -e "  This tool provides a user-friendly GUI for theme management."

exit 0 