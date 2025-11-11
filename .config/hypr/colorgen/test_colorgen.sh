#!/bin/bash

# Test script for colorgen fixes
# This script helps verify that the colorgen system handles errors properly

echo "=== Colorgen Error Handling Test ==="
echo

# Check if required tools are installed
echo "Checking dependencies..."
missing_deps=()

if ! command -v python3 >/dev/null 2>&1; then
    missing_deps+=("python3")
fi

if ! command -v matugen >/dev/null 2>&1; then
    missing_deps+=("matugen")
fi

if ! command -v jq >/dev/null 2>&1; then
    missing_deps+=("jq")
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "ERROR: Missing dependencies: ${missing_deps[*]}"
    echo "Please install them before running colorgen"
    exit 1
fi

echo "✓ All dependencies found"
echo

# Check Python modules
echo "Checking Python modules..."
python3 -c "import PIL, numpy, colorsys" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: Missing Python modules (PIL/Pillow, numpy)"
    echo "Install with: pip install Pillow numpy"
    exit 1
fi
echo "✓ Python modules OK"
echo

# Test with a sample wallpaper if provided
if [ -n "$1" ] && [ -f "$1" ]; then
    WALLPAPER="$1"
    echo "Testing with wallpaper: $WALLPAPER"
    echo
    
    # Create test directory
    TEST_DIR="/tmp/colorgen_test_$$"
    mkdir -p "$TEST_DIR"
    echo "Using test directory: $TEST_DIR"
    
    # Run Python colorgen
    echo "Running python_colorgen.py..."
    python3 python_colorgen.py "$WALLPAPER" --colorgen-dir "$TEST_DIR" --debug
    result=$?
    
    echo
    if [ $result -eq 0 ]; then
        echo "✓ Python colorgen succeeded"
        
        # Check output files
        echo
        echo "Checking output files..."
        
        files=("colors.json" "dark_colors.json" "light_colors.json" "colors.conf" "colors.css" "border_color.txt")
        all_ok=true
        
        for file in "${files[@]}"; do
            if [ -f "$TEST_DIR/$file" ]; then
                size=$(stat -c%s "$TEST_DIR/$file" 2>/dev/null || stat -f%z "$TEST_DIR/$file" 2>/dev/null)
                echo "  ✓ $file ($size bytes)"
                
                # Validate JSON files
                if [[ "$file" == *.json ]]; then
                    if jq empty "$TEST_DIR/$file" 2>/dev/null; then
                        # Check for null values in critical fields
                        if [ "$file" = "dark_colors.json" ]; then
                            primary=$(jq -r '.primary' "$TEST_DIR/$file")
                            if [ "$primary" = "null" ] || [ -z "$primary" ]; then
                                echo "    ✗ WARNING: primary color is null or empty"
                                all_ok=false
                            else
                                echo "    ✓ primary color: $primary"
                            fi
                        fi
                    else
                        echo "    ✗ ERROR: Invalid JSON"
                        all_ok=false
                    fi
                fi
            else
                echo "  ✗ $file - MISSING"
                all_ok=false
            fi
        done
        
        echo
        if [ "$all_ok" = true ]; then
            echo "✓ All tests passed!"
            echo
            echo "Generated files are in: $TEST_DIR"
            echo "You can inspect them or remove the directory when done."
        else
            echo "✗ Some tests failed - check output above"
            exit 1
        fi
    else
        echo "✗ Python colorgen failed with exit code: $result"
        echo
        echo "Check the error messages above for details."
        exit 1
    fi
else
    echo "Usage: $0 <wallpaper_image>"
    echo
    echo "Example: $0 ~/Pictures/wallpaper.jpg"
    echo
    echo "This will test the colorgen system with the provided wallpaper"
    echo "and create output files in /tmp/colorgen_test_*/"
fi
