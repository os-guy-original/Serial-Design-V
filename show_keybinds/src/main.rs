use gtk::prelude::*;
use gtk::{Application, ApplicationWindow, CssProvider};
use anyhow::{Result, anyhow};
use log::{info, error};

mod config_parser;
mod ui;

use config_parser::ConfigParser;

const APP_ID: &str = "com.github.hyprland_keybinds";

fn main() -> Result<()> {
    // Initialize logger
    env_logger::init();
    
    // Initialize GTK
    gtk::init()?;
    
    // Load CSS
    load_css();
    
    // Create a new application
    let app = Application::builder()
        .application_id(APP_ID)
        .build();
    
    // Connect to "activate" signal
    app.connect_activate(build_ui);
    
    // Run the application
    let status = app.run();
    if status == 0.into() {
        Ok(())
    } else {
        Err(anyhow!("Application exited with status: {:?}", status))
    }
}

fn build_ui(app: &Application) {
    // Parse keybinds from config
    let mut config_parser = ConfigParser::new();
    let keybinds = match config_parser.parse_keybinds() {
        Ok(keybinds) => {
            info!("Found {} keybinds", keybinds.len());
            keybinds
        },
        Err(e) => {
            error!("Failed to parse keybinds: {}", e);
            Vec::new()
        }
    };
    
    // Create a window with fixed size and floating behavior
    let window = ApplicationWindow::builder()
        .application(app)
        .title("Hyprland Keybinds")
        .default_width(800)
        .default_height(600)
        .width_request(800)
        .height_request(600)
        .resizable(false)
        .decorated(true)
        .build();
    
    // Main vertical box
    let main_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
    
    // Create header bar with dark background
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    header_box.add_css_class("header");
    header_box.set_spacing(10);
    
    // Add title to header
    let title_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
    title_box.set_margin_start(20);
    title_box.set_margin_top(10);
    title_box.set_margin_bottom(10);
    title_box.set_halign(gtk::Align::Start);
    title_box.set_hexpand(true);
    
    let title_label = gtk::Label::new(Some("Current List Of"));
    title_label.add_css_class("header-title");
    title_label.set_halign(gtk::Align::Start);
    
    let subtitle_label = gtk::Label::new(Some("Serial Design V Keybinds"));
    subtitle_label.add_css_class("header-subtitle");
    subtitle_label.set_halign(gtk::Align::Start);
    
    title_box.append(&title_label);
    title_box.append(&subtitle_label);
    
    // Create search button for header
    let search_button = gtk::Button::with_label("Search");
    search_button.add_css_class("search-button");
    search_button.set_margin_end(20);
    search_button.set_valign(gtk::Align::Center);
    
    // Add elements to header
    header_box.append(&title_box);
    header_box.append(&search_button);
    
    // Create search entry (initially hidden)
    let search_entry = gtk::SearchEntry::new();
    search_entry.set_placeholder_text(Some("Search keybinds..."));
    search_entry.set_margin_start(20);
    search_entry.set_margin_end(5);
    search_entry.set_margin_top(10);
    search_entry.set_margin_bottom(10);
    search_entry.set_hexpand(true);
    
    // Create search container with entry and close button
    let search_container = gtk::Box::new(gtk::Orientation::Horizontal, 5);
    search_container.set_visible(false);
    search_container.set_margin_start(20);
    search_container.set_margin_end(20);
    search_container.set_margin_top(10);
    search_container.set_margin_bottom(10);
    
    // Add close button for search
    let close_button = gtk::Button::new();
    let close_icon = gtk::Image::from_icon_name("window-close-symbolic");
    close_button.set_child(Some(&close_icon));
    close_button.set_tooltip_text(Some("Close"));
    
    // Add widgets to search container
    search_container.append(&search_entry);
    search_container.append(&close_button);
    
    // Add header and search to main box
    main_box.append(&header_box);
    main_box.append(&search_container);
    
    // Connect search button click
    let search_container_weak = search_container.downgrade();
    let search_button_weak = search_button.downgrade();
    search_button.connect_clicked(move |_| {
        if let (Some(container), Some(btn)) = (search_container_weak.upgrade(), search_button_weak.upgrade()) {
            container.set_visible(true);
            btn.set_sensitive(false);
            // Focus the search entry directly
            if let Some(entry) = container.first_child() {
                if let Some(search_entry) = entry.downcast_ref::<gtk::SearchEntry>() {
                    search_entry.grab_focus();
                }
            }
        }
    });
    
    // Connect close button click
    let search_container_weak = search_container.downgrade();
    let search_button_weak = search_button.downgrade();
    close_button.connect_clicked(move |_| {
        if let (Some(container), Some(btn)) = (search_container_weak.upgrade(), search_button_weak.upgrade()) {
            container.set_visible(false);
            btn.set_sensitive(true);
            
            // Clear the search entry
            if let Some(entry) = container.first_child() {
                if let Some(search_entry) = entry.downcast_ref::<gtk::SearchEntry>() {
                    search_entry.set_text("");
                }
            }
        }
    });
    
    // Create a scrolled window for the keybind list
    let scrolled_window = gtk::ScrolledWindow::new();
    scrolled_window.set_vexpand(true);
    scrolled_window.set_hexpand(true);
    scrolled_window.set_policy(gtk::PolicyType::Automatic, gtk::PolicyType::Automatic);
    
    // Create a FlowBox to arrange keybinds in a grid
    let keybind_flow = gtk::FlowBox::new();
    keybind_flow.set_selection_mode(gtk::SelectionMode::None);
    keybind_flow.set_homogeneous(false);
    keybind_flow.set_column_spacing(10);
    keybind_flow.set_row_spacing(10);
    keybind_flow.set_min_children_per_line(1);
    keybind_flow.set_max_children_per_line(4);
    keybind_flow.set_activate_on_single_click(false);
    keybind_flow.set_margin_start(10);
    keybind_flow.set_margin_end(10);
    keybind_flow.set_margin_top(10);
    keybind_flow.set_margin_bottom(10);
    keybind_flow.set_valign(gtk::Align::Start);
    keybind_flow.set_halign(gtk::Align::Fill);
    keybind_flow.set_vexpand(true);
    keybind_flow.set_hexpand(true);
    
    // Populate keybind grid
    for keybind in &keybinds {
        // Create a frame for better visibility
        let frame = gtk::Frame::new(None);
        frame.set_size_request(180, 80); // Sabit genişlik ve minimum yükseklik
        
        // Create a box for this keybind
        let keybind_box = gtk::Box::new(gtk::Orientation::Vertical, 3);
        keybind_box.set_margin_top(8);
        keybind_box.set_margin_bottom(8);
        keybind_box.set_margin_start(10);
        keybind_box.set_margin_end(10);
        keybind_box.set_vexpand(true);  // Dikey genişleme
        keybind_box.set_valign(gtk::Align::Center);  // Dikey ortalama
        
        // Create the key combo label
        let key_combo = if keybind.modifiers.is_empty() {
            keybind.key.clone()
        } else {
            format!("{} + {}", keybind.modifiers.join(" + "), keybind.key)
        };
        
        let key_label = gtk::Label::new(Some(&key_combo));
        key_label.add_css_class("keybind-combo");
        key_label.set_xalign(0.0);
        key_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        
        // Create the action label - simplify it for display
        let display_action = if keybind.action.starts_with("exec") {
            if let Some(first_comma) = keybind.action.find(',') {
                if let Some(command) = keybind.action[first_comma+1..].trim().split_whitespace().next() {
                    command.to_string()
                } else {
                    keybind.action.clone()
                }
            } else {
                keybind.action.clone()
            }
        } else {
            keybind.action.clone()
        };
        
        let action_label = gtk::Label::new(Some(&display_action));
        action_label.add_css_class("keybind-action");
        action_label.set_xalign(0.0);
        action_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        
        // Add both labels to the box
        keybind_box.append(&key_label);
        keybind_box.append(&action_label);
        
        // Add the box to the frame
        frame.set_child(Some(&keybind_box));
        
        // Add the frame to the flow box
        keybind_flow.insert(&frame, -1);
    }
    
    // Add flow box to scrolled window
    scrolled_window.set_child(Some(&keybind_flow));
    main_box.append(&scrolled_window);
    
    // Set up simple search filtering
    let keybind_flow_weak = keybind_flow.downgrade();
    search_entry.connect_search_changed(move |entry| {
        let search_text = entry.text().to_lowercase();
        
        if let Some(flow) = keybind_flow_weak.upgrade() {
            // Get all children safely
            for child in flow.observe_children().snapshot().iter() {
                if let Some(flow_child) = child.downcast_ref::<gtk::FlowBoxChild>() {
                    // Default visibility - show all if search is empty
                    let mut visible = search_text.is_empty();
                    
                    // Only do detailed check if needed
                    if !search_text.is_empty() {
                        if let Some(frame) = flow_child.child() {
                            if let Some(box_widget) = frame.first_child() {
                                // Try each label in the box for a match
                                if let Some(keybind_box) = box_widget.downcast_ref::<gtk::Box>() {
                                    let mut curr = keybind_box.first_child();
                                    while let Some(widget) = curr {
                                        if let Some(label) = widget.downcast_ref::<gtk::Label>() {
                                            if label.text().to_lowercase().contains(&search_text) {
                                                visible = true;
                                                break;
                                            }
                                        }
                                        curr = widget.next_sibling();
                                    }
                                }
                            }
                        }
                    }
                    
                    // Set visibility based on search match
                    flow_child.set_visible(visible);
                }
            }
        }
    });
    
    // Set the main box as the window's child
    window.set_child(Some(&main_box));
    
    // Show the window
    window.present();
}

fn load_css() {
    // Load CSS for styling
    let provider = CssProvider::new();
    provider.load_from_data(
        "
        .header {
            padding: 10px 0;
        }
        
        .header-title {
            font-size: 16px;
            font-weight: normal;
        }
        
        .header-subtitle {
            font-size: 24px;
            font-weight: bold;
        }
        
        .search-button {
            border-radius: 18px;
            padding: 5px 15px;
            font-weight: bold;
        }
        
        .keybind-combo {
            font-weight: bold;
            font-size: 15px;
            margin-bottom: 3px;
        }
        
        .keybind-action {
            font-size: 12px;
            opacity: 0.7;
        }
        
        entry {
            border-radius: 4px;
            padding: 6px;
        }
        "
    );
    
    // Add the provider to the default screen
    gtk::style_context_add_provider_for_display(
        &gtk::gdk::Display::default().expect("Could not connect to a display."),
        &provider,
        gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
    );
}
