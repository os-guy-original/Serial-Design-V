use gtk::{self, prelude::*};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::collections::HashMap;
use libadwaita;
use libadwaita::prelude::*;
use chrono;
use dirs;

// Structure to hold app information
#[derive(Clone)]
struct AppInfo {
    name: String,
    command: String,
    comment: String,
}

// Function to create the default apps tab content
pub fn create_default_apps_content() -> gtk::Widget {
    // Main container
    let content = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content.set_margin_start(20);
    content.set_margin_end(20);
    content.set_margin_top(20);
    content.set_margin_bottom(20);
    
    // Add header
    let header_box = gtk::Box::new(gtk::Orientation::Vertical, 8);
    
    let title = gtk::Label::new(Some("Default Applications"));
    title.add_css_class("title-1");
    title.set_halign(gtk::Align::Start);
    
    let subtitle = gtk::Label::new(Some("Configure your default applications for various tasks. Changes are applied immediately."));
    subtitle.add_css_class("subtitle");
    subtitle.set_halign(gtk::Align::Start);
    
    header_box.append(&title);
    header_box.append(&subtitle);
    content.append(&header_box);
    
    // Create scrollable area
    let scrolled_window = gtk::ScrolledWindow::new();
    scrolled_window.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    scrolled_window.set_vexpand(true);
    
    // Create box for app settings
    let apps_box = gtk::Box::new(gtk::Orientation::Vertical, 15);
    apps_box.set_margin_start(10);
    apps_box.set_margin_end(10);
    apps_box.set_margin_top(10);
    apps_box.set_margin_bottom(10);
    
    // Get the path to the keybinds.conf file
    let config_path = get_keybinds_path();
    
    // Read current configuration
    let config_content = match fs::read_to_string(&config_path) {
        Ok(content) => content,
        Err(e) => {
            println!("Error reading config file: {}", e);
            String::new()
        }
    };
    
    // Parse the configuration to find default apps
    let default_apps = parse_default_apps(&config_content);
    
    // Create UI for each default app
    create_app_settings(&apps_box, "File Manager", "E", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Browser", "B", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Text Editor", "T", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Video Player", "M", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Music Player", "M", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Photo Viewer", "P", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Task Manager", "ESCAPE", &default_apps, &config_path, &config_content);
    create_app_settings(&apps_box, "Terminal Emulator", "Return", &default_apps, &config_path, &config_content);
    
    // Create a button box for the backup button
    let button_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    button_box.set_halign(gtk::Align::Center);
    button_box.set_margin_top(20);
    button_box.set_margin_bottom(20);
    
    // Add a backup button
    let backup_button = gtk::Button::new();
    backup_button.set_label("Backup Configuration");
    backup_button.add_css_class("pill");
    
    // Add button to the box
    button_box.append(&backup_button);
    
    // Connect backup button signal
    let config_path_clone = config_path.clone();
    backup_button.connect_clicked(move |button| {
        let success = create_config_backup(&config_path_clone);
        
        // Show a toast notification
        if let Some(root) = button.root().and_then(|r| r.downcast::<gtk::Window>().ok()) {
            let message = if success {
                "Configuration backed up successfully"
            } else {
                "Failed to create backup"
            };
            
            let toast = libadwaita::Toast::new(message);
            toast.set_timeout(2);
            
            // Try to find an AdwToastOverlay in the widget hierarchy
            if let Some(overlay) = find_toast_overlay(root.upcast_ref::<gtk::Widget>()) {
                overlay.add_toast(toast);
            }
        }
    });
    
    apps_box.append(&button_box);
    
    // Add the apps box to the scrolled window
    scrolled_window.set_child(Some(&apps_box));
    
    // Add scrolled window to the main container
    content.append(&scrolled_window);
    
    content.into()
}

// Function to get the path to the keybinds.conf file
fn get_keybinds_path() -> PathBuf {
    let home = std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        });
    home.join(".config/hypr/configs/keybinds.conf")
}

