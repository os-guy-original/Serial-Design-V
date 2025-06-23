#!/bin/bash

# Test script for swww_manager.sh
# This script tests the various functions in the swww manager

# Source the centralized swww manager
source "$HOME/.config/hypr/scripts/ui/swww_manager.sh"

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $message"
    else
        echo -e "${RED}[FAILED]${NC} $message"
    fi
}

# Function to run a test
run_test() {
    local test_name=$1
    local test_cmd=$2
    
    echo -e "${YELLOW}Running test:${NC} $test_name"
    eval "$test_cmd"
    print_status $? "$test_name"
    echo ""
}

# Test 1: Initialize swww
run_test "Initialize swww" "initialize_swww"

# Test 2: Ensure swww is running
run_test "Ensure swww is running" "ensure_swww_running"

# Test 3: Set wallpaper
if [ -f "$DEFAULT_BG" ]; then
    run_test "Set wallpaper" "set_wallpaper \"$DEFAULT_BG\""
else
    echo -e "${RED}[SKIPPED]${NC} Set wallpaper - Default background not found"
fi

# Test 4: Change wallpaper with transition
if [ -f "$DEFAULT_BG" ]; then
    run_test "Change wallpaper with transition" "change_wallpaper_with_transition \"$DEFAULT_BG\" \"wipe\""
else
    echo -e "${RED}[SKIPPED]${NC} Change wallpaper with transition - Default background not found"
fi

# Test 5: Fix swww
run_test "Fix swww" "fix_swww_doesnt_work"

echo -e "${YELLOW}All tests completed${NC}"
exit 0 