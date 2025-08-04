use gtk::prelude::*;
use gtk;
use libadwaita as adw;
use libadwaita::prelude::*;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use glib;
use serde;
use serde_json;
use serde::{Serialize, Deserialize};
use std::rc::Rc;
use std::cell::RefCell;

// Function to get the home directory
fn get_home_dir() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        })
}

// Default paths to look for wallpapers
fn get_wallpaper_paths() -> Vec<PathBuf> {
    let home = get_home_dir();
    vec![
        home.join("Pictures"),
        home.join("Pictures/Wallpapers"),
        home.join(".local/share/backgrounds"),
        PathBuf::from("/usr/share/backgrounds"),
        PathBuf::from("/usr/share/wallpapers"),
    ]
}

// File extensions to filter for images
const IMAGE_EXTENSIONS: &[&str] = &[
    "jpg", "jpeg", "png", "webp", "bmp"
];

// Path to the current wallpaper file
fn get_current_wallpaper_path() -> PathBuf {
    get_home_dir().join(".config/hypr/cache/state/last_wallpaper")
}

// Data structure persisted in ~/.config/main_center/wallpaper_folders.json
#[derive(serde::Serialize, serde::Deserialize, Clone)]
struct UserWallpaperFolder {
    name: String,
    path: String,
}

fn folders_config_path() -> PathBuf {
    get_home_dir().join(".config/main_center/wallpaper_folders.json")
}

fn load_user_folders() -> Vec<UserWallpaperFolder> {
    let path = folders_config_path();
    if let Ok(data) = std::fs::read_to_string(path) {
        serde_json::from_str::<Vec<UserWallpaperFolder>>(&data).unwrap_or_default()
    } else {
        Vec::new()
    }
}

fn save_user_folders(folders: &[UserWallpaperFolder]) {
    if let Some(parent) = folders_config_path().parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    if let Ok(json) = serde_json::to_string_pretty(folders) {
        let _ = std::fs::write(folders_config_path(), json);
    }
}

// Build a complete gallery page widget for a given directory (None = default aggregated)
fn create_gallery_page(base_dir: Option<PathBuf>) -> gtk::Box {
    // Clone of earlier implementation but parameterised
    let page_box = gtk::Box::new(gtk::Orientation::Vertical, 0);

    // Scroll area
    let scroll = gtk::ScrolledWindow::new();
    scroll.set_vexpand(true);
    scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);

    // Re-use existing gallery building logic via much of original code
    // We'll embed previous container logic into an inner builder closure, largely the same as before but reusing refresh_wallpaper_ui(base_dir.clone())

    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_top(16);
    content_box.set_margin_bottom(16);

    // Current wallpaper section (reuse earlier small helper logic)
    let current_wallpaper_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    let current_label = gtk::Label::new(Some("Current Wallpaper"));
    current_label.add_css_class("title-3");
    current_label.set_halign(gtk::Align::Start);
    current_wallpaper_box.append(&current_label);

    let current_frame = gtk::Frame::new(None);
    current_frame.add_css_class("view");
    current_frame.set_size_request(300, 200);

    let current_image = gtk::Picture::new();
    if let Some(path) = get_current_wallpaper() {
        if Path::new(&path).exists() {
            current_image.set_filename(Some(&path));
        }
    }
    current_image.set_content_fit(gtk::ContentFit::Cover);
    current_image.set_size_request(300, 200);
    current_frame.set_child(Some(&current_image));
    current_wallpaper_box.append(&current_frame);

    let path_label = gtk::Label::new(None);
    path_label.add_css_class("caption");
    path_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    path_label.set_max_width_chars(40);
    current_wallpaper_box.append(&path_label);

    content_box.append(&current_wallpaper_box);
    content_box.append(&gtk::Separator::new(gtk::Orientation::Horizontal));
    let gallery_label = gtk::Label::new(Some("Available Wallpapers"));
    gallery_label.add_css_class("title-3");
    gallery_label.set_halign(gtk::Align::Start);
    content_box.append(&gallery_label);

    let gallery = gtk::FlowBox::new();
    gallery.set_valign(gtk::Align::Start);
    gallery.set_max_children_per_line(4);
    gallery.set_min_children_per_line(2);
    gallery.set_selection_mode(gtk::SelectionMode::None);
    gallery.set_homogeneous(true);
    gallery.set_row_spacing(20);
    gallery.set_column_spacing(20);

    let gallery_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
    gallery_container.set_vexpand(true);
    content_box.append(&gallery_container);

    scroll.set_child(Some(&content_box));
    page_box.append(&scroll);

    let buttons_enabled = Arc::new(Mutex::new(true));

    // Initial load
    let gallery_clone = gallery.clone();
    let gallery_container_clone = gallery_container.clone();
    let buttons_enabled_clone = buttons_enabled.clone();
    let current_image_clone = current_image.clone();
    let path_label_clone = path_label.clone();
    let base_clone = base_dir.clone();
    glib::idle_add_local_once(move || {
        refresh_wallpaper_ui(base_clone, &gallery_clone, &gallery_container_clone, &current_image_clone, &path_label_clone, &buttons_enabled_clone);
    });

    // Refresh button per page (top-level will provide separate button, but we add keyboard? skip)

    page_box
}

