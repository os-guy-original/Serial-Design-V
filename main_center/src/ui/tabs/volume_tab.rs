use gtk::prelude::*;
use gtk;
use libadwaita as adw;
use crate::ui::tabs::ui_utils::{create_card, set_card_content};
use std::io::Read;
use std::process::{Command, Stdio};
use std::collections::HashMap;

// Function to get current sink volume
fn get_sink_volume() -> f64 {
    let output = Command::new("sh")
        .arg("-c")
        .arg("pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+(?=%)' | head -1")
        .output();
    
    match output {
        Ok(output) => {
            let volume_str = String::from_utf8_lossy(&output.stdout);
            match volume_str.trim().parse::<f64>() {
                Ok(volume) => volume,
                Err(_) => 75.0 // Default if parsing fails
            }
        },
        Err(_) => 75.0 // Default if command fails
    }
}

// Function to get current source (microphone) volume
fn get_source_volume() -> f64 {
    let output = Command::new("sh")
        .arg("-c")
        .arg("pactl get-source-volume @DEFAULT_SOURCE@ | grep -oP '[0-9]+(?=%)' | head -1")
        .output();
    
    match output {
        Ok(output) => {
            let volume_str = String::from_utf8_lossy(&output.stdout);
            match volume_str.trim().parse::<f64>() {
                Ok(volume) => volume,
                Err(_) => 70.0 // Default if parsing fails
            }
        },
        Err(_) => 70.0 // Default if command fails
    }
}

// Function to check if sink is muted
fn is_sink_muted() -> bool {
    let output = Command::new("sh")
        .arg("-c")
        .arg("pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo 'muted' || echo 'unmuted'")
        .output();
    
    match output {
        Ok(output) => {
            let mute_str = String::from_utf8_lossy(&output.stdout);
            mute_str.trim() == "muted"
        },
        Err(_) => false // Default to unmuted if command fails
    }
}

// Function to check if source is muted
fn is_source_muted() -> bool {
    let output = Command::new("sh")
        .arg("-c")
        .arg("pactl get-source-mute @DEFAULT_SOURCE@ | grep -q 'yes' && echo 'muted' || echo 'unmuted'")
        .output();
    
    match output {
        Ok(output) => {
            let mute_str = String::from_utf8_lossy(&output.stdout);
            mute_str.trim() == "muted"
        },
        Err(_) => false // Default to unmuted if command fails
    }
}

// Structure to hold audio application information
struct AudioApp {
    id: u32,
    name: String,
    volume: f64,
    is_muted: bool,
    icon_name: String,
}

// Function to get active audio applications
fn get_audio_apps() -> Vec<AudioApp> {
    let mut apps = Vec::new();
    
    let output = Command::new("sh")
        .arg("-c")
        .arg("pactl list sink-inputs")
        .output();
    
    if let Ok(output) = output {
        let output_str = String::from_utf8_lossy(&output.stdout);
        let sections: Vec<&str> = output_str.split("Sink Input #").skip(1).collect();
        
        for section in sections {
            let mut id = 0;
            let mut name = String::new();
            let mut volume = 100.0;
            let mut is_muted = false;
            
            // Extract ID
            if let Some(first_line) = section.lines().next() {
                if let Ok(parsed_id) = first_line.trim().parse::<u32>() {
                    id = parsed_id;
                }
            }
            
            // Extract application name
            if let Some(app_name_line) = section.lines()
                .find(|line| line.trim().starts_with("application.name = ")) {
                if let Some(app_name) = app_name_line.split('=').nth(1) {
                    // Clean up the name: remove quotes, trim
                    name = app_name.trim()
                        .trim_matches('"')
                        .to_string();
                }
            }
            
            // If no application.name, try application.process.binary
            if name.is_empty() {
                if let Some(binary_line) = section.lines()
                    .find(|line| line.trim().starts_with("application.process.binary = ")) {
                    if let Some(binary_name) = binary_line.split('=').nth(1) {
                        name = binary_name.trim()
                            .trim_matches('"')
                            .to_string();
                    }
                }
            }
            
            // If still no name, just use the ID
            if name.is_empty() {
                name = format!("Application #{}", id);
            }
            
            // Extract volume
            if let Some(volume_line) = section.lines()
                .find(|line| line.trim().starts_with("Volume:")) {
                if let Some(volume_percent) = volume_line
                    .find('%')
                    .and_then(|pos| {
                        let vol_str = &volume_line[..pos];
                        vol_str.chars().rev()
                            .take_while(|c| c.is_digit(10) || *c == ' ')
                            .collect::<String>()
                            .chars()
                            .rev()
                            .collect::<String>();
                        vol_str.trim().parse::<f64>().ok()
                    }) {
                    volume = volume_percent;
                }
            }
            
            // Check mute status
            if let Some(mute_line) = section.lines()
                .find(|line| line.trim().starts_with("Mute:")) {
                is_muted = mute_line.contains("yes");
            }
            
            // Determine icon based on application name
            let icon_name = determine_app_icon(&name);
            
            // Add to apps list
            apps.push(AudioApp { 
                id, 
                name, 
                volume, 
                is_muted,
                icon_name 
            });
        }
    }
    
    apps
}

