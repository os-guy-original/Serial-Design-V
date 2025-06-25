use gtk::{self, prelude::*};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::collections::{HashMap, HashSet};
use std::sync::{Mutex, OnceLock};
use libadwaita;
use libadwaita::prelude::*;
use chrono;
use dirs;
use std::rc::Rc;

// Structure to hold app information
#[derive(Clone)]
struct AppInfo {
    name: String,
    command: String,
    comment: String,
}

// Cache for desktop files to avoid rescanning
static DESKTOP_FILES_CACHE: OnceLock<Mutex<Option<Vec<(PathBuf, String)>>>> = OnceLock::new();
// Cache for app installation status
static APP_CACHE: OnceLock<Mutex<HashSet<String>>> = OnceLock::new();
// Cache for mainmod value
static MAINMOD_CACHE: OnceLock<String> = OnceLock::new();

// Function to get desktop files cache
fn get_desktop_files_cache() -> &'static Mutex<Option<Vec<(PathBuf, String)>>> {
    DESKTOP_FILES_CACHE.get_or_init(|| Mutex::new(None))
}

// Function to get app installation status cache
fn get_app_cache() -> &'static Mutex<HashSet<String>> {
    APP_CACHE.get_or_init(|| Mutex::new(HashSet::new()))
}

// Function to create the default apps tab content
pub fn create_default_apps_content() -> gtk::Widget {
    // Main container
    let content = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content.set_margin_start(20);
    content.set_margin_end(20);
    content.set_margin_top(20);
    content.set_margin_bottom(20);
    content.set_vexpand(true);
    content.set_valign(gtk::Align::Fill);
    
    // Add header
    let header_box = gtk::Box::new(gtk::Orientation::Vertical, 8);
    
    let title = gtk::Label::new(Some("Default Applications"));
    title.add_css_class("title-1");
    title.set_halign(gtk::Align::Start);
    
    header_box.append(&title);
    content.append(&header_box);
    
    // Create scrolled window for the content
    let hyprland_scroll = gtk::ScrolledWindow::new();
    hyprland_scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    hyprland_scroll.set_vexpand(true);
    
    // Create page for Hyprland
    let hyprland_page = gtk::Box::new(gtk::Orientation::Vertical, 15);
    hyprland_page.set_margin_start(10);
    hyprland_page.set_margin_end(10);
    hyprland_page.set_margin_top(10);
    hyprland_page.set_margin_bottom(10);
    
    // Add page to scrolled window
    hyprland_scroll.set_child(Some(&hyprland_page));
    
    // Create loading spinner
    let hyprland_spinner_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    hyprland_spinner_box.set_vexpand(true);
    hyprland_spinner_box.set_valign(gtk::Align::Center);
    hyprland_spinner_box.set_halign(gtk::Align::Center);
    
    let hyprland_spinner = gtk::Spinner::new();
    hyprland_spinner.set_size_request(32, 32);
    hyprland_spinner.start();
    
    let hyprland_spinner_label = gtk::Label::new(Some("Loading Hyprland configuration..."));
    hyprland_spinner_label.add_css_class("title-4");
    
    hyprland_spinner_box.append(&hyprland_spinner);
    hyprland_spinner_box.append(&hyprland_spinner_label);
    
    // Add spinner to the hyprland page initially
    hyprland_page.append(&hyprland_spinner_box);
    
    // Add the content to the main container
    content.append(&hyprland_scroll);
    
    // Start loading the page immediately
    gtk::glib::idle_add_local_once(move || {
        load_hyprland_page_incrementally(&hyprland_page, &hyprland_spinner_box);
    });
    
    content.into()
}

// Function to scan a directory for desktop files optimized for performance
fn scan_directory_for_desktop_files_optimized(
    dir: &PathBuf,
    desktop_files: &mut Vec<(PathBuf, String)>,
    processed_files: &mut HashSet<String>
) {
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.filter_map(Result::ok) {
            let path = entry.path();
            
            if path.is_dir() {
                // Skip certain directories known to contain no desktop files
                let dir_name = path.file_name().map(|n| n.to_string_lossy().to_lowercase()).unwrap_or_default();
                if dir_name == "icons" || dir_name == "appdata" || dir_name == "themes" {
                    continue;
                }
                
                // Recursively scan subdirectories
                scan_directory_for_desktop_files_optimized(&path, desktop_files, processed_files);
                continue;
            }
            
            // Check if this is a desktop file
            if path.extension().map_or(false, |ext| ext == "desktop") {
                // Skip if we've already processed this file (by canonical path)
                let canonical_path = path.to_string_lossy().to_string();
                if processed_files.contains(&canonical_path) {
                    continue;
                }
                
                processed_files.insert(canonical_path);
                
                // Read the file content
                if let Ok(content) = fs::read_to_string(&path) {
                    // Add the file to our list
                    desktop_files.push((path.clone(), content.into()));
                }
            }
        }
    }
}

// Function to extract a value from a desktop entry
fn extract_desktop_entry(content: &str, key: &str) -> String {
    let key_prefix = format!("{}=", key);
    
    for line in content.lines() {
        if line.starts_with(&key_prefix) {
            return line.splitn(2, '=').nth(1).unwrap_or("").to_string();
        }
    }
    
    // If we didn't find it in the first pass, do a more thorough search
    let mut in_desktop_entry = false;
    
    for line in content.lines() {
        if line.trim() == "[Desktop Entry]" {
            in_desktop_entry = true;
            continue;
        } else if line.starts_with('[') && in_desktop_entry {
            // We've moved to another section
            in_desktop_entry = false;
        }
        
        if in_desktop_entry && line.starts_with(&key_prefix) {
            return line.splitn(2, '=').nth(1).unwrap_or("").to_string();
        }
    }
    
    String::new()
}

// Function to clean up Exec command from desktop file
fn clean_exec_command(exec: &str) -> Option<String> {
    // Remove field codes like %f, %F, %u, %U, etc.
    let mut cmd = exec.to_string();
    
    // Remove quotes if present
    if cmd.starts_with('"') && cmd.ends_with('"') {
        cmd = cmd[1..cmd.len()-1].to_string();
    }
    
    // Remove field codes
    let field_codes = ["%f", "%F", "%u", "%U", "%d", "%D", "%n", "%N", "%i", "%c", "%k", "%v", "%m"];
    for code in field_codes.iter() {
        cmd = cmd.replace(code, "");
    }
    
    // Return the cleaned command
    Some(cmd.trim().to_string())
}