pub fn create_wallpaper_content() -> gtk::Widget {
    let root = gtk::Box::new(gtk::Orientation::Vertical, 10);
    root.set_margin_top(24);
    root.set_margin_bottom(24);
    root.set_margin_start(24);
    root.set_margin_end(24);

    // Header row
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    let title_lbl = gtk::Label::new(Some("Wallpapers"));
    title_lbl.add_css_class("title-2");
    title_lbl.set_halign(gtk::Align::Start);
    title_lbl.set_hexpand(true);

    let manage_btn = gtk::Button::new();
    manage_btn.set_icon_name("list-add-symbolic");
    manage_btn.add_css_class("circular");
    manage_btn.set_tooltip_text(Some("Add picture folder"));

    // Button to manage existing categories
    let edit_btn = gtk::Button::new();
    edit_btn.set_icon_name("view-list-symbolic");
    edit_btn.add_css_class("circular");
    edit_btn.set_tooltip_text(Some("Manage existing categories"));

    header_box.append(&title_lbl);
    header_box.append(&manage_btn);
    header_box.append(&edit_btn);
    root.append(&header_box);

    // TabView
    let tabview = adw::TabView::new();
    let tabbar = adw::TabBar::new();
    tabbar.set_view(Some(&tabview));
    root.append(&tabbar);
    root.append(&tabview);

    // Flag to allow programmatic tab closes
    let allow_close = Rc::new(RefCell::new(false));

    // Intercept close requests so that closing a tab via its close button
    // also removes the corresponding category from the persisted JSON list.
    // We no longer block user-initiated closes; instead we perform cleanup
    // and then allow the page to disappear.
    tabview.connect_close_page(move |_tv, page| {
        let title = page.title();

        // Skip the built-in "Default" page which is not backed by a user folder.
        if title != "Default" {
            let mut folders = load_user_folders();
            folders.retain(|f| f.name != title);
            save_user_folders(&folders);
        }

        // Returning false tells TabView to proceed with closing the page.
        false
    });

    // Default page
    let default_page = create_gallery_page(None);
    let page = tabview.append(&default_page);
    page.set_title("Default");
    page.set_icon(Some(&gtk::gio::ThemedIcon::new("image-x-generic-symbolic")));

    // Load user folders
    let mut user_folders = load_user_folders();
    for folder in &user_folders {
        let widget = create_gallery_page(Some(PathBuf::from(&folder.path)));
        let pg = tabview.append(&widget);
        pg.set_title(&folder.name);
        pg.set_icon(Some(&gtk::gio::ThemedIcon::new("folder-pictures-symbolic")));
    }

    let tabview_ref = tabview.clone();
    let manage_anchor_btn = manage_btn.clone();
    // Manage button click
    manage_btn.connect_clicked(move |_| {
        // File chooser dialog
        let file_chooser = gtk::FileChooserNative::new(
            Some("Select Picture Folder"),
            None::<&gtk::Window>,
            gtk::FileChooserAction::SelectFolder,
            Some("Select"),
            Some("Cancel"),
        );

        let tv_inner = tabview_ref.clone();
        let anchor_btn = manage_anchor_btn.clone();
        file_chooser.connect_response(move |fc, resp| {
            if resp == gtk::ResponseType::Accept {
                if let Some(folder_path) = fc.file().and_then(|f| f.path()) {
                    // Prompt for name using a Popover anchored to the Manage button.
                    let pop = gtk::Popover::new();
                    pop.set_has_arrow(true);
                    pop.set_parent(&anchor_btn);
                    let vbox = gtk::Box::new(gtk::Orientation::Vertical, 6);
                    vbox.set_margin_top(12);
                    vbox.set_margin_bottom(12);
                    vbox.set_margin_start(12);
                    vbox.set_margin_end(12);

                    let entry = gtk::Entry::new();
                    entry.set_placeholder_text(Some("Folder name"));
                    vbox.append(&entry);

                    let hbox = gtk::Box::new(gtk::Orientation::Horizontal, 6);
                    let add_btn = gtk::Button::with_label("Add");
                    let cancel_btn = gtk::Button::with_label("Cancel");
                    hbox.append(&cancel_btn);
                    hbox.append(&add_btn);
                    vbox.append(&hbox);

                    pop.set_child(Some(&vbox));

                    let pop_rc = Rc::new(pop);
                    let tv_dialog = tv_inner.clone();
                    let folder_path_clone = folder_path.clone();

                    // Clone handles for closures
                    let pop_for_add = pop_rc.clone();
                    let pop_for_cancel = pop_rc.clone();

                    add_btn.connect_clicked(move |_| {
                        let name = entry.text().to_string();
                        if name.trim().is_empty() {
                            return;
                        }
                        let mut folders = load_user_folders();
                        folders.push(UserWallpaperFolder { name: name.clone(), path: folder_path_clone.to_string_lossy().into_owned() });
                        save_user_folders(&folders);

                        let new_widget = create_gallery_page(Some(folder_path_clone.clone()));
                        let new_page = tv_dialog.append(&new_widget);
                        new_page.set_title(&name);
                        new_page.set_icon(Some(&gtk::gio::ThemedIcon::new("folder-pictures-symbolic")));

                        pop_for_add.popdown();
                    });

                    cancel_btn.connect_clicked(move |_| {
                        pop_for_cancel.popdown();
                    });

                    pop_rc.popup();
                }
            }
        });

        file_chooser.show();
    });

    // --- Manage Existing Categories popover ---
    let tv_for_edit = tabview.clone();
    let allow_close_edit = allow_close.clone();
    let anchor_edit_btn = edit_btn.clone();
    edit_btn.connect_clicked(move |_| {
        // Load folders each time to stay up to date
        let folders = load_user_folders();
        let pop = gtk::Popover::new();
        pop.set_parent(&anchor_edit_btn);
        pop.set_has_arrow(true);

        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 6);
        vbox.set_margin_top(12);
        vbox.set_margin_bottom(12);
        vbox.set_margin_start(12);
        vbox.set_margin_end(12);

        if folders.is_empty() {
            let lbl = gtk::Label::new(Some("No categories added"));
            lbl.add_css_class("dim-label");
            vbox.append(&lbl);
        } else {
            for folder in folders {
                let row = gtk::Box::new(gtk::Orientation::Horizontal, 6);
                let lbl = gtk::Label::new(Some(&folder.name));
                lbl.set_tooltip_text(Some(&folder.path));
                lbl.set_hexpand(true);
                lbl.set_halign(gtk::Align::Start);
                let lbl_rc = Rc::new(lbl);

                // Rename button
                let rename_btn = gtk::Button::new();
                rename_btn.set_icon_name("document-edit-symbolic");
                rename_btn.add_css_class("circular");

                // Change-path button
                let path_btn = gtk::Button::new();
                path_btn.set_icon_name("folder-open-symbolic");
                path_btn.add_css_class("circular");

                let remove_btn = gtk::Button::new();
                remove_btn.set_icon_name("user-trash-symbolic");
                remove_btn.add_css_class("circular");

                // =====================================================
                // Remove handler
                // =====================================================
                let path_to_remove = folder.path.clone();
                let name_to_remove = folder.name.clone();

                let tv_remove = tv_for_edit.clone();
                let row_clone_for_remove = row.clone();
                let allow = allow_close_edit.clone();
                let lbl_for_remove = lbl_rc.clone();
                remove_btn.connect_clicked(move |_| {
                    // Update JSON
                    let mut folders_vec = load_user_folders();
                    folders_vec.retain(|f| f.path != path_to_remove);
                    save_user_folders(&folders_vec);

                    // Determine current title (might have been renamed)
                    let current_title = lbl_for_remove.text().to_string();

                    // Close tab if open (temporarily allow)
                    *allow.borrow_mut() = true;
                    let mut target: Option<adw::TabPage> = None;
                    for page_res in tv_remove.pages().iter::<adw::TabPage>() {
                        if let Ok(pg) = page_res {
                            if pg.title().as_str() == current_title {
                                target = Some(pg.clone());
                                break;
                            }
                        }
                    }
                    if let Some(pg) = target {
                        tv_remove.close_page(&pg);
                    }
                    *allow.borrow_mut() = false;
                    // Remove row widget from its parent container
                    row_clone_for_remove.unparent();
                });

                // =====================================================
                // Rename handler
                // =====================================================
                let tv_rename = tv_for_edit.clone();
                let lbl_for_rename = lbl_rc.clone();
                let path_for_rename = folder.path.clone();
                let old_name_clone = folder.name.clone();
                rename_btn.connect_clicked(move |btn| {
                    let pop = gtk::Popover::new();
                    pop.set_parent(btn);
                    pop.set_has_arrow(true);

                    let pv_box = gtk::Box::new(gtk::Orientation::Vertical, 6);
                    pv_box.set_margin_top(12);
                    pv_box.set_margin_bottom(12);
                    pv_box.set_margin_start(12);
                    pv_box.set_margin_end(12);

                    let entry = gtk::Entry::new();
                    entry.set_text(&old_name_clone);
                    pv_box.append(&entry);

                    let hbx = gtk::Box::new(gtk::Orientation::Horizontal, 6);
                    let save_btn = gtk::Button::with_label("Save");
                    let cancel_btn = gtk::Button::with_label("Cancel");
                    hbx.append(&cancel_btn);
                    hbx.append(&save_btn);
                    pv_box.append(&hbx);

                    pop.set_child(Some(&pv_box));
                    let pop_rc = Rc::new(pop);

                    let pop_save = pop_rc.clone();
                    let tv_upd = tv_rename.clone();
                    let lbl_upd = lbl_for_rename.clone();
                    let path_match = path_for_rename.clone();
                    let old_name_local = old_name_clone.clone();
                    save_btn.connect_clicked(move |_| {
                        let new_name = entry.text().to_string();
                        if new_name.trim().is_empty() {
                            return;
                        }

                        // Update JSON
                        let mut folders_vec = load_user_folders();
                        if let Some(fld) = folders_vec.iter_mut().find(|f| f.path == path_match) {
                            fld.name = new_name.clone();
                        }
                        save_user_folders(&folders_vec);

                        // Update label
                        lbl_upd.set_text(&new_name);

                        // Update tab title if open
                        for page_res in tv_upd.pages().iter::<adw::TabPage>() {
                            if let Ok(pg) = page_res {
                                if pg.title().as_str() == old_name_local {
                                    pg.set_title(&new_name);
                                    break;
                                }
                            }
                        }

                        pop_save.popdown();
                    });

                    let pop_cancel = pop_rc.clone();
                    cancel_btn.connect_clicked(move |_| { pop_cancel.popdown(); });

                    pop_rc.popup();
                });

                // =====================================================
                // Change-path handler
                // =====================================================
                let lbl_for_path = lbl_rc.clone();
                let tv_path = tv_for_edit.clone();
                let name_for_path = folder.name.clone();
                let old_path_clone = folder.path.clone();
                let allow_path = allow_close_edit.clone();
                path_btn.connect_clicked(move |_| {
                    let file_chooser = gtk::FileChooserNative::new(
                        Some("Select New Folder"),
                        None::<&gtk::Window>,
                        gtk::FileChooserAction::SelectFolder,
                        Some("Select"),
                        Some("Cancel"),
                    );

                    let tv_update = tv_path.clone();
                    let name_curr = name_for_path.clone();
                    let old_path_match = old_path_clone.clone();
                    let lbl_tooltip = lbl_for_path.clone();
                    let allow2 = allow_path.clone();
                    file_chooser.connect_response(move |fc, resp| {
                        if resp == gtk::ResponseType::Accept {
                            if let Some(new_folder) = fc.file().and_then(|f| f.path()) {
                                let new_path_str = new_folder.to_string_lossy().into_owned();

                                // Update JSON
                                let mut folders_vec = load_user_folders();
                                if let Some(fld) = folders_vec.iter_mut().find(|f| f.path == old_path_match) {
                                    fld.path = new_path_str.clone();
                                }
                                save_user_folders(&folders_vec);

                                // Update tooltip
                                lbl_tooltip.set_tooltip_text(Some(&new_path_str));

                                // Refresh tab: close old, open new
                                *allow2.borrow_mut() = true;
                                for page_res in tv_update.pages().iter::<adw::TabPage>() {
                                    if let Ok(pg) = page_res {
                                        if pg.title().as_str() == name_curr {
                                            tv_update.close_page(&pg);
                                            break;
                                        }
                                    }
                                }
                                *allow2.borrow_mut() = false;

                                let new_widget = create_gallery_page(Some(PathBuf::from(&new_path_str)));
                                let new_page = tv_update.append(&new_widget);
                                new_page.set_title(&name_curr);
                                new_page.set_icon(Some(&gtk::gio::ThemedIcon::new("folder-pictures-symbolic")));
                            }
                        }
                    });

                    file_chooser.show();
                });

                // Append widgets to row
                row.append(&*lbl_rc);
                row.append(&rename_btn);
                row.append(&path_btn);
                row.append(&remove_btn);
                vbox.append(&row);
            }
        }

        pop.set_child(Some(&vbox));
        pop.popup();
    });

    root.into()
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
            
            // Run material_extract.sh with --also-set-wallpaper flag
            let extract_script = format!("{0}/.config/hypr/colorgen/material_extract.sh", get_home_dir().display());
            let _ = Command::new("bash")
                .args([&extract_script, "--also-set-wallpaper", &path_str_clone])
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
                        refresh_wallpaper_ui(None, &gallery, &gallery_container, &current_image, &path_label, &buttons_enabled);
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
    // First try reading from the Hyprland cache file
    if let Ok(content) = fs::read_to_string(get_current_wallpaper_path()) {
        let path = content.trim().to_string();
        if !path.is_empty() && Path::new(&path).exists() {
            return Some(path);
        }
    }
    
    // If that fails, try to find a default wallpaper
    for path in get_wallpaper_paths() {
        if path.exists() {
            if let Ok(entries) = fs::read_dir(&path) {
                for entry in entries.filter_map(|e| e.ok()) {
                    let file_path = entry.path();
                    if file_path.is_file() {
                        if let Some(extension) = file_path.extension().and_then(|ext| ext.to_str()) {
                            if IMAGE_EXTENSIONS.iter().any(|&img_ext| img_ext.eq_ignore_ascii_case(extension)) {
                                // Found a valid image file, use it as default
                                if let Some(path_str) = file_path.to_str() {
                                    return Some(path_str.to_string());
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    None
}

// Helper to scan a single directory for image files
fn find_wallpapers_in_dir(dir: &Path) -> Vec<PathBuf> {
    let mut result = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() {
                if let Some(extension) = path.extension().and_then(|ext| ext.to_str()) {
                    if IMAGE_EXTENSIONS.iter().any(|&img_ext| img_ext.eq_ignore_ascii_case(extension)) {
                        result.push(path);
                    }
                }
            }
        }
    }
    result
}

// Function to find wallpapers in either the default search paths (None) or a specific directory (Some(path))
fn find_wallpapers(base_dir: Option<&Path>) -> Vec<PathBuf> {
    let mut wallpapers = Vec::new();

    if let Some(dir) = base_dir {
        wallpapers.extend(find_wallpapers_in_dir(dir));
    } else {
        for path in get_wallpaper_paths().iter() {
            wallpapers.extend(find_wallpapers_in_dir(path));
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

// Helper function to refresh the wallpaper UI for a given directory
fn refresh_wallpaper_ui(base_dir: Option<PathBuf>, gallery: &gtk::FlowBox, gallery_container: &gtk::Box, current_image: &gtk::Picture, path_label: &gtk::Label, buttons_enabled: &Arc<Mutex<bool>>) {
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
    
    // Update the current wallpaper display
    let wallpaper_found = if let Some(path) = &current_wallpaper {
        if Path::new(path).exists() {
            // Try to set the image and handle any errors
            match current_image.set_filename(Some(path)) {
                _ => {
                    // Update the label with the filename
                    if let Some(filename) = Path::new(path).file_name() {
                        if let Some(filename_str) = filename.to_str() {
                            path_label.set_text(filename_str);
                        } else {
                            path_label.set_text(path);
                        }
                    } else {
                        path_label.set_text(path);
                    }
                    true
                }
            }
        } else {
            eprintln!("Wallpaper file not found: {}", path);
            current_image.set_filename(None::<&std::path::Path>);
            path_label.set_text("Wallpaper file not found");
            false
        }
    } else {
        current_image.set_filename(None::<&std::path::Path>);
        path_label.set_text("No wallpaper set");
        false
    };
    
    // If we couldn't display the wallpaper, use a simple gray background
    if !wallpaper_found {
        // Just use a standard CSS class that already exists
        current_image.add_css_class("dim-label");
    }

    // Load images again
    let wallpapers = find_wallpapers(base_dir.as_deref());
    let gallery_clone = gallery.clone();
    let gallery_container_clone = gallery_container.clone();
    let buttons_enabled_clone = buttons_enabled.clone();
    let current_wallpaper_clone = current_wallpaper.clone();
    let current_image_clone = current_image.clone();
    let path_label_clone = path_label.clone();
    
    glib::idle_add_local_once(move || {
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
            
            // If we don't have a current wallpaper set, use the first wallpaper we find
            if !wallpaper_found && !wallpapers.is_empty() {
                if let Some(first_wallpaper) = wallpapers.first() {
                    if let Some(path_str) = first_wallpaper.to_str() {
                        current_image_clone.set_filename(Some(path_str));
                        if let Some(filename) = first_wallpaper.file_name() {
                            if let Some(filename_str) = filename.to_str() {
                                path_label_clone.set_text(filename_str);
                            }
                        }
                    }
                }
            }
            
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