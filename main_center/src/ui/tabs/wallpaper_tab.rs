use gtk::prelude::*;
use gtk;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use glib;

// Default paths to look for wallpapers
const WALLPAPER_PATHS: &[&str] = &[
    "/home/sd-v/Pictures",
];

// File extensions to filter for images
const IMAGE_EXTENSIONS: &[&str] = &[
    "jpg", "jpeg", "png", "webp", "bmp"
];

// Path to the current wallpaper file
const CURRENT_WALLPAPER_PATH: &str = "/home/sd-v/.config/hypr/last_wallpaper";

pub fn create_wallpaper_content() -> gtk::Widget {
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
    
    let header = gtk::Label::new(Some("Wallpaper Gallery"));
    header.add_css_class("title-2");
    header.set_halign(gtk::Align::Start);
    header.set_hexpand(true);
    
    // Add a refresh button
    let refresh_button = gtk::Button::new();
    refresh_button.set_icon_name("view-refresh-symbolic");
    refresh_button.add_css_class("circular");
    refresh_button.set_tooltip_text(Some("Refresh wallpaper list"));
    
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
    
    // Create a box to hold the current wallpaper section and gallery
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_top(16);
    content_box.set_margin_bottom(16);
    
    // Create current wallpaper section
    let current_wallpaper_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    
    let current_label = gtk::Label::new(Some("Current Wallpaper"));
    current_label.add_css_class("title-3");
    current_label.set_halign(gtk::Align::Start);
    current_wallpaper_box.append(&current_label);
    
    // Create a frame for the current wallpaper
    let current_frame = gtk::Frame::new(None);
    current_frame.add_css_class("view");
    current_frame.set_size_request(300, 200);
    
    // Get current wallpaper path
    let current_wallpaper = get_current_wallpaper();
    
    // Create the image widget for current wallpaper
    let current_image = gtk::Picture::new();
    if let Some(path) = &current_wallpaper {
        // Check if the file exists before setting it
        if Path::new(path).exists() {
            current_image.set_filename(Some(path));
        } else {
            // If file doesn't exist, don't set it
            current_image.set_filename(None::<&std::path::Path>);
        }
    }
    current_image.set_content_fit(gtk::ContentFit::Cover);
    current_image.set_size_request(300, 200);
    
    current_frame.set_child(Some(&current_image));
    current_wallpaper_box.append(&current_frame);
    
    // Add current wallpaper path label
    let path_label = gtk::Label::new(None);
    if let Some(path) = &current_wallpaper {
        if Path::new(path).exists() {
            if let Some(filename) = Path::new(path).file_name() {
                if let Some(filename_str) = filename.to_str() {
                    path_label.set_text(filename_str);
                }
            }
        } else {
            path_label.set_text("Wallpaper file not found");
        }
    } else {
        path_label.set_text("No wallpaper set");
    }
    path_label.add_css_class("caption");
    path_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    path_label.set_max_width_chars(40);
    current_wallpaper_box.append(&path_label);
    
    // Add current wallpaper section to content
    content_box.append(&current_wallpaper_box);
    
    // Add a separator between current wallpaper and gallery
    let gallery_separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    content_box.append(&gallery_separator);
    
    // Add gallery label
    let gallery_label = gtk::Label::new(Some("Available Wallpapers"));
    gallery_label.add_css_class("title-3");
    gallery_label.set_halign(gtk::Align::Start);
    content_box.append(&gallery_label);
    
    // Create a FlowBox for the gallery
    let gallery = gtk::FlowBox::new();
    gallery.set_valign(gtk::Align::Start);
    gallery.set_max_children_per_line(4);
    gallery.set_min_children_per_line(2);
    gallery.set_selection_mode(gtk::SelectionMode::None);
    gallery.set_homogeneous(true);
    gallery.set_row_spacing(20);
    gallery.set_column_spacing(20);
    
    // Create a loading indicator
    let spinner = gtk::Spinner::new();
    spinner.set_size_request(32, 32);
    spinner.set_halign(gtk::Align::Center);
    spinner.set_valign(gtk::Align::Center);
    spinner.set_vexpand(true);
    spinner.start();
    
    // Initial loading message
    let loading_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    loading_box.set_halign(gtk::Align::Center);
    loading_box.set_valign(gtk::Align::Center);
    loading_box.set_vexpand(true);
    
    loading_box.append(&spinner);
    
    let loading_label = gtk::Label::new(Some("Loading wallpapers..."));
    loading_label.add_css_class("dim-label");
    loading_box.append(&loading_label);
    
    // Add loading indicator to the gallery area
    let gallery_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
    gallery_container.set_vexpand(true);
    gallery_container.append(&loading_box);
    content_box.append(&gallery_container);
    
    // Add content box to scroll
    scroll.set_child(Some(&content_box));
    container.append(&scroll);
    content.append(&container);
    
    // Create a shared reference to track button states
    let buttons_enabled = Arc::new(Mutex::new(true));
    
    // Load images in the background to avoid blocking the UI
    let gallery_clone = gallery.clone();
    let gallery_container_clone = gallery_container.clone();
    let buttons_enabled_clone = buttons_enabled.clone();
    let current_image_clone = current_image.clone();
    let path_label_clone = path_label.clone();
    
    glib::idle_add_local_once(move || {
        refresh_wallpaper_ui(&gallery_clone, &gallery_container_clone, &current_image_clone, &path_label_clone, &buttons_enabled_clone);
    });
    
    // Connect refresh button
    refresh_button.connect_clicked(glib::clone!(@weak gallery, @weak gallery_container, @weak current_image, @weak path_label, @strong buttons_enabled => move |_| {
        refresh_wallpaper_ui(&gallery, &gallery_container, &current_image, &path_label, &buttons_enabled);
    }));
    
    content.into()
}