// Function to check if an app is installed
fn is_app_installed(app_name: &str) -> bool {
    // Check the cache first
    let cache = get_app_cache();
    
    // Try to get a lock on the cache
    if let Ok(cache) = cache.try_lock() {
        // If the app is in the cache, it's installed
        if cache.contains(app_name) {
            return true;
        }
    }
    
    // Try multiple detection methods
    let is_installed = check_app_installed_multiple_ways(app_name);
    
    // If it's installed, add it to the cache
    if is_installed {
        if let Ok(mut cache) = cache.try_lock() {
            cache.insert(app_name.to_string());
        }
    }
    
    is_installed
}

fn check_app_installed_multiple_ways(app_name: &str) -> bool {
    // Method 1: Check with `which` command
    let which_check = Command::new("which")
        .arg(app_name)
        .output()
        .map(|output| output.status.success())
        .unwrap_or(false);
    
    if which_check {
        return true;
    }
    
    // Method 2: Check if desktop file exists
    let home = std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        });
    
    let desktop_dirs = [
        PathBuf::from("/usr/share/applications"),
        PathBuf::from("/usr/local/share/applications"),
        home.join(".local/share/applications"),
    ];
    
    let desktop_file = format!("{}.desktop", app_name.to_lowercase());
    
    for dir in desktop_dirs.iter() {
        if dir.join(&desktop_file).exists() {
            return true;
        }
    }
    
    false
}

// Function to find a toast overlay in the widget hierarchy
fn find_toast_overlay(widget: &gtk::Widget) -> Option<libadwaita::ToastOverlay> {
    // Check if this widget is a ToastOverlay
    if let Some(overlay) = widget.downcast_ref::<libadwaita::ToastOverlay>() {
        return Some(overlay.clone());
    }
    
    // If it's a container, check its children
    if let Some(container) = widget.downcast_ref::<gtk::Widget>() {
        // Try to get the first child
        if let Some(child) = container.first_child() {
            // Recursively check this child
            if let Some(overlay) = find_toast_overlay(&child) {
                return Some(overlay);
            }
            
            // Check siblings
            let mut sibling = child.next_sibling();
            while let Some(sib) = sibling {
                if let Some(overlay) = find_toast_overlay(&sib) {
                    return Some(overlay);
                }
                sibling = sib.next_sibling();
            }
        }
    }
    
    None
}

// Function to load the Hyprland page incrementally
fn load_hyprland_page_incrementally(page: &gtk::Box, spinner_box: &gtk::Box) {
    // Step 1: Read the config file in a separate idle callback
    let page_clone = page.clone();
    let spinner_box_clone = spinner_box.clone();
    
    gtk::glib::idle_add_local_once(move || {
        // Get the path to the keybinds.conf file
        let config_path = get_keybinds_path();
        
        // Read current configuration
        let config_content = match fs::read_to_string(&config_path) {
            Ok(content) => content,
            Err(e) => {
                eprintln!("Error reading config file: {}", e);
                String::new()
            }
        };
        
        // Step 2: Parse the configuration in another idle callback
        let page_clone2 = page_clone.clone();
        let spinner_box_clone2 = spinner_box_clone.clone();
        let config_path_clone = config_path.clone();
        
        gtk::glib::idle_add_local_once(move || {
            // Parse the configuration to find default apps
            let default_apps = parse_default_apps(&config_content);
            
            // Step 3: Build the UI incrementally
            build_hyprland_page_incrementally(
                &page_clone2, 
                &spinner_box_clone2, 
                &default_apps, 
                &config_path_clone, 
                &config_content
            );
        });
    });
}

// Function to get the path to the keybindings.conf file
fn get_keybinds_path() -> PathBuf {
    let home = std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        });
    
    // Check for the keybindings file in common locations
    let possible_paths = [
        home.join(".config/hypr/keybindings.conf"),
        home.join(".config/hypr/keybinds.conf"),
        home.join(".config/hypr/configs/keybinds.conf"),
        home.join(".config/hypr/configs/binds.conf"),
        home.join(".config/hypr/hyprland.conf"), // Fallback to main config
    ];
    
    for path in possible_paths.iter() {
        if path.exists() {
            return path.clone();
        }
    }
    
    // Default to keybindings.conf if none found
    home.join(".config/hypr/keybindings.conf")
}

// Function to parse default apps from the config file
fn parse_default_apps(config_content: &str) -> HashMap<String, String> {
    let mut default_apps = HashMap::new();
    let mut current_app_type = String::new();
    let mut in_apps_section = false;
    
    // First try to find the managed section (marked with ##### delimiters)
    let mut in_managed_section = false;
    let mut managed_section_found = false;
    
    // Parse the config line by line
    for line in config_content.lines() {
        let trimmed = line.trim();
        
        // Check for managed section markers
        if trimmed.starts_with("#####") {
            if !in_managed_section {
                in_managed_section = true;
                managed_section_found = true;
                continue;
            } else {
                in_managed_section = false;
                break; // We've processed the entire managed section
            }
        }
        
        // Skip if we're not in the managed section yet
        if managed_section_found && !in_managed_section {
            continue;
        }
        
        // Check for comments that indicate app types
        if trimmed.starts_with("## ") {
            current_app_type = trimmed.trim_start_matches("## ").trim().to_string();
            continue;
        }
        
        // Check for the APPS section if we're not in managed mode
        if !managed_section_found && trimmed.starts_with("# APPS") {
            in_apps_section = true;
            continue;
        }
        
        // If we're not in any recognized section, skip
        if !managed_section_found && !in_apps_section {
            continue;
        }
        
        // Check for new section (ending APPS section)
        if !managed_section_found && in_apps_section && trimmed.starts_with('#') && !trimmed.starts_with("##") {
            in_apps_section = false;
            continue;
        }
        
        // Look for bind lines that define apps
        if (managed_section_found || in_apps_section) && 
           !current_app_type.is_empty() && 
           trimmed.starts_with("bind = ") && 
           trimmed.contains(", exec, ") {
            
            // Extract the command part
            let parts: Vec<&str> = trimmed.split(", exec, ").collect();
            if parts.len() >= 2 {
                let command = parts[1].trim().to_string();
                default_apps.insert(current_app_type.clone(), command);
            }
        }
    }
    
    default_apps
}

