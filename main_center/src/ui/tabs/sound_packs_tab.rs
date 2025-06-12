use gtk;

use libadwaita as adw;
use libadwaita::prelude::*;
use crate::ui::tabs::ui_utils::{create_card, set_card_content};
use std::path::{Path, PathBuf};
use std::fs;
use std::fs::File;
use std::io::{Read, Write};
use std::process::Command;
use std::collections::HashMap;
use std::error::Error;
use std::ffi::OsStr;

// Define struct to hold sound pack information
struct SoundPack {
    name: String,
    path: PathBuf,
    is_active: bool,
}

// Check if a directory is a valid sound pack (contains index.theme)
fn is_valid_sound_pack(dir_path: &Path) -> bool {
    let index_path = dir_path.join("index.theme");
    index_path.exists() && index_path.is_file()
}

// Read sound pack name from index.theme
fn read_sound_pack_name(dir_path: &Path) -> Result<String, Box<dyn Error>> {
    let index_path = dir_path.join("index.theme");
    let mut file = File::open(&index_path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;

    // Look for Name= in the file
    for line in contents.lines() {
        if line.starts_with("Name=") {
            return Ok(line.trim_start_matches("Name=").trim().to_string());
        }
    }

    // If no name found, use directory name
    Ok(dir_path.file_name()
        .and_then(OsStr::to_str)
        .unwrap_or("Unknown")
        .to_string())
}

// Get sound directories from index.theme
fn get_sound_directories(dir_path: &Path) -> Result<Vec<String>, Box<dyn Error>> {
    let index_path = dir_path.join("index.theme");
    let mut file = File::open(&index_path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;

    let mut directories = Vec::new();

    // Look for Directories= in the file
    for line in contents.lines() {
        if line.starts_with("Directories=") {
            let dirs_str = line.trim_start_matches("Directories=").trim();
            directories = dirs_str.split(',')
                .map(|s| s.trim().to_string())
                .collect();
            break;
        }
    }

    Ok(directories)
}

// Get the active sound pack name
fn get_active_sound_pack() -> String {
    let config_path = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .join(".config/hypr/sounds/default-sound");
    
    if let Ok(mut file) = File::open(config_path) {
        let mut contents = String::new();
        if file.read_to_string(&mut contents).is_ok() {
            return contents.trim().to_string();
        }
    }
    
    "default".to_string() // Default if not set
}

// Convert a name to a filesystem-safe name (replace spaces with underscores)
fn sanitize_name_for_fs(name: &str) -> String {
    name.replace(' ', "_")
}

// Map sound files from the pack to default sound names
fn map_sound_files(source_dirs: &Vec<PathBuf>, default_dir: &Path) -> HashMap<String, PathBuf> {
    let mut mapped_sounds = HashMap::new();
    let mut default_sounds = HashMap::new();

    // Get default sound files
    if let Ok(entries) = fs::read_dir(default_dir) {
        for entry in entries.filter_map(Result::ok) {
            if let Some(name) = entry.path().file_stem().and_then(OsStr::to_str) {
                default_sounds.insert(name.to_string(), entry.path());
            }
        }
    }

    // Define common sound name mappings
    let sound_mappings: HashMap<&str, Vec<&str>> = [
        // Map default sound names to common sound names in other themes
        ("notification", vec!["message-new-instant", "message-attention", "message-new-email", "im-contact-online"]),
        ("warning", vec!["dialog-warning", "battery-caution"]),
        ("error", vec!["dialog-error", "message-error"]),
        ("error-critical", vec!["dialog-error-critical", "dialog-error-serious", "suspend-error"]),
        ("critical", vec!["dialog-error-critical", "dialog-error-serious"]),
        ("info", vec!["dialog-information", "complete-download"]),
        ("screenshot", vec!["screen-capture", "camera-shutter"]),
        ("login", vec!["desktop-login", "service-login"]),
        ("logout", vec!["desktop-logout", "service-logout", "system-shutdown"]),
        ("device-added", vec!["device-added"]),
        ("device-removed", vec!["device-removed"]),
        ("volume-up", vec!["audio-volume-change"]),
        ("volume-down", vec!["audio-volume-change"]),
        ("mute", vec!["audio-volume-change"]),
        ("unmute", vec!["audio-volume-change"]),
        ("charging", vec!["power-plug", "battery-full"]),
        ("record-start", vec!["camera-shutter", "camera-focus"]),
        ("record-stop", vec!["complete-media-burn", "complete-copy"]),
        ("toggle_performance", vec!["bell-window-system", "bell-terminal"]),
    ].iter().cloned().collect();

    // First pass: try to find exact matches or matches from the mapping
    for default_name in default_sounds.keys() {
        // Try to find exact matches first
        let mut found_exact_match = false;
        
        for source_dir in source_dirs {
            if let Ok(entries) = fs::read_dir(source_dir) {
                for entry in entries.filter_map(Result::ok) {
                    if !entry.path().is_file() {
                        continue;
                    }

                    // Only consider audio files
                    if let Some(ext) = entry.path().extension().and_then(OsStr::to_str) {
                        if !["ogg", "wav", "mp3", "flac"].contains(&ext.to_lowercase().as_str()) {
                            continue;
                        }
                    } else {
                        continue;
                    }

                    // Check for exact filename match (without extension)
                    if let Some(source_name) = entry.path().file_stem().and_then(OsStr::to_str) {
                        if source_name.to_lowercase() == default_name.to_lowercase() {
                            mapped_sounds.insert(default_name.clone(), entry.path());
                            found_exact_match = true;
                            break;
                        }
                    }
                }
            }
            
            if found_exact_match {
                break;
            }
        }
        
        // If no exact match, try the mappings
        if !found_exact_match {
            if let Some(alternative_names) = sound_mappings.get(default_name.as_str()) {
                for alt_name in alternative_names {
                    let mut found_alt_match = false;
                    
                    for source_dir in source_dirs {
                        if let Ok(entries) = fs::read_dir(source_dir) {
                            for entry in entries.filter_map(Result::ok) {
                                if !entry.path().is_file() {
                                    continue;
                                }

                                // Only consider audio files
                                if let Some(ext) = entry.path().extension().and_then(OsStr::to_str) {
                                    if !["ogg", "wav", "mp3", "flac"].contains(&ext.to_lowercase().as_str()) {
                                        continue;
                                    }
                                } else {
                                    continue;
                                }

                                if let Some(source_name) = entry.path().file_stem().and_then(OsStr::to_str) {
                                    if source_name.to_lowercase() == alt_name.to_lowercase() {
                                        mapped_sounds.insert(default_name.clone(), entry.path());
                                        found_alt_match = true;
                                        break;
                                    }
                                }
                            }
                        }
                        
                        if found_alt_match {
                            break;
                        }
                    }
                    
                    if found_alt_match {
                        break;
                    }
                }
            }
        }
    }

    // Second pass: try partial name matching for sounds that weren't matched yet
    for default_name in default_sounds.keys() {
        if !mapped_sounds.contains_key(default_name) {
            for source_dir in source_dirs {
                if let Ok(entries) = fs::read_dir(source_dir) {
                    for entry in entries.filter_map(Result::ok) {
                        if !entry.path().is_file() {
                            continue;
                        }

                        // Only consider audio files
                        if let Some(ext) = entry.path().extension().and_then(OsStr::to_str) {
                            if !["ogg", "wav", "mp3", "flac"].contains(&ext.to_lowercase().as_str()) {
                                continue;
                            }
                        } else {
                            continue;
                        }

                        if let Some(source_name) = entry.path().file_stem().and_then(OsStr::to_str) {
                            let source_lower = source_name.to_lowercase();
                            let default_lower = default_name.to_lowercase();
                            
                            // Check if source contains default name or vice versa
                            if source_lower.contains(&default_lower) || default_lower.contains(&source_lower) {
                                mapped_sounds.insert(default_name.clone(), entry.path());
                                break;
                            }
                            
                            // Check for word parts (e.g., "volume" in "volume-up")
                            let default_parts: Vec<&str> = default_lower.split(|c| c == '-' || c == '_').collect();
                            let source_parts: Vec<&str> = source_lower.split(|c| c == '-' || c == '_').collect();
                            
                            for default_part in &default_parts {
                                for source_part in &source_parts {
                                    if default_part.len() > 3 && source_part.len() > 3 && 
                                       (default_part.contains(source_part) || source_part.contains(default_part)) {
                                        mapped_sounds.insert(default_name.clone(), entry.path());
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                
                if mapped_sounds.contains_key(default_name) {
                    break;
                }
            }
        }
    }

    // Third pass: for any remaining unmapped sounds, pick sounds by category or context
    let remaining_default_sounds: Vec<String> = default_sounds.keys()
        .filter(|name| !mapped_sounds.contains_key(*name))
        .cloned()
        .collect();
    
    if !remaining_default_sounds.is_empty() && !mapped_sounds.is_empty() {
        // Group source sounds by directory/category
        let mut notification_sounds = Vec::new();
        let mut action_sounds = Vec::new();
        let mut ui_sounds = Vec::new();
        let mut other_sounds = Vec::new();
        
        for source_dir in source_dirs {
            let dir_name = source_dir.file_name().and_then(OsStr::to_str).unwrap_or("");
            
            if let Ok(entries) = fs::read_dir(source_dir) {
                for entry in entries.filter_map(Result::ok) {
                    if !entry.path().is_file() {
                        continue;
                    }

                    // Only consider audio files
                    if let Some(ext) = entry.path().extension().and_then(OsStr::to_str) {
                        if !["ogg", "wav", "mp3", "flac"].contains(&ext.to_lowercase().as_str()) {
                            continue;
                        }
                    } else {
                        continue;
                    }
                    
                    // Skip files already used in mapping
                    if mapped_sounds.values().any(|p| *p == entry.path()) {
                        continue;
                    }
                    
                    match dir_name.to_lowercase().as_str() {
                        "notifications" => notification_sounds.push(entry.path()),
                        "actions" => action_sounds.push(entry.path()),
                        "ui" => ui_sounds.push(entry.path()),
                        _ => other_sounds.push(entry.path()),
                    }
                }
            }
        }
        
        // Map remaining sounds by category
        for default_name in remaining_default_sounds {
            let lower_name = default_name.to_lowercase();
            
            // Choose appropriate category based on default sound name
            let source_list = if lower_name.contains("notification") || lower_name.contains("warning") || 
                                lower_name.contains("error") || lower_name.contains("critical") || 
                                lower_name.contains("info") {
                if !notification_sounds.is_empty() {
                    &notification_sounds
                } else {
                    &other_sounds
                }
            } else if lower_name.contains("screenshot") || lower_name.contains("record") {
                if !action_sounds.is_empty() {
                    &action_sounds
                } else {
                    &other_sounds
                }
            } else {
                if !ui_sounds.is_empty() {
                    &ui_sounds
                } else {
                    &other_sounds
                }
            };
            
            // Pick a sound from the appropriate category if available
            if !source_list.is_empty() {
                // Use a simple hash of the default name to pick a consistent sound
                let index = default_name.bytes().fold(0, |acc, b| acc + b as usize) % source_list.len();
                mapped_sounds.insert(default_name, source_list[index].clone());
            }
        }
    }

    // Final pass: for any default sounds that don't have a match, just pick any sound file
    // (only if we have at least one sound file)
    if !mapped_sounds.is_empty() {
        let mut all_source_sounds = Vec::new();
        
        for source_dir in source_dirs {
            if let Ok(entries) = fs::read_dir(source_dir) {
                for entry in entries.filter_map(Result::ok) {
                    if !entry.path().is_file() {
                        continue;
                    }

                    // Only consider audio files
                    if let Some(ext) = entry.path().extension().and_then(OsStr::to_str) {
                        if !["ogg", "wav", "mp3", "flac"].contains(&ext.to_lowercase().as_str()) {
                            continue;
                        }
                        
                        // Skip files already used in mapping
                        if !mapped_sounds.values().any(|p| *p == entry.path()) {
                            all_source_sounds.push(entry.path());
                        }
                    }
                }
            }
        }
        
        if !all_source_sounds.is_empty() {
            for default_name in default_sounds.keys() {
                if !mapped_sounds.contains_key(default_name) {
                    // Use a simple hash of the default name to pick a consistent sound
                    let index = default_name.bytes().fold(0, |acc, b| acc + b as usize) % all_source_sounds.len();
                    mapped_sounds.insert(default_name.clone(), all_source_sounds[index].clone());
                }
            }
        }
    }

    mapped_sounds
}

// Import a sound pack
fn import_sound_pack(source_path: &Path) -> Result<(), Box<dyn Error>> {
    // Verify this is a valid sound pack
    if !is_valid_sound_pack(source_path) {
        return Err("Not a valid sound pack (missing index.theme)".into());
    }

    // Get sound pack name
    let pack_name = read_sound_pack_name(source_path)?;
    
    // Sanitize the name for filesystem operations
    let fs_pack_name = sanitize_name_for_fs(&pack_name);
    
    // Get sound directories from index.theme
    let directories = get_sound_directories(source_path)?;
    
    // Create full paths to source directories
    let source_dirs: Vec<PathBuf> = directories.iter()
        .map(|dir| source_path.join(dir))
        .collect();
    
    // Default sounds directory
    let default_dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .join(".config/hypr/sounds/default");
    
    // Target directory for the sound pack - use sanitized name
    let target_dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .join(format!(".config/hypr/sounds/{}", fs_pack_name));
    
    // Create target directory if it doesn't exist
    fs::create_dir_all(&target_dir)?;
    
    // Map source sounds to default sound names
    let mapped_sounds = map_sound_files(&source_dirs, &default_dir);
    
    // Copy all mapped sounds to target directory
    for (default_name, source_file) in mapped_sounds {
        let target_file = target_dir.join(format!("{}{}", default_name, 
            source_file.extension()
                .and_then(OsStr::to_str)
                .map(|ext| format!(".{}", ext))
                .unwrap_or_default()));
        
        fs::copy(source_file, target_file)?;
    }
    
    Ok(())
}

// Activate a sound pack
fn activate_sound_pack(pack_name: &str) -> Result<(), Box<dyn Error>> {
    // Sanitize the pack name for filesystem operations
    let fs_pack_name = sanitize_name_for_fs(pack_name);
    
    // Write sanitized pack name to default-sound file
    let config_path = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .join(".config/hypr/sounds/default-sound");
    
    let mut file = File::create(config_path)?;
    file.write_all(fs_pack_name.as_bytes())?;
    
    // Get home directory for script paths
    let home_dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .to_string_lossy()
        .to_string();
    
    // Use direct command execution through bash to avoid blocking the UI
    println!("Activating sound pack: {}", fs_pack_name);
    
    // Create a single command that handles both operations
    let command = format!(
        "hyprctl dispatch exec [float] 'bash -c \"bash {home}/.config/hypr/scripts/notification/manage_notifications.sh stop && sleep 1 && bash {home}/.config/hypr/scripts/notification/run_notifications.sh\"'", 
        home = home_dir
    );
    
    // Execute the command
    Command::new("sh")
        .arg("-c")
        .arg(&command)
        .spawn()?;
    
    println!("Sound pack activation completed for: {}", pack_name);
    Ok(())
}

// Get list of installed sound packs
fn get_installed_sound_packs() -> Vec<SoundPack> {
    let mut packs = Vec::new();
    let active_pack = get_active_sound_pack();
    
    // Sound packs directory
    if let Some(home_dir) = dirs::home_dir() {
        let sounds_dir = home_dir.join(".config/hypr/sounds");
        
        if let Ok(entries) = fs::read_dir(sounds_dir) {
            for entry in entries.filter_map(Result::ok) {
                let path = entry.path();
                
                // Skip files and the default directory
                if !path.is_dir() || path.file_name().unwrap_or_default() == "default" {
                    continue;
                }
                
                if let Some(name) = path.file_name().and_then(OsStr::to_str) {
                    // For display in UI, convert underscores back to spaces
                    let display_name = name.replace('_', " ");
                    
                    packs.push(SoundPack {
                        name: display_name,
                        path: path.clone(),
                        is_active: name == active_pack,
                    });
                }
            }
        }
    }
    
    packs
}

// Function to remove a sound pack
fn remove_sound_pack(pack_name: &str) -> Result<(), Box<dyn Error>> {
    // Sanitize the pack name for filesystem operations
    let fs_pack_name = sanitize_name_for_fs(pack_name);
    
    // Get the sound pack directory
    let pack_dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/"))
        .join(format!(".config/hypr/sounds/{}", fs_pack_name));
    
    // If this is the active pack, prevent removal
    let active_pack = get_active_sound_pack();
    if active_pack == fs_pack_name {
        return Err("Cannot remove the active sound pack. Activate another pack first.".into());
    }
    
    // Remove the directory and all its contents
    if pack_dir.exists() && pack_dir.is_dir() {
        fs::remove_dir_all(pack_dir)?;
        println!("Sound pack removed: {}", pack_name);
        Ok(())
    } else {
        Err(format!("Sound pack directory not found: {}", pack_name).into())
    }
}

// Create the sound packs tab UI
pub fn create_sound_packs_content() -> gtk::Widget {
    // Create toast overlay for notifications
    let toast_overlay = adw::ToastOverlay::new();
    
    // Create main content box
    let content = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content.set_margin_top(24);
    content.set_margin_bottom(24);
    content.set_margin_start(24);
    content.set_margin_end(24);
    
    // Create scrolled window
    let scroll = gtk::ScrolledWindow::new();
    scroll.set_vexpand(true);
    scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    
    let sound_packs_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    
    // Create import section card
    let import_card = create_card("Import Sound Pack");
    
    let import_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    import_box.set_margin_top(16);
    import_box.set_margin_bottom(16);
    import_box.set_margin_start(16);
    import_box.set_margin_end(16);
    
    // Add description label
    let description = gtk::Label::new(Some("Import a sound pack folder containing an index.theme file."));
    description.set_halign(gtk::Align::Start);
    description.set_wrap(true);
    description.set_margin_bottom(12);
    import_box.append(&description);
    
    // Add buttons in a horizontal box
    let buttons_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    buttons_box.set_halign(gtk::Align::Start);
    
    // Add file chooser button
    let file_chooser_button = gtk::Button::with_label("Select Sound Pack Folder");
    file_chooser_button.add_css_class("suggested-action");
    file_chooser_button.add_css_class("pill");
    
    // Create a status label for showing the current active pack
    let status_label = gtk::Label::new(Some(&format!("Active sound pack: {}", get_active_sound_pack())));
    status_label.set_halign(gtk::Align::Start);
    status_label.set_margin_top(12);
    status_label.add_css_class("caption");
    status_label.add_css_class("dim-label");
    
    // Create a container for the list of installed packs
    let installed_list_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
    
    // Function to refresh the list of installed sound packs
    let refresh_sound_packs_list = {
        let installed_list_container = installed_list_container.clone();
        let status_label = status_label.clone();
        let toast_overlay = toast_overlay.clone();
        
        move || {
            // Clear existing content - remove all children
            while let Some(child) = installed_list_container.first_child() {
                installed_list_container.remove(&child);
            }
            
            // Update status label
            status_label.set_label(&format!("Active sound pack: {}", get_active_sound_pack()));
            
            // Get installed sound packs
            let sound_packs = get_installed_sound_packs();
            
            if sound_packs.is_empty() {
                let no_packs_label = gtk::Label::new(Some("No sound packs installed"));
                no_packs_label.set_halign(gtk::Align::Start);
                no_packs_label.add_css_class("dim-label");
                installed_list_container.append(&no_packs_label);
            } else {
                // Create list box for sound packs
                let list_box = gtk::ListBox::new();
                list_box.set_selection_mode(gtk::SelectionMode::None);
                list_box.add_css_class("boxed-list");
                
                for pack in sound_packs {
                    let row = adw::ActionRow::new();
                    row.set_title(&pack.name);
                    
                    // Add icon
                    let icon = gtk::Image::from_icon_name("audio-x-generic-symbolic");
                    row.add_prefix(&icon);
                    
                    // Create a box for buttons
                    let buttons_box = gtk::Box::new(gtk::Orientation::Horizontal, 4);
                    buttons_box.set_valign(gtk::Align::Center);
                    
                    // Add "Open Folder" button
                    let open_folder_button = gtk::Button::new();
                    open_folder_button.set_icon_name("folder-symbolic");
                    open_folder_button.add_css_class("flat");
                    open_folder_button.set_valign(gtk::Align::Center);
                    open_folder_button.set_tooltip_text(Some("Open sound pack folder"));
                    
                    let pack_path = pack.path.clone();
                    open_folder_button.connect_clicked(move |_| {
                        // Open the folder using xdg-open
                        if let Err(e) = Command::new("xdg-open")
                            .arg(&pack_path)
                            .spawn() {
                            println!("Error opening folder: {}", e);
                        }
                    });
                    
                    buttons_box.append(&open_folder_button);
                    
                    // Add activation button if not active
                    if !pack.is_active {
                        let activate_button = gtk::Button::with_label("Activate");
                        activate_button.add_css_class("flat");
                        activate_button.set_valign(gtk::Align::Center);
                        
                        let pack_name = pack.name.clone();
                        let toast_overlay_clone = toast_overlay.clone();
                        // Create a refresh function that will be cloned for both activate and remove buttons
                        let refresh_fn = gtk::glib::clone!(@strong installed_list_container, @strong status_label, @strong toast_overlay => move || {
                            // Update status label
                            status_label.set_label(&format!("Active sound pack: {}", get_active_sound_pack()));
                            
                            // Refresh list - remove all children
                            while let Some(child) = installed_list_container.first_child() {
                                installed_list_container.remove(&child);
                            }
                            
                            // Get updated sound packs
                            let updated_packs = get_installed_sound_packs();
                            
                            if updated_packs.is_empty() {
                                let no_packs_label = gtk::Label::new(Some("No sound packs installed"));
                                no_packs_label.set_halign(gtk::Align::Start);
                                no_packs_label.add_css_class("dim-label");
                                installed_list_container.append(&no_packs_label);
                            } else {
                                // Create new list box
                                let new_list_box = gtk::ListBox::new();
                                new_list_box.set_selection_mode(gtk::SelectionMode::None);
                                new_list_box.add_css_class("boxed-list");
                                
                                for pack in updated_packs {
                                    let updated_row = adw::ActionRow::new();
                                    updated_row.set_title(&pack.name);
                                    
                                    // Add icon
                                    let updated_icon = gtk::Image::from_icon_name("audio-x-generic-symbolic");
                                    updated_row.add_prefix(&updated_icon);
                                    
                                    // Create buttons box
                                    let updated_buttons_box = gtk::Box::new(gtk::Orientation::Horizontal, 4);
                                    updated_buttons_box.set_valign(gtk::Align::Center);
                                    
                                    // Add "Open Folder" button
                                    let open_folder_button = gtk::Button::new();
                                    open_folder_button.set_icon_name("folder-symbolic");
                                    open_folder_button.add_css_class("flat");
                                    open_folder_button.set_valign(gtk::Align::Center);
                                    open_folder_button.set_tooltip_text(Some("Open sound pack folder"));
                                    
                                    let pack_path = pack.path.clone();
                                    open_folder_button.connect_clicked(move |_| {
                                        // Open the folder using xdg-open
                                        if let Err(e) = Command::new("xdg-open")
                                            .arg(&pack_path)
                                            .spawn() {
                                            println!("Error opening folder: {}", e);
                                        }
                                    });
                                    
                                    updated_buttons_box.append(&open_folder_button);
                                    
                                    // Add activation button if not active
                                    if !pack.is_active {
                                        let updated_activate_button = gtk::Button::with_label("Activate");
                                        updated_activate_button.add_css_class("flat");
                                        updated_activate_button.set_valign(gtk::Align::Center);
                                        updated_buttons_box.append(&updated_activate_button);
                                        
                                        // Add remove button
                                        let remove_btn = gtk::Button::new();
                                        remove_btn.set_icon_name("user-trash-symbolic");
                                        remove_btn.add_css_class("flat");
                                        remove_btn.set_valign(gtk::Align::Center);
                                        remove_btn.set_tooltip_text(Some("Remove sound pack"));
                                        updated_buttons_box.append(&remove_btn);
                                    } else {
                                        // Show active indicator
                                        let active_label = gtk::Label::new(Some("Active"));
                                        active_label.add_css_class("success");
                                        active_label.add_css_class("caption");
                                        active_label.set_valign(gtk::Align::Center);
                                        updated_buttons_box.append(&active_label);
                                    }
                                    
                                    updated_row.add_suffix(&updated_buttons_box);
                                    new_list_box.append(&updated_row);
                                }
                                
                                installed_list_container.append(&new_list_box);
                            }
                            
                            // Add a success toast for refresh
                            let toast = adw::Toast::new("Sound pack list refreshed");
                            toast.set_timeout(2);
                            toast_overlay.add_toast(toast);
                        });
                        
                        // Clone the refresh function for activate button
                        let refresh_fn_for_activate = refresh_fn.clone();
                        
                        activate_button.connect_clicked(move |_| {
                            match activate_sound_pack(&pack_name) {
                                Ok(()) => {
                                    // Show success toast
                                    let toast = adw::Toast::new(&format!("Sound pack '{}' activated", pack_name));
                                    toast.set_timeout(3);
                                    toast_overlay_clone.add_toast(toast);
                                    
                                    // Show success dialog
                                    let dialog = gtk::MessageDialog::new(
                                        None::<&gtk::Window>,
                                        gtk::DialogFlags::MODAL,
                                        gtk::MessageType::Info,
                                        gtk::ButtonsType::Close,
                                        &format!("The system is now using the sound pack '{}'.", pack_name)
                                    );
                                    
                                    dialog.set_title(Some(&format!("Sound Pack '{}' Activated", pack_name)));
                                    
                                    let refresh_fn_clone = refresh_fn_for_activate.clone();
                                    dialog.connect_response(move |dialog, _| {
                                        dialog.close();
                                        // Refresh the UI after closing the dialog
                                        refresh_fn_clone();
                                    });
                                    dialog.present();
                                },
                                Err(e) => {
                                    // Show error toast
                                    let toast = adw::Toast::new(&format!("Error activating sound pack: {}", e));
                                    toast.set_timeout(3);
                                    toast_overlay_clone.add_toast(toast);
                                }
                            }
                        });
                        
                        buttons_box.append(&activate_button);
                        
                        // Add remove button
                        let remove_button = gtk::Button::new();
                        remove_button.set_icon_name("user-trash-symbolic");
                        remove_button.add_css_class("flat");
                        remove_button.set_valign(gtk::Align::Center);
                        remove_button.set_tooltip_text(Some("Remove sound pack"));
                        
                        let pack_name = pack.name.clone();
                        let toast_overlay_clone = toast_overlay.clone();
                        // Clone the refresh function for remove button
                        let refresh_fn_for_remove = refresh_fn.clone();
                        
                        remove_button.connect_clicked(move |_| {
                            // Confirm deletion with a dialog
                            let confirm_dialog = gtk::MessageDialog::new(
                                None::<&gtk::Window>,
                                gtk::DialogFlags::MODAL,
                                gtk::MessageType::Question,
                                gtk::ButtonsType::None,
                                &format!("Are you sure you want to remove the sound pack '{}'?", pack_name)
                            );
                            
                            confirm_dialog.set_title(Some("Confirm Removal"));
                            confirm_dialog.add_button("Cancel", gtk::ResponseType::Cancel);
                            confirm_dialog.add_button("Remove", gtk::ResponseType::Accept);
                            
                            let pack_name_clone = pack_name.clone();
                            let toast_overlay_clone2 = toast_overlay_clone.clone();
                            let refresh_fn_clone = refresh_fn_for_remove.clone();
                            
                            confirm_dialog.connect_response(move |dialog, response| {
                                dialog.close();
                                
                                if response == gtk::ResponseType::Accept {
                                    match remove_sound_pack(&pack_name_clone) {
                                        Ok(()) => {
                                            // Show success toast
                                            let toast = adw::Toast::new(&format!("Sound pack '{}' removed", pack_name_clone));
                                            toast.set_timeout(3);
                                            toast_overlay_clone2.add_toast(toast);
                                            
                                            // Refresh the UI
                                            refresh_fn_clone();
                                        },
                                        Err(e) => {
                                            // Show error toast
                                            let toast = adw::Toast::new(&format!("Error removing sound pack: {}", e));
                                            toast.set_timeout(3);
                                            toast_overlay_clone2.add_toast(toast);
                                        }
                                    }
                                }
                            });
                            
                            confirm_dialog.present();
                        });
                        
                        buttons_box.append(&remove_button);
                    } else {
                        // Show active indicator
                        let active_label = gtk::Label::new(Some("Active"));
                        active_label.add_css_class("success");
                        active_label.add_css_class("caption");
                        active_label.set_valign(gtk::Align::Center);
                        buttons_box.append(&active_label);
                    }
                    
                    row.add_suffix(&buttons_box);
                    list_box.append(&row);
                }
                
                installed_list_container.append(&list_box);
            }
            
            // Add a success toast for refresh
            let toast = adw::Toast::new("Sound pack list refreshed");
            toast.set_timeout(2);
            toast_overlay.add_toast(toast);
        }
    };
    
    // Add Set To Defaults button
    let set_default_button = gtk::Button::with_label("Set To Defaults");
    set_default_button.add_css_class("pill");
    
    // Clone components for refresh
    let toast_overlay_default = toast_overlay.clone();
    let status_label_clone = status_label.clone();
    let refresh_fn = refresh_sound_packs_list.clone();
    
    set_default_button.connect_clicked(move |_| {
        match activate_sound_pack("default") {
            Ok(()) => {
                // Show success dialog
                let dialog = gtk::MessageDialog::new(
                    None::<&gtk::Window>,
                    gtk::DialogFlags::MODAL,
                    gtk::MessageType::Info,
                    gtk::ButtonsType::Close,
                    "The system has been set to use the default sound pack."
                );
                
                dialog.set_title(Some("Default Sounds Activated"));
                
                // Update status label
                status_label_clone.set_label(&format!("Active sound pack: {}", get_active_sound_pack()));
                
                // Show success toast
                let toast = adw::Toast::new("Default sounds activated successfully");
                toast.set_timeout(3);
                toast_overlay_default.add_toast(toast);
                
                // Clone refresh_fn before moving it into the closure
                let refresh_fn_clone = refresh_fn.clone();
                dialog.connect_response(move |dialog, _| {
                    dialog.close();
                    // Refresh the UI after closing the dialog
                    refresh_fn_clone();
                });
                dialog.present();
            },
            Err(e) => {
                // Show error toast
                let toast = adw::Toast::new(&format!("Error activating default sounds: {}", e));
                toast.set_timeout(3);
                toast_overlay_default.add_toast(toast);
            }
        }
    });
    
    // Clone toast_overlay for use in closure
    let toast_overlay_clone = toast_overlay.clone();
    let status_label_clone = status_label.clone();
    let refresh_fn = refresh_sound_packs_list.clone();
    
    file_chooser_button.connect_clicked(move |_| {
        // Create simple file chooser dialog
        let file_chooser = gtk::FileChooserDialog::new(
            Some("Select Sound Pack Folder"),
            None::<&gtk::Window>,
            gtk::FileChooserAction::SelectFolder,
            &[
                ("Cancel", gtk::ResponseType::Cancel),
                ("Select", gtk::ResponseType::Accept),
            ],
        );
        
        // Set modal
        file_chooser.set_modal(true);
        
        // Connect response signal
        let toast_overlay_clone2 = toast_overlay_clone.clone();
        let status_label_clone2 = status_label_clone.clone();
        let refresh_fn2 = refresh_fn.clone();
        
        file_chooser.connect_response(move |dialog, response| {
            if response == gtk::ResponseType::Accept {
                if let Some(folder) = dialog.file().and_then(|f| f.path()) {
                    match import_sound_pack(&folder) {
                        Ok(()) => {
                            // Show success toast
                            let toast = adw::Toast::new("Sound pack imported successfully");
                            toast.set_timeout(3);
                            toast_overlay_clone2.add_toast(toast);
                            
                            // Update status label in case the newly imported pack becomes active
                            status_label_clone2.set_label(&format!("Active sound pack: {}", get_active_sound_pack()));
                            
                            // Refresh the sound packs list
                            refresh_fn2();
                        },
                        Err(e) => {
                            // Show error toast
                            let toast = adw::Toast::new(&format!("Error importing sound pack: {}", e));
                            toast.set_timeout(3);
                            toast_overlay_clone2.add_toast(toast);
                        }
                    }
                }
            }
            dialog.close();
        });
        
        // Show the dialog
        file_chooser.show();
    });
    
    buttons_box.append(&file_chooser_button);
    buttons_box.append(&set_default_button);
    
    import_box.append(&buttons_box);
    import_box.append(&status_label);
    
    // Set card content
    set_card_content(&import_card, &import_box);
    sound_packs_box.append(&import_card);
    
    // Create installed sound packs card
    let installed_card = create_card("Installed Sound Packs");
    
    let installed_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
    installed_box.set_margin_top(16);
    installed_box.set_margin_bottom(16);
    installed_box.set_margin_start(16);
    installed_box.set_margin_end(16);
    
    // Add the list container to the installed box
    installed_box.append(&installed_list_container);
    
    // Set card content
    set_card_content(&installed_card, &installed_box);
    sound_packs_box.append(&installed_card);
    
    // Add refresh button at the bottom
    let refresh_button = gtk::Button::with_label("Refresh Sound Pack List");
    refresh_button.set_halign(gtk::Align::Center);
    refresh_button.set_margin_top(10);
    refresh_button.add_css_class("pill");
    
    let refresh_fn = refresh_sound_packs_list.clone();
    
    refresh_button.connect_clicked(move |_| {
        refresh_fn();
    });
    
    sound_packs_box.append(&refresh_button);
    
    // Add content to scroll
    scroll.set_child(Some(&sound_packs_box));
    content.append(&scroll);
    
    // Set toast overlay content
    toast_overlay.set_child(Some(&content));
    
    // Initial population of the sound packs list
    refresh_sound_packs_list();
    
    // Return the widget
    toast_overlay.upcast()
}
