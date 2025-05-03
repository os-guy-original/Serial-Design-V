use gtk4::prelude::*;
use gtk4::{Application, ApplicationWindow};
use glib::clone;
use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{self, BufRead};
use std::path::{Path, PathBuf};
use std::cell::RefCell;
use std::rc::Rc;

#[derive(Clone)]
struct HyprVariable {
    name: String,
    value: String,
    file: String,
    line_number: usize,
    original_line: String,
}

#[derive(Clone)]
struct SourceStatement {
    path: String,
    file: String,
    resolved_path: PathBuf,
}

fn find_hyprland_config_dir() -> Option<PathBuf> {
    let home = std::env::var("HOME").ok()?;
    let config_dir = Path::new(&home).join(".config").join("hypr");
    
    if config_dir.exists() {
        return Some(config_dir);
    }
    
    None
}

fn resolve_source_path(source_path: &str, base_dir: &Path) -> Option<PathBuf> {
    // Handle path that starts with ~
    if source_path.starts_with('~') {
        if let Ok(home) = std::env::var("HOME") {
            let path = source_path.replacen('~', &home, 1);
            let resolved = PathBuf::from(path);
            if resolved.exists() {
                return Some(resolved);
            }
        }
    }
    
    // Try as absolute path
    let absolute = PathBuf::from(source_path);
    if absolute.exists() {
        return Some(absolute);
    }
    
    // Try as relative path to the base_dir
    let relative = base_dir.join(source_path);
    if relative.exists() {
        return Some(relative);
    }
    
    None
}

fn parse_hyprland_configs(base_dir: &Path) -> (Vec<HyprVariable>, Vec<SourceStatement>) {
    let mut variables = Vec::new();
    let mut sources = Vec::new();
    let mut processed_files = HashSet::new();
    
    // Start with the main config file
    let main_config = base_dir.join("hyprland.conf");
    if main_config.exists() {
        process_config_file(&main_config, base_dir, &mut variables, &mut sources, &mut processed_files);
    } else {
        // If main config doesn't exist, try finding it in subdirectories
        if let Ok(entries) = fs::read_dir(base_dir) {
            for entry in entries.filter_map(Result::ok) {
                let path = entry.path();
                if path.is_dir() {
                    let potential_config = path.join("hyprland.conf");
                    if potential_config.exists() {
                        process_config_file(&potential_config, base_dir, &mut variables, &mut sources, &mut processed_files);
                        break;
                    }
                }
            }
        }
    }
    
    // Process all the sources we've found
    let mut i = 0;
    while i < sources.len() {
        if let Some(resolved_path) = &sources[i].resolved_path.canonicalize().ok() {
            if !processed_files.contains(resolved_path) {
                process_config_file(resolved_path, base_dir, &mut variables, &mut sources, &mut processed_files);
            }
        }
        i += 1;
    }
    
    (variables, sources)
}

fn normalize_variable_value(value: &str) -> String {
    value.trim().to_string()
}

fn process_config_file(path: &Path, base_dir: &Path, variables: &mut Vec<HyprVariable>, sources: &mut Vec<SourceStatement>, processed_files: &mut HashSet<PathBuf>) {
    let canonical_path = match path.canonicalize() {
        Ok(p) => p,
        Err(_) => return,
    };
    
    // Skip if we've already processed this file
    if processed_files.contains(&canonical_path) {
        return;
    }
    
    processed_files.insert(canonical_path.clone());
    
    let file = match fs::File::open(path) {
        Ok(file) => file,
        Err(_) => return,
    };
    
    // Regex for variable assignment: name = value
    let var_regex = Regex::new(r"^\s*(\w+)\s*=\s*(.+?)\s*$").unwrap();
    
    // Regex for section headers
    let section_regex = Regex::new(r"^\s*(\w+)\s*\{\s*$").unwrap();
    
    // Regex for source statements
    let source_regex = Regex::new(r"^\s*source\s*=\s*(.+?)\s*$").unwrap();
    
    let relative_path = path.strip_prefix(base_dir).unwrap_or(path);
    let file_display = relative_path.display().to_string();
    
    let reader = io::BufReader::new(file);
    let mut current_section = String::new();
    
    for (line_number, line_result) in reader.lines().enumerate() {
        if let Ok(line) = line_result {
            // Skip comments and empty lines
            if line.trim().starts_with('#') || line.trim().is_empty() {
                continue;
            }
            
            // Handle source statements
            if let Some(cap) = source_regex.captures(&line) {
                let source_path_str = cap[1].to_string();
                let resolved_path = resolve_source_path(&source_path_str, base_dir)
                    .unwrap_or_else(|| PathBuf::from(&source_path_str));
                
                sources.push(SourceStatement {
                    path: source_path_str,
                    file: file_display.clone(),
                    resolved_path,
                });
                continue;
            }
            
            // Handle section headers
            if let Some(cap) = section_regex.captures(&line) {
                current_section = cap[1].to_string();
                continue;
            }
            
            // Handle section closing
            if line.trim() == "}" {
                current_section.clear();
                continue;
            }
            
            // Handle variable assignments
            if let Some(cap) = var_regex.captures(&line) {
                let var_name = cap[1].to_string();
                let var_value = normalize_variable_value(&cap[2]);
                
                let full_name = if current_section.is_empty() {
                    var_name
                } else {
                    format!("{}.{}", current_section, var_name)
                };
                
                variables.push(HyprVariable {
                    name: full_name,
                    value: var_value,
                    file: file_display.clone(),
                    line_number: line_number + 1,
                    original_line: line.clone(),
                });
            }
        }
    }
}