// Function to find keybinding for an app type
fn find_keybinding_for_app_type(app_type: &str, config_content: &str) -> String {
    let mut in_managed_section = false;
    let mut found_app_comment = false;
    
    // First check the managed section marked with #####
    for line in config_content.lines() {
        let trimmed = line.trim();
        
        // Check for section markers (lines with multiple #)
        if trimmed.starts_with("#####") {
            if !in_managed_section {
                // Found the start marker
                in_managed_section = true;
                continue;
            } else {
                // Found the end marker - exit the managed section
                break;
            }
        }
        
        // Skip if we're not in the managed section yet
        if !in_managed_section {
            continue;
        }
        
        // Check if we've found the app type comment
        if trimmed == format!("## {}", app_type) {
            found_app_comment = true;
            continue;
        }
        
        // If we found the app comment, the next bind line contains the keybinding
        if found_app_comment && trimmed.starts_with("bind = ") {
            // Extract the key binding part
            let parts: Vec<&str> = trimmed.split(", exec, ").collect();
            if parts.len() >= 1 {
                let key_parts: Vec<&str> = parts[0].split(", ").collect();
                if key_parts.len() >= 2 {
                    // Return everything after "bind = "
                    return parts[0].trim_start_matches("bind = ").to_string();
                }
            }
            break;
        }
    }
    
    // Fallback to the old method if not found in the managed section
    in_managed_section = false;
    found_app_comment = false;
    
    for line in config_content.lines() {
        let trimmed = line.trim();
        
        // Check if we're in the APPS section
        if trimmed.starts_with("# APPS") && (trimmed.contains("Managed") || trimmed.contains("managed")) {
            in_managed_section = true;
            continue;
        }
        
        // Skip if we're not in the APPS section yet
        if !in_managed_section {
            continue;
        }
        
        // Check if we've moved past the APPS section
        if trimmed.starts_with("#") && !trimmed.starts_with("##") && trimmed != "# APPS" {
            break;
        }
        
        // Check if we've found the app type comment
        if trimmed == format!("## {}", app_type) {
            found_app_comment = true;
            continue;
        }
        
        // If we found the app comment, the next bind line contains the keybinding
        if found_app_comment && trimmed.starts_with("bind = ") {
            // Extract the key binding part
            let parts: Vec<&str> = trimmed.split(", exec, ").collect();
            if parts.len() >= 1 {
                let key_parts: Vec<&str> = parts[0].split(", ").collect();
                if key_parts.len() >= 2 {
                    // Return everything after "bind = "
                    return parts[0].trim_start_matches("bind = ").to_string();
                }
            }
            break;
        }
    }
    
    // Return default keybinding if not found, using $mainMOD for better display
    match app_type {
        "File Manager" => "$mainMod, E".to_string(),
        "Browser" => "$mainMod SHIFT, B".to_string(),
        "Text Editor" => "$mainMod CTRL SHIFT, T".to_string(),
        "Video Player" => "$mainMod ALT, M".to_string(),
        "Music Player" => "$mainMod SHIFT, M".to_string(),
        "Photo Viewer" => "$mainMod SHIFT, P".to_string(),
        "Task Manager" => "CTRL SHIFT, ESCAPE".to_string(),
        "Terminal Emulator" => "$mainMod, Return".to_string(),
        _ => "$mainMod, F10".to_string(),
    }
}

// Function to format keybinding for display
fn format_keybinding(keybinding: &str) -> String {
    // Try to find the mainmod value in the Hyprland config
    let mainmod = find_mainmod_value();
    
    // Handle the case where the entire keybinding is just $mainMod
    if keybinding.trim() == "$mainMod" {
        return mainmod;
    }
    
    // Split by commas and spaces to handle all possible formats
    let mut formatted_parts: Vec<String> = Vec::new();
    
    // First handle the case where we have comma-separated parts
    for part in keybinding.split(',') {
        let trimmed_part = part.trim();
        
        // Handle parts that might contain multiple modifiers with spaces
        let mut has_mainmod = false;
        
        // Check if this part contains any form of $mainMod
        if trimmed_part.contains("$mainMod") || 
           trimmed_part.contains("$mainmod") || 
           trimmed_part.contains("$MAINMOD") || 
           trimmed_part.contains("$mod") {
            has_mainmod = true;
            
            // Add the actual mainmod value if not already present
            if !formatted_parts.contains(&mainmod) {
                formatted_parts.push(mainmod.clone());
            }
        }
        
        // Process other modifiers in this part
        for word in trimmed_part.split_whitespace() {
            let processed_word = match word.trim() {
                "$mainMod" | "$mainmod" | "$MAINMOD" | "$mod" => continue, // Skip as we've already handled this
                "SUPER" => "Super".to_string(),
                "SHIFT" => "Shift".to_string(),
                "CTRL" => "Ctrl".to_string(),
                "ALT" => "Alt".to_string(),
                "Return" => "Enter".to_string(),
                "ESCAPE" => "Esc".to_string(),
                "SUPER_L" => "Super".to_string(),
                other => other.to_string(),
            };
            
            if !processed_word.is_empty() && !formatted_parts.contains(&processed_word) {
                formatted_parts.push(processed_word);
            }
        }
        
        // If this part had no recognized content and wasn't just a mainmod variant, add it as is
        if formatted_parts.is_empty() && !has_mainmod && !trimmed_part.is_empty() {
            formatted_parts.push(trimmed_part.to_string());
        }
    }
    
    // Join all parts with + symbol
    if formatted_parts.is_empty() {
        // Fallback in case we couldn't parse anything
        return keybinding.replace(',', "+").replace("$mainMod", &mainmod);
    } else {
        return formatted_parts.join("+");
    }
}

