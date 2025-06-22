use gtk::{self, prelude::*};
use std::fs::{self, File};
use std::io::{self, BufRead, Write};
use std::path::{Path, PathBuf};
use crate::ui::tabs::ui_utils::{create_card, set_card_content};
use std::collections::HashMap;
use std::process::Command;

// Function to get the home directory
fn get_home_dir() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        })
}

// Paths to the facts configuration and script
fn get_facts_config_path() -> PathBuf {
    get_home_dir().join(".config/hypr/scripts/utils/facts/facts_config.conf")
}

fn get_facts_script_path() -> PathBuf {
    get_home_dir().join(".config/hypr/scripts/utils/facts/cool_facts.sh")
}

pub fn create_cool_facts_content() -> gtk::Widget {
    // Create main container
    let content = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content.set_margin_top(24);
    content.set_margin_bottom(24);
    content.set_margin_start(24);
    content.set_margin_end(24);
    
    // Create a container with a stylish background
    let container = gtk::Box::new(gtk::Orientation::Vertical, 20);
    container.add_css_class("card");
    container.set_margin_bottom(20);
    container.set_margin_top(10);
    container.set_margin_start(10);
    container.set_margin_end(10);
    
    // Create header with icon
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_top(16);
    header_box.set_margin_start(16);
    header_box.set_margin_end(16);
    
    let header = gtk::Label::new(Some("Cool Facts Configuration"));
    header.add_css_class("title-2");
    header.set_halign(gtk::Align::Start);
    header.set_hexpand(true);
    
    // Add a refresh button
    let refresh_button = gtk::Button::new();
    refresh_button.set_icon_name("view-refresh-symbolic");
    refresh_button.add_css_class("circular");
    refresh_button.add_css_class("pill");
    refresh_button.set_tooltip_text(Some("Reload configuration"));
    
    header_box.append(&header);
    header_box.append(&refresh_button);
    container.append(&header_box);
    
    // Separator
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_start(16);
    separator.set_margin_end(16);
    container.append(&separator);
    
    // Create scrollable content area
    let scroll = gtk::ScrolledWindow::new();
    scroll.set_vexpand(true);
    scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_bottom(16);
    content_box.set_margin_top(10);
    
    // Read the current configuration
    let config = load_config();
    
    // Create a shared config for all widgets
    let shared_config = std::rc::Rc::new(std::cell::RefCell::new(config));
    
    // Check if the script is running
    let is_running = check_if_facts_script_running();
    
    // Main service control card (moved to top)
    let service_card = create_card("Service Control");
    let service_box = gtk::Box::new(gtk::Orientation::Vertical, 15);
    service_box.set_margin_top(16);
    service_box.set_margin_bottom(16);
    service_box.set_margin_start(16);
    service_box.set_margin_end(16);
    
    // Service status indicator
    let status_row = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    let status_label = gtk::Label::new(Some("Cool Facts Service:"));
    status_label.set_halign(gtk::Align::Start);
    status_label.set_hexpand(true);
    
    let status_value = gtk::Label::new(None);
    if is_running {
        status_value.set_text("Running");
        status_value.add_css_class("success");
        status_value.add_css_class("heading");
    } else {
        status_value.set_text("Not Running");
        status_value.add_css_class("error");
        status_value.add_css_class("heading");
    }
    status_value.set_halign(gtk::Align::End);
    
    status_row.append(&status_label);
    status_row.append(&status_value);
    service_box.append(&status_row);
    
    // Service enable/disable switch
    let enable_row = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    let enable_label = gtk::Label::new(Some("Enable Cool Facts:"));
    enable_label.set_halign(gtk::Align::Start);
    enable_label.set_hexpand(true);
    
    let enable_switch = gtk::Switch::new();
    enable_switch.set_halign(gtk::Align::End);
    let is_enabled = shared_config.borrow().get("ENABLE_FACTS").unwrap_or(&String::from("yes")) == "yes";
    enable_switch.set_active(is_enabled);
    
    // If config says enabled but service not running, or disabled but service running,
    // we need to synchronize them
    if is_enabled != is_running {
        if is_enabled {
            // Config says enabled but service not running - start it
            let script_path = get_facts_script_path();
            let _ = Command::new("bash")
                .arg(script_path)
                .spawn();
            
            // Update UI
            status_value.set_text("Running");
            status_value.remove_css_class("error");
            status_value.add_css_class("success");
        } else {
            // Config says disabled but service running - stop it
            let _ = Command::new("pkill")
                .arg("-f")
                .arg("cool_facts.sh")
                .output();
            
            // Update UI
            status_value.set_text("Not Running");
            status_value.remove_css_class("success");
            status_value.add_css_class("error");
        }
    }
    
    // Connect enable switch to control service and save config
    let config_clone = shared_config.clone();
    let status_value_clone = status_value.clone();
    enable_switch.connect_state_set(move |_, state| {
        // Update configuration
        let mut config = config_clone.borrow_mut();
        config.insert("ENABLE_FACTS".to_string(), if state { "yes".to_string() } else { "no".to_string() });
        save_config(&config);
        
        // Control service
        if state {
            // Start the service
            let script_path = get_facts_script_path();
            let _ = Command::new("bash")
                .arg(script_path)
                .spawn();
                
            // Update UI
            status_value_clone.set_text("Running");
            status_value_clone.remove_css_class("error");
            status_value_clone.add_css_class("success");
        } else {
            // Stop the service
            let _ = Command::new("pkill")
                .arg("-f")
                .arg("cool_facts.sh")
                .output();
            
            // Update UI
            status_value_clone.set_text("Not Running");
            status_value_clone.remove_css_class("success");
            status_value_clone.add_css_class("error");
        }
        
        gtk::Inhibit(false)
    });
    
    enable_row.append(&enable_label);
    enable_row.append(&enable_switch);
    service_box.append(&enable_row);
    
    // Add service control description
    let service_desc = gtk::Label::new(Some("Enable or disable the Cool Facts service. When enabled, facts will be displayed according to your settings."));
    service_desc.set_wrap(true);
    service_desc.set_halign(gtk::Align::Start);
    service_desc.add_css_class("dim-label");
    service_desc.add_css_class("caption");
    service_box.append(&service_desc);
    
    set_card_content(&service_card, &service_box);
    content_box.append(&service_card);
    
    // Description text
    let desc_label = gtk::Label::new(Some("Configure the Cool Facts display settings. Changes are applied automatically."));
    desc_label.set_wrap(true);
    desc_label.set_halign(gtk::Align::Start);
    desc_label.add_css_class("dim-label");
    content_box.append(&desc_label);
    
    // Display settings card (renamed from Basic Settings)
    let basic_card = create_card("Display Settings");
    let basic_grid = gtk::Grid::new();
    basic_grid.set_row_spacing(15);
    basic_grid.set_column_spacing(15);
    basic_grid.set_margin_top(10);
    basic_grid.set_margin_bottom(10);
    basic_grid.set_margin_start(10);
    basic_grid.set_margin_end(10);
    
    // Interval Setting
    let interval_label = gtk::Label::new(Some("Interval (minutes)"));
    interval_label.set_halign(gtk::Align::Start);
    basic_grid.attach(&interval_label, 0, 0, 1, 1);
    
    let interval_adj = gtk::Adjustment::new(
        shared_config.borrow().get("INTERVAL").unwrap_or(&String::from("5")).parse::<f64>().unwrap_or(5.0),
        1.0, 60.0, 1.0, 5.0, 0.0
    );
    let interval_spin = gtk::SpinButton::new(Some(&interval_adj), 1.0, 0);
    interval_spin.set_halign(gtk::Align::End);
    basic_grid.attach(&interval_spin, 1, 0, 1, 1);
    
    // Connect interval spinner to auto-save
    let config_clone = shared_config.clone();
    interval_spin.connect_value_changed(move |spin| {
        let mut config = config_clone.borrow_mut();
        config.insert("INTERVAL".to_string(), spin.value().to_string());
        save_config(&config);
    });
    
    // Display Time Setting
    let display_time_label = gtk::Label::new(Some("Display Time (seconds)"));
    display_time_label.set_halign(gtk::Align::Start);
    basic_grid.attach(&display_time_label, 0, 1, 1, 1);
    
    let display_time_adj = gtk::Adjustment::new(
        shared_config.borrow().get("DISPLAY_TIME").unwrap_or(&String::from("10")).parse::<f64>().unwrap_or(10.0),
        1.0, 60.0, 1.0, 5.0, 0.0
    );
    let display_time_spin = gtk::SpinButton::new(Some(&display_time_adj), 1.0, 0);
    display_time_spin.set_halign(gtk::Align::End);
    basic_grid.attach(&display_time_spin, 1, 1, 1, 1);
    
    // Connect display time spinner to auto-save
    let config_clone = shared_config.clone();
    display_time_spin.connect_value_changed(move |spin| {
        let mut config = config_clone.borrow_mut();
        config.insert("DISPLAY_TIME".to_string(), spin.value().to_string());
        save_config(&config);
    });
    
    // Title Setting
    let title_label = gtk::Label::new(Some("Notification Title"));
    title_label.set_halign(gtk::Align::Start);
    basic_grid.attach(&title_label, 0, 2, 1, 1);
    
    let title_entry = gtk::Entry::new();
    title_entry.set_text(shared_config.borrow().get("TITLE").unwrap_or(&String::from("Did you know?")));
    title_entry.set_halign(gtk::Align::End);
    title_entry.set_hexpand(true);
    basic_grid.attach(&title_entry, 1, 2, 1, 1);
    
    // Connect title entry to auto-save
    let config_clone = shared_config.clone();
    title_entry.connect_changed(move |entry| {
        let mut config = config_clone.borrow_mut();
        config.insert("TITLE".to_string(), entry.text().to_string());
        save_config(&config);
    });
    
    set_card_content(&basic_card, &basic_grid);
    content_box.append(&basic_card);
    
    // Advanced settings card
    let advanced_card = create_card("Advanced Settings");
    let advanced_grid = gtk::Grid::new();
    advanced_grid.set_row_spacing(15);
    advanced_grid.set_column_spacing(15);
    advanced_grid.set_margin_top(10);
    advanced_grid.set_margin_bottom(10);
    advanced_grid.set_margin_start(10);
    advanced_grid.set_margin_end(10);
    
    // Facts API Setting
    let api_label = gtk::Label::new(Some("Facts API URL"));
    api_label.set_halign(gtk::Align::Start);
    advanced_grid.attach(&api_label, 0, 0, 1, 1);
    
    let api_entry = gtk::Entry::new();
    api_entry.set_text(shared_config.borrow().get("FACTS_API").unwrap_or(&String::from("https://uselessfacts.jsph.pl/api/v2/facts/random")));
    api_entry.set_halign(gtk::Align::End);
    api_entry.set_hexpand(true);
    advanced_grid.attach(&api_entry, 1, 0, 1, 1);
    
    // Connect API entry to auto-save
    let config_clone = shared_config.clone();
    api_entry.connect_changed(move |entry| {
        let mut config = config_clone.borrow_mut();
        config.insert("FACTS_API".to_string(), entry.text().to_string());
        save_config(&config);
    });
    
    // Text-to-Speech Setting
    let tts_label = gtk::Label::new(Some("Text-to-Speech"));
    tts_label.set_halign(gtk::Align::Start);
    advanced_grid.attach(&tts_label, 0, 1, 1, 1);
    
    let tts_switch = gtk::Switch::new();
    tts_switch.set_halign(gtk::Align::End);
    tts_switch.set_active(shared_config.borrow().get("TTS_ENABLED").unwrap_or(&String::from("no")) == "yes");
    advanced_grid.attach(&tts_switch, 1, 1, 1, 1);
    
    // Connect TTS switch to auto-save
    let config_clone = shared_config.clone();
    tts_switch.connect_state_set(move |_, state| {
        let mut config = config_clone.borrow_mut();
        config.insert("TTS_ENABLED".to_string(), if state { "yes".to_string() } else { "no".to_string() });
        save_config(&config);
        gtk::Inhibit(false)
    });
    
    set_card_content(&advanced_card, &advanced_grid);
    content_box.append(&advanced_card);
    
    // Debug settings card
    let debug_card = create_card("Debug Settings");
    let debug_grid = gtk::Grid::new();
    debug_grid.set_row_spacing(15);
    debug_grid.set_column_spacing(15);
    debug_grid.set_margin_top(10);
    debug_grid.set_margin_bottom(10);
    debug_grid.set_margin_start(10);
    debug_grid.set_margin_end(10);
    
    // Debug Enabled Setting
    let debug_enabled_label = gtk::Label::new(Some("Enable Debug Logging"));
    debug_enabled_label.set_halign(gtk::Align::Start);
    debug_grid.attach(&debug_enabled_label, 0, 0, 1, 1);
    
    let debug_enabled_switch = gtk::Switch::new();
    debug_enabled_switch.set_halign(gtk::Align::End);
    debug_enabled_switch.set_active(shared_config.borrow().get("DEBUG_ENABLED").unwrap_or(&String::from("no")) == "yes");
    debug_grid.attach(&debug_enabled_switch, 1, 0, 1, 1);
    
    // Connect debug enabled switch to auto-save
    let config_clone = shared_config.clone();
    debug_enabled_switch.connect_state_set(move |_, state| {
        let mut config = config_clone.borrow_mut();
        config.insert("DEBUG_ENABLED".to_string(), if state { "yes".to_string() } else { "no".to_string() });
        save_config(&config);
        gtk::Inhibit(false)
    });
    
    // Debug Log File Setting
    let debug_log_label = gtk::Label::new(Some("Debug Log File"));
    debug_log_label.set_halign(gtk::Align::Start);
    debug_grid.attach(&debug_log_label, 0, 1, 1, 1);
    
    let debug_log_entry = gtk::Entry::new();
    debug_log_entry.set_text(shared_config.borrow().get("DEBUG_LOG_FILE").unwrap_or(&String::from("$HOME/.cache/cool_facts_debug.log")));
    debug_log_entry.set_halign(gtk::Align::End);
    debug_log_entry.set_hexpand(true);
    debug_grid.attach(&debug_log_entry, 1, 1, 1, 1);
    
    // Connect debug log entry to auto-save
    let config_clone = shared_config.clone();
    debug_log_entry.connect_changed(move |entry| {
        let mut config = config_clone.borrow_mut();
        config.insert("DEBUG_LOG_FILE".to_string(), entry.text().to_string());
        save_config(&config);
    });
    
    // Debug Level Setting
    let debug_level_label = gtk::Label::new(Some("Debug Level"));
    debug_level_label.set_halign(gtk::Align::Start);
    debug_grid.attach(&debug_level_label, 0, 2, 1, 1);
    
    let debug_level_adj = gtk::Adjustment::new(
        shared_config.borrow().get("DEBUG_LEVEL").unwrap_or(&String::from("3")).parse::<f64>().unwrap_or(3.0),
        1.0, 4.0, 1.0, 1.0, 0.0
    );
    let debug_level_spin = gtk::SpinButton::new(Some(&debug_level_adj), 1.0, 0);
    debug_level_spin.set_halign(gtk::Align::End);
    debug_grid.attach(&debug_level_spin, 1, 2, 1, 1);
    
    // Connect debug level spinner to auto-save
    let config_clone = shared_config.clone();
    debug_level_spin.connect_value_changed(move |spin| {
        let mut config = config_clone.borrow_mut();
        config.insert("DEBUG_LEVEL".to_string(), spin.value().to_string());
        save_config(&config);
    });
    
    // Debug level description
    let debug_level_desc = gtk::Label::new(Some("1=errors only, 2=warnings, 3=info, 4=verbose"));
    debug_level_desc.set_halign(gtk::Align::Start);
    debug_level_desc.add_css_class("dim-label");
    debug_level_desc.add_css_class("caption");
    debug_grid.attach(&debug_level_desc, 0, 3, 2, 1);
    
    set_card_content(&debug_card, &debug_grid);
    content_box.append(&debug_card);
    
    // Add a status indicator for auto-save
    let status_indicator = gtk::Label::new(Some("Settings are applied automatically"));
    status_indicator.add_css_class("dim-label");
    status_indicator.add_css_class("caption");
    status_indicator.set_halign(gtk::Align::End);
    status_indicator.set_margin_top(20);
    content_box.append(&status_indicator);
    
    // Connect refresh button
    refresh_button.connect_clicked(glib::clone!(@weak enable_switch, @weak interval_spin, 
        @weak display_time_spin, @weak title_entry, @weak api_entry, @weak tts_switch, 
        @weak debug_enabled_switch, @weak debug_log_entry, @weak debug_level_spin, @weak shared_config, @weak status_value => move |_| {
        
        // Reload configuration
        *shared_config.borrow_mut() = load_config();
        let config = shared_config.borrow();
        
        // Check service status
        let is_running = check_if_facts_script_running();
        
        // Update status indicator
        if is_running {
            status_value.set_text("Running");
            status_value.remove_css_class("error");
            status_value.add_css_class("success");
        } else {
            status_value.set_text("Not Running");
            status_value.remove_css_class("success");
            status_value.add_css_class("error");
        }
        
        // Update UI without triggering change events
        let is_enabled = config.get("ENABLE_FACTS").unwrap_or(&String::from("yes")) == "yes";
        enable_switch.set_active(is_enabled);
        
        // Synchronize service state with config
        if is_enabled != is_running {
            if is_enabled {
                // Start the service
                let script_path = get_facts_script_path();
                let _ = Command::new("bash")
                    .arg(script_path)
                    .spawn();
                
                // Update UI
                status_value.set_text("Running");
                status_value.remove_css_class("error");
                status_value.add_css_class("success");
            } else {
                // Stop the service
                let _ = Command::new("pkill")
                    .arg("-f")
                    .arg("cool_facts.sh")
                    .output();
                
                // Update UI
                status_value.set_text("Not Running");
                status_value.remove_css_class("success");
                status_value.add_css_class("error");
            }
        }
        
        interval_spin.set_value(config.get("INTERVAL").unwrap_or(&String::from("5")).parse::<f64>().unwrap_or(5.0));
        display_time_spin.set_value(config.get("DISPLAY_TIME").unwrap_or(&String::from("10")).parse::<f64>().unwrap_or(10.0));
        title_entry.set_text(config.get("TITLE").unwrap_or(&String::from("Did you know?")));
        api_entry.set_text(config.get("FACTS_API").unwrap_or(&String::from("https://uselessfacts.jsph.pl/api/v2/facts/random")));
        tts_switch.set_active(config.get("TTS_ENABLED").unwrap_or(&String::from("no")) == "yes");
        debug_enabled_switch.set_active(config.get("DEBUG_ENABLED").unwrap_or(&String::from("no")) == "yes");
        debug_log_entry.set_text(config.get("DEBUG_LOG_FILE").unwrap_or(&String::from("$HOME/.cache/cool_facts_debug.log")));
        debug_level_spin.set_value(config.get("DEBUG_LEVEL").unwrap_or(&String::from("3")).parse::<f64>().unwrap_or(3.0));
    }));
    
    scroll.set_child(Some(&content_box));
    container.append(&scroll);
    content.append(&container);
    
    content.into()
}