// Function to parse default apps from config content
fn parse_default_apps(content: &str) -> HashMap<String, AppInfo> {
    let mut apps = HashMap::new();
    let mut current_comment = String::new();
    let mut in_apps_section = false;
    
    for line in content.lines() {
        let trimmed = line.trim();
        
        // Check if we're in the APPS section
        if trimmed == "# APPS - Managed By User & Scripts" {
            in_apps_section = true;
            continue;
        }
        
        // Skip if we're not in the APPS section yet
        if !in_apps_section {
            continue;
        }
        
        // Check if we've moved past the APPS section
        if trimmed.starts_with("# APPS") && !trimmed.contains("Managed By User") {
            break;
        }
        
        // Parse comment lines (app categories)
        if trimmed.starts_with("##") {
            current_comment = trimmed.trim_start_matches("##").trim().to_string();
        } 
        // Parse bind lines (app commands)
        else if trimmed.starts_with("bind = ") && !current_comment.is_empty() {
            // Extract the key and command
            let parts: Vec<&str> = trimmed.split(", exec, ").collect();
            if parts.len() == 2 {
                let key_parts: Vec<&str> = parts[0].split(", ").collect();
                if key_parts.len() >= 2 {
                    let _key = key_parts.last().unwrap().to_string();
                    let command = parts[1].to_string();
                    
                    // Extract app name from command
                    let app_name = command.split_whitespace().next().unwrap_or(&command).to_string();
                    
                    apps.insert(current_comment.clone(), AppInfo {
                        name: app_name,
                        command: command.clone(),
                        comment: current_comment.clone(),
                    });
                }
            }
        }
    }
    
    apps
}