// Helper function to determine icon name based on app name
fn determine_app_icon(app_name: &str) -> String {
    let app_name_lower = app_name.to_lowercase();
    
    // Map common applications to appropriate icons
    let app_icon_map: HashMap<&str, &str> = [
        ("firefox", "web-browser"),
        ("chrome", "web-browser"),
        ("chromium", "web-browser"),
        ("brave", "web-browser"),
        ("vlc", "multimedia-player"),
        ("mpv", "multimedia-player"),
        ("spotify", "multimedia-player"),
        ("discord", "network-workgroup"),
        ("element", "network-workgroup"),
        ("telegram", "network-workgroup"),
        ("zoom", "video-display"),
        ("skype", "video-display"),
        ("kodi", "multimedia-player"),
        ("rhythmbox", "multimedia-player"),
        ("clementine", "multimedia-player"),
    ].iter().cloned().collect();
    
    for (app, icon) in app_icon_map {
        if app_name_lower.contains(app) {
            return icon.to_string();
        }
    }
    
    // Default icon if no match
    "applications-multimedia".to_string()
}

// Function to set the volume of a specific application
fn set_app_volume(app_id: u32, volume: i32) {
    let command = format!("pactl set-sink-input-volume {} {}%", app_id, volume);
    
    std::thread::spawn(move || {
        match Command::new("sh")
            .arg("-c")
            .arg(&command)
            .output() {
            Ok(_) => println!("Set app #{} volume to {}%", app_id, volume),
            Err(e) => eprintln!("Failed to set app volume: {}", e),
        }
    });
}

// Function to set the mute state of a specific application
fn set_app_mute(app_id: u32, mute: bool) {
    let command = format!("pactl set-sink-input-mute {} {}", app_id, if mute { "1" } else { "0" });
    
    std::thread::spawn(move || {
        match Command::new("sh")
            .arg("-c")
            .arg(&command)
            .output() {
            Ok(_) => println!("Set app #{} mute state to {}", app_id, mute),
            Err(e) => eprintln!("Failed to set app mute: {}", e),
        }
    });
}