// Function to create a wallpaper item widget
fn create_wallpaper_item(
    path: &Path,
    buttons_enabled: Arc<Mutex<bool>>,
    is_current: bool,
    gallery: &gtk::FlowBox,
    gallery_container: &gtk::Box,
    current_image: &gtk::Picture,
    path_label: &gtk::Label,
) -> gtk::Box {
    let item = gtk::Box::new(gtk::Orientation::Vertical, 10);
    item.set_size_request(200, 200);
    
    // Create a frame for the image
    let frame = gtk::Frame::new(None);
    frame.add_css_class("view");
    frame.set_size_request(200, 150);
    
    // Create the image widget
    let image = gtk::Picture::for_filename(path);
    image.set_content_fit(gtk::ContentFit::Cover);
    image.set_size_request(200, 150);
    
    // Create an overlay for the frame to place the preview button
    let overlay = gtk::Overlay::new();
    overlay.set_child(Some(&image));
    
    // Create a preview button with fullscreen icon
    let preview_button = gtk::Button::new();
    preview_button.set_icon_name("view-fullscreen-symbolic");
    preview_button.add_css_class("circular");
    preview_button.add_css_class("opaque");
    preview_button.set_halign(gtk::Align::End);
    preview_button.set_valign(gtk::Align::Start);
    preview_button.set_margin_top(5);
    preview_button.set_margin_end(5);
    preview_button.set_tooltip_text(Some("Preview wallpaper"));
    preview_button.set_visible(false); // Initially hidden
    overlay.add_overlay(&preview_button);
    
    // Add hover effect to show/hide the button
    let controller = gtk::EventControllerMotion::new();
    controller.connect_enter(glib::clone!(@weak preview_button => move |_, _, _| {
        preview_button.set_visible(true);
    }));
    controller.connect_leave(glib::clone!(@weak preview_button => move |_| {
        preview_button.set_visible(false);
    }));
    image.add_controller(controller);
    
    // Add hover effect to the button itself to keep it visible
    let button_controller = gtk::EventControllerMotion::new();
    button_controller.connect_enter(glib::clone!(@weak preview_button => move |_, _, _| {
        preview_button.set_visible(true);
    }));
    button_controller.connect_leave(glib::clone!(@weak preview_button => move |_| {
        preview_button.set_visible(false);
    }));
    preview_button.add_controller(button_controller);
    
    frame.set_child(Some(&overlay));
    item.append(&frame);
    
    // Create a label with the filename
    let filename = path.file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("Unknown");
    
    let name_label = gtk::Label::new(Some(filename));
    name_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    name_label.set_max_width_chars(20);
    name_label.set_tooltip_text(Some(filename));
    item.append(&name_label);
    
    // Create a button to set as wallpaper, unless this is the current wallpaper
    if !is_current {
        let button_box = gtk::Box::new(gtk::Orientation::Horizontal, 5);
        button_box.set_halign(gtk::Align::Center);
        
        let set_button = gtk::Button::new();
        set_button.set_label("Set As Wallpaper");
        // Use a non-light color style
        set_button.add_css_class("accent");
        set_button.add_css_class("pill");
        button_box.append(&set_button);
        
        item.append(&button_box);
        
        // Connect the button click
        let path_str = path.to_str().unwrap_or("").to_string();
        let buttons_clone = buttons_enabled.clone();
        
        let gallery_refresh = gallery.clone();
        let gallery_container_refresh = gallery_container.clone();
        let current_image_refresh = current_image.clone();
        let path_label_refresh = path_label.clone();
        let buttons_enabled_refresh = buttons_enabled.clone();
        set_button.connect_clicked(glib::clone!(@weak set_button, @weak item => move |_| {
            // Disable all buttons during processing
            let mut enabled = buttons_clone.lock().unwrap();
            if !*enabled {
                return;
            }
            *enabled = false;
            drop(enabled);
            
            // Update button appearance
            set_button.set_label("Setting...");
            set_button.set_sensitive(false);
            
            // Create a clone for the timeout
            let path_str_clone = path_str.clone();
            let set_button_clone = set_button.clone();
            let buttons_clone2 = buttons_clone.clone();
            
            // Set the wallpaper by writing to the last_wallpaper file
            let _ = fs::write(CURRENT_WALLPAPER_PATH, &path_str_clone);
            
            // Apply the wallpaper using swww
            let _ = Command::new("swww")
                .args(["img", &path_str_clone, "--transition-type", "wave"])
                .spawn();
            
            // Run the material extract script in the background, silencing all output
            let _ = Command::new("sh")
                .arg("-c")
                .arg("/home/sd-v/.config/hypr/colorgen/material_extract.sh >/dev/null 2>&1 &")
                .spawn();
            
            // Create a flag to track if the timeout is active
            let timeout_active = Arc::new(Mutex::new(true));
            let timeout_active_clone = timeout_active.clone();
            
            // First remove any existing indicator file
            let _ = fs::remove_file("/tmp/done_color_application");
            
            // Clone the widget references before moving into closure
            let gallery_refresh_clone = gallery_refresh.clone();
            let gallery_container_refresh_clone = gallery_container_refresh.clone();
            let current_image_refresh_clone = current_image_refresh.clone();
            let path_label_refresh_clone = path_label_refresh.clone();
            let buttons_enabled_refresh_clone = buttons_enabled_refresh.clone();
            
            // Use glib::timeout_add_local to periodically check for the finish indicator file
            glib::timeout_add_local(Duration::from_millis(500), move || {
                // Check if we should continue checking
                let active = *timeout_active_clone.lock().unwrap();
                if !active {
                    return glib::Continue(false);
                }
                
                // Check if the indicator file exists
                if Path::new("/tmp/done_color_application").exists() {
                    // Defer UI updates to the main thread to avoid freeze
                    let set_button_clone2 = set_button_clone.clone();
                    let buttons_clone2b = buttons_clone2.clone();
                    // Widget references for refresh captured here (already owned)
                    let gallery = gallery_refresh_clone.clone();
                    let gallery_container = gallery_container_refresh_clone.clone();
                    let current_image = current_image_refresh_clone.clone();
                    let path_label = path_label_refresh_clone.clone();
                    let buttons_enabled = buttons_enabled_refresh_clone.clone();
                    glib::idle_add_local_once(move || {
                        let mut enabled = buttons_clone2b.lock().unwrap();
                        *enabled = true;
                        drop(enabled);
                        set_button_clone2.set_label("Set As Wallpaper");
                        set_button_clone2.set_sensitive(true);
                        // Refresh the wallpaper UI
                        refresh_wallpaper_ui(&gallery, &gallery_container, &current_image, &path_label, &buttons_enabled);
                    });
                    // Remove the indicator file
                    let _ = fs::remove_file("/tmp/done_color_application");
                    // No longer restart the application; colors will apply system-wide without reopening this window
                    // Stop this timeout loop now that the task is complete
                    let mut active_flag = timeout_active_clone.lock().unwrap();
                    *active_flag = false;
                    return glib::Continue(false);
                }
                
                // Continue checking
                glib::Continue(true)
            });
            
            // Add a timeout to stop checking after 30 seconds
            let buttons_clone3 = buttons_clone.clone();
            let set_button_clone2 = set_button.clone();
            let timeout_active_clone2 = timeout_active.clone();
            
            glib::timeout_add_local(Duration::from_secs(30), move || {
                // Mark the timeout as inactive
                let mut active = timeout_active_clone2.lock().unwrap();
                *active = false;
                drop(active);
                
                // Re-enable buttons
                let mut enabled = buttons_clone3.lock().unwrap();
                *enabled = true;
                drop(enabled);
                
                // Update button appearance
                set_button_clone2.set_label("Set As Wallpaper");
                set_button_clone2.set_sensitive(true);
                
                glib::Continue(false)
            });
        }));
    } else {
        // Add a "Current" indicator for the current wallpaper
        let current_label = gtk::Label::new(Some("Current Wallpaper"));
        current_label.add_css_class("caption");
        current_label.add_css_class("dim-label");
        current_label.set_halign(gtk::Align::Center);
        item.append(&current_label);
    }
    
    // Connect preview button to show a larger preview
    let path_str = path.to_str().unwrap_or("").to_string();
    let gallery_container_clone = gallery_container.clone();
    let gallery_clone = gallery.clone();
    preview_button.connect_clicked(move |_| {
        show_preview_dialog(&path_str, &gallery_container_clone, &gallery_clone);
    });
    
    item
}