fn save_changes(changes: &[(String, usize, String, String)], base_dir: &Path) -> Result<(), String> {
    // Group changes by file
    let mut file_changes: HashMap<String, Vec<(usize, String, String)>> = HashMap::new();
    
    for (file, line_number, new_value, original_line) in changes {
        file_changes.entry(file.clone())
            .or_default()
            .push((*line_number, new_value.clone(), original_line.clone()));
    }
    
    // Process each file
    for (file_path, changes) in file_changes {
        let full_path = base_dir.join(&file_path);
        
        // Read the file
        let file_content = match fs::read_to_string(&full_path) {
            Ok(content) => content,
            Err(e) => return Err(format!("Failed to read {}: {}", file_path, e)),
        };
        
        let lines: Vec<String> = file_content.lines().map(String::from).collect();
        let mut new_lines = lines.clone();
        
        // Apply changes
        for (line_number, new_value, original_line) in changes {
            if line_number > 0 && line_number <= new_lines.len() {
                let line_idx = line_number - 1;
                let original_line_in_file = &lines[line_idx];
                
                // More flexible line matching - ignore whitespace differences
                let original_line_trimmed = original_line.trim();
                let file_line_trimmed = original_line_in_file.trim();
                
                // Extract just the variable part for safer matching
                let original_var_part = if let Some(idx) = original_line_trimmed.find('=') {
                    original_line_trimmed[0..idx].trim()
                } else {
                    original_line_trimmed
                };
                
                let file_var_part = if let Some(idx) = file_line_trimmed.find('=') {
                    file_line_trimmed[0..idx].trim()
                } else {
                    file_line_trimmed
                };
                
                // Check if the line contains the right variable, even if the value has changed
                if file_var_part == original_var_part || 
                   file_line_trimmed.contains(original_var_part) || 
                   original_line_trimmed.contains(file_var_part) {
                    new_lines[line_idx] = new_value.clone();
                } else {
                    return Err(format!(
                        "Line mismatch in {} at line {}:\n- Expected: '{}'\n- Found: '{}'\n\nVariable parts:\n- Expected: '{}'\n- Found: '{}'",
                        file_path, line_number, original_line, original_line_in_file, original_var_part, file_var_part
                    ));
                }
            } else {
                return Err(format!("Invalid line number {} in {} (file has {} lines)", 
                                  line_number, file_path, new_lines.len()));
            }
        }
        
        // Write the file
        match fs::write(&full_path, new_lines.join("\n")) {
            Ok(_) => (),
            Err(e) => return Err(format!("Failed to write {}: {}", file_path, e)),
        }
    }
    
    Ok(())
}

