#!/bin/bash

# ============================================================================
# Dark Theme VSCode Script for Hyprland Colorgen
# 
# This script applies Material You dark theme colors to VSCode settings
# ============================================================================

# Set strict error handling
set -euo pipefail

# Define paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
COLORGEN_DIR="$XDG_CONFIG_HOME/hypr/colorgen"
VSCODE_SETTINGS="$XDG_CONFIG_HOME/Code/User/settings.json"
DARK_COLORS_JSON="$COLORGEN_DIR/dark_colors.json"

# Script name for logging
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Basic logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "[${timestamp}] [${SCRIPT_NAME}] [${level}] ${message}"
}

log "INFO" "Applying Material You dark theme colors to VSCode"

# Check if files exist
if [ ! -f "$DARK_COLORS_JSON" ]; then
    log "ERROR" "Material You dark colors not found. Run material_extract.sh first."
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
log "INFO" "Extracting Material You dark colors for VSCode..."

# Extract colors from JSON for Material You palette
# We use jq to parse the JSON and extract the colors
extract_color() {
    local color_name=$1
    local default_color=$2
    local color=$(jq -r ".$color_name" "$DARK_COLORS_JSON" 2>/dev/null)
    
    if [ -z "$color" ] || [ "$color" = "null" ]; then
        echo "$default_color"
    else
        echo "$color"
    fi
}

# Get required colors from Material You palette
background=$(extract_color "background" "#1C1B1F")
surface=$(extract_color "surface" "#1C1B1F")
surface_container=$(extract_color "surface_container" "#211F26")
surface_container_low=$(extract_color "surface_container_low" "#1D1B20")
surface_container_high=$(extract_color "surface_container_high" "#2B2930")
surface_container_highest=$(extract_color "surface_container_highest" "#36343B")
surface_container_lowest=$(extract_color "surface_container_lowest" "#0F0E11")
surface_bright=$(extract_color "surface_bright" "#3E3A43")
surface_dim=$(extract_color "surface_dim" "#141318")
surface_variant=$(extract_color "surface_variant" "#49454F")
surface_tint=$(extract_color "surface_tint" "#D0BCFF")
on_surface=$(extract_color "on_surface" "#E6E0E9")
on_surface_variant=$(extract_color "on_surface_variant" "#CAC4D0")
inverse_surface=$(extract_color "inverse_surface" "#E6E0E9")
inverse_on_surface=$(extract_color "inverse_on_surface" "#322F35")
inverse_primary=$(extract_color "inverse_primary" "#6750A4")
primary=$(extract_color "primary" "#D0BCFF")
primary_container=$(extract_color "primary_container" "#4F378B")
on_primary=$(extract_color "on_primary" "#381E72")
on_primary_container=$(extract_color "on_primary_container" "#EADDFF")
primary_fixed=$(extract_color "primary_fixed" "#EADDFF")
primary_fixed_dim=$(extract_color "primary_fixed_dim" "#D0BCFF")
on_primary_fixed=$(extract_color "on_primary_fixed" "#21005D")
on_primary_fixed_variant=$(extract_color "on_primary_fixed_variant" "#4F378B")
secondary=$(extract_color "secondary" "#CCC2DC")
secondary_container=$(extract_color "secondary_container" "#4A4458")
on_secondary=$(extract_color "on_secondary" "#332D41")
on_secondary_container=$(extract_color "on_secondary_container" "#E8DEF8")
secondary_fixed=$(extract_color "secondary_fixed" "#E8DEF8")
secondary_fixed_dim=$(extract_color "secondary_fixed_dim" "#CCC2DC")
on_secondary_fixed=$(extract_color "on_secondary_fixed" "#1D192B")
on_secondary_fixed_variant=$(extract_color "on_secondary_fixed_variant" "#4A4458")
tertiary=$(extract_color "tertiary" "#EFB8C8")
tertiary_container=$(extract_color "tertiary_container" "#633B48")
on_tertiary=$(extract_color "on_tertiary" "#492532")
on_tertiary_container=$(extract_color "on_tertiary_container" "#FFD8E4")
tertiary_fixed=$(extract_color "tertiary_fixed" "#FFD8E4")
tertiary_fixed_dim=$(extract_color "tertiary_fixed_dim" "#EFB8C8")
on_tertiary_fixed=$(extract_color "on_tertiary_fixed" "#31111D")
on_tertiary_fixed_variant=$(extract_color "on_tertiary_fixed_variant" "#633B48")
error=$(extract_color "error" "#F2B8B5")
error_container=$(extract_color "error_container" "#8C1D18")
on_error=$(extract_color "on_error" "#601410")
on_error_container=$(extract_color "on_error_container" "#F9DEDC")
outline=$(extract_color "outline" "#938F99")
outline_variant=$(extract_color "outline_variant" "#444746")
scrim=$(extract_color "scrim" "#000000")
shadow=$(extract_color "shadow" "#000000")