// Function to get the current wallpaper path
fn get_current_wallpaper() -> Option<String> {
    if let Ok(content) = fs::read_to_string(CURRENT_WALLPAPER_PATH) {
        let path = content.trim().to_string();
        if !path.is_empty() {
            return Some(path);
        }
    }
    None
}

// Function to find all wallpaper images
fn find_wallpapers() -> Vec<PathBuf> {
    let mut wallpapers = Vec::new();
    
    for &path in WALLPAPER_PATHS {
        if let Ok(entries) = fs::read_dir(path) {
            for entry in entries.filter_map(|e| e.ok()) {
                let path = entry.path();
                
                // Check if it's a file with an image extension
                if path.is_file() {
                    if let Some(extension) = path.extension().and_then(|ext| ext.to_str()) {
                        if IMAGE_EXTENSIONS.iter().any(|&img_ext| img_ext.eq_ignore_ascii_case(extension)) {
                            wallpapers.push(path);
                        }
                    }
                }
            }
        }
    }
    
    // Sort wallpapers by name
    wallpapers.sort_by(|a, b| {
        let a_name = a.file_name().and_then(|n| n.to_str()).unwrap_or("");
        let b_name = b.file_name().and_then(|n| n.to_str()).unwrap_or("");
        a_name.cmp(b_name)
    });
    
    wallpapers
}

