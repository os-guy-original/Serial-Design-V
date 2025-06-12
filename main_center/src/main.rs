mod ui;
// Remove hyprland module since we don't need it
// mod hyprland;

use gtk::prelude::*;
use glib;
use libadwaita as adw;
use std::env;

use ui::app_window::AppWindow;

fn main() -> glib::ExitCode {
    // Force Wayland usage by setting GDK_BACKEND environment variable
    env::set_var("GDK_BACKEND", "wayland");
    
    // Let GTK handle theme settings
    env::set_var("GTK_THEME_VARIANT", "system");
    
    // Check if running on XWayland by examining WAYLAND_DISPLAY and XDG_SESSION_TYPE
    let is_xwayland = env::var("WAYLAND_DISPLAY").is_ok() && 
                      (env::var("XDG_SESSION_TYPE").map(|v| v != "wayland").unwrap_or(true));
    
    // If running on XWayland, set DISPLAY to null to make Xorg invisible
    if is_xwayland {
        env::set_var("DISPLAY", "");
        println!("Detected XWayland, setting DISPLAY to empty to force native Wayland");
    }
    
    // Initialize GTK and Libadwaita
    adw::init().expect("Failed to initialize libadwaita");
    
    // Create a new application
    let app = adw::Application::new(
        Some("org.example.main_center"),
        Default::default(),
    );
    
    // Connect to the activate signal
    app.connect_activate(build_ui);
    
    // Run the application
    app.run()
}

fn build_ui(app: &adw::Application) {
    // Create the main window
    let window = AppWindow::new(app);
    
    // Present the window to the user
    window.window.show();
}