fn get_config_file_path() -> PathBuf {
    get_facts_config_path()
}

fn load_config() -> HashMap<String, String> {
    let mut config = HashMap::new();
    let path = get_config_file_path();
    
    if !path.exists() {
        return config;
    }
    
    // Read the file
    if let Ok(file) = File::open(&path) {
        let reader = io::BufReader::new(file);
        
        for line in reader.lines() {
            if let Ok(line) = line {
                let trimmed = line.trim();
                
                // Skip comments and empty lines
                if trimmed.is_empty() || trimmed.starts_with('#') {
                    continue;
                }
                
                // Parse key-value pairs
                if let Some(pos) = trimmed.find('=') {
                    let key = trimmed[..pos].trim().to_string();
                    let value = trimmed[pos+1..].trim().to_string();
                    config.insert(key, value);
                }
            }
        }
    }
    
    config
}

fn save_config(config: &HashMap<String, String>) -> bool {
    let path = get_config_file_path();
    
    // Create parent directories if they don't exist
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            if let Err(_) = fs::create_dir_all(parent) {
                return false;
            }
        }
    }
    
    // Read existing file to preserve comments and structure
    let mut lines = Vec::new();
    let mut processed_keys = Vec::new();
    
    if path.exists() {
        if let Ok(file) = File::open(&path) {
            let reader = io::BufReader::new(file);
            
            for line in reader.lines() {
                if let Ok(line) = line {
                    let trimmed = line.trim();
                    
                    // Preserve comments and empty lines
                    if trimmed.is_empty() || trimmed.starts_with('#') {
                        lines.push(line);
                        continue;
                    }
                    
                    // Update existing keys
                    if let Some(pos) = trimmed.find('=') {
                        let key = trimmed[..pos].trim().to_string();
                        if let Some(value) = config.get(&key) {
                            lines.push(format!("{}={}", key, value));
                            processed_keys.push(key.clone());
                        } else {
                            // Keep unchanged lines
                            lines.push(line);
                        }
                    } else {
                        // Keep any other lines
                        lines.push(line);
                    }
                }
            }
        }
    }
    
    // Add any new keys that weren't in the original file
    for (key, value) in config {
        if !processed_keys.contains(key) {
            lines.push(format!("{}={}", key, value));
        }
    }
    
    // Write back to file
    if let Ok(mut file) = File::create(&path) {
        for line in lines {
            if let Err(_) = writeln!(file, "{}", line) {
                return false;
            }
        }
        return true;
    }
    
    false
}

fn check_if_facts_script_running() -> bool {
    // Check if the cool_facts.sh script is running using pgrep
    let output = Command::new("pgrep")
        .arg("-f")
        .arg("cool_facts.sh")
        .output();
    
    match output {
        Ok(output) => {
            // If the command was successful and returned PIDs, the script is running
            !output.stdout.is_empty()
        },
        Err(_) => {
            // If the command failed, assume the script is not running
            false
        }
    }
}