// Helper function to refresh the wallpaper UI (current image, label, and gallery)
fn refresh_wallpaper_ui(gallery: &gtk::FlowBox, gallery_container: &gtk::Box, current_image: &gtk::Picture, path_label: &gtk::Label, buttons_enabled: &Arc<Mutex<bool>>) {
    // Clear existing gallery items
    while let Some(child) = gallery.first_child() {
        gallery.remove(&child);
    }

    // Show loading indicator again
    let spinner = gtk::Spinner::new();
    spinner.set_size_request(32, 32);
    spinner.set_halign(gtk::Align::Center);
    spinner.set_valign(gtk::Align::Center);
    spinner.set_vexpand(true);
    spinner.start();

    let loading_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    loading_box.set_halign(gtk::Align::Center);
    loading_box.set_valign(gtk::Align::Center);
    loading_box.set_vexpand(true);
    loading_box.append(&spinner);
    let loading_label = gtk::Label::new(Some("Loading wallpapers..."));
    loading_label.add_css_class("dim-label");
    loading_box.append(&loading_label);

    // Clear the gallery container and add the loading indicator
    while let Some(child) = gallery_container.first_child() {
        gallery_container.remove(&child);
    }
    gallery_container.append(&loading_box);

    // Get fresh current wallpaper path
    let current_wallpaper = get_current_wallpaper();
    if let Some(path) = &current_wallpaper {
        if Path::new(path).exists() {
            current_image.set_filename(Some(path));
            if let Some(filename) = Path::new(path).file_name() {
                if let Some(filename_str) = filename.to_str() {
                    path_label.set_text(filename_str);
                }
            }
        } else {
            current_image.set_filename(None::<&std::path::Path>);
            path_label.set_text("Wallpaper file not found");
        }
    } else {
        current_image.set_filename(None::<&std::path::Path>);
        path_label.set_text("No wallpaper set");
    }

    // Load images again
    let gallery_clone = gallery.clone();
    let gallery_container_clone = gallery_container.clone();
    let buttons_enabled_clone = buttons_enabled.clone();
    let current_wallpaper_clone = current_wallpaper.clone();
    let current_image_clone = current_image.clone();
    let path_label_clone = path_label.clone();
    glib::idle_add_local_once(move || {
        let wallpapers = find_wallpapers();
        if wallpapers.is_empty() {
            let no_wallpapers_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
            no_wallpapers_box.set_halign(gtk::Align::Center);
            no_wallpapers_box.set_valign(gtk::Align::Center);
            no_wallpapers_box.set_vexpand(true);
            let no_wallpapers_icon = gtk::Image::from_icon_name("dialog-information-symbolic");
            no_wallpapers_icon.set_pixel_size(48);
            no_wallpapers_icon.add_css_class("dim-label");
            no_wallpapers_box.append(&no_wallpapers_icon);
            let no_wallpapers_label = gtk::Label::new(Some("No wallpapers found"));
            no_wallpapers_label.add_css_class("title-3");
            no_wallpapers_box.append(&no_wallpapers_label);
            let no_wallpapers_hint = gtk::Label::new(Some("Add some images to your Pictures folder"));
            no_wallpapers_hint.add_css_class("dim-label");
            no_wallpapers_box.append(&no_wallpapers_hint);
            while let Some(child) = gallery_container_clone.first_child() {
                gallery_container_clone.remove(&child);
            }
            gallery_container_clone.append(&no_wallpapers_box);
            return;
        }
        for wallpaper_path in wallpapers {
            let is_current = if let Some(current) = &current_wallpaper_clone {
                wallpaper_path == Path::new(current)
            } else {
                false
            };
            let wallpaper_item = create_wallpaper_item(
                &wallpaper_path,
                buttons_enabled_clone.clone(),
                is_current,
                &gallery_clone,
                &gallery_container_clone,
                &current_image_clone,
                &path_label_clone,
            );
            gallery_clone.append(&wallpaper_item);
        }
        while let Some(child) = gallery_container_clone.first_child() {
            gallery_container_clone.remove(&child);
        }
        gallery_container_clone.append(&gallery_clone);
    });
}