// Function to find the value of mainmod in Hyprland config
fn find_mainmod_value() -> String {
    // Return the cached value if available
    if let Some(value) = MAINMOD_CACHE.get() {
        return value.clone();
    }
    
    // Default value if we can't find the actual value
    let default_value = "Super".to_string();
    
    // Try to read the Hyprland config file
    let home_dir = match dirs::home_dir() {
        Some(path) => path,
        None => {
            let _ = MAINMOD_CACHE.set(default_value.clone());
            return default_value;
        },
    };
    
    // Check common locations for the Hyprland config
    let config_paths = [
        home_dir.join(".config/hypr/hyprland.conf"),
        home_dir.join(".config/hypr/keybinds.conf"),
        home_dir.join(".config/hypr/configs/keybinds.conf"),
        home_dir.join(".config/hypr/configs/binds.conf"),
        home_dir.join(".config/hypr/configs/config.conf"),
        home_dir.join(".config/hypr/configs/variables.conf"),
        home_dir.join(".config/hypr/configs/default.conf"),
        home_dir.join(".config/hypr/configs/settings.conf"),
    ];
    
    // Different variable name patterns to check
    let variable_patterns = [
        "$mainMod", "$mainmod", "$mod", "$MAIN_MOD", "$main_mod", 
        "$MAINMOD", "$Mod", "$MOD", "mainMod", "mainmod", "MODKEY"
    ];
    
    // First try to find the exact variable definition
    for path in &config_paths {
        if let Ok(content) = std::fs::read_to_string(path) {
            // Look for all possible variable definitions
            for line in content.lines() {
                let trimmed = line.trim();
                
                // Check for any of our variable patterns
                for &pattern in &variable_patterns {
                    if trimmed.starts_with(pattern) && trimmed.contains('=') {
                        let equals_pos = trimmed.find('=').unwrap();
                        let value = trimmed[equals_pos+1..].trim();
                        
                        // Convert the value to a more readable format
                        let result = match value.to_uppercase().as_str() {
                            "SUPER" => "Super".to_string(),
                            "ALT" => "Alt".to_string(),
                            "CTRL" | "CONTROL" => "Ctrl".to_string(),
                            "SHIFT" => "Shift".to_string(),
                            "META" => "Meta".to_string(),
                            _ => value.to_string(),
                        };
                        
                        // Cache the result
                        let _ = MAINMOD_CACHE.set(result.clone());
                        return result;
                    }
                }
            }
        }
    }
    
    // If we couldn't find an explicit definition, check bind lines to infer the value
    for path in &config_paths {
        if let Ok(content) = std::fs::read_to_string(path) {
            for line in content.lines() {
                let trimmed = line.trim();
                
                // Look for the most common keybinding patterns
                if trimmed.starts_with("bind = ") {
                    // Check for usage of our variable patterns
                    for &pattern in &variable_patterns {
                        if trimmed.contains(pattern) {
                            // We found a line using a variable, assume it's SUPER by default
                            let _ = MAINMOD_CACHE.set("Super".to_string());
                            return "Super".to_string();
                        }
                    }
                    
                    // Also check for direct SUPER usage in bind lines
                    if trimmed.contains("SUPER") || trimmed.contains("Super") {
                        let _ = MAINMOD_CACHE.set("Super".to_string());
                        return "Super".to_string();
                    }
                }
            }
        }
    }
    
    // If we couldn't find it, cache and return the default value
    let _ = MAINMOD_CACHE.set(default_value.clone());
    default_value
}

// Function to build the Hyprland page UI incrementally
fn build_hyprland_page_incrementally(
    page: &gtk::Box, 
    spinner_box: &gtk::Box, 
    default_apps: &HashMap<String, String>, 
    config_path: &PathBuf, 
    config_content: &str
) {
    // Remove the spinner
    page.remove(spinner_box);
    
    // Add description
    let description = gtk::Label::new(Some("Configure default applications launched by keyboard shortcuts in Hyprland."));
    description.add_css_class("subtitle");
    description.set_halign(gtk::Align::Start);
    description.set_margin_bottom(20);
    page.append(&description);
    
    // Create a section for each app type
    create_app_section(page, "Terminal Emulator", default_apps, config_path, config_content);
    create_app_section(page, "File Manager", default_apps, config_path, config_content);
    create_app_section(page, "Browser", default_apps, config_path, config_content);
    create_app_section(page, "Text Editor", default_apps, config_path, config_content);
    create_app_section(page, "Video Player", default_apps, config_path, config_content);
    create_app_section(page, "Music Player", default_apps, config_path, config_content);
    create_app_section(page, "Photo Viewer", default_apps, config_path, config_content);
    create_app_section(page, "Task Manager", default_apps, config_path, config_content);
}

