#!/bin/bash

# ============================================================================
# Light Theme VSCode Script for Hyprland Colorgen
# 
# This script applies Material You light theme colors to VSCode settings
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
VSCODE_SETTINGS="$XDG_CONFIG_HOME/Code/User/settings.json"
LIGHT_COLORS_JSON="$COLORGEN_DIR/light_colors.json"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying Material You light theme colors to VSCode"

# Check if files exist
if [ ! -f "$LIGHT_COLORS_JSON" ]; then
    log "ERROR" "Material You light colors not found. Run material_extract.sh first."
    exit 1
fi

if [ ! -f "$VSCODE_SETTINGS" ]; then
    log "WARNING" "VSCode settings.json not found. Creating a new one."
    mkdir -p "$(dirname "$VSCODE_SETTINGS")"
    echo "{}" > "$VSCODE_SETTINGS"
fi

# Create backup once if it doesn't exist
VSCODE_BACKUP="$XDG_CONFIG_HOME/Code/User/backups/settings.json.original"
if [ ! -f "$VSCODE_BACKUP" ] && [ -f "$VSCODE_SETTINGS" ]; then
    mkdir -p "$XDG_CONFIG_HOME/Code/User/backups"
    cp "$VSCODE_SETTINGS" "$VSCODE_BACKUP" 2>/dev/null || true
    log "INFO" "Created backup of original VSCode settings"
fi

# Extract colors from the appropriate color file
log "INFO" "Extracting Material You light colors for VSCode..."

# Extract colors from JSON for Material You palette
# We use jq to parse the JSON and extract the colors
extract_color() {
    local color_name=$1
    local default_color=$2
    local color=$(jq -r ".$color_name" "$LIGHT_COLORS_JSON" 2>/dev/null)
    
    if [ -z "$color" ] || [ "$color" = "null" ]; then
        echo "$default_color"
    else
        echo "$color"
    fi
}

# Get required colors from Material You palette
background=$(extract_color "background" "#FFFBFE")
surface=$(extract_color "surface" "#FFFBFE")
surface_container=$(extract_color "surface_container" "#F3EDF7")
surface_container_low=$(extract_color "surface_container_low" "#F7F2FA")
surface_container_high=$(extract_color "surface_container_high" "#ECE6F0")
surface_container_highest=$(extract_color "surface_container_highest" "#E6E0E9")
surface_container_lowest=$(extract_color "surface_container_lowest" "#FFFFFF")
surface_bright=$(extract_color "surface_bright" "#FDF7FF")
surface_dim=$(extract_color "surface_dim" "#DED8E1")
surface_variant=$(extract_color "surface_variant" "#E7E0EC")
surface_tint=$(extract_color "surface_tint" "#6750A4")
on_surface=$(extract_color "on_surface" "#1C1B1F")
on_surface_variant=$(extract_color "on_surface_variant" "#49454F")
inverse_surface=$(extract_color "inverse_surface" "#313033")
inverse_on_surface=$(extract_color "inverse_on_surface" "#F4EFF4")
inverse_primary=$(extract_color "inverse_primary" "#D0BCFF")
primary=$(extract_color "primary" "#6750A4")
primary_container=$(extract_color "primary_container" "#EADDFF")
on_primary=$(extract_color "on_primary" "#FFFFFF")
on_primary_container=$(extract_color "on_primary_container" "#21005D")
primary_fixed=$(extract_color "primary_fixed" "#EADDFF")
primary_fixed_dim=$(extract_color "primary_fixed_dim" "#D0BCFF")
on_primary_fixed=$(extract_color "on_primary_fixed" "#21005D")
on_primary_fixed_variant=$(extract_color "on_primary_fixed_variant" "#4F378B")
secondary=$(extract_color "secondary" "#625B71")
secondary_container=$(extract_color "secondary_container" "#E8DEF8")
on_secondary=$(extract_color "on_secondary" "#FFFFFF")
on_secondary_container=$(extract_color "on_secondary_container" "#1D192B")
secondary_fixed=$(extract_color "secondary_fixed" "#E8DEF8")
secondary_fixed_dim=$(extract_color "secondary_fixed_dim" "#CCC2DC")
on_secondary_fixed=$(extract_color "on_secondary_fixed" "#1D192B")
on_secondary_fixed_variant=$(extract_color "on_secondary_fixed_variant" "#4A4458")
tertiary=$(extract_color "tertiary" "#7D5260")
tertiary_container=$(extract_color "tertiary_container" "#FFD8E4")
on_tertiary=$(extract_color "on_tertiary" "#FFFFFF")
on_tertiary_container=$(extract_color "on_tertiary_container" "#31111D")
tertiary_fixed=$(extract_color "tertiary_fixed" "#FFD8E4")
tertiary_fixed_dim=$(extract_color "tertiary_fixed_dim" "#EFB8C8")
on_tertiary_fixed=$(extract_color "on_tertiary_fixed" "#31111D")
on_tertiary_fixed_variant=$(extract_color "on_tertiary_fixed_variant" "#633B48")
error=$(extract_color "error" "#B3261E")
error_container=$(extract_color "error_container" "#F9DEDC")
on_error=$(extract_color "on_error" "#FFFFFF")
on_error_container=$(extract_color "on_error_container" "#410E0B")
outline=$(extract_color "outline" "#79747E")
outline_variant=$(extract_color "outline_variant" "#C4C7C5")
scrim=$(extract_color "scrim" "#000000")
shadow=$(extract_color "shadow" "#000000")