// Function to show a preview dialog for the wallpaper
fn show_preview_dialog(path: &str, gallery_container: &gtk::Box, gallery: &gtk::FlowBox) {
    // Remove the gallery from the content box to make space for the preview
    gallery_container.remove(gallery);
    
    // Create a new box for the preview
    let preview_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    preview_box.set_vexpand(true);
    preview_box.set_hexpand(true);
    preview_box.set_margin_top(10);
    preview_box.set_margin_bottom(10);
    preview_box.set_margin_start(10);
    preview_box.set_margin_end(10);
    
    // Add a title for the preview
    let preview_title = gtk::Label::new(Some("Wallpaper Preview"));
    preview_title.add_css_class("title-3");
    preview_title.set_halign(gtk::Align::Start);
    preview_box.append(&preview_title);
    
    // Create the image widget for the preview
    let image = gtk::Picture::for_filename(path);
    image.set_content_fit(gtk::ContentFit::Contain);
    image.set_vexpand(true);
    image.set_hexpand(true);
    image.set_size_request(400, 300);
    preview_box.append(&image);
    
    // Add a close button to return to the gallery
    let close_button = gtk::Button::with_label("Back to Gallery");
    close_button.add_css_class("pill");
    close_button.set_halign(gtk::Align::Center);
    let gallery_clone2 = gallery.clone();
    close_button.connect_clicked(glib::clone!(@weak gallery_container, @weak gallery_clone2, @weak preview_box => move |_| {
        gallery_container.remove(&preview_box);
        gallery_container.append(&gallery_clone2);
    }));
    preview_box.append(&close_button);
    
    // Add the preview box to the content
    gallery_container.append(&preview_box);
}