// Function to update default app in config
fn update_default_app(config_path: &PathBuf, config_content: &str, app_type: &str, new_command: &str) {
    let mut new_content = String::new();
    let mut found = false;
    let mut current_comment = String::new();
    let mut in_managed_section = false;
    
    // First, find the managed section
    let lines: Vec<&str> = config_content.lines().collect();
    
    // Track the beginning and end of the managed section
    let mut managed_start_index = 0;
    let mut managed_end_index = lines.len();
    
    // Find the managed section boundaries
    for (i, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        
        if trimmed.starts_with("#####") {
            if !in_managed_section {
                in_managed_section = true;
                managed_start_index = i;
            } else {
                managed_end_index = i;
                break;
            }
        }
    }
    
    // If no managed section found, use the whole file
    if !in_managed_section {
        managed_start_index = 0;
        managed_end_index = lines.len();
    }
    
    // Build the new content with the update in the managed section
    for (i, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        
        // Track comments to identify app sections
        if i >= managed_start_index && i <= managed_end_index && trimmed.starts_with("## ") {
            current_comment = trimmed.trim_start_matches("## ").trim().to_string();
        }
        
        // Check if this is the line for the app type we want to update
        if i >= managed_start_index && i <= managed_end_index && 
           current_comment == app_type && 
           trimmed.starts_with("bind = ") && 
           trimmed.contains(", exec, ") {
            // This is the line we want to update
            let bind_parts: Vec<&str> = trimmed.split(", exec, ").collect();
            if bind_parts.len() >= 2 {
                // Keep the keybinding part but update the command
                let new_line = format!("{}, exec, {}", bind_parts[0], new_command);
                    new_content.push_str(&new_line);
                    new_content.push('\n');
                found = true;
                    continue;
            }
        }
        
        // Keep all other lines as they are
        new_content.push_str(line);
        new_content.push('\n');
    }
    
    // If we didn't find the app in the config, add it to the managed section
    if !found {
        // Keep the original $mainMod reference for the default keybindings
        let default_keybind = match app_type {
            "Terminal Emulator" => "$mainMod, Return",
            "File Manager" => "$mainMod, E",
            "Browser" => "$mainMod SHIFT, B",
            "Text Editor" => "$mainMod CTRL SHIFT, T",
            "Video Player" => "$mainMod ALT, M",
            "Music Player" => "$mainMod SHIFT, M",
            "Photo Viewer" => "$mainMod SHIFT, P",
            "Task Manager" => "CTRL SHIFT, ESCAPE",
            _ => "$mainMod, F10", // Default fallback
        };
        
        // If managed section was found, add it there
        if in_managed_section {
            // Create new content with our addition in the right place
            let mut updated_content = String::new();
            let mut added = false;
            
            for (i, line) in lines.iter().enumerate() {
                // If we're at the end of the managed section and haven't added yet
                if i == managed_end_index && !added {
                    // Add the new app section right before the end marker
                    updated_content.push_str(&format!("## {}\n", app_type));
                    updated_content.push_str(&format!("bind = {}, exec, {}\n", default_keybind, new_command));
                    added = true;
                }
                
                // Add the current line
                updated_content.push_str(line);
                updated_content.push('\n');
            }
            
            new_content = updated_content;
        } else {
            // No managed section, create one
            new_content.push_str("\n#####################################################\n");
            new_content.push_str("# APPS - Managed By User & Scripts\n");
            new_content.push_str(&format!("## {}\n", app_type));
            new_content.push_str(&format!("bind = {}, exec, {}\n", default_keybind, new_command));
            new_content.push_str("#####################################################\n");
        }
    }
    
    // Save the updated config
    if let Ok(original_content) = fs::read_to_string(config_path) {
        if original_content != new_content {
            // Create a backup of the original file
            let backup_path = config_path.with_extension("conf.bak");
            let _ = fs::write(&backup_path, &original_content);
            
            // Write the new content
            if let Err(e) = fs::write(config_path, new_content) {
                eprintln!("Error writing to config file: {}", e);
            }
        }
    }
}

// Function to get installed apps by type
fn get_installed_apps_by_type(app_type: &str) -> Vec<AppInfo> {
    // Initialize the desktop files cache if needed
    let mut desktop_files = Vec::new();
    let mut processed_files: HashSet<String> = HashSet::new();
    
    let home = std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        });
    
    // Define all directories to scan
    let all_dirs = [
        // Standard locations
        PathBuf::from("/usr/share/applications"),
        home.join(".local/share/applications"),
    ];
    
    // Scan for desktop files
    for dir in all_dirs.iter().filter(|dir| dir.exists()) {
        scan_directory_for_desktop_files_optimized(dir, &mut desktop_files, &mut processed_files);
    }
    
    // Create a list of app info entries
    let mut apps = Vec::new();
    let mut processed_app_names = HashSet::new();
    
    for (_, content) in desktop_files {
        // Check if this app matches our type
        if is_app_matching_type(&content, app_type) {
            let name = extract_desktop_entry(&content, "Name");
            let exec = extract_desktop_entry(&content, "Exec");
            let no_display = extract_desktop_entry(&content, "NoDisplay").to_lowercase();
            let hidden = extract_desktop_entry(&content, "Hidden").to_lowercase();
            
            // Skip hidden/no-display apps
            if no_display == "true" || hidden == "true" {
                continue;
            }
            
            // Skip if name or exec is empty
            if name.is_empty() || exec.is_empty() {
                continue;
            }
            
            // Skip duplicate app names
            if processed_app_names.contains(&name) {
                continue;
            }
            
            if let Some(cmd) = clean_exec_command(&exec) {
                processed_app_names.insert(name.clone());
                
                // Add the app
                apps.push(AppInfo {
                    name,
                    command: cmd,
                    comment: extract_desktop_entry(&content, "Comment"),
                });
            }
        }
    }
    
    // Sort apps by name
    apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    
    // If no apps were found, add a placeholder
    if apps.is_empty() {
        apps.push(AppInfo {
            name: "No apps found".to_string(),
            command: "".to_string(),
            comment: app_type.to_string(),
        });
    }
    
    apps
}

// Function to check if an app matches a specific type based on its desktop file content
fn is_app_matching_type(content: &str, app_type: &str) -> bool {
    // Skip NoDisplay and Hidden apps
    let no_display = extract_desktop_entry(content, "NoDisplay").to_lowercase();
    let hidden = extract_desktop_entry(content, "Hidden").to_lowercase();
    
    if no_display == "true" || hidden == "true" {
        return false;
    }
    
    // Get categories from desktop file
    let categories = extract_desktop_entry(content, "Categories").to_lowercase();
    
    // First check for exact categories match
    match app_type {
        "Browser" => {
            if categories.contains("browser") || categories.contains("webbrowser") {
                return true;
            }
            
            // Additional browser checks
            let exec = extract_desktop_entry(content, "Exec").to_lowercase();
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            
            return name.contains("browser") || name.contains("firefox") || 
                   name.contains("chrome") || name.contains("chromium") || 
                   exec.contains("firefox") || exec.contains("chrome");
        },
        "File Manager" => {
            if categories.contains("filemanager") || categories.contains("file-manager") {
                return true;
            }
            
            // Additional file manager checks
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("file") && (name.contains("manager") || name.contains("browser"));
        },
        "Text Editor" => {
            if categories.contains("texteditor") || categories.contains("text-editor") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("text") && name.contains("editor");
        },
        "Video Player" => {
            if categories.contains("video") || categories.contains("player") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("video") || name.contains("player") || 
                   name.contains("mpv") || name.contains("vlc");
        },
        "Music Player" => {
            if categories.contains("audio") || categories.contains("music") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("music") || name.contains("audio") || 
                   name.contains("player");
        },
        "Photo Viewer" => {
            if categories.contains("graphics") || categories.contains("viewer") || 
               categories.contains("image") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("image") || name.contains("photo") || 
                   name.contains("picture") || name.contains("viewer");
        },
        "Terminal Emulator" => {
            if categories.contains("terminal") || categories.contains("term") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("terminal") || name.contains("term") ||
                   name.contains("console");
        },
        "Task Manager" => {
            if categories.contains("monitor") || categories.contains("system") {
                return true;
            }
            
            let name = extract_desktop_entry(content, "Name").to_lowercase();
            return name.contains("task") || name.contains("process") || 
                   name.contains("system") || name.contains("monitor");
        },
        _ => false,
    }
}

