mod ui;
mod hyprland;

use gtk::prelude::*;
use glib;
use libadwaita as adw;

use ui::app_window::AppWindow;

fn main() -> glib::ExitCode {
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