fn show_warning_dialog(parent: &ApplicationWindow, message: &str, on_ok: Box<dyn Fn() + 'static>) {
    // Create a dialog with a clear title and message
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Warning)
        .buttons(gtk4::ButtonsType::None) // We'll add custom buttons
        .text("Warning")
        .secondary_text(message)
        .build();
    
    // Add custom styled buttons
    dialog.add_button("Cancel", gtk4::ResponseType::Cancel);
    dialog.add_button("OK", gtk4::ResponseType::Ok);
    
    // Style the buttons to match libadwaita style
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Cancel) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Set default responses
    dialog.set_default_response(gtk4::ResponseType::Cancel);
    
    // Connect the response signal
    dialog.connect_response(move |dialog, response| {
        dialog.close();
        if response == gtk4::ResponseType::Ok {
            on_ok();
        }
    });
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.show();
}

fn show_error_dialog(parent: &ApplicationWindow, message: &str) {
    // Create a dialog with a clear title and message
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Error)
        .buttons(gtk4::ButtonsType::None)
        .text("Error")
        .secondary_text(message)
        .build();
    
    // Add a styled button
    dialog.add_button("OK", gtk4::ResponseType::Ok);
    
    // Style the button
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Default response
    dialog.set_default_response(gtk4::ResponseType::Ok);
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.connect_response(|dialog, _| {
        dialog.close();
    });
    
    dialog.show();
}

fn show_success_dialog(parent: &ApplicationWindow, message: &str, on_ok: Box<dyn Fn() + 'static>) {
    // Create a dialog with a clear title and message
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Info)
        .buttons(gtk4::ButtonsType::None)
        .text("Success")
        .secondary_text(message)
        .build();
    
    // Add a styled button
    dialog.add_button("OK", gtk4::ResponseType::Ok);
    
    // Style the button
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Default response
    dialog.set_default_response(gtk4::ResponseType::Ok);
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.connect_response(move |dialog, _| {
        dialog.close();
        on_ok();
    });
    
    dialog.show();
}

fn show_initial_warning(parent: &ApplicationWindow) {
    // Create a dialog with a clear title and message
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Warning)
        .buttons(gtk4::ButtonsType::None)
        .text("WARNING: Editing Hyprland Configuration Files")
        .secondary_text("This tool allows you to edit your Hyprland configuration files directly.\n\nIf you don't know what you're doing, DO NOT modify these values as it may break your Hyprland configuration.")
        .build();
    
    // Add custom styled buttons
    dialog.add_button("Exit", gtk4::ResponseType::Cancel);
    dialog.add_button("Continue", gtk4::ResponseType::Ok);
    
    // Style the buttons
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Cancel) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("destructive-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Default response
    dialog.set_default_response(gtk4::ResponseType::Ok);
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.connect_response(move |dialog, response| {
        dialog.close();
        if response == gtk4::ResponseType::Cancel {
            std::process::exit(0);
        }
    });
    
    dialog.show();
}

fn show_info_dialog(parent: &ApplicationWindow, message: &str) {
    // Create a dialog with a clear title and message
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Info)
        .buttons(gtk4::ButtonsType::None)
        .text("Information")
        .secondary_text(message)
        .build();
    
    // Add a styled button
    dialog.add_button("OK", gtk4::ResponseType::Ok);
    
    // Style the button
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Default response
    dialog.set_default_response(gtk4::ResponseType::Ok);
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.connect_response(|dialog, _| {
        dialog.close();
    });
    
    dialog.show();
}

fn refresh_ui() {
    // Process pending events to keep the UI responsive
    // Use a gentler approach that works better with Wayland
    if glib::MainContext::pending(&glib::MainContext::default()) {
        glib::MainContext::iteration(&glib::MainContext::default(), false);
    }
}

fn build_ui(application: &Application) {
    // Use CSS for styling without aggressive overrides
    let provider = gtk4::CssProvider::new();
    provider.load_from_data(
        "
        .suggested-action {
            background-color: #89b4fa;  /* Catppuccin blue */
            color: #1e1e2e;  /* Dark text for contrast */
            font-weight: bold;
            border-radius: 8px;
            padding: 4px 8px;
        }
        .suggested-action:hover {
            background-color: #74c7ec;  /* Lighter blue on hover */
        }
        .destructive-action {
            background-color: #f38ba8;  /* Catppuccin red */
            color: #1e1e2e;
            font-weight: bold;
            border-radius: 8px;
            padding: 4px 8px;
        }
        .destructive-action:hover {
            background-color: #f5c2e7;  /* Lighter red on hover */
        }
        "
    );
    gtk4::style_context_add_provider_for_display(
        &gtk4::gdk::Display::default().expect("Could not connect to a display."),
        &provider,
        gtk4::STYLE_PROVIDER_PRIORITY_APPLICATION,
    );

    // Create a window with proper floating appearance
    let window = ApplicationWindow::builder()
        .application(application)
        .title("Hyprland Configuration Variables")
        .default_width(850)
        .default_height(650)
        .resizable(false)  // Fixed size for floating appearance
        .build();
    
    // Add visual traits to suggest a floating dialog
    window.set_decorated(true);
    
    // Make the window modal-like by setting it as a dialog
    window.add_css_class("dialog");
    
    // Show the window immediately
    window.present();
    
    // Use a one-shot idle handler to load the content
    glib::idle_add_local_once(clone!(@weak window => move || {
        load_application_content(&window);
    }));
}