// Function to create a section for an app type in the Hyprland page
fn create_app_section(
    container: &gtk::Box, 
    app_type: &str, 
    default_apps: &HashMap<String, String>, 
    config_path: &PathBuf, 
    config_content: &str
) {
    // Get current default app for this type (if any)
    let current_app = default_apps.get(app_type).cloned().unwrap_or_default();
    let current_app_clone = current_app.clone();
    
    // Create a preference group for this app type
    let group = libadwaita::PreferencesGroup::new();
    group.set_title(app_type);
    group.set_margin_top(8);
    group.set_margin_bottom(8);
    
    // Create action row for app selection with dropdown
    let dropdown_row = libadwaita::ActionRow::new();
    dropdown_row.set_title("Application");
    dropdown_row.set_height_request(48);
    dropdown_row.set_activatable(false);
    
    // Get the available apps for this type
    let apps = get_installed_apps_by_type(app_type);
    
    // Create dropdown for app selection
    let dropdown = gtk::DropDown::new(None::<gtk::StringList>, None::<gtk::Expression>);
    let string_list = gtk::StringList::new(&[]);
    
    // Add apps to the dropdown
    for app in &apps {
        string_list.append(&app.name);
    }
    
    dropdown.set_model(Some(&string_list));
    dropdown.set_hexpand(true);
    dropdown.set_valign(gtk::Align::Center);
    dropdown.set_vexpand(false);
    dropdown.set_margin_start(4);
    dropdown.set_margin_end(4);
    
    // Set the current selection
    let mut found_current = false;
    for (i, app) in apps.iter().enumerate() {
        if app.command == current_app || 
           app.command.split_whitespace().next().unwrap_or("") == current_app.split_whitespace().next().unwrap_or("") {
            dropdown.set_selected(i as u32);
            found_current = true;
            break;
        }
    }
    
    // If current app not found in dropdown, add it as a custom option
    if !found_current && !current_app.is_empty() {
        // Add the current custom app to the dropdown
        let app_name = current_app.split_whitespace().next().unwrap_or(&current_app).to_string();
        string_list.append(&format!("Custom: {}", app_name));
        dropdown.set_selected((apps.len()) as u32);
    }
    
    // Create test button for dropdown row
    let test_button = gtk::Button::new();
    test_button.set_icon_name("media-playback-start-symbolic");
    test_button.set_tooltip_text(Some("Test this application"));
    test_button.add_css_class("flat");
    test_button.set_valign(gtk::Align::Center);
    test_button.set_vexpand(false);
    test_button.set_margin_start(4);
    test_button.set_margin_end(4);
    
    // Create custom command row
    let custom_row = libadwaita::ActionRow::new();
    custom_row.set_title("Custom Command");
    custom_row.set_height_request(48);
    custom_row.set_activatable(false);
    
    // Create custom command entry
    let custom_entry = gtk::Entry::new();
    custom_entry.set_hexpand(true);
    custom_entry.set_valign(gtk::Align::Center);
    custom_entry.set_vexpand(false);
    if !found_current && !current_app.is_empty() {
        custom_entry.set_text(&current_app);
    } else {
        // Default placeholder
        custom_entry.set_placeholder_text(Some("Enter custom command (e.g., firefox)"));
    }
    
    // Create command check status icon that shows command availability
    let status_icon = gtk::Image::new();
    status_icon.add_css_class("dim-label");
    status_icon.set_tooltip_text(Some("Command availability not checked"));
    status_icon.set_icon_name(Some("dialog-question-symbolic"));
    status_icon.set_valign(gtk::Align::Center);
    status_icon.set_margin_start(4);
    status_icon.set_margin_end(4);
    
    // Create custom command test button (play icon)
    let custom_test_button = gtk::Button::new();
    custom_test_button.set_icon_name("media-playback-start-symbolic");
    custom_test_button.set_tooltip_text(Some("Test this custom command"));
    custom_test_button.add_css_class("flat");
    custom_test_button.set_valign(gtk::Align::Center);
    custom_test_button.set_vexpand(false);
    custom_test_button.set_margin_start(4);
    custom_test_button.set_margin_end(4);
    
    // Create save button (tick)
    let custom_save_button = Rc::new(gtk::Button::new());
    custom_save_button.set_icon_name("object-select-symbolic");
    custom_save_button.set_tooltip_text(Some("Save this custom command"));
    custom_save_button.add_css_class("flat");
    custom_save_button.set_valign(gtk::Align::Center);
    custom_save_button.set_vexpand(false);
    custom_save_button.set_margin_start(4);
    custom_save_button.set_margin_end(4);
    
    // Initially disable the save button until custom command mode is active
    custom_save_button.set_sensitive(false);
    
    // Connect custom test button to run the command
    let custom_entry_for_test = custom_entry.clone();
    custom_test_button.connect_clicked(move |_| {
        let command = custom_entry_for_test.text().to_string();
        if !command.is_empty() {
            let _ = Command::new("sh")
                .arg("-c")
                .arg(&command)
                .spawn();
        }
    });
    
    // Create custom command checkbox (enable/disable)
    let custom_checkbox = gtk::CheckButton::new();
    custom_checkbox.set_tooltip_text(Some("When activated, this command will be used always to run from this keybinding"));
    custom_checkbox.set_valign(gtk::Align::Center);
    custom_checkbox.set_margin_start(4);
    custom_checkbox.set_margin_end(4);
    
    // Add checkbox and entry to the custom row
    custom_row.add_prefix(&custom_checkbox);
    custom_row.add_suffix(&status_icon);
    custom_row.add_suffix(&custom_test_button);
    custom_row.add_suffix(&*custom_save_button);
    custom_row.add_suffix(&custom_entry);
    
    // Set checkbox state based on if we're using a custom command
    if !found_current && !current_app.is_empty() {
        custom_checkbox.set_active(true);
        custom_entry.set_sensitive(true);
        dropdown_row.set_sensitive(false);  // Hide dropdown initially
        dropdown_row.set_visible(false);
        
        // Check command availability for the initial custom command
        let cmd = current_app.split_whitespace().next().unwrap_or("").to_string();
        if !cmd.is_empty() {
            // Check if command exists
            let exists = Command::new("which")
                .arg(&cmd)
                .output()
                .map(|output| output.status.success())
                .unwrap_or(false);
            
            if exists {
                status_icon.set_icon_name(Some("object-select-symbolic"));
                status_icon.set_tooltip_text(Some("Command is available in the system"));
                status_icon.add_css_class("success");
                status_icon.remove_css_class("warning");
            } else {
                status_icon.set_icon_name(Some("dialog-warning-symbolic"));
                status_icon.set_tooltip_text(Some("Command not found in PATH"));
                status_icon.add_css_class("warning");
                status_icon.remove_css_class("success");
            }
        }
    } else {
        custom_checkbox.set_active(false);
        custom_entry.set_sensitive(false);
        dropdown_row.set_sensitive(true);  // Show dropdown initially
        dropdown_row.set_visible(true);
    }
    
    // Add buttons and dropdown to the dropdown row
    dropdown_row.add_prefix(&test_button);
    dropdown_row.add_suffix(&dropdown);
    
    // Connect checkbox to enable/disable entry and show/hide dropdown
    let custom_entry_for_toggle = custom_entry.clone();
    let dropdown_row_for_toggle = dropdown_row.clone();
    let status_icon_for_toggle = status_icon.clone();
    custom_checkbox.connect_toggled(move |checkbox| {
        let is_active = checkbox.is_active();
        custom_entry_for_toggle.set_sensitive(is_active);
        dropdown_row_for_toggle.set_sensitive(!is_active);
        dropdown_row_for_toggle.set_visible(!is_active);
        
        // Check command availability when checkbox is toggled on
        if is_active {
            let command = custom_entry_for_toggle.text().to_string();
            if !command.is_empty() {
                let cmd = command.split_whitespace().next().unwrap_or("").to_string();
                if cmd.is_empty() {
                    status_icon_for_toggle.set_icon_name(Some("dialog-warning-symbolic"));
                    status_icon_for_toggle.set_tooltip_text(Some("No command specified"));
                    status_icon_for_toggle.remove_css_class("success");
                    status_icon_for_toggle.add_css_class("warning");
                    return;
                }
                
                // Check if command exists
                let exists = Command::new("which")
                    .arg(&cmd)
                    .output()
                    .map(|output| output.status.success())
                    .unwrap_or(false);
                
                if exists {
                    status_icon_for_toggle.set_icon_name(Some("object-select-symbolic"));
                    status_icon_for_toggle.set_tooltip_text(Some("Command is available in the system"));
                    status_icon_for_toggle.add_css_class("success");
                    status_icon_for_toggle.remove_css_class("warning");
                } else {
                    status_icon_for_toggle.set_icon_name(Some("dialog-warning-symbolic"));
                    status_icon_for_toggle.set_tooltip_text(Some("Command not found in PATH"));
                    status_icon_for_toggle.add_css_class("warning");
                    status_icon_for_toggle.remove_css_class("success");
                }
            }
        }
    });
    
    // Clone apps for button closure
    let apps_clone = apps.clone();
    let current_app_for_button = current_app_clone.clone();
    
    // Connect test button to launch the app from dropdown
    let dropdown_for_test = dropdown.clone();
    let apps_for_test = apps_clone.clone();
    let current_app_for_test = current_app_for_button.clone();
    test_button.connect_clicked(move |_| {
        // Get the selected item from dropdown
        let selected = dropdown_for_test.selected();
        
        let command = if selected < apps_for_test.len() as u32 {
            // Use command from the selected app
            apps_for_test[selected as usize].command.clone()
        } else {
            // Use the custom command if available
            current_app_for_test.clone()
        };
        
        if !command.is_empty() {
            println!("Launching command: {}", command);
            
            // Launch the application asynchronously in a separate thread
            let command_clone = command.clone();
            std::thread::spawn(move || {
                let _ = Command::new("sh")
                    .arg("-c")
                    .arg(&command_clone)
                    .spawn();
            });
        }
    });
    
    // Connect dropdown to update config
    let app_type_clone = app_type.to_string();
    let config_path_clone = config_path.clone();
    let config_content_clone = config_content.to_string();
    let apps_clone = apps.clone();
    let custom_entry_clone = custom_entry.clone();
    let custom_checkbox_clone = custom_checkbox.clone();
    
    dropdown.connect_selected_notify(move |dropdown| {
        // Skip updating if custom command is enabled
        if custom_checkbox_clone.is_active() {
            return;
        }
        
        let selected = dropdown.selected();
        let new_command = if selected < apps_clone.len() as u32 {
            // Use command from the selected app
            apps_clone[selected as usize].command.clone()
        } else {
            // Keep the custom command
            current_app_clone.clone()
        };
        
        // Update the config file
        update_default_app(&config_path_clone, &config_content_clone, &app_type_clone, &new_command);
        
        // Also update the custom entry to match the selected command
        custom_entry_clone.set_text(&new_command);
        
        // Show a toast notification
        if let Some(root) = dropdown.root().and_then(|r| r.downcast::<gtk::Window>().ok()) {
            // Get app name from dropdown
            let app_name = if selected < apps_clone.len() as u32 {
                apps_clone[selected as usize].name.clone()
            } else {
                format!("Custom app: {}", new_command.split_whitespace().next().unwrap_or(&new_command))
            };
            
            let toast = libadwaita::Toast::new(&format!("Default {} updated to {}", app_type_clone.to_lowercase(), app_name));
            toast.set_timeout(2);
            
            if let Some(overlay) = find_toast_overlay(root.upcast_ref::<gtk::Widget>()) {
                overlay.add_toast(toast);
            }
        }
    });
    
    // Connect custom entry to update config when custom command is active
    let app_type_clone = app_type.to_string();
    let config_path_clone = config_path.clone();
    let config_content_clone = config_content.to_string();
    let custom_checkbox_clone = custom_checkbox.clone();
    let status_icon_for_entry = status_icon.clone();
    
    custom_entry.connect_changed(move |entry| {
        // Only validate availability; actual saving is done via tick button.
        if !custom_checkbox_clone.is_active() {
            return;
        }
        let command = entry.text().to_string();
        if command.is_empty() {
            status_icon_for_entry.set_icon_name(Some("dialog-warning-symbolic"));
            status_icon_for_entry.set_tooltip_text(Some("No command specified"));
            status_icon_for_entry.remove_css_class("success");
            status_icon_for_entry.add_css_class("warning");
            return;
        }
        let cmd = command.split_whitespace().next().unwrap_or("");
        let exists = Command::new("which")
            .arg(cmd)
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);
        if exists {
            status_icon_for_entry.set_icon_name(Some("object-select-symbolic"));
            status_icon_for_entry.set_tooltip_text(Some("Command is available in the system"));
            status_icon_for_entry.add_css_class("success");
            status_icon_for_entry.remove_css_class("warning");
        } else {
            status_icon_for_entry.set_icon_name(Some("dialog-warning-symbolic"));
            status_icon_for_entry.set_tooltip_text(Some("Command not found in PATH"));
            status_icon_for_entry.add_css_class("warning");
            status_icon_for_entry.remove_css_class("success");
        }
    });
    
    // Connect checkbox to update config when toggled
    let save_btn_toggle = custom_save_button.clone();
    let dropdown_for_chk = dropdown.clone();
    let apps_for_chk = apps.clone();
    let config_path_chk = config_path.clone();
    let config_content_chk = config_content.to_string();
    let app_type_chk = app_type.to_string();
    let custom_entry_chk = custom_entry.clone();
    custom_checkbox.connect_toggled(move |checkbox| {
        let active = checkbox.is_active();
        save_btn_toggle.set_sensitive(active);
        if !active {
            // save current dropdown selection
            let selected = dropdown_for_chk.selected();
            let command = if selected < apps_for_chk.len() as u32 {
                apps_for_chk[selected as usize].command.clone()
            } else {
                custom_entry_chk.text().to_string()
            };
            if !command.is_empty() {
                update_default_app(&config_path_chk, &config_content_chk, &app_type_chk, &command);
            }
        }
    });
    
    // =========================================================
    // Custom save button handler (tick)
    // =========================================================
    let app_type_save = app_type.to_string();
    let config_path_save = config_path.clone();
    let config_content_save = config_content.to_string();
    let custom_entry_save = custom_entry.clone();
    let custom_checkbox_save = custom_checkbox.clone();
    let status_icon_save = status_icon.clone();
    let apps_for_dropdown = apps.clone();
    let dropdown_ref = dropdown.clone();

    custom_save_button.connect_clicked(move |btn| {
        // Only save if custom mode is active
        if !custom_checkbox_save.is_active() {
            return;
        }

        let new_command = custom_entry_save.text().to_string();
        if new_command.trim().is_empty() {
            return;
        }

        // Persist the new command in the Hyprland config
        update_default_app(&config_path_save, &config_content_save, &app_type_save, &new_command);

        // Visually mark as saved / available
        status_icon_save.set_icon_name(Some("object-select-symbolic"));
        status_icon_save.set_tooltip_text(Some("Command saved and available in the system"));
        status_icon_save.add_css_class("success");
        status_icon_save.remove_css_class("warning");

        // Keep dropdown in sync by appending a placeholder custom entry (last item)
        // so that if user later disables custom mode the dropdown has an option.
        if apps_for_dropdown.iter().all(|a| a.command != new_command) {
            let idx = apps_for_dropdown.len() as u32; // custom item index
            dropdown_ref.set_selected(idx);
        }

        // Show toast notification
        if let Some(root) = btn.root().and_then(|r| r.downcast::<gtk::Window>().ok()) {
            let toast = libadwaita::Toast::new(&format!(
                "Custom command saved for {}",
                app_type_save.to_lowercase()
            ));
            toast.set_timeout(2);
            if let Some(overlay) = find_toast_overlay(root.upcast_ref::<gtk::Widget>()) {
                overlay.add_toast(toast);
            }
        }
    });
    
    // Add keybinding info row
    let keybinding_row = libadwaita::ActionRow::new();
    keybinding_row.set_title("Keyboard Shortcut");
    keybinding_row.set_height_request(48);
    keybinding_row.set_activatable(false);
    
    // Get keybinding for this app type
    let keybinding = find_keybinding_for_app_type(app_type, config_content);
    
    // Format the keybinding string
    let formatted_keybinding = format_keybinding(&keybinding);
    
    // Create a styled container for the keybinding
    let keybinding_box = gtk::Box::new(gtk::Orientation::Horizontal, 4);
    keybinding_box.set_halign(gtk::Align::End);
    keybinding_box.set_valign(gtk::Align::Center);
    keybinding_box.set_margin_start(4);
    keybinding_box.set_margin_end(4);
    
    // Split the formatted keybinding by + and create a styled label for each part
    for (i, part) in formatted_keybinding.split('+').enumerate() {
        // Add a + symbol between parts (except before the first part)
        if i > 0 {
            let plus_label = gtk::Label::new(Some("+"));
            plus_label.add_css_class("dim-label");
            keybinding_box.append(&plus_label);
        }
        
        // Create a styled label for the key
        let key_label = gtk::Label::new(Some(part.trim()));
        key_label.add_css_class("keycap");
        key_label.set_margin_start(2);
        key_label.set_margin_end(2);
        keybinding_box.append(&key_label);
    }
    
    // Add the styled keybinding box to the row
    keybinding_row.add_suffix(&keybinding_box);
    
    // Add rows to the group
    group.add(&dropdown_row);
    group.add(&custom_row);
    group.add(&keybinding_row);
    
    // Add the group to the container
    container.append(&group);
    
    // Add separator
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_top(10);
    separator.set_margin_bottom(10);
    container.append(&separator);

    // Save button logic
    let app_type_save = app_type.to_string();
}