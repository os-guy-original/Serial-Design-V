mod ui;
// Remove hyprland module since we don't need it
// mod hyprland;

use gtk::prelude::*;
use glib;
use libadwaita as adw;
use std::env;
use std::sync::Once;
use std::panic;

use ui::app_window::AppWindow;

// Initialize environment variables only once
static ENV_INIT: Once = Once::new();

fn main() -> glib::ExitCode {
    // Set up custom panic handler to log errors
    panic::set_hook(Box::new(|panic_info| {
        eprintln!("Application panic: {}", panic_info);
        if let Some(location) = panic_info.location() {
            eprintln!("Panic occurred in file '{}' at line {}", location.file(), location.line());
        }
    }));

    // Initialize environment variables only once
    ENV_INIT.call_once(|| {
        // Force Wayland usage by setting GDK_BACKEND environment variable
        if env::var("GDK_BACKEND").is_err() {
            env::set_var("GDK_BACKEND", "wayland");
        }
        
        // Let GTK handle theme settings
        if env::var("GTK_THEME_VARIANT").is_err() {
            env::set_var("GTK_THEME_VARIANT", "system");
        }
        
        // Check if running on XWayland by examining WAYLAND_DISPLAY and XDG_SESSION_TYPE
        let is_xwayland = env::var("WAYLAND_DISPLAY").is_ok() && 
                          (env::var("XDG_SESSION_TYPE").map(|v| v != "wayland").unwrap_or(true));
        
        // If running on XWayland, set DISPLAY to null to make Xorg invisible
        if is_xwayland {
            env::set_var("DISPLAY", "");
            println!("Detected XWayland, setting DISPLAY to empty to force native Wayland");
        }
    });
    
    // Initialize GTK and Libadwaita with proper error handling
    match adw::init() {
        Ok(_) => (),
        Err(e) => {
            eprintln!("Failed to initialize libadwaita: {}", e);
            return glib::ExitCode::FAILURE;
        }
    }
    
    // Create a new application with accelerated rendering
    let app = adw::Application::builder()
        .application_id("org.example.main_center")
        .build();
    
    // Connect to the activate signal
    app.connect_activate(build_ui);
    
    // Run the application
    app.run()
}

fn build_ui(app: &adw::Application) {
    // Create the main window with error handling
    let window = match std::panic::catch_unwind(|| AppWindow::new(app)) {
        Ok(window) => window,
        Err(e) => {
            eprintln!("Failed to create application window: {:?}", e);
            return;
        }
    };
    
    // Present the window to the user
    window.window.present();
}
