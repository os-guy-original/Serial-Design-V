use gtk::prelude::*;
use libadwaita as adw;
use libadwaita::prelude::*;
use std::fs;
use std::path::Path;

pub fn create_clock_config_content() -> gtk::Widget {
    let main_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
    main_box.set_hexpand(true);
    main_box.set_vexpand(true);

    // Header
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_top(20);
    header_box.set_margin_bottom(20);
    header_box.set_margin_start(20);
    header_box.set_margin_end(20);

    let title_label = gtk::Label::new(Some("Clock Configuration"));
    title_label.add_css_class("title-1");
    title_label.set_hexpand(true);
    title_label.set_halign(gtk::Align::Start);

    header_box.append(&title_label);
    main_box.append(&header_box);

    // Content area
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content_box.set_margin_start(20);
    content_box.set_margin_end(20);
    content_box.set_margin_bottom(20);

    // Algorithm selection group
    let algorithm_group = adw::PreferencesGroup::new();
    algorithm_group.set_title("Position Algorithm");
    algorithm_group.set_description(Some("Choose how the clock finds its position on the wallpaper"));

    let algorithm_row = adw::ComboRow::new();
    algorithm_row.set_title("Algorithm");
    algorithm_row.set_subtitle("Affects speed and accuracy of positioning");

    let algorithm_model = gtk::StringList::new(&[
        "Ultra Fast (Recommended)",
        "Fast", 
        "Original (Most Accurate)"
    ]);
    algorithm_row.set_model(Some(&algorithm_model));

    // Load current algorithm
    let current_algorithm = load_current_algorithm();
    let selected_index = match current_algorithm.as_str() {
        "ultra_fast" => 0,
        "fast" => 1,
        "original" => 2,
        _ => 0,
    };
    algorithm_row.set_selected(selected_index);

    // Save algorithm on change
    algorithm_row.connect_selected_notify(|row| {
        let algorithm = match row.selected() {
            0 => "ultra_fast",
            1 => "fast", 
            2 => "original",
            _ => "ultra_fast",
        };
        save_algorithm(algorithm);
    });

    algorithm_group.add(&algorithm_row);
    content_box.append(&algorithm_group);

    // Important info group
    let important_info_group = adw::PreferencesGroup::new();
    important_info_group.set_title("Important Information");
    
    let info_row = adw::ActionRow::new();
    info_row.set_title("Algorithm Recommendation");
    info_row.set_subtitle("Original method might be faster than others. I put different methods because different methods can detect different areas based on the given wallpaper. If you want to use best accurate positioning method, use the \"Original\" method.");
    
    let info_icon = gtk::Image::from_icon_name("dialog-information-symbolic");
    info_row.add_prefix(&info_icon);
    
    important_info_group.add(&info_row);
    content_box.append(&important_info_group);

    // Performance info group
    let info_group = adw::PreferencesGroup::new();
    info_group.set_title("Algorithm Information");

    let ultra_fast_row = adw::ActionRow::new();
    ultra_fast_row.set_title("Ultra Fast");
    ultra_fast_row.set_subtitle("8x faster, strategic sampling");
    let ultra_fast_icon = gtk::Image::from_icon_name("emblem-ok-symbolic");
    ultra_fast_row.add_suffix(&ultra_fast_icon);

    let fast_row = adw::ActionRow::new();
    fast_row.set_title("Fast");
    fast_row.set_subtitle("4x faster, optimized search");
    let fast_icon = gtk::Image::from_icon_name("semi-starred-symbolic");
    fast_row.add_suffix(&fast_icon);

    let original_row = adw::ActionRow::new();
    original_row.set_title("Original");
    original_row.set_subtitle("Most thorough analysis");
    let original_icon = gtk::Image::from_icon_name("starred-symbolic");
    original_row.add_suffix(&original_icon);

    info_group.add(&ultra_fast_row);
    info_group.add(&fast_row);
    info_group.add(&original_row);
    content_box.append(&info_group);



    // Test button group
    let test_group = adw::PreferencesGroup::new();
    test_group.set_title("Test Configuration");

    let test_row = adw::ActionRow::new();
    test_row.set_title("Test Algorithm");
    test_row.set_subtitle("Run test on current wallpaper");

    let test_button = gtk::Button::with_label("Test");
    test_button.add_css_class("pill");
    test_button.set_valign(gtk::Align::Center);

    test_button.connect_clicked(|_| {
        test_algorithm();
    });

    test_row.add_suffix(&test_button);
    test_group.add(&test_row);
    content_box.append(&test_group);

    main_box.append(&content_box);
    main_box.upcast()
}

fn load_current_algorithm() -> String {
    let config_path = dirs::home_dir()
        .unwrap_or_default()
        .join(".config/hypr/scripts/ui/empty_area/config.conf");
    
    if let Ok(content) = fs::read_to_string(&config_path) {
        for line in content.lines() {
            if line.starts_with("ALGORITHM=") {
                return line.split('=').nth(1).unwrap_or("ultra_fast").to_string();
            }
        }
    }
    "ultra_fast".to_string()
}