fn load_application_content(window: &ApplicationWindow) {
    // Find Hyprland config directory
    let config_dir = match find_hyprland_config_dir() {
        Some(dir) => dir,
        None => {
            show_error_window(window, "Could not find Hyprland config directory.");
            return;
        }
    };
    
    // Parse variables from config files
    let (variables, sources) = parse_hyprland_configs(&config_dir);
    
    if variables.is_empty() && sources.is_empty() {
        show_error_window(window, "No variables or sources found in Hyprland configuration files.");
        return;
    }
    
    // Show initial warning
    show_initial_warning(window);
    
    // Create a main box
    let main_box = gtk4::Box::new(gtk4::Orientation::Vertical, 0);
    main_box.set_margin_top(16);
    main_box.set_margin_bottom(16);
    main_box.set_margin_start(16);
    main_box.set_margin_end(16);
    main_box.add_css_class("main-container");
    
    // Add a header with title
    let header = gtk4::Box::new(gtk4::Orientation::Horizontal, 0);
    header.set_margin_top(16);
    header.set_margin_bottom(16);
    header.set_margin_start(16);
    header.set_margin_end(16);
    
    let title = gtk4::Label::new(Some("Hyprland Configuration Variables"));
    title.set_markup("<b>Hyprland Configuration Variables</b>");
    title.set_halign(gtk4::Align::Start);
    header.append(&title);
    
    // Group variables by source file
    let mut file_vars: HashMap<String, Vec<usize>> = HashMap::new();
    for (idx, var) in variables.iter().enumerate() {
        file_vars.entry(var.file.clone()).or_insert_with(Vec::new).push(idx);
    }
    
    // Get unique config files (both from variables and sources)
    let mut unique_files = HashSet::new();
    for var in &variables {
        unique_files.insert(var.file.clone());
    }
    
    // Add a summary of parsed files
    let file_count = unique_files.len();
    let var_count = variables.len();
    let source_count = sources.len();
    
    let file_label = gtk4::Label::new(Some(&format!(
        "Parsed {} files, found {} variables, {} source statements", 
        file_count, var_count, source_count
    )));
    file_label.set_halign(gtk4::Align::End);
    file_label.set_hexpand(true);
    header.append(&file_label);
    
    main_box.append(&header);
    main_box.append(&gtk4::Separator::new(gtk4::Orientation::Horizontal));
    
    // Add a search box at the top
    let search_box = gtk4::Box::new(gtk4::Orientation::Horizontal, 6);
    search_box.set_margin_top(8);
    search_box.set_margin_bottom(8);
    search_box.set_margin_start(12);
    search_box.set_margin_end(12);
    
    let search_label = gtk4::Label::new(Some("Search:"));
    search_box.append(&search_label);
    
    let search_entry = gtk4::Entry::new();
    search_entry.set_hexpand(true);
    search_box.append(&search_entry);
    
    main_box.append(&search_box);
    main_box.append(&gtk4::Separator::new(gtk4::Orientation::Horizontal));
    
    // Force a UI refresh to keep the window responsive during load
    refresh_ui();
    
    // Create a horizontal box to hold the notebook (for vertical tabs)
    let notebook_box = gtk4::Box::new(gtk4::Orientation::Horizontal, 0);
    notebook_box.set_vexpand(true);
    notebook_box.set_hexpand(true);
    
    // Create notebook (tabs) for each file with vertical tabs
    let notebook = gtk4::Notebook::new();
    notebook.set_vexpand(true);
    notebook.set_hexpand(true);
    notebook.set_tab_pos(gtk4::PositionType::Left); // Set tabs to be on the left side
    
    // Create a hash map to store list boxes for each tab
    let mut list_boxes = HashMap::new();
    
    // Shared state to track changes
    let changes = Rc::new(RefCell::new(Vec::new()));
    let variables = Rc::new(RefCell::new(variables));
    
    // First add a dedicated tab for source statements if there are any
    if !sources.is_empty() {
        // Create a scrollable container for the source statements
        let scrolled_window = gtk4::ScrolledWindow::new();
        scrolled_window.set_vexpand(true);
        scrolled_window.set_hexpand(true);
        
        // Create a box with the source statements
        let list_box = gtk4::ListBox::new();
        list_box.set_selection_mode(gtk4::SelectionMode::None);
        
        // Add each source statement to the list box
        // Process in batches of 20 to keep UI responsive
        let batch_size = 10; // Reduce batch size to avoid overwhelming the renderer
        for chunk in sources.chunks(batch_size) {
            for source in chunk {
                let row = gtk4::ListBoxRow::new();
                let hbox = gtk4::Box::new(gtk4::Orientation::Horizontal, 12);
                hbox.set_margin_top(6);
                hbox.set_margin_bottom(6);
                hbox.set_margin_start(12);
                hbox.set_margin_end(12);
                
                let source_label = gtk4::Label::new(Some("source ="));
                source_label.set_halign(gtk4::Align::Start);
                source_label.set_width_chars(10);
                source_label.set_xalign(0.0);
                source_label.set_selectable(true);
                
                let path_label = gtk4::Label::new(Some(&source.path));
                path_label.set_halign(gtk4::Align::Start);
                path_label.set_hexpand(true);
                path_label.set_xalign(0.0);
                path_label.set_ellipsize(gtk4::pango::EllipsizeMode::End);
                path_label.set_selectable(true);
                
                let file_label = gtk4::Label::new(Some(&source.file));
                file_label.set_halign(gtk4::Align::End);
                file_label.set_xalign(1.0);
                file_label.set_selectable(true);
                
                hbox.append(&source_label);
                hbox.append(&path_label);
                hbox.append(&file_label);
                row.set_child(Some(&hbox));
                list_box.append(&row);
            }
            
            // Process UI events after each batch to keep UI responsive
            refresh_ui();
        }
        
        // Store the list box for later search filtering
        list_boxes.insert("Sources".to_string(), list_box.clone());
        
        // Add the list box to the scrolled window
        scrolled_window.set_child(Some(&list_box));
        
        // Create tab label
        let label = gtk4::Label::new(Some("Source Statements"));
        
        // Add the tab to the notebook as the first tab
        notebook.insert_page(&scrolled_window, Some(&label), Some(0));
    }
    
    // Sort file names for consistent tab order
    let mut file_names: Vec<String> = file_vars.keys().cloned().collect();
    file_names.sort();
    
    // Create a tab for each file and add its variables
    for file_name in file_names {
        let var_indices = &file_vars[&file_name];
        
        // Create a scrollable container for the variables
        let scrolled_window = gtk4::ScrolledWindow::new();
        scrolled_window.set_vexpand(true);
        scrolled_window.set_hexpand(true);
        
        // Create a box with the variables
        let list_box = gtk4::ListBox::new();
        list_box.set_selection_mode(gtk4::SelectionMode::None);
        
        // Add each variable to the list box
        // Process in batches of 20 to keep UI responsive
        let batch_size = 10; // Reduce batch size to avoid overwhelming the renderer
        for chunk in var_indices.chunks(batch_size) {
            for &idx in chunk {
                let var = &variables.borrow()[idx];
                
                let row = gtk4::ListBoxRow::new();
                let hbox = gtk4::Box::new(gtk4::Orientation::Horizontal, 12);
                hbox.set_margin_top(6);
                hbox.set_margin_bottom(6);
                hbox.set_margin_start(12);
                hbox.set_margin_end(12);
                
                let key_label = gtk4::Label::new(Some(&var.name));
                key_label.set_halign(gtk4::Align::Start);
                key_label.set_width_chars(30);
                key_label.set_xalign(0.0);
                key_label.set_selectable(true);
                
                // Create an editable entry for the value instead of a label
                let value_entry = gtk4::Entry::new();
                value_entry.set_text(&var.value);
                value_entry.set_halign(gtk4::Align::Start);
                value_entry.set_hexpand(true);
                
                // Connect to the changed signal
                let changes_clone = changes.clone();
                let var_clone = var.clone();
                
                value_entry.connect_changed(move |entry| {
                    let new_text = entry.text().to_string();
                    
                    // Always add or update the change
                    let mut changes_ref = changes_clone.borrow_mut();
                    
                    // First, remove any existing change for this variable
                    changes_ref.retain(|(f, ln, _, _)| {
                        *f != var_clone.file || *ln != var_clone.line_number
                    });
                    
                    // Extract the actual variable name from section.varname
                    let var_name = if var_clone.name.contains('.') {
                        let parts: Vec<&str> = var_clone.name.split('.').collect();
                        if let Some(last_part) = parts.last() {
                            last_part.to_string()
                        } else {
                            var_clone.name.clone()
                        }
                    } else {
                        var_clone.name.clone()
                    };
                    
                    // Get the original line to preserve formatting/indentation
                    let indentation = var_clone.original_line
                        .chars()
                        .take_while(|c| c.is_whitespace())
                        .collect::<String>();
                    
                    // Include proper spacing in the formatted line
                    let new_line = format!("{}{} = {}", indentation, var_name, new_text);
                    
                    // Always add the change regardless of comparison with original value
                    changes_ref.push((
                        var_clone.file.clone(),
                        var_clone.line_number,
                        new_line,
                        var_clone.original_line.clone(),
                    ));
                });
                
                hbox.append(&key_label);
                hbox.append(&value_entry);
                row.set_child(Some(&hbox));
                list_box.append(&row);
            }
            
            // Process UI events after each batch to keep UI responsive
            refresh_ui();
        }
        
        // Store the list box for later search filtering
        list_boxes.insert(file_name.clone(), list_box.clone());
        
        // Add the list box to the scrolled window
        scrolled_window.set_child(Some(&list_box));
        
        // Create tab label
        let tab_label = Path::new(&file_name)
            .file_name()
            .and_then(|f| f.to_str())
            .unwrap_or(&file_name);
        
        let label = gtk4::Label::new(Some(tab_label));
        
        // Add the tab to the notebook
        notebook.append_page(&scrolled_window, Some(&label));
    }
    
    // Add the notebook to the notebook box
    notebook_box.append(&notebook);
    
    // Add the notebook box to the main box
    main_box.append(&notebook_box);
    
    // Create a bottom box for the Save Button
    let bottom_box = gtk4::Box::new(gtk4::Orientation::Horizontal, 0);
    bottom_box.set_margin_top(16);
    bottom_box.set_margin_bottom(24); // Extra bottom margin for visual balance
    bottom_box.set_margin_start(16);
    bottom_box.set_margin_end(16);
    bottom_box.set_halign(gtk4::Align::Center);
    
    // Create a save button with prominent styling
    let save_button = gtk4::Button::with_label("Save Changes");
    save_button.add_css_class("suggested-action"); // Apply bright blue highlight
    save_button.add_css_class("pill");           // Add pill shape if available
    save_button.set_hexpand(false);
    save_button.set_margin_top(8);
    save_button.set_margin_bottom(8);
    save_button.set_margin_start(8);
    save_button.set_margin_end(8);
    save_button.set_height_request(42); // Make button taller
    save_button.set_width_request(160); // Set a wider fixed width
    
    bottom_box.append(&save_button);
    main_box.append(&bottom_box);
    
    // Set up the save button click handler
    let config_dir_clone = config_dir.clone();
    let window_clone = window.clone();
    let changes_clone = changes.clone();
    let variables_clone = variables.clone();
    
    save_button.connect_clicked(move |_button| {
        let changes_ref = changes_clone.borrow();
        
        // Always proceed with saving, regardless of whether changes_ref is empty
        let changes_count = changes_ref.len();
        let msg = format!(
            "You are about to save your Hyprland configuration files.",
        );
        
        let changes_vec = changes_ref.clone();
        let config_dir_clone2 = config_dir_clone.clone();
        let window_clone2 = window_clone.clone();
        let changes_clone2 = changes_clone.clone();
        let variables_clone2 = variables_clone.clone();
        
        show_warning_dialog(&window_clone, &msg, Box::new(move || {
            match save_changes(&changes_vec, &config_dir_clone2) {
                Ok(_) => {
                    // Update the original variable values with the new values
                    let mut vars = variables_clone2.borrow_mut();
                    for (file, line_number, new_value, _) in &changes_vec {
                        for var in vars.iter_mut() {
                            if var.file == *file && var.line_number == *line_number {
                                if let Some(start_idx) = new_value.find('=') {
                                    let value = normalize_variable_value(&new_value[start_idx+1..]);
                                    var.value = value;
                                    
                                    // Update the original line to match what's in the file now
                                    var.original_line = new_value.clone();
                                }
                                break;
                            }
                        }
                    }
                    
                    // Show success dialog with callback to clear changes
                    let changes_clone3 = changes_clone2.clone();
                    
                    show_success_dialog(
                        &window_clone2, 
                        "Successfully saved your configuration files.",
                        Box::new(move || {
                            // Clear changes when dialog is closed
                            changes_clone3.borrow_mut().clear();
                        })
                    );
                }
                Err(err) => {
                    show_error_dialog(&window_clone2, &format!("Failed to save changes: {}", err));
                }
            }
        }));
    });
    
    // Implement search functionality
    let list_boxes_clone = list_boxes.clone();
    search_entry.connect_changed(move |entry| {
        let query = entry.text().to_lowercase();
        
        for (_, list_box) in &list_boxes_clone {
            // In GTK4, we need to get the rows differently
            for row in list_box.observe_children().snapshot().iter() {
                if let Some(row) = row.downcast_ref::<gtk4::ListBoxRow>() {
                    if let Some(hbox) = row.child() {
                        let mut contains_query = false;
                        
                        // Check if the row contains the text in either column
                        if let Some(box_container) = hbox.downcast_ref::<gtk4::Box>() {
                            // In GTK4, we iterate through children differently
                            let mut first_child = box_container.first_child();
                            while let Some(child) = first_child {
                                // Check if it's a label (variable name)
                                if let Some(label) = child.downcast_ref::<gtk4::Label>() {
                                    let text = label.text().to_string().to_lowercase();
                                    if text.contains(&query) {
                                        contains_query = true;
                                        break;
                                    }
                                } else if let Some(entry) = child.downcast_ref::<gtk4::Entry>() {
                                    let text = entry.text().to_string().to_lowercase();
                                    if text.contains(&query) {
                                        contains_query = true;
                                        break;
                                    }
                                }
                                
                                first_child = child.next_sibling();
                            }
                        }
                        
                        row.set_visible(query.is_empty() || contains_query);
                    }
                }
            }
        }
    });
    
    // Add the main box to the window
    window.set_child(Some(&main_box));
    
    // Show the window
    window.present();
}