# Define darker, more saturated colors for better contrast in light mode
primary_dark=$(extract_color "on_primary_container" "#21005D")
secondary_dark=$(extract_color "on_secondary_container" "#1D192B")
tertiary_dark=$(extract_color "on_tertiary_container" "#31111D")

# Use these colors if they're too light
if [ "$primary" = "#6750A4" ] || [ "$primary" = "#884b6b" ]; then
    primary_dark="#4a2c82"  # Darker purple/magenta
fi
if [ "$secondary" = "#625B71" ] || [ "$secondary" = "#725763" ]; then
    secondary_dark="#4a3b57"  # Darker slate
fi
if [ "$tertiary" = "#7D5260" ] || [ "$tertiary" = "#7f543a" ]; then
    tertiary_dark="#5d3040"  # Darker burgundy/brown
fi

log "INFO" "Primary color: $primary"
log "INFO" "Background color: $background"
log "INFO" "Using darker accent colors for better contrast"

# Create VSCode color customizations JSON
VSCODE_COLORS=$(cat << EOF
{
  "editor.background": "${background}",
  "editor.foreground": "${on_surface}",
  "editorLineNumber.foreground": "${outline}",
  "editorLineNumber.activeForeground": "${primary_dark}",
  "editor.selectionBackground": "${primary_container}",
  "editor.selectionHighlightBackground": "${primary_container}50",
  "editor.findMatchBackground": "${tertiary_dark}40",
  "editor.findMatchHighlightBackground": "${tertiary_dark}30",
  "editorCursor.foreground": "${primary_dark}",
  "editorWhitespace.foreground": "${outline}",
  "editorIndentGuide.background": "${outline}80",
  "editorIndentGuide.activeBackground": "${primary_dark}80",
  "editorRuler.foreground": "${outline}80",
  "editorOverviewRuler.border": "${outline}",
  "editorWidget.background": "${surface_container}",
  "editorWidget.foreground": "${on_surface}",
  "editorSuggestWidget.background": "${surface_container_high}",
  "editorSuggestWidget.foreground": "${on_surface}",
  "editorSuggestWidget.highlightForeground": "${primary_dark}",
  "editorSuggestWidget.selectedBackground": "${primary_dark}",
  "editorSuggestWidget.selectedForeground": "${on_primary}",
  "editorHoverWidget.background": "${surface_container_high}",
  "editorHoverWidget.foreground": "${on_surface}",
  "editorError.foreground": "${error}",
  "editorWarning.foreground": "${tertiary_dark}",
  "editorInfo.foreground": "${secondary_dark}",
  "editorHint.foreground": "${on_surface_variant}",
  "editorBracketMatch.background": "${primary_container}40",
  "editorBracketHighlight.foreground1": "${primary_dark}",
  "editorBracketHighlight.foreground2": "${secondary_dark}",
  "editorBracketHighlight.foreground3": "${tertiary_dark}",
  "editorBracketHighlight.foreground4": "${primary_fixed_dim}",
  "editorBracketHighlight.foreground5": "${secondary_fixed_dim}",
  "editorBracketHighlight.foreground6": "${tertiary_fixed_dim}",
  "editorGutter.background": "${background}",
  "editorGutter.modifiedBackground": "${secondary_dark}",
  "editorGutter.addedBackground": "${tertiary_dark}",
  "editorGutter.deletedBackground": "${error}",
  
  "activityBar.background": "${surface_container}",
  "activityBar.foreground": "${on_surface}",
  "activityBar.inactiveForeground": "${on_surface_variant}",
  "activityBar.activeBorder": "${primary_dark}",
  "activityBarBadge.background": "${primary_dark}",
  "activityBarBadge.foreground": "${on_primary}",
  "activityBar.activeBackground": "${primary_dark}40",
  
  "sideBar.background": "${surface_container_low}",
  "sideBar.foreground": "${on_surface}",
  "sideBarTitle.foreground": "${primary_dark}",
  "sideBarSectionHeader.background": "${surface_container}",
  "sideBarSectionHeader.foreground": "${on_surface}",
  "sideBar.dropBackground": "${primary_container}40",
  
  "titleBar.activeBackground": "${surface_container_high}",
  "titleBar.activeForeground": "${on_surface}",
  "titleBar.inactiveBackground": "${surface_container}",
  "titleBar.inactiveForeground": "${on_surface_variant}",
  
  "statusBar.background": "${surface_container_high}",
  "statusBar.foreground": "${on_surface}",
  "statusBar.noFolderBackground": "${surface_container_high}",
  "statusBar.debuggingBackground": "${primary_container}",
  "statusBarItem.remoteBackground": "${primary_dark}",
  "statusBarItem.remoteForeground": "${on_primary}",
  "statusBarItem.prominentBackground": "${primary_dark}",
  "statusBarItem.prominentForeground": "${on_primary}",
  "statusBarItem.prominentHoverBackground": "${primary_container}",
  "statusBarItem.hoverBackground": "${surface_container_highest}",
  "statusBarItem.activeBackground": "${surface_container_highest}",
  "statusBar.errorBackground": "${error}",
  "statusBar.errorForeground": "${on_error}",
  "statusBar.warningBackground": "${tertiary_dark}",
  "statusBar.warningForeground": "${on_tertiary}",
  
  "tab.activeBackground": "${surface_container_lowest}",
  "tab.activeForeground": "${on_surface}",
  "tab.activeBorder": "${primary_dark}",
  "tab.inactiveBackground": "${surface_container_low}",
  "tab.inactiveForeground": "${on_surface_variant}",
  "tab.unfocusedActiveBorder": "${outline}",
  "tab.hoverBackground": "${surface_container}",
  "tab.unfocusedHoverBackground": "${surface_container_low}",
  "tab.activeModifiedBorder": "${secondary_dark}",
  "tab.inactiveModifiedBorder": "${secondary_container}",
  "tab.unfocusedActiveModifiedBorder": "${secondary_container}",
  "tab.unfocusedInactiveModifiedBorder": "${secondary_container}",
  
  "terminal.background": "${background}",
  "terminal.foreground": "${on_surface}",
  "terminalCursor.foreground": "${primary_dark}",
  "terminal.ansiBlack": "${surface_container_highest}",
  "terminal.ansiRed": "${error}",
  "terminal.ansiGreen": "#2e7d32",
  "terminal.ansiYellow": "#7f6000",
  "terminal.ansiBlue": "#0d47a1",
  "terminal.ansiMagenta": "#7b1fa2",
  "terminal.ansiCyan": "#00695c",
  "terminal.ansiWhite": "${on_surface}",
  "terminal.ansiBrightBlack": "${on_surface_variant}",
  "terminal.ansiBrightRed": "#d32f2f",
  "terminal.ansiBrightGreen": "#388e3c",
  "terminal.ansiBrightYellow": "#f9a825",
  "terminal.ansiBrightBlue": "#1976d2",
  "terminal.ansiBrightMagenta": "#8e24aa",
  "terminal.ansiBrightCyan": "#00897b",
  "terminal.ansiBrightWhite": "${inverse_surface}",
  "terminal.selectionBackground": "${primary_container}50",
  
  "list.activeSelectionBackground": "${primary_dark}",
  "list.activeSelectionForeground": "${on_primary}",
  "list.inactiveSelectionBackground": "${surface_container_high}",
  "list.inactiveSelectionForeground": "${on_surface}",
  "list.hoverBackground": "${surface_container_high}50",
  "list.highlightForeground": "${primary_dark}",
  "list.focusBackground": "${primary_dark}80",
  "list.focusForeground": "${on_primary}",
  "list.inactiveFocusBackground": "${primary_container}40",
  "list.errorForeground": "${error}",
  "list.warningForeground": "${tertiary_dark}",
  "list.dropBackground": "${primary_container}40",
  "list.invalidItemForeground": "${error}",
  "listFilterWidget.background": "${surface_container_high}",
  "listFilterWidget.outline": "${primary_dark}",
  "listFilterWidget.noMatchesOutline": "${error}",
  
  "panel.background": "${surface_container_low}",
  "panel.border": "${outline}",
  "panelTitle.activeBorder": "${primary_dark}",
  "panelTitle.activeForeground": "${on_surface}",
  "panelTitle.inactiveForeground": "${on_surface_variant}",
  "panelSection.dropBackground": "${primary_container}40",
  
  "button.background": "${primary_dark}",
  "button.foreground": "${on_primary}",
  "button.hoverBackground": "${primary_fixed_dim}",
  "button.secondaryBackground": "${secondary_dark}",
  "button.secondaryForeground": "${on_secondary}",
  "button.secondaryHoverBackground": "${secondary_fixed_dim}",
  "button.separator": "${outline}",
  
  "extensionIcon.starForeground": "${tertiary_dark}",
  "extensionIcon.verifiedForeground": "${primary_dark}",
  "extensionIcon.preReleaseForeground": "${secondary_dark}",
  "extensionIcon.sponsorForeground": "${tertiary_dark}",
  
  "extensionButton.background": "${surface_container_high}",
  "extensionButton.foreground": "${on_surface}",
  "extensionButton.hoverBackground": "${surface_container_highest}",
  
  "extensionButton.prominentBackground": "${primary_dark}",
  "extensionButton.prominentForeground": "${on_primary}",
  "extensionButton.prominentHoverBackground": "${primary_fixed_dim}",
  
  "extensionBadge.remoteBackground": "${primary_dark}",
  "extensionBadge.remoteForeground": "${on_primary}",
  
  "extensionEditor.background": "${background}",
  "extensionEditor.foreground": "${on_surface}",
  "extensionEditor.preReleaseBackground": "${tertiary_container}",
  "extensionEditor.preReleaseForeground": "${on_tertiary_container}",
  "extensionEditor.starForeground": "${tertiary_dark}",
  "extensionEditor.verifiedPublisherForeground": "${primary_dark}",
  "extensionEditor.verifiedPublisherBackground": "${primary_container}40",
  
  "welcomePage.tileBackground": "${surface_container}",
  "welcomePage.tileHoverBackground": "${surface_container_high}",
  "welcomePage.progress.background": "${surface_container_high}",
  "welcomePage.progress.foreground": "${primary_dark}",
  "welcomePage.buttonBackground": "${primary_dark}",
  "welcomePage.buttonHoverBackground": "${primary_fixed_dim}",
  "welcomePage.buttonForeground": "${on_primary}",
  
  "actionButton.background": "${surface_container_high}",
  "actionButton.foreground": "${on_surface}",
  "actionButton.hoverBackground": "${primary_dark}",
  "actionButton.hoverForeground": "${on_primary}",
  "actionButton.toggledBackground": "${primary_container}",
  "actionButton.toggledForeground": "${on_primary_container}",
  "actionButton.border": "${outline}",
  
  "input.background": "${surface_container_highest}",
  "input.foreground": "${on_surface}",
  "input.placeholderForeground": "${on_surface_variant}",
  "inputOption.activeBackground": "${primary_container}",
  "inputOption.activeBorder": "${primary_dark}",
  "inputOption.activeForeground": "${on_primary_container}",
  "inputValidation.errorBackground": "${error_container}",
  "inputValidation.errorForeground": "${on_error_container}",
  "inputValidation.errorBorder": "${error}",
  "inputValidation.infoBackground": "${primary_container}",
  "inputValidation.infoForeground": "${on_primary_container}",
  "inputValidation.infoBorder": "${primary_dark}",
  "inputValidation.warningBackground": "${tertiary_container}",
  "inputValidation.warningForeground": "${on_tertiary_container}",
  "inputValidation.warningBorder": "${tertiary_dark}",
  
  "scrollbarSlider.background": "${outline}80",
  "scrollbarSlider.hoverBackground": "${outline}",
  "scrollbarSlider.activeBackground": "${primary_dark}80",
  
  "badge.background": "${primary_dark}",
  "badge.foreground": "${on_primary}",
  
  "progressBar.background": "${primary_dark}",
  
  "textPreformat.foreground": "${primary_dark}",
  "textPreformat.background": "${primary_container}20",
  "textBlockQuote.background": "${surface_container_high}",
  "textBlockQuote.border": "${primary_dark}",
  "textCodeBlock.background": "${surface_container_high}",
  "textLink.activeForeground": "${primary_dark}",
  "textLink.foreground": "${primary_dark}",
  "textSeparator.foreground": "${outline}",
  
  "editor.selectionHighlightBorder": "${primary_dark}",
  "editor.wordHighlightBackground": "${primary_container}30",
  "editor.wordHighlightStrongBackground": "${primary_container}50",
  "editor.wordHighlightBorder": "${primary_dark}50",
  "editor.wordHighlightStrongBorder": "${primary_dark}",
  "editor.findRangeHighlightBackground": "${tertiary_container}30",
  "editor.rangeHighlightBackground": "${primary_container}20",
  
  "descriptionForeground": "${on_surface_variant}",
  
  "selection.background": "${primary_container}",
  
  "editorOverviewRuler.findMatchForeground": "${tertiary_dark}50",
  "editorOverviewRuler.rangeHighlightForeground": "${primary_dark}50",
  "editorOverviewRuler.selectionHighlightForeground": "${primary_container}",
  "editorOverviewRuler.wordHighlightForeground": "${primary_container}70",
  "editorOverviewRuler.wordHighlightStrongForeground": "${primary_dark}70",
  
  "breadcrumb.background": "${background}",
  "breadcrumb.foreground": "${on_surface_variant}",
  "breadcrumb.focusForeground": "${on_surface}",
  "breadcrumb.activeSelectionForeground": "${primary_dark}",
  "breadcrumbPicker.background": "${surface_container}",
  
  "menu.background": "${surface_container}",
  "menu.foreground": "${on_surface}",
  "menu.selectionBackground": "${primary_dark}",
  "menu.selectionForeground": "${on_primary}",
  "menu.separatorBackground": "${outline}",
  
  "menubar.selectionBackground": "${primary_dark}",
  "menubar.selectionForeground": "${on_primary}",
  
  "notifications.background": "${surface_container}",
  "notifications.foreground": "${on_surface}",
  "notificationLink.foreground": "${primary_dark}",
  "notificationsErrorIcon.foreground": "${error}",
  "notificationsWarningIcon.foreground": "${tertiary_dark}",
  "notificationsInfoIcon.foreground": "${primary_dark}",
  
  "gitDecoration.addedResourceForeground": "#2e7d32",
  "gitDecoration.modifiedResourceForeground": "#0d47a1",
  "gitDecoration.deletedResourceForeground": "${error}",
  "gitDecoration.untrackedResourceForeground": "#7f6000",
  "gitDecoration.ignoredResourceForeground": "${on_surface_variant}",
  "gitDecoration.conflictingResourceForeground": "${error}",
  "gitDecoration.submoduleResourceForeground": "${primary_fixed_dim}",
  
  "scm.providerBorder": "${outline}",
  
  "diffEditor.insertedTextBackground": "#2e7d3220",
  "diffEditor.removedTextBackground": "${error}20",
  "diffEditor.diagonalFill": "${outline}40",
  
  "debugToolBar.background": "${surface_container}",
  "debugToolBar.border": "${outline}",
  "debugIcon.breakpointForeground": "${error}",
  "debugIcon.breakpointDisabledForeground": "${error}80",
  "debugIcon.breakpointUnverifiedForeground": "${on_surface_variant}",
  "debugIcon.breakpointCurrentStackframeForeground": "${tertiary_dark}",
  "debugIcon.breakpointStackframeForeground": "${tertiary_container}",
  
  "editor.stackFrameHighlightBackground": "${tertiary_container}30",
  "editor.focusedStackFrameHighlightBackground": "${tertiary_container}60",
  
  "peekView.border": "${primary_dark}",
  "peekViewEditor.background": "${surface_container_low}",
  "peekViewEditor.matchHighlightBackground": "${tertiary_dark}30",
  "peekViewResult.background": "${surface_container}",
  "peekViewResult.fileForeground": "${on_surface}",
  "peekViewResult.lineForeground": "${on_surface}",
  "peekViewResult.matchHighlightBackground": "${tertiary_dark}30",
  "peekViewResult.selectionBackground": "${primary_dark}",
  "peekViewResult.selectionForeground": "${on_primary}",
  "peekViewTitle.background": "${surface_container_high}",
  "peekViewTitleDescription.foreground": "${on_surface}",
  "peekViewTitleLabel.foreground": "${primary_dark}",
  
  "symbolIcon.arrayForeground": "${tertiary_dark}",
  "symbolIcon.booleanForeground": "${error}",
  "symbolIcon.classForeground": "${primary_dark}",
  "symbolIcon.colorForeground": "${tertiary_dark}",
  "symbolIcon.constantForeground": "${primary_dark}",
  "symbolIcon.enumeratorForeground": "${primary_dark}",
  "symbolIcon.enumeratorMemberForeground": "${primary_dark}",
  "symbolIcon.eventForeground": "${tertiary_dark}",
  "symbolIcon.fieldForeground": "${secondary_dark}",
  "symbolIcon.fileForeground": "${on_surface}",
  "symbolIcon.folderForeground": "${on_surface}",
  "symbolIcon.functionForeground": "${secondary_dark}",
  "symbolIcon.interfaceForeground": "${primary_dark}",
  "symbolIcon.keyForeground": "${tertiary_dark}",
  "symbolIcon.keywordForeground": "${error}",
  "symbolIcon.methodForeground": "${secondary_dark}",
  "symbolIcon.moduleForeground": "${primary_dark}",
  "symbolIcon.namespaceForeground": "${primary_dark}",
  "symbolIcon.nullForeground": "${error}",
  "symbolIcon.numberForeground": "${tertiary_dark}",
  "symbolIcon.objectForeground": "${primary_dark}",
  "symbolIcon.operatorForeground": "${tertiary_dark}",
  "symbolIcon.packageForeground": "${primary_dark}",
  "symbolIcon.propertyForeground": "${secondary_dark}",
  "symbolIcon.referenceForeground": "${on_surface}",
  "symbolIcon.snippetForeground": "${tertiary_dark}",
  "symbolIcon.stringForeground": "${tertiary_dark}",
  "symbolIcon.structForeground": "${primary_dark}",
  "symbolIcon.textForeground": "${on_surface}",
  "symbolIcon.typeParameterForeground": "${tertiary_dark}",
  "symbolIcon.unitForeground": "${tertiary_dark}",
  "symbolIcon.variableForeground": "${secondary_dark}",
  "focusBorder": "${outline}",
  "editorGroup.focusedEmptyBorder": "${primary_dark}"
}
EOF
)

# Update VSCode settings.json
log "INFO" "Updating VSCode settings.json with Material You light colors..."

# Check if workbench.colorCustomizations already exists
if grep -q "workbench.colorCustomizations" "$VSCODE_SETTINGS"; then
    log "INFO" "workbench.colorCustomizations already exists, updating it..."
    # Use jq to update the existing colorCustomizations
    TMP_FILE=$(mktemp)
    jq --argjson colors "$VSCODE_COLORS" '.["workbench.colorCustomizations"] = $colors' "$VSCODE_SETTINGS" > "$TMP_FILE"
    mv "$TMP_FILE" "$VSCODE_SETTINGS"
else
    log "INFO" "Adding workbench.colorCustomizations to settings.json..."
    # Add colorCustomizations to the settings file
    TMP_FILE=$(mktemp)
    jq --argjson colors "$VSCODE_COLORS" '. + {"workbench.colorCustomizations": $colors}' "$VSCODE_SETTINGS" > "$TMP_FILE"
    mv "$TMP_FILE" "$VSCODE_SETTINGS"
fi

log "INFO" "VSCode Material You light theme applied successfully!"

exit 0 