fn save_algorithm(algorithm: &str) {
    let config_path = dirs::home_dir()
        .unwrap_or_default()
        .join(".config/hypr/scripts/ui/empty_area/config.conf");
    
    let config_content = format!(
        "# Empty Area Finder Configuration
# This file controls which algorithm is used for clock positioning

# Algorithm selection: original, fast, ultra_fast
ALGORITHM={}

# Performance settings
ENABLE_COMPLEXITY_AVOIDANCE=true
ENABLE_BACKGROUND_ANALYSIS=true
ENABLE_POSITION_CACHING=false

# Position preferences
PREFER_UPPER_POSITIONS=true
AVOID_CENTER_LOGO=true
USE_RULE_OF_THIRDS=true

# Debug settings
ENABLE_DEBUG_OUTPUT=false
SAVE_DEBUG_IMAGES=false
", algorithm);

    if let Some(parent) = config_path.parent() {
        let _ = fs::create_dir_all(parent);
    }
    
    if let Err(e) = fs::write(&config_path, config_content) {
        eprintln!("Failed to save algorithm config: {}", e);
    } else {
        println!("Clock algorithm changed to: {} ({})", algorithm, match algorithm {
        "ultra_fast" => "8x faster, strategic sampling",
        "fast" => "4x faster, optimized search", 
        "original" => "most thorough analysis",
        _ => "unknown algorithm",
    });
    }
}

fn test_algorithm() {
    // Show initial notification
    let _ = std::process::Command::new("notify-send")
        .arg("Clock Algorithm Test")
        .arg("Starting test... This may take a few seconds")
        .arg("-t")
        .arg("3000")
        .spawn();
    
    let wallpaper_path = dirs::home_dir()
        .unwrap_or_default()
        .join(".config/hypr/cache/state/last_wallpaper");
    
    if let Ok(wallpaper_content) = fs::read_to_string(&wallpaper_path) {
        let wallpaper = wallpaper_content.trim().to_string();
        if Path::new(&wallpaper).exists() {
            let dispatcher_path = dirs::home_dir()
                .unwrap_or_default()
                .join(".config/hypr/scripts/ui/empty_area/empty_area_dispatcher.py");
            
            // Get current algorithm for display
            let current_algorithm = load_current_algorithm();
            let algorithm_name = match current_algorithm.as_str() {
                "ultra_fast" => "Ultra Fast",
                "fast" => "Fast",
                "original" => "Original",
                _ => "Unknown",
            };
            
            std::thread::spawn(move || {
                let start_time = std::time::Instant::now();
                
                match std::process::Command::new("python3")
                    .arg(&dispatcher_path)
                    .arg(&wallpaper)
                    .output() {
                    Ok(output) => {
                        let duration = start_time.elapsed();
                        let result = String::from_utf8_lossy(&output.stdout);
                        
                        println!("\n=== Clock Algorithm Test Results ===");
                        println!("Algorithm: {}", algorithm_name);
                        println!("Processing time: {:.2}s", duration.as_secs_f64());
                        println!("Wallpaper: {}", wallpaper);
                        println!("\nDetailed output:\n{}", result);
                        println!("====================================\n");
                        
                        // Show detailed notification
                        let notification_text = format!(
                            "Test completed!\n{} algorithm took {:.2}s\nCheck terminal for detailed results",
                            algorithm_name,
                            duration.as_secs_f64()
                        );
                        
                        let _ = std::process::Command::new("notify-send")
                            .arg("Clock Algorithm Test - Success")
                            .arg(&notification_text)
                            .arg("-t")
                            .arg("5000")
                            .spawn();
                    }
                    Err(e) => {
                        eprintln!("Failed to test algorithm: {}", e);
                        let error_msg = format!(
                            "Test failed: {}\nCheck if Python script exists at:\n{}",
                            e,
                            dispatcher_path.display()
                        );
                        
                        let _ = std::process::Command::new("notify-send")
                            .arg("Clock Algorithm Test - Error")
                            .arg(&error_msg)
                            .arg("-t")
                            .arg("7000")
                            .spawn();
                    }
                }
            });
        } else {
            let error_msg = format!(
                "Wallpaper file not found:\n{}\n\nMake sure you have set a wallpaper first",
                wallpaper
            );
            
            let _ = std::process::Command::new("notify-send")
                .arg("Clock Algorithm Test - No Wallpaper")
                .arg(&error_msg)
                .arg("-t")
                .arg("5000")
                .spawn();
        }
    } else {
        let error_msg = format!(
            "Could not read wallpaper path from:\n{}\n\nMake sure Hyprland wallpaper system is working",
            wallpaper_path.display()
        );
        
        let _ = std::process::Command::new("notify-send")
            .arg("Clock Algorithm Test - Configuration Error")
            .arg(&error_msg)
            .arg("-t")
            .arg("5000")
            .spawn();
    }
}