fn show_error_window<W: IsA<gtk4::Window>>(parent: &W, message: &str) {
    let dialog = gtk4::MessageDialog::builder()
        .transient_for(parent)
        .modal(true)
        .destroy_with_parent(true)
        .message_type(gtk4::MessageType::Error)
        .buttons(gtk4::ButtonsType::None)
        .text("Error")
        .secondary_text(message)
        .build();
    
    // Add a styled button
    dialog.add_button("OK", gtk4::ResponseType::Ok);
    
    // Style the button
    if let Some(button) = dialog.widget_for_response(gtk4::ResponseType::Ok) {
        if let Some(button) = button.downcast_ref::<gtk4::Button>() {
            button.add_css_class("suggested-action");
            button.set_margin_start(8);
            button.set_margin_end(8);
            button.set_margin_top(8);
            button.set_margin_bottom(8);
        }
    }
    
    // Default response
    dialog.set_default_response(gtk4::ResponseType::Ok);
    
    // Add some spacing and padding to the content area
    let content_area = dialog.content_area();
    content_area.set_margin_top(16);
    content_area.set_margin_bottom(16);
    content_area.set_margin_start(16);
    content_area.set_margin_end(16);
    content_area.set_spacing(12);
    
    dialog.connect_response(|dialog, _| {
        dialog.close();
    });
    
    dialog.show();
}

fn main() {
    // Create a GTK4 application
    let app = Application::builder()
        .application_id("com.example.hyprland-settings")
        .build();

    app.connect_activate(build_ui);

    // Run the application
    app.run();
}
