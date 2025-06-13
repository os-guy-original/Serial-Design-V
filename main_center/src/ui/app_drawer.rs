use gtk::{self, prelude::*, gio};
use libadwaita as adw;
use libadwaita::prelude::AdwWindowExt;
use std::cell::RefCell;
use std::rc::Rc;
use std::collections::HashMap;
use std::sync::Arc;
use std::thread;
use glib;

pub struct AppDrawer {
    pub drawer: adw::Window,
    pub button: gtk::Button,
    search_entry: gtk::SearchEntry,
    categories_box: gtk::Box,
    all_apps: Rc<RefCell<Vec<AppInfo>>>,
}

#[derive(Clone)]
struct AppInfo {
    name: String,
    icon: String,
    exec: String,
}

impl AppDrawer {
    pub fn new() -> Self {
        // Create the button for opening the drawer
        let button = gtk::Button::new();
        button.set_icon_name("view-grid-symbolic");
        button.add_css_class("circular");
        button.add_css_class("flat");
        button.set_tooltip_text(Some("Open App Drawer"));
        
        // Create the drawer window
        let drawer = adw::Window::new();
        drawer.set_title(Some("App Drawer"));
        drawer.set_default_size(600, 500);
        drawer.set_modal(true);
        drawer.set_resizable(false);
        drawer.set_deletable(true);
        
        // Make the window floating for Wayland/Hyprland
        drawer.set_startup_id("WINDOW_ROLE=floating_window");
        
        // Create main content box
        let content_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
        
        // Create header bar with search
        let header_bar = adw::HeaderBar::new();
        header_bar.set_show_end_title_buttons(true);
        header_bar.set_title_widget(Some(&gtk::Label::new(Some("Applications"))));
        
        // Create search entry
        let search_entry = gtk::SearchEntry::new();
        search_entry.set_hexpand(true);
        search_entry.set_placeholder_text(Some("Search applications..."));
        header_bar.pack_start(&search_entry);
        
        content_box.append(&header_bar);
        
        // Create a scrolled window for app categories
        let scroll = gtk::ScrolledWindow::new();
        scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
        scroll.set_hexpand(true);
        scroll.set_vexpand(true);
        
        // Create a box to hold all categories
        let categories_box = gtk::Box::new(gtk::Orientation::Vertical, 15);
        categories_box.set_margin_start(20);
        categories_box.set_margin_end(20);
        categories_box.set_margin_top(20);
        categories_box.set_margin_bottom(20);
        
        scroll.set_child(Some(&categories_box));
        content_box.append(&scroll);
        
        // Set up drawer content
        drawer.set_content(Some(&content_box));
        
        let all_apps = Rc::new(RefCell::new(Vec::new()));
        
        let app_drawer = Self {
            drawer,
            button,
            search_entry,
            categories_box,
            all_apps,
        };
        
        // Connect the button to open the drawer
        let drawer_ref = app_drawer.drawer.clone();
        app_drawer.button.connect_clicked(move |_| {
            // Load applications before showing
            drawer_ref.present();
        });
        
        // Connect search entry to filter apps
        let all_apps_clone = Rc::clone(&app_drawer.all_apps);
        let categories_box_clone = app_drawer.categories_box.clone();
        app_drawer.search_entry.connect_search_changed(move |entry| {
            let search_text = entry.text().to_lowercase();
            Self::filter_apps(&categories_box_clone, &all_apps_clone.borrow(), &search_text);
        });
        
        // Load apps when drawer is shown
        let all_apps_clone = Rc::clone(&app_drawer.all_apps);
        let categories_box_clone = app_drawer.categories_box.clone();
        app_drawer.drawer.connect_map(move |_| {
            // Only reload if we don't have apps already
            if all_apps_clone.borrow().is_empty() {
                let apps = Self::load_applications();
                *all_apps_clone.borrow_mut() = apps;
                Self::populate_categories(&categories_box_clone, &all_apps_clone.borrow(), "");
            }
        });
        
        app_drawer
    }
    