pub fn create_volume_manager_content() -> gtk::Widget {
    // Create a toast overlay, we'll keep this without showing toasts
    let toast_overlay = adw::ToastOverlay::new();
    
    let content = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content.set_margin_top(24);
    content.set_margin_bottom(24);
    content.set_margin_start(24);
    content.set_margin_end(24);
    
    // Create a scrolled window for the volume manager
    let scroll = gtk::ScrolledWindow::new();
    scroll.set_vexpand(true);
    scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    
    let volume_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    
    // Create a card for the volume manager
    let volume_card = create_card("Volume Manager");
    
    // Create a grid for volume controls
    let volume_grid = gtk::Grid::new();
    volume_grid.set_row_spacing(16);
    volume_grid.set_column_spacing(32);
    volume_grid.set_margin_top(16);
    volume_grid.set_margin_bottom(16);
    volume_grid.set_margin_start(16);
    volume_grid.set_margin_end(16);
    
    // Get current system volume
    let current_volume = get_sink_volume();
    let current_mute = is_sink_muted();
    
    // Main volume control
    let main_volume_label = gtk::Label::new(Some("Main Volume"));
    main_volume_label.set_halign(gtk::Align::Start);
    main_volume_label.add_css_class("heading");
    
    let main_volume_adjustment = gtk::Adjustment::new(
        current_volume,  // Use current system volume
        0.0,   // min
        150.0, // max - allow up to 150% for PulseAudio
        1.0,   // step
        5.0,   // page
        0.0    // page_size
    );
    
    let main_volume_scale = gtk::Scale::new(gtk::Orientation::Horizontal, Some(&main_volume_adjustment));
    main_volume_scale.set_hexpand(true);
    main_volume_scale.set_draw_value(true);
    main_volume_scale.set_value_pos(gtk::PositionType::Right);
    main_volume_scale.set_digits(0);
    
    // Use default GTK styling
    main_volume_scale.add_css_class("accent");
    
    // Connect to volume changes and directly control system volume
    main_volume_adjustment.connect_value_changed(move |adj| {
        let value = adj.value() as i32;
        
        // Use pactl to set the system volume
        let command = format!("pactl set-sink-volume @DEFAULT_SINK@ {}%", value);
        
        // Execute the command in a separate thread to avoid UI blocking
        std::thread::spawn(move || {
            match std::process::Command::new("sh")
                .arg("-c")
                .arg(&command)
                .output() {
                Ok(_) => println!("Set system volume to {}%", value),
                Err(e) => eprintln!("Failed to set volume: {}", e),
            }
        });
    });
    
    // Add icon for main volume
    let main_volume_icon = gtk::Image::from_icon_name("audio-volume-high-symbolic");
    
    volume_grid.attach(&main_volume_icon, 0, 0, 1, 1);
    volume_grid.attach(&main_volume_label, 1, 0, 1, 1);
    volume_grid.attach(&main_volume_scale, 2, 0, 1, 1);
    
    // Add mute toggle button
    let mute_button = gtk::ToggleButton::new();
    mute_button.set_icon_name("audio-volume-muted-symbolic");
    mute_button.set_tooltip_text(Some("Mute/Unmute"));
    mute_button.set_active(current_mute); // Set based on current state
    
    mute_button.connect_toggled(|button| {
        let muted = button.is_active();
        let command = format!("pactl set-sink-mute @DEFAULT_SINK@ {}", if muted { "1" } else { "0" });
        
        std::thread::spawn(move || {
            match std::process::Command::new("sh")
                .arg("-c")
                .arg(&command)
                .output() {
                Ok(_) => println!("Set mute state to {}", muted),
                Err(e) => eprintln!("Failed to set mute: {}", e),
            }
        });
    });
    
    volume_grid.attach(&mute_button, 3, 0, 1, 1);
    
    // Get current microphone volume and mute state
    let current_mic_volume = get_source_volume();
    let current_mic_mute = is_source_muted();
    
    // Add microphone volume control
    let mic_volume_label = gtk::Label::new(Some("Microphone"));
    mic_volume_label.set_halign(gtk::Align::Start);
    mic_volume_label.add_css_class("heading");
    
    let mic_volume_adjustment = gtk::Adjustment::new(
        current_mic_volume,  // Use current microphone volume
        0.0,   // min
        150.0, // max - allow up to 150% for PulseAudio
        1.0,   // step
        5.0,   // page
        0.0    // page_size
    );
    
    let mic_volume_scale = gtk::Scale::new(gtk::Orientation::Horizontal, Some(&mic_volume_adjustment));
    mic_volume_scale.set_hexpand(true);
    mic_volume_scale.set_draw_value(true);
    mic_volume_scale.set_value_pos(gtk::PositionType::Right);
    mic_volume_scale.set_digits(0);
    mic_volume_scale.add_css_class("accent");
    
    // Connect to volume changes to control microphone
    mic_volume_adjustment.connect_value_changed(move |adj| {
        let value = adj.value() as i32;
        
        // Use pactl to set the microphone volume
        let command = format!("pactl set-source-volume @DEFAULT_SOURCE@ {}%", value);
        
        std::thread::spawn(move || {
            match std::process::Command::new("sh")
                .arg("-c")
                .arg(&command)
                .output() {
                Ok(_) => println!("Set microphone volume to {}%", value),
                Err(e) => eprintln!("Failed to set microphone volume: {}", e),
            }
        });
    });
    
    // Add icon for microphone
    let mic_icon = gtk::Image::from_icon_name("audio-input-microphone-symbolic");
    
    // Add mic mute toggle button
    let mic_mute_button = gtk::ToggleButton::new();
    mic_mute_button.set_icon_name("microphone-sensitivity-muted-symbolic");
    mic_mute_button.set_tooltip_text(Some("Mute/Unmute Microphone"));
    mic_mute_button.set_active(current_mic_mute); // Set based on current state
    
    mic_mute_button.connect_toggled(|button| {
        let muted = button.is_active();
        let command = format!("pactl set-source-mute @DEFAULT_SOURCE@ {}", if muted { "1" } else { "0" });
        
        std::thread::spawn(move || {
            match std::process::Command::new("sh")
                .arg("-c")
                .arg(&command)
                .output() {
                Ok(_) => println!("Set microphone mute state to {}", muted),
                Err(e) => eprintln!("Failed to set microphone mute: {}", e),
            }
        });
    });
    
    // Attach microphone controls to the grid (row 1)
    volume_grid.attach(&mic_icon, 0, 1, 1, 1);
    volume_grid.attach(&mic_volume_label, 1, 1, 1, 1);
    volume_grid.attach(&mic_volume_scale, 2, 1, 1, 1);
    volume_grid.attach(&mic_mute_button, 3, 1, 1, 1);
    
    // Add separator
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_top(10);
    separator.set_margin_bottom(10);
    
    volume_grid.attach(&separator, 0, 2, 4, 1);
    
    // Application volumes header - make it bigger
    let app_header_label = gtk::Label::new(Some("Application Volumes"));
    app_header_label.set_halign(gtk::Align::Start);
    app_header_label.add_css_class("title-2");
    app_header_label.set_margin_top(16);
    app_header_label.set_margin_bottom(8);
    
    volume_grid.attach(&app_header_label, 0, 3, 4, 1);
    
    // Create a container for application controls that can be updated
    let app_controls_container = gtk::Box::new(gtk::Orientation::Vertical, 8);
    volume_grid.attach(&app_controls_container, 0, 4, 4, 1);
    
    // Add a refresh button
    let refresh_button = gtk::Button::with_label("Refresh Audio Devices");
    refresh_button.set_margin_top(20);
    refresh_button.set_halign(gtk::Align::Center);
    refresh_button.set_hexpand(true);
    refresh_button.add_css_class("pill");
    refresh_button.add_css_class("suggested-action");
    
    // Clone adjustments and mute buttons for the refresh action
    let main_adj_clone = main_volume_adjustment.clone();
    let mic_adj_clone = mic_volume_adjustment.clone();
    let mute_btn_clone = mute_button.clone();
    let mic_mute_btn_clone = mic_mute_button.clone();
    let app_container_clone = app_controls_container.clone();
    
    // Function to update the application list
    let update_app_list = move |container: &gtk::Box| {
        // Clear existing controls - remove all children from the container
        while let Some(child) = container.first_child() {
            container.remove(&child);
        }
        
        // Get active applications
        let apps = get_audio_apps();
        
        if apps.is_empty() {
            // Show a message when no applications are using audio
            let no_apps_label = gtk::Label::new(Some("No applications currently using audio"));
            no_apps_label.set_margin_top(10);
            no_apps_label.set_margin_bottom(10);
            no_apps_label.add_css_class("dim-label");
            container.append(&no_apps_label);
        } else {
            // Add controls for each application
            for app in apps {
                // Create a grid for this app row with the same spacing as the main grid
                let app_row = gtk::Grid::new();
                app_row.set_column_spacing(32);
                app_row.set_margin_top(8);
                app_row.set_margin_bottom(8);
                
                // App icon - same column 0 as main volume
                let app_icon = gtk::Image::from_icon_name(&app.icon_name);
                
                // App label - same column 1 as main volume
                let app_label = gtk::Label::new(Some(&app.name));
                app_label.set_halign(gtk::Align::Start);
                
                // App volume adjustment
                let app_adjustment = gtk::Adjustment::new(
                    app.volume,
                    0.0,   // min
                    150.0, // max
                    1.0,   // step
                    5.0,   // page
                    0.0    // page_size
                );
                
                // App volume slider - make it exactly like the main slider
                let app_scale = gtk::Scale::new(gtk::Orientation::Horizontal, Some(&app_adjustment));
                app_scale.set_hexpand(true);  // This ensures the slider expands to fill available space
                app_scale.set_draw_value(true);
                app_scale.set_value_pos(gtk::PositionType::Right);
                app_scale.set_digits(0);
                app_scale.add_css_class("accent");
                
                // Connect to volume changes for this app
                let app_id = app.id;
                app_adjustment.connect_value_changed(move |adj| {
                    let value = adj.value() as i32;
                    set_app_volume(app_id, value);
                });
                
                // App mute button - same column 3 as main volume
                let app_mute_button = gtk::ToggleButton::new();
                app_mute_button.set_icon_name("audio-volume-muted-symbolic");
                app_mute_button.set_tooltip_text(Some("Mute/Unmute"));
                app_mute_button.set_active(app.is_muted);
                
                let app_id = app.id;
                app_mute_button.connect_toggled(move |button| {
                    let muted = button.is_active();
                    set_app_mute(app_id, muted);
                });
                
                // Attach everything to the grid - use same columns as main volume
                app_row.attach(&app_icon, 0, 0, 1, 1);
                app_row.attach(&app_label, 1, 0, 1, 1);
                app_row.attach(&app_scale, 2, 0, 1, 1);
                app_row.attach(&app_mute_button, 3, 0, 1, 1);
                
                // Append this app row to the container
                container.append(&app_row);
            }
        }
    };
    
    // Initial population of the app list
    update_app_list(&app_controls_container);
    
    // Connect refresh button click
    refresh_button.connect_clicked(move |_| {
        println!("Refreshing audio devices...");
        
        // Update main volume slider
        let updated_volume = get_sink_volume();
        main_adj_clone.set_value(updated_volume);
        
        // Update mic volume slider
        let updated_mic_volume = get_source_volume();
        mic_adj_clone.set_value(updated_mic_volume);
        
        // Update mute buttons
        let updated_mute = is_sink_muted();
        mute_btn_clone.set_active(updated_mute);
        
        let updated_mic_mute = is_source_muted();
        mic_mute_btn_clone.set_active(updated_mic_mute);
        
        // Update application list
        update_app_list(&app_container_clone);
    });
    
    volume_grid.attach(&refresh_button, 0, 5, 4, 1);
    
    // Use our helper function to set the content
    set_card_content(&volume_card, &volume_grid);
    volume_box.append(&volume_card);
    
    scroll.set_child(Some(&volume_box));
    content.append(&scroll);
    
    toast_overlay.set_child(Some(&content));
    toast_overlay.into()
} 