log "INFO" "Primary color: $primary"
log "INFO" "Background color: $background"

# Create VSCode color customizations JSON
VSCODE_COLORS=$(cat << EOF
{
  "editor.background": "${background}",
  "editor.foreground": "${on_surface}",
  "editorLineNumber.foreground": "${outline}",
  "editorLineNumber.activeForeground": "${primary}",
  "editor.selectionBackground": "${primary_container}",
  "editor.selectionHighlightBackground": "${primary_container}50",
  "editor.findMatchBackground": "${tertiary}50",
  "editor.findMatchHighlightBackground": "${tertiary}30",
  "editorCursor.foreground": "${primary}",
  "editorWhitespace.foreground": "${outline}40",
  "editorIndentGuide.background": "${outline}40",
  "editorIndentGuide.activeBackground": "${primary}40",
  "editorRuler.foreground": "${outline}40",
  "editorOverviewRuler.border": "${outline}",
  "editorWidget.background": "${surface_container}",
  "editorWidget.foreground": "${on_surface}",
  "editorSuggestWidget.background": "${surface_container_high}",
  "editorSuggestWidget.foreground": "${on_surface}",
  "editorSuggestWidget.highlightForeground": "${primary}",
  "editorSuggestWidget.selectedBackground": "${primary}",
  "editorSuggestWidget.selectedForeground": "${background}",
  "editorHoverWidget.background": "${surface_container_high}",
  "editorHoverWidget.foreground": "${on_surface}",
  "editorError.foreground": "${error}",
  "editorWarning.foreground": "${tertiary}",
  "editorInfo.foreground": "${secondary}",
  "editorHint.foreground": "${outline}",
  "editorBracketMatch.background": "${primary_container}40",
  "editorBracketHighlight.foreground1": "${primary}",
  "editorBracketHighlight.foreground2": "${secondary}",
  "editorBracketHighlight.foreground3": "${tertiary}",
  "editorBracketHighlight.foreground4": "${primary_fixed_dim}",
  "editorBracketHighlight.foreground5": "${secondary_fixed_dim}",
  "editorBracketHighlight.foreground6": "${tertiary_fixed_dim}",
  "editorGutter.background": "${background}",
  "editorGutter.modifiedBackground": "${secondary}",
  "editorGutter.addedBackground": "${tertiary}",
  "editorGutter.deletedBackground": "${error}",
  
  "activityBar.background": "${surface_container}",
  "activityBar.foreground": "${on_surface}",
  "activityBar.inactiveForeground": "${on_surface_variant}",
  "activityBar.activeBorder": "${primary}",
  "activityBarBadge.background": "${primary}",
  "activityBarBadge.foreground": "${background}",
  "activityBar.activeBackground": "${primary}40",
  
  "sideBar.background": "${surface_container_low}",
  "sideBar.foreground": "${on_surface}",
  "sideBarTitle.foreground": "${primary}",
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
  "statusBarItem.remoteBackground": "${primary_container}",
  "statusBarItem.remoteForeground": "${on_surface}",
  "statusBarItem.prominentBackground": "${primary}",
  "statusBarItem.prominentForeground": "${background}",
  "statusBarItem.prominentHoverBackground": "${primary_container}",
  "statusBarItem.hoverBackground": "${surface_container_highest}",
  "statusBarItem.activeBackground": "${surface_container_highest}",
  "statusBar.errorBackground": "${error_container}",
  "statusBar.errorForeground": "${on_error_container}",
  "statusBar.warningBackground": "${tertiary_container}",
  "statusBar.warningForeground": "${on_tertiary_container}",
  
  "tab.activeBackground": "${surface_container_high}",
  "tab.activeForeground": "${on_surface}",
  "tab.activeBorder": "${surface_container_high}",
  "tab.activeBorderTop": "${primary}",
  "tab.inactiveBackground": "${surface_container}",
  "tab.inactiveForeground": "${on_surface_variant}",
  "tab.unfocusedActiveBorder": "${surface_container_high}",
  "tab.unfocusedActiveBorderTop": "${outline}",
  "tab.hoverBackground": "${surface_container_highest}",
  "tab.unfocusedHoverBackground": "${surface_container_high}",
  "tab.activeModifiedBorder": "${secondary}",
  "tab.inactiveModifiedBorder": "${secondary_container}",
  "tab.unfocusedActiveModifiedBorder": "${secondary_container}",
  "tab.unfocusedInactiveModifiedBorder": "${secondary_container}",
  
  "terminal.background": "${background}",
  "terminal.foreground": "${on_surface}",
  "terminalCursor.foreground": "${primary}",
  "terminal.ansiBlack": "${surface_container_lowest}",
  "terminal.ansiRed": "${error}",
  "terminal.ansiGreen": "${tertiary}",
  "terminal.ansiYellow": "${tertiary_fixed_dim}",
  "terminal.ansiBlue": "${primary}",
  "terminal.ansiMagenta": "${primary_fixed_dim}",
  "terminal.ansiCyan": "${secondary}",
  "terminal.ansiWhite": "${on_surface}",
  "terminal.ansiBrightBlack": "${surface_variant}",
  "terminal.ansiBrightRed": "${error_container}",
  "terminal.ansiBrightGreen": "${tertiary_container}",
  "terminal.ansiBrightYellow": "${tertiary_fixed}",
  "terminal.ansiBrightBlue": "${primary_container}",
  "terminal.ansiBrightMagenta": "${primary_fixed}",
  "terminal.ansiBrightCyan": "${secondary_container}",
  "terminal.ansiBrightWhite": "${inverse_surface}",
  "terminal.selectionBackground": "${primary_container}50",
  
  "list.activeSelectionBackground": "${primary}",
  "list.activeSelectionForeground": "${background}",
  "list.inactiveSelectionBackground": "${surface_container_high}",
  "list.inactiveSelectionForeground": "${on_surface}",
  "list.hoverBackground": "${surface_container_high}50",
  "list.highlightForeground": "${primary}",
  "list.focusBackground": "${primary}80",
  "list.focusForeground": "${background}",
  "list.inactiveFocusBackground": "${primary_container}40",
  "list.errorForeground": "${error}",
  "list.warningForeground": "${tertiary}",
  "list.dropBackground": "${primary_container}40",
  "list.invalidItemForeground": "${error}",
  "listFilterWidget.background": "${surface_container_high}",
  "listFilterWidget.outline": "${primary}",
  "listFilterWidget.noMatchesOutline": "${error}",
  
  "panel.background": "${surface_container_low}",
  "panel.border": "${outline}",
  "panelTitle.activeBorder": "${primary}",
  "panelTitle.activeForeground": "${on_surface}",
  "panelTitle.inactiveForeground": "${on_surface_variant}",
  "panelSection.dropBackground": "${primary_container}40",
  
  "button.background": "${primary}",
  "button.foreground": "${background}",
  "button.hoverBackground": "${primary}CC",
  "button.border": "${primary}",
  "button.secondaryBackground": "${surface_container_high}",
  "button.secondaryForeground": "${on_surface}",
  "button.secondaryHoverBackground": "${surface_container_highest}",
  "button.separator": "${outline}",

  "commandCenter.activeForeground": "${on_surface}",
  "commandCenter.inactiveForeground": "${on_surface_variant}",
  
  "extensionIcon.starForeground": "${tertiary}",
  "extensionIcon.verifiedForeground": "${primary}",
  "extensionIcon.preReleaseForeground": "${secondary}",
  "extensionIcon.sponsorForeground": "${tertiary}",
  
  "extensionButton.background": "${primary}",
  "extensionButton.foreground": "${on_surface}",
  "extensionButton.hoverBackground": "${on_tertiary_container}",
  "extensionButton.border": "${outline}",
  
  "extensionButton.prominentBackground": "${primary}",
  "extensionButton.prominentForeground": "${background}",
  "extensionButton.prominentHoverBackground": "${primary}CC",
  "extensionButton.prominentBorder": "${primary}",
  
  "extensionBadge.remoteBackground": "${primary}",
  "extensionBadge.remoteForeground": "${background}",
  
  "extensionEditor.background": "${background}",
  "extensionEditor.foreground": "${on_surface}",
  "extensionEditor.preReleaseBackground": "${tertiary_container}",
  "extensionEditor.preReleaseForeground": "${on_tertiary_container}",
  "extensionEditor.starForeground": "${tertiary}",
  "extensionEditor.verifiedPublisherForeground": "${primary}",
  "extensionEditor.verifiedPublisherBackground": "${primary_container}40",

  "extension.installButton.background": "${primary}",
  "extension.installButton.foreground": "${background}",
  "extension.installButton.hoverBackground": "${primary}CC",
  "extension.installButton.border": "${primary}",

  "extension.installButton.prominentBackground": "${primary}",
  "extension.installButton.prominentForeground": "${background}",
  
  "welcomePage.tileBackground": "${surface_container}",
  "welcomePage.tileHoverBackground": "${surface_container_high}",
  "welcomePage.progress.background": "${surface_container_high}",
  "welcomePage.progress.foreground": "${primary}",
  "welcomePage.buttonBackground": "${primary}",
  "welcomePage.buttonHoverBackground": "${primary}CC",
  "welcomePage.buttonForeground": "${background}",
  
  "actionButton.background": "${surface_container_high}",
  "actionButton.foreground": "${on_surface}",
  "actionButton.hoverBackground": "${primary}",
  "actionButton.toggledBackground": "${primary_container}",
  "actionButton.toggledForeground": "${on_primary_container}",
  "actionButton.border": "${outline}",
  
  "input.background": "${surface_container_highest}",
  "input.foreground": "${on_surface}",
  "input.placeholderForeground": "${on_surface_variant}",
  "input.border": "${outline}",
  "inputOption.activeBackground": "${primary_container}",
  "inputOption.activeBorder": "${primary}",
  "inputOption.activeForeground": "${primary}",
  "inputValidation.errorBackground": "${error_container}",
  "inputValidation.errorForeground": "${on_error_container}",
  "inputValidation.errorBorder": "${error}",
  "inputValidation.infoBackground": "${primary_container}",
  "inputValidation.infoForeground": "${on_primary_container}",
  "inputValidation.infoBorder": "${primary}",
  "inputValidation.warningBackground": "${tertiary_container}",
  "inputValidation.warningForeground": "${on_tertiary_container}",
  "inputValidation.warningBorder": "${tertiary}",
  
  "scrollbarSlider.background": "${outline}40",
  "scrollbarSlider.hoverBackground": "${outline}60",
  "scrollbarSlider.activeBackground": "${primary}40",
  
  "badge.background": "${primary}",
  "badge.foreground": "${background}",
  
  "progressBar.background": "${primary}",
  
  "textPreformat.foreground": "${primary}",
  "textPreformat.background": "${primary_container}20",
  "textBlockQuote.background": "${surface_container_high}",
  "textBlockQuote.border": "${primary}",
  "textCodeBlock.background": "${surface_container_high}",
  "textLink.activeForeground": "${primary}",
  "textLink.foreground": "${primary}",
  "textSeparator.foreground": "${outline}",
  
  "editor.selectionHighlightBorder": "${primary}",
  "editor.wordHighlightBackground": "${primary_container}30",
  "editor.wordHighlightStrongBackground": "${primary_container}50",
  "editor.wordHighlightBorder": "${primary}50",
  "editor.wordHighlightStrongBorder": "${primary}",
  "editor.findRangeHighlightBackground": "${tertiary_container}30",
  "editor.rangeHighlightBackground": "${primary_container}20",
  
  "descriptionForeground": "${on_surface_variant}",
  
  "selection.background": "${primary_container}",
  
  "editorOverviewRuler.findMatchForeground": "${tertiary}50",
  "editorOverviewRuler.rangeHighlightForeground": "${primary}50",
  "editorOverviewRuler.selectionHighlightForeground": "${primary_container}",
  "editorOverviewRuler.wordHighlightForeground": "${primary_container}70",
  "editorOverviewRuler.wordHighlightStrongForeground": "${primary}70",
  
  "breadcrumb.background": "${background}",
  "breadcrumb.foreground": "${on_surface_variant}",
  "breadcrumb.focusForeground": "${on_surface}",
  "breadcrumb.activeSelectionForeground": "${primary}",
  "breadcrumbPicker.background": "${surface_container}",
  
  "menu.background": "${surface_container}",
  "menu.foreground": "${on_surface}",
  "menu.selectionBackground": "${primary}",
  "menu.selectionForeground": "${background}",
  "menu.separatorBackground": "${outline}",
  
  "menubar.selectionBackground": "${primary}",
  "menubar.selectionForeground": "${background}",
  
  "notifications.background": "${surface_container}",
  "notifications.foreground": "${on_surface}",
  "notificationLink.foreground": "${primary}",
  "notificationsErrorIcon.foreground": "${error}",
  "notificationsWarningIcon.foreground": "${tertiary}",
  "notificationsInfoIcon.foreground": "${primary}",
  
  "gitDecoration.addedResourceForeground": "${tertiary}",
  "gitDecoration.modifiedResourceForeground": "${secondary}",
  "gitDecoration.deletedResourceForeground": "${error}",
  "gitDecoration.untrackedResourceForeground": "${tertiary_fixed_dim}",
  "gitDecoration.ignoredResourceForeground": "${outline}",
  "gitDecoration.conflictingResourceForeground": "${error_container}",
  "gitDecoration.submoduleResourceForeground": "${primary_fixed_dim}",
  
  "scm.providerBorder": "${outline}",
  
  "diffEditor.insertedTextBackground": "${tertiary}20",
  "diffEditor.removedTextBackground": "${error}20",
  "diffEditor.diagonalFill": "${outline}40",
  
  "debugToolBar.background": "${surface_container}",
  "debugToolBar.border": "${outline}",
  "debugIcon.breakpointForeground": "${error}",
  "debugIcon.breakpointDisabledForeground": "${error}50",
  "debugIcon.breakpointUnverifiedForeground": "${outline}",
  "debugIcon.breakpointCurrentStackframeForeground": "${tertiary}",
  "debugIcon.breakpointStackframeForeground": "${tertiary_container}",
  
  "editor.stackFrameHighlightBackground": "${tertiary_container}30",
  "editor.focusedStackFrameHighlightBackground": "${tertiary_container}60",
  
  "peekView.border": "${primary}",
  "peekViewEditor.background": "${surface_container_low}",
  "peekViewEditor.matchHighlightBackground": "${tertiary}30",
  "peekViewResult.background": "${surface_container}",
  "peekViewResult.fileForeground": "${on_surface}",
  "peekViewResult.lineForeground": "${on_surface_variant}",
  "peekViewResult.matchHighlightBackground": "${tertiary}30",
  "peekViewResult.selectionBackground": "${primary}",
  "peekViewResult.selectionForeground": "${background}",
  "peekViewTitle.background": "${surface_container_high}",
  "peekViewTitleDescription.foreground": "${on_surface_variant}",
  "peekViewTitleLabel.foreground": "${primary}",
  
  "symbolIcon.arrayForeground": "${tertiary}",
  "symbolIcon.booleanForeground": "${error}",
  "symbolIcon.classForeground": "${primary}",
  "symbolIcon.colorForeground": "${tertiary_fixed_dim}",
  "symbolIcon.constantForeground": "${primary_fixed_dim}",
  "symbolIcon.enumeratorForeground": "${primary}",
  "symbolIcon.enumeratorMemberForeground": "${primary_container}",
  "symbolIcon.eventForeground": "${tertiary}",
  "symbolIcon.fieldForeground": "${secondary}",
  "symbolIcon.fileForeground": "${on_surface_variant}",
  "symbolIcon.folderForeground": "${on_surface_variant}",
  "symbolIcon.functionForeground": "${secondary}",
  "symbolIcon.interfaceForeground": "${primary}",
  "symbolIcon.keyForeground": "${tertiary_fixed_dim}",
  "symbolIcon.keywordForeground": "${error}",
  "symbolIcon.methodForeground": "${secondary}",
  "symbolIcon.moduleForeground": "${primary_fixed_dim}",
  "symbolIcon.namespaceForeground": "${primary}",
  "symbolIcon.nullForeground": "${error_container}",
  "symbolIcon.numberForeground": "${tertiary_fixed_dim}",
  "symbolIcon.objectForeground": "${primary}",
  "symbolIcon.operatorForeground": "${tertiary}",
  "symbolIcon.packageForeground": "${primary_fixed_dim}",
  "symbolIcon.propertyForeground": "${secondary}",
  "symbolIcon.referenceForeground": "${on_surface_variant}",
  "symbolIcon.snippetForeground": "${tertiary}",
  "symbolIcon.stringForeground": "${tertiary_fixed_dim}",
  "symbolIcon.structForeground": "${primary}",
  "symbolIcon.textForeground": "${on_surface_variant}",
  "symbolIcon.typeParameterForeground": "${tertiary}",
  "symbolIcon.unitForeground": "${tertiary_fixed_dim}",
  "symbolIcon.variableForeground": "${secondary}",
  "focusBorder": "${outline}",
  "editorGroup.focusedEmptyBorder": "${primary}",
  
  "searchEditor.findMatchBackground": "${tertiary}50",
  "searchEditor.findMatchBorder": "${tertiary}",
  "searchEditor.textInputBorder": "${outline}",
  "search.resultsInfoForeground": "${on_surface_variant}",
  
  "settings.headerForeground": "${primary}",
  "settings.modifiedItemIndicator": "${primary}",
  "settings.dropdownBackground": "${surface_container_high}",
  "settings.dropdownForeground": "${on_surface}",
  "settings.dropdownBorder": "${outline}",
  "settings.dropdownListBorder": "${outline}",
  "settings.checkboxBackground": "${surface_container_high}",
  "settings.checkboxForeground": "${on_surface}",
  "settings.checkboxBorder": "${outline}",
  "settings.textInputBackground": "${surface_container_high}",
  "settings.textInputForeground": "${on_surface}",
  "settings.textInputBorder": "${outline}",
  "settings.numberInputBackground": "${surface_container_high}",
  "settings.numberInputForeground": "${on_surface}",
  "settings.numberInputBorder": "${outline}",
  
  "quickInput.background": "${surface_container}",
  "quickInput.foreground": "${on_surface}",
  "quickInputTitle.background": "${surface_container_high}",
  "quickInputList.focusBackground": "${primary}",
  "quickInputList.focusForeground": "${on_primary}",
  "quickInput.descriptionForeground": "${on_surface_variant}",
  "pickerGroup.foreground": "${primary}",
  
  "searchView.queryMatch": "${tertiary}",
  "search.searchEditorFindOptions": "${tertiary}",
  "searchEditor.findMatchForeground": "${on_surface}",
  "search.inputBoxHoverForeground": "${on_surface}",
  "search.inputBoxForeground": "${on_surface}",
  "searchEditor.textInputForeground": "${on_surface}",
  "inputBox.foreground": "${on_surface}",
  "inputBox.placeholderForeground": "${on_surface_variant}",
  "inputBox.background": "${surface_container_high}",
  "inputBox.hoverBackground": "${surface_container_highest}",
  "inputBox.hoverForeground": "${on_surface}",
  "searchEditor.queryMatch.foreground": "${on_surface}",
  "searchEditor.queryMatch.background": "${tertiary}50",
  
  "extensionButton.prominentBackground": "${primary}",
  "extensionButton.prominentForeground": "${background}",
  "extensionButton.prominentHoverBackground": "${primary}CC",
  "extensionButton.prominentBorder": "${primary}",
  
  "marketplace.installButtonBackground": "${primary}",
  "marketplace.installButtonForeground": "${on_primary}",
  "marketplace.installButtonHoverBackground": "${primary}CC",
  "marketplace.installButtonBorder": "${primary}",
  "marketplace.actionButtonBackground": "${surface_container_high}",
  "marketplace.actionButtonForeground": "${on_surface}",
  "marketplace.actionButtonHoverBackground": "${surface_container_highest}",
  "marketplace.actionButtonBorder": "${outline}"
}
EOF
)

# Update VSCode settings.json
log "INFO" "Updating VSCode settings.json with Material You dark colors..."

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

log "INFO" "VSCode Material You dark theme applied successfully!"

exit 0 