// Function to create UI for app settings
fn create_app_settings(
    container: &gtk::Box, 
    app_type: &str, 
    _key: &str, 
    default_apps: &HashMap<String, AppInfo>,
    config_path: &PathBuf,
    config_content: &str
) {
    // Create a list box for this app type
    let list_box = libadwaita::PreferencesGroup::new();
    list_box.set_title(app_type);
    list_box.set_description(Some(&format!("Choose your default {}", app_type.to_lowercase())));
    
    // Create a row for the dropdown
    let row = libadwaita::ActionRow::new();
    row.set_title("Application");
    
    // Create dropdown for app selection
    let dropdown = gtk::DropDown::new(None::<gtk::StringList>, None::<gtk::Expression>);
    
    // Get installed apps of this type
    let apps = get_installed_apps_by_type(app_type);
    let string_list = gtk::StringList::new(&[]);
    
    // Add apps to the dropdown
    for app in &apps {
        string_list.append(&app.name);
    }
    
    dropdown.set_model(Some(&string_list));
    dropdown.set_hexpand(true);
    
    // Set the current selection
    if let Some(app_info) = default_apps.get(app_type) {
        for (i, app) in apps.iter().enumerate() {
            if app.command.split_whitespace().next().unwrap_or("") == app_info.command.split_whitespace().next().unwrap_or("") {
                dropdown.set_selected(i as u32);
                break;
            }
        }
    }
    
    // Connect signal to update config when selection changes
    let apps_clone = apps.clone();
    let config_path = config_path.clone();
    let config_content = config_content.to_string();
    let app_type_clone = app_type.to_string();
    dropdown.connect_selected_notify(move |dropdown| {
        let selected = dropdown.selected();
        if selected < apps_clone.len() as u32 {
            let selected_app = &apps_clone[selected as usize];
            update_default_app(&config_path, &config_content, &app_type_clone, &selected_app.command);
            
            // Show a toast notification
            if let Some(root) = dropdown.root().and_then(|r| r.downcast::<gtk::Window>().ok()) {
                let toast = libadwaita::Toast::new(&format!("Default {} updated to {}", app_type_clone.to_lowercase(), selected_app.name));
                toast.set_timeout(2);
                
                // Try to find an AdwToastOverlay in the widget hierarchy
                if let Some(overlay) = find_toast_overlay(root.upcast_ref::<gtk::Widget>()) {
                    overlay.add_toast(toast);
                }
            }
        }
    });
    
    // Add dropdown to the row
    row.add_suffix(&dropdown);
    
    // Add the row to the list box
    list_box.add(&row);
    
    // Add the list box to the container
    container.append(&list_box);
    
    // Add separator
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_top(10);
    separator.set_margin_bottom(10);
    container.append(&separator);
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

// Function to get installed apps by type
fn get_installed_apps_by_type(app_type: &str) -> Vec<AppInfo> {
    let mut apps = Vec::new();
    
    // First try to get apps from desktop files
    let desktop_apps = get_apps_from_desktop_files(app_type);
    if !desktop_apps.is_empty() {
        apps.extend(desktop_apps);
    } else {
        // Fallback to hardcoded lists if desktop file scanning fails
        match app_type {
            "File Manager" => {
                // Common file managers
                let file_managers = [
                    ("Nemo", "nemo"),
                    ("Nautilus", "nautilus --new-window"),
                    ("Thunar", "thunar"),
                    ("PCManFM", "pcmanfm"),
                    ("Dolphin", "dolphin"),
                ];
                
                for (name, cmd) in file_managers.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Browser" => {
                // Common browsers
                let browsers = [
                    ("Firefox", "firefox"),
                    ("Chrome", "google-chrome-stable"),
                    ("Chromium", "chromium"),
                    ("Brave", "brave-browser"),
                    ("Vivaldi", "vivaldi-stable"),
                    ("Opera", "opera"),
                ];
                
                for (name, cmd) in browsers.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Text Editor" => {
                // Common text editors
                let editors = [
                    ("Gedit", "gedit"),
                    ("Kate", "kate"),
                    ("Mousepad", "mousepad"),
                    ("Geany", "geany"),
                    ("VSCode", "code"),
                    ("Sublime Text", "subl"),
                ];
                
                for (name, cmd) in editors.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Video Player" => {
                // Common video players
                let players = [
                    ("MPV", "mpv"),
                    ("VLC", "vlc"),
                    ("Celluloid", "celluloid"),
                    ("SMPlayer", "smplayer"),
                ];
                
                for (name, cmd) in players.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Music Player" => {
                // Common music players
                let players = [
                    ("MPV", "mpv"),
                    ("Rhythmbox", "rhythmbox"),
                    ("Audacious", "audacious"),
                    ("Clementine", "clementine"),
                ];
                
                for (name, cmd) in players.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Photo Viewer" => {
                // Common photo viewers
                let viewers = [
                    ("Eye of GNOME", "eog"),
                    ("Gwenview", "gwenview"),
                    ("Ristretto", "ristretto"),
                    ("Geeqie", "geeqie"),
                ];
                
                for (name, cmd) in viewers.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Task Manager" => {
                // Common task managers
                let task_managers = [
                    ("Mission Center", "missioncenter"),
                    ("GNOME System Monitor", "gnome-system-monitor"),
                    ("KSysGuard", "ksysguard"),
                    ("XFCE Task Manager", "xfce4-taskmanager"),
                ];
                
                for (name, cmd) in task_managers.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            "Terminal Emulator" => {
                // Common terminals
                let terminals = [
                    ("Kitty", "kitty"),
                    ("GNOME Terminal", "gnome-terminal"),
                    ("Konsole", "konsole"),
                    ("Alacritty", "alacritty"),
                    ("Terminator", "terminator"),
                    ("XFCE Terminal", "xfce4-terminal"),
                ];
                
                for (name, cmd) in terminals.iter() {
                    if is_app_installed(cmd.split_whitespace().next().unwrap_or("")) {
                        apps.push(AppInfo {
                            name: name.to_string(),
                            command: cmd.to_string(),
                            comment: app_type.to_string(),
                        });
                    }
                }
            },
            _ => {}
        }
    }
    
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

// Function to get apps from desktop files
fn get_apps_from_desktop_files(app_type: &str) -> Vec<AppInfo> {
    let mut apps = Vec::new();
    
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
    
    // Map app_type to desktop file categories and mime types
    let (categories, mime_types) = match app_type {
        "File Manager" => (vec!["FileManager", "FileSystem"], vec!["inode/directory"]),
        "Browser" => (vec!["WebBrowser"], vec!["text/html", "x-scheme-handler/http", "x-scheme-handler/https"]),
        "Text Editor" => (vec!["TextEditor"], vec!["text/plain"]),
        "Video Player" => (vec!["Video", "Player", "AudioVideo"], vec!["video/mp4", "video/x-matroska"]),
        "Music Player" => (vec!["Audio", "Music", "Player", "AudioVideo"], vec!["audio/mpeg", "audio/x-wav"]),
        "Photo Viewer" => (vec!["Graphics", "Viewer"], vec!["image/png", "image/jpeg"]),
        "Task Manager" => (vec!["System", "Monitor"], vec![]),
        "Terminal Emulator" => (vec!["TerminalEmulator"], vec!["application/x-terminal"]),
        _ => (vec![], vec![]),
    };
    
    // Scan desktop directories
    for dir in desktop_dirs.iter() {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.filter_map(Result::ok) {
                if let Some(path) = entry.path().to_str() {
                    if path.ends_with(".desktop") {
                        if let Ok(content) = fs::read_to_string(path) {
                            let name = extract_desktop_entry(&content, "Name");
                            let exec = extract_desktop_entry(&content, "Exec");
                            let desktop_categories = extract_desktop_entry(&content, "Categories");
                            let desktop_mime_types = extract_desktop_entry(&content, "MimeType");
                            let no_display = extract_desktop_entry(&content, "NoDisplay");
                            
                            // Skip hidden applications
                            if no_display.to_lowercase() == "true" {
                                continue;
                            }
                            
                            // Check if this app matches our criteria
                            let category_match = !categories.is_empty() && categories.iter().any(|&cat| desktop_categories.contains(cat));
                            let mime_match = !mime_types.is_empty() && mime_types.iter().any(|&mime| desktop_mime_types.contains(mime));
                            
                            if category_match || mime_match {
                                if let Some(cmd) = clean_exec_command(&exec) {
                                    apps.push(AppInfo {
                                        name: name.clone(),
                                        command: cmd,
                                        comment: app_type.to_string(),
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Sort apps by name
    apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    
    // Remove duplicates (keeping the first occurrence)
    let mut unique_apps = Vec::new();
    let mut seen_names = std::collections::HashSet::new();
    
    for app in apps {
        if !seen_names.contains(&app.name) {
            seen_names.insert(app.name.clone());
            unique_apps.push(app);
        }
    }
    
    unique_apps
}

// Function to extract a value from a desktop entry
fn extract_desktop_entry(content: &str, key: &str) -> String {
    let mut in_desktop_entry = false;
    
    for line in content.lines() {
        if line.trim() == "[Desktop Entry]" {
            in_desktop_entry = true;
            continue;
        } else if line.starts_with('[') && in_desktop_entry {
            in_desktop_entry = false;
        }
        
        if in_desktop_entry && line.starts_with(&format!("{}=", key)) {
            return line.splitn(2, '=').nth(1).unwrap_or("").to_string();
        }
    }
    
    String::new()
}

// Function to clean up the Exec command from desktop files
fn clean_exec_command(exec: &str) -> Option<String> {
    if exec.is_empty() {
        return None;
    }
    
    // Remove field codes like %f, %F, %u, %U, etc.
    let mut cmd = exec.to_string();
    let field_codes = [" %f", " %F", " %u", " %U", " %d", " %D", " %n", " %N", " %i", " %c", " %k", " %v", " %m"];
    
    for code in field_codes.iter() {
        cmd = cmd.replace(code, "");
    }
    
    // Remove any remaining % arguments
    if let Some(pos) = cmd.find(" %") {
        cmd = cmd[..pos].to_string();
    }
    
    // Remove quotes if present
    cmd = cmd.trim_matches('"').to_string();
    
    Some(cmd)
}

// Function to check if an app is installed
fn is_app_installed(app_name: &str) -> bool {
    Command::new("which")
        .arg(app_name)
        .output()
        .map(|output| output.status.success())
        .unwrap_or(false)
}

// Function to update default app in config
fn update_default_app(config_path: &PathBuf, config_content: &str, app_type: &str, new_command: &str) {
    let mut new_content = String::new();
    let mut in_apps_section = false;
    let mut found_app = false;
    
    for line in config_content.lines() {
        let trimmed = line.trim();
        
        // Check if we're in the APPS section
        if trimmed == "# APPS - Managed By User & Scripts" {
            in_apps_section = true;
            new_content.push_str(line);
            new_content.push('\n');
            continue;
        }
        
        // Check if we've found the app type comment
        if in_apps_section && trimmed == format!("## {}", app_type) {
            new_content.push_str(line);
            new_content.push('\n');
            
            // Read the next line (the bind command)
            continue;
        }
        
        // If we're on the line after the app type comment, replace the command
        if in_apps_section && !found_app && line.contains(", exec, ") && line.contains("bind = ") {
            let prev_line = new_content.lines().last().unwrap_or("");
            if prev_line.trim() == format!("## {}", app_type) {
                // Extract the key binding part
                let parts: Vec<&str> = line.split(", exec, ").collect();
                if parts.len() == 2 {
                    let key_part = parts[0];
                    new_content.push_str(&format!("{}, exec, {}", key_part, new_command));
                    new_content.push('\n');
                    found_app = true;
                    continue;
                }
            }
        }
        
        // Add the line as is
        new_content.push_str(line);
        new_content.push('\n');
    }
    
    // Write the updated content back to the file
    if found_app {
        if let Err(e) = fs::write(config_path, new_content) {
            println!("Error writing to config file: {}", e);
        }
    }

    // Also update xdg-mime default application
    update_xdg_mime_default(app_type, new_command);
}

// Function to update xdg-mime default application
fn update_xdg_mime_default(app_type: &str, command: &str) {
    // Extract desktop file name from command
    let app_name = command.split_whitespace().next().unwrap_or("");
    if app_name.is_empty() {
        return;
    }
    
    // Find the desktop file for this application
    let desktop_file = find_desktop_file(app_name);
    if desktop_file.is_empty() {
        return;
    }
    
    // Get mime types for this application type
    let mime_types = get_mime_types_for_app_type(app_type);
    
    // Set default application for each mime type
    for mime_type in mime_types {
        let _ = Command::new("xdg-mime")
            .arg("default")
            .arg(&desktop_file)
            .arg(mime_type)
            .output();
    }
}

// Function to find desktop file for an application
fn find_desktop_file(app_name: &str) -> String {
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
    
    for dir in desktop_dirs.iter() {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.filter_map(Result::ok) {
                if let Some(path) = entry.path().to_str() {
                    if path.ends_with(".desktop") {
                        if let Ok(content) = fs::read_to_string(path) {
                            let exec = extract_desktop_entry(&content, "Exec");
                            if let Some(cmd) = clean_exec_command(&exec) {
                                if cmd.split_whitespace().next().unwrap_or("") == app_name {
                                    return entry.path().file_name()
                                        .unwrap_or_default()
                                        .to_string_lossy()
                                        .to_string();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    String::new()
}

// Function to get mime types for an application type
fn get_mime_types_for_app_type(app_type: &str) -> Vec<&'static str> {
    match app_type {
        "File Manager" => vec!["inode/directory"],
        "Browser" => vec!["text/html", "x-scheme-handler/http", "x-scheme-handler/https"],
        "Text Editor" => vec!["text/plain"],
        "Video Player" => vec!["video/mp4", "video/x-matroska", "video/mpeg"],
        "Music Player" => vec!["audio/mpeg", "audio/x-wav", "audio/ogg"],
        "Photo Viewer" => vec!["image/png", "image/jpeg", "image/gif"],
        "Terminal Emulator" => vec!["application/x-terminal"],
        _ => vec![],
    }
}

// Function to create a backup of the config file
fn create_config_backup(config_path: &PathBuf) -> bool {
    let backup_dir = config_path.parent().unwrap().join("backups");
    
    // Create backup directory if it doesn't exist
    if !backup_dir.exists() {
        if let Err(e) = fs::create_dir_all(&backup_dir) {
            println!("Error creating backup directory: {}", e);
            return false;
        }
    }
    
    // Generate backup filename with timestamp
    let timestamp = chrono::Local::now().format("%Y%m%d_%H%M%S");
    let filename = config_path.file_name().unwrap().to_str().unwrap();
    let backup_path = backup_dir.join(format!("{}_{}", timestamp, filename));
    
    // Copy the file
    match fs::copy(config_path, backup_path) {
        Ok(_) => true,
        Err(e) => {
            println!("Error creating backup: {}", e);
            false
        }
    }
}