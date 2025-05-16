use gtk::prelude::*;
use gtk::{self, glib, WindowHandle};
use libadwaita;
use libadwaita::prelude::*;
use crate::ui::sidebar::Sidebar;
use crate::ui::tabs::Tabs;

pub struct AppWindow {
    pub window: libadwaita::ApplicationWindow,
}

impl AppWindow {
    pub fn new(app: &libadwaita::Application) -> Self {
        // Create the main window
        let window = libadwaita::ApplicationWindow::new(app);
        window.set_title(Some("Main Center"));
        
        // Set a fixed size - can't be resized
        window.set_default_size(900, 600);
        window.set_resizable(false);
        
        // Make window floating and borderless
        window.set_decorated(false);
        window.set_deletable(true);
        window.add_css_class("rounded");
        window.add_css_class("floating");
        
        // Set window to appear on top
        window.set_modal(true);
        
        // Initialize CSS
        Self::init_css();
        
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
        
        // Control buttons
        let controls_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        
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
        // Load the CSS provider for main styles
        let provider = gtk::CssProvider::new();
        
        // Check for CSS in multiple locations with better error handling
        let mut css_loaded = false;
        
        // First try user config directory
        if let Some(config_dir) = glib::user_config_dir().to_str() {
            let app_css = format!("{}/main_center/style.css", config_dir);
            if std::path::Path::new(&app_css).exists() {
                provider.load_from_file(&gtk::gio::File::for_path(&app_css));
                css_loaded = true;
                println!("Loaded CSS from user config: {}", app_css);
            }
        }
        
        // Then try relative path from executable
        if !css_loaded {
            let assets_css = std::path::Path::new("assets/style.css");
            if assets_css.exists() {
                provider.load_from_file(&gtk::gio::File::for_path(assets_css));
                css_loaded = true;
                println!("Loaded CSS from assets directory");
            }
        }
        
        // Finally fall back to embedded CSS
        if !css_loaded {
            provider.load_from_data(include_str!("../../assets/style.css"));
            println!("Loaded CSS from embedded resource");
        }
        
        // Apply to the default screen
        gtk::style_context_add_provider_for_display(
            &gtk::gdk::Display::default().expect("Could not get default display"),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
        
        // Load media player specific CSS
        let media_provider = gtk::CssProvider::new();
        let media_css = std::path::Path::new("assets/media_player.css");
        if media_css.exists() {
            media_provider.load_from_file(&gtk::gio::File::for_path(media_css));
            println!("Loaded media player CSS from assets directory");
            
            // Apply media-specific CSS
            gtk::style_context_add_provider_for_display(
                &gtk::gdk::Display::default().expect("Could not get default display"),
                &media_provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }
    }
} 