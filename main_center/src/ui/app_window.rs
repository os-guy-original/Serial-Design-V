use gtk::{self, glib, WindowHandle};
use libadwaita;
use libadwaita::prelude::*;
use crate::ui::sidebar::Sidebar;
use crate::ui::tabs::Tabs;
use crate::ui::app_drawer::AppDrawer;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::sync::Once;
use std::path::Path;

pub struct AppWindow {
    pub window: libadwaita::ApplicationWindow,
}

// Flag to track if CSS has been initialized
static CSS_INITIALIZED: AtomicBool = AtomicBool::new(false);
// Use Once for thread-safe initialization
static CSS_INIT: Once = Once::new();
// Global mutex for CSS loading to prevent race conditions
static CSS_MUTEX: Mutex<()> = Mutex::new(());

impl AppWindow {
    pub fn new(app: &libadwaita::Application) -> Self {
        // Create the main window
        let window = libadwaita::ApplicationWindow::new(app);
        window.set_title(Some("Main Center"));
        
        // Set a fixed size - can't be resized
        window.set_default_size(900, 600);
        window.set_resizable(false);
        
        // Make window borderless but use GTK's styling
        window.set_decorated(false);
        window.set_deletable(true);
        window.add_css_class("rounded");
        
        // Use GTK's default styling for the window
        window.add_css_class("default");
        
        // Set window to appear on top
        window.set_modal(true);
        
        // Initialize CSS only once using thread-safe Once
        CSS_INIT.call_once(|| {
            Self::init_css();
        });
        
        // Create a vertical box to hold all UI elements
        let vbox = gtk::Box::new(gtk::Orientation::Vertical, 0);
        
        // Create a custom window handle for dragging
        let window_handle = WindowHandle::new();
        window_handle.add_css_class("draggable");
        
        // Create a header with drag handle and buttons
        let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        header_box.set_margin_top(8);
        header_box.set_margin_bottom(8);
        header_box.set_margin_start(8);
        header_box.set_margin_end(8);
        
        // App title
        let title_label = gtk::Label::new(Some("Main Center"));
        title_label.add_css_class("title-4");
        title_label.set_hexpand(true);
        title_label.set_halign(gtk::Align::Start);
        
        // Create app drawer
        let app_drawer = AppDrawer::new();
        let app_drawer_button = app_drawer.button;
        
        // Control buttons box
        let controls_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        
        // Add app drawer button first
        controls_box.append(&app_drawer_button);
        
        // Close button
        let close_button = gtk::Button::new();
        close_button.set_icon_name("window-close-symbolic");
        close_button.add_css_class("circular");
        close_button.add_css_class("flat");
        close_button.add_css_class("destructive-action");
        close_button.connect_clicked(glib::clone!(@weak window => move |_| {
            window.close();
        }));
        
        // Add buttons to controls
        controls_box.append(&close_button);
        
        // Add elements to the header
        header_box.append(&title_label);
        header_box.append(&controls_box);
        
        // Set up the window handle
        window_handle.set_child(Some(&header_box));
        vbox.append(&window_handle);
        
        // Add separator
        let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
        vbox.append(&separator);
        
        // Create the main content area (horizontal box)
        let content = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        content.set_vexpand(true);
        
        // Create tabs area
        let tabs = Tabs::new();
        content.append(&tabs.widget);
        
        // Create the sidebar (now on the right)
        let sidebar = Sidebar::new();
        content.append(&sidebar.widget);
        
        // Add the content to the window
        vbox.append(&content);
        window.set_content(Some(&vbox));
        
        AppWindow { window }
    }
    
    fn init_css() {
        // Use a mutex to prevent race conditions during CSS loading
        let _lock = CSS_MUTEX.lock().unwrap_or_else(|_| {
            // If the mutex is poisoned, we'll create a new one
            CSS_INITIALIZED.store(false, Ordering::SeqCst);
            CSS_MUTEX.lock().expect("Failed to acquire CSS mutex")
        });
        
        // Check if CSS is already initialized
        if CSS_INITIALIZED.load(Ordering::SeqCst) {
            return;
        }
        
        // Load the CSS provider for main styles
        let provider = gtk::CssProvider::new();
        
        // Check for CSS in multiple locations with better error handling
        let mut css_loaded = false;
        
        // First try user config directory
        if let Some(config_dir) = glib::user_config_dir().to_str() {
            let app_css = format!("{}/main_center/style.css", config_dir);
            if Path::new(&app_css).exists() {
                // Use a safer method to load CSS
                match std::fs::read_to_string(&app_css) {
                    Ok(css_content) => {
                        provider.load_from_data(&css_content);
                        css_loaded = true;
                        println!("Loaded CSS from user config: {}", app_css);
                    },
                    Err(e) => println!("Failed to read CSS file {}: {}", app_css, e),
                }
            }
        }
        
        // Then try relative path from executable
        if !css_loaded {
            let assets_css = Path::new("assets/style.css");
            if assets_css.exists() {
                match std::fs::read_to_string(assets_css) {
                    Ok(css_content) => {
                        provider.load_from_data(&css_content);
                        css_loaded = true;
                        println!("Loaded CSS from assets directory");
                    },
                    Err(e) => println!("Failed to read CSS file {:?}: {}", assets_css, e),
                }
            }
        }
        
        // Finally fall back to embedded CSS
        if !css_loaded {
            provider.load_from_data(include_str!("../../assets/style.css"));
            println!("Loaded CSS from embedded resource");
        }
        
        // Apply to the default screen
        if let Some(display) = gtk::gdk::Display::default() {
            gtk::style_context_add_provider_for_display(
                &display,
                &provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        } else {
            println!("Warning: Could not get default display for CSS");
        }
        
        // Load media player specific CSS
        let media_css = Path::new("assets/media_player.css");
        if media_css.exists() {
            let media_provider = gtk::CssProvider::new();
            match std::fs::read_to_string(media_css) {
                Ok(css_content) => {
                    media_provider.load_from_data(&css_content);
                    println!("Loaded media player CSS from assets directory");
                    
                    // Apply media-specific CSS
                    if let Some(display) = gtk::gdk::Display::default() {
                        gtk::style_context_add_provider_for_display(
                            &display,
                            &media_provider,
                            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
                        );
                    }
                },
                Err(e) => println!("Failed to read CSS file {:?}: {}", media_css, e),
            }
        }
        
        // Mark CSS as initialized
        CSS_INITIALIZED.store(true, Ordering::SeqCst);
    }
} 