    fn load_applications() -> Vec<AppInfo> {
        let mut apps = Vec::new();
        let app_info_list = gio::AppInfo::all();
        
        // Pre-allocate capacity to avoid reallocations
        apps.reserve(app_info_list.len());
        
        for app_info in app_info_list {
            if !app_info.should_show() {
                continue;
            }
            
            // Get app details
            let name = app_info.display_name().to_string();
            let icon = if let Some(icon) = app_info.icon() {
                // Use icon name if available
                if let Some(gicon) = icon.dynamic_cast_ref::<gio::ThemedIcon>() {
                    let names = gicon.names();
                    if !names.is_empty() {
                        if let Some(first_name) = names.first() {
                            first_name.to_string()
                        } else {
                            "application-x-executable-symbolic".to_string()
                        }
                    } else {
                        "application-x-executable-symbolic".to_string()
                    }
                } else {
                    "application-x-executable-symbolic".to_string()
                }
            } else {
                "application-x-executable-symbolic".to_string()
            };
            
            // Get exec command
            let exec = if let Some(cmd) = app_info.commandline() {
                cmd.as_os_str().to_string_lossy().to_string()
            } else {
                continue; // Skip if no command available
            };
            
            apps.push(AppInfo {
                name,
                icon,
                exec,
            });
        }
        
        // Sort apps alphabetically
        apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        
        apps
    }
    
    fn populate_categories(categories_box: &gtk::Box, apps: &[AppInfo], search_filter: &str) {
        // Clear existing content
        while let Some(child) = categories_box.first_child() {
            categories_box.remove(&child);
        }
        
        // Group apps by first letter
        let mut letter_groups: HashMap<String, Vec<&AppInfo>> = HashMap::with_capacity(27); // A-Z + #
        
        for app in apps {
            // Skip if doesn't match search filter
            if !search_filter.is_empty() && !app.name.to_lowercase().contains(search_filter) {
                continue;
            }
            
            // Get first letter and uppercase it
            let first_letter = app.name.chars()
                .next()
                .map(|c| c.to_uppercase().to_string())
                .unwrap_or_else(|| "#".to_string());
            
            // Get numeric or special characters under '#'
            let letter = if first_letter.chars().next().unwrap().is_alphabetic() {
                first_letter
            } else {
                "#".to_string()
            };
            
            letter_groups.entry(letter).or_default().push(app);
        }
        
        // Get sorted letters
        let mut letters: Vec<String> = letter_groups.keys().cloned().collect();
        letters.sort();
        
        // Special handling to put '#' at the end if it exists
        if let Some(pos) = letters.iter().position(|s| s == "#") {
            let special = letters.remove(pos);
            letters.push(special);
        }
        
        // Create category for each letter that has apps
        for letter in &letters {
            if let Some(apps) = letter_groups.get(letter) {
                // Create category expander
                let expander = Self::create_category_expander(letter, apps);
                categories_box.append(&expander);
            }
        }
        
        // Show "No results found" message if empty
        if categories_box.first_child().is_none() {
            let no_results = gtk::Label::new(Some("No applications found"));
            no_results.add_css_class("dim-label");
            no_results.set_margin_top(50);
            no_results.set_margin_bottom(50);
            categories_box.append(&no_results);
        }
    }
    
    fn create_category_expander(letter: &str, apps: &[&AppInfo]) -> gtk::Expander {
        // Create expander for the category
        let expander = gtk::Expander::new(Some(&format!("{} ({})", letter, apps.len())));
        expander.set_expanded(true);
        expander.add_css_class("app-category");
        
        // Create flow box for the apps in this category
        let flow_box = gtk::FlowBox::new();
        flow_box.set_valign(gtk::Align::Start);
        flow_box.set_max_children_per_line(5);
        flow_box.set_min_children_per_line(2);
        flow_box.set_selection_mode(gtk::SelectionMode::None);
        flow_box.set_homogeneous(true);
        flow_box.set_row_spacing(10);
        flow_box.set_column_spacing(10);
        flow_box.set_margin_top(10);
        flow_box.set_margin_bottom(10);
        
        // Add app buttons to the flow box
        for app in apps {
            flow_box.append(&Self::create_app_button(app));
        }
        
        expander.set_child(Some(&flow_box));
        expander
    }
    
    fn create_app_button(app: &AppInfo) -> gtk::Box {
        // Create button box
        let button_box = gtk::Box::new(gtk::Orientation::Vertical, 5);
        button_box.set_halign(gtk::Align::Center);
        button_box.add_css_class("app-button");
        
        // Create button to launch app
        let button = gtk::Button::new();
        button.set_halign(gtk::Align::Center);
        
        // Try to use the app's icon
        let icon = gtk::Image::from_icon_name(&app.icon);
        icon.set_pixel_size(48);
        button.set_child(Some(&icon));
        
        // Set tooltip with app name
        button.set_tooltip_text(Some(&app.name));
        
        // Make button look like an icon
        button.add_css_class("flat");
        button.add_css_class("circular");
        button.add_css_class("app-icon");
        
        // Connect click to launch the app
        let app_name = app.name.clone();
        let app_exec = app.exec.clone();
        button.connect_clicked(move |button| {
            // Create thread-safe wrapped values for the app info
            let app_name_arc = Arc::new(app_name.clone());
            let app_exec_arc = Arc::new(app_exec.clone());
            
            // Find the drawer window to close it after launching
            let mut widget: Option<gtk::Widget> = Some(button.clone().upcast());
            let mut window_to_close: Option<adw::Window> = None;
            
            while let Some(w) = widget {
                if let Some(window) = w.ancestor(adw::Window::static_type()) {
                    if let Ok(adw_window) = window.downcast::<adw::Window>() {
                        window_to_close = Some(adw_window);
                        break;
                    }
                }
                widget = w.parent();
            }
            
            // Create a channel to communicate between threads
            let (tx, rx) = glib::MainContext::channel(glib::PRIORITY_DEFAULT);
            
            // Clone app_name for use in the rx.attach closure
            let app_name_for_dialog = app_name.clone();
            
            // Spawn a separate thread to launch the application
            // This isolates the app launching from the main GTK thread
            thread::spawn(move || {
                // First try to find the app by name in the system's app registry
                let app_name = app_name_arc.as_ref();
                let app_exec = app_exec_arc.as_ref();
                let mut launched = false;
                
                // Create a launch context
                let context = gio::AppLaunchContext::new();
                
                // First approach: Try to launch by app name
                for app_info in &gio::AppInfo::all() {
                    if app_info.display_name().to_string() == *app_name {
                        match app_info.launch(&[], Some(&context)) {
                            Ok(_) => {
                                println!("Launched application: {}", app_name);
                                launched = true;
                                break;
                            },
                            Err(e) => println!("Failed to launch by name: {}", e),
                        }
                    }
                }
                
                // Second approach: Try by command line
                if !launched {
                    // Parse command to remove field codes like %f, %u, etc.
                    let cmd_parts: Vec<&str> = app_exec.split_whitespace()
                        .filter(|part| !part.starts_with('%'))
                        .collect();
                        
                    if !cmd_parts.is_empty() {
                        let cmd = cmd_parts[0];
                        
                        // Try to find the app by executable name
                        for app_info in &gio::AppInfo::all() {
                            if let Some(cmd_line) = app_info.commandline() {
                                if cmd_line.as_os_str().to_string_lossy().contains(cmd) {
                                    match app_info.launch(&[], Some(&context)) {
                                        Ok(_) => {
                                            println!("Launched application by command match: {}", cmd);
                                            launched = true;
                                            break;
                                        },
                                        Err(e) => println!("Failed to launch by command match: {}", e),
                                    }
                                }
                            }
                        }
                        
                        // Third approach: Fall back to direct command execution
                        if !launched {
                            let full_cmd = if cmd_parts.len() > 1 {
                                format!("{} {}", cmd, cmd_parts[1..].join(" "))
                            } else {
                                cmd.to_string()
                            };
                            
                            // Use spawn_command_line_async which is safer in this context
                            match glib::spawn_command_line_async(&full_cmd) {
                                Ok(_) => {
                                    println!("Launched application via command: {}", cmd);
                                    launched = true;
                                },
                                Err(e) => println!("Failed to launch application: {}", e),
                            }
                        }
                    }
                }
                
                // Send the result back to the main thread
                let _ = tx.send(launched);
            });
            
            // Handle the result in the main thread
            rx.attach(None, move |launched: bool| {
                if launched {
                    // If we have a window to close, do it after a small delay
                    if let Some(window) = &window_to_close {
                        let window_clone = window.clone();
                        glib::timeout_add_local_once(std::time::Duration::from_millis(300), move || {
                            window_clone.close();
                        });
                    }
                } else {
                    // If launch failed, show an error dialog
                    if let Some(window) = &window_to_close {
                        let dialog = gtk::MessageDialog::new(
                            Some(window),
                            gtk::DialogFlags::MODAL,
                            gtk::MessageType::Error,
                            gtk::ButtonsType::Ok,
                            &format!("Failed to launch {}", app_name_for_dialog)
                        );
                        dialog.connect_response(|dialog, _| {
                            dialog.close();
                        });
                        dialog.show();
                    }
                }
                
                // Continue receiving messages
                glib::Continue(true)
            });
        });
        
        // Add button to box
        button_box.append(&button);
        
        // Add app name label
        let label = gtk::Label::new(Some(&app.name));
        label.set_max_width_chars(12);
        label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        label.set_lines(2);
        label.set_justify(gtk::Justification::Center);
        label.set_wrap(true);
        label.set_wrap_mode(gtk::pango::WrapMode::Word);
        
        button_box.append(&label);
        
        button_box
    }
    
    fn filter_apps(categories_box: &gtk::Box, apps: &[AppInfo], search_text: &str) {
        Self::populate_categories(categories_box, apps, search_text);
    }
}