use gtk::prelude::*;
use gtk;
use gio;
use glib;
use std::path::PathBuf;

// Function to get the home directory
fn get_home_dir() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir().unwrap_or_else(|| PathBuf::from("/tmp"))
        })
}

pub fn create_troubleshoot_content() -> gtk::Widget {
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
    
    // Create header
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_top(16);
    header_box.set_margin_start(16);
    header_box.set_margin_end(16);
    
    let header = gtk::Label::new(Some("System Troubleshooting"));
    header.add_css_class("title-2");
    header.set_halign(gtk::Align::Start);
    header.set_hexpand(true);
    
    header_box.append(&header);
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
    
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 16);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_bottom(16);
    content_box.set_margin_top(16);
    
    // Helper function to create action buttons with loading state
    let create_action_button = |title: &str, icon: &str, description: &str, command: &str| {
        let action_box = gtk::Box::new(gtk::Orientation::Horizontal, 16);
        action_box.set_margin_top(8);
        action_box.set_margin_bottom(8);
        
        // Create button icon
        let button_icon = gtk::Image::from_icon_name(icon);
        button_icon.set_pixel_size(24);
        
        // Create info box
        let info_box = gtk::Box::new(gtk::Orientation::Vertical, 4);
        info_box.set_hexpand(true);
        
        let title_label = gtk::Label::new(Some(title));
        title_label.set_halign(gtk::Align::Start);
        title_label.add_css_class("heading");
        
        let desc_label = gtk::Label::new(Some(description));
        desc_label.set_halign(gtk::Align::Start);
        desc_label.add_css_class("caption");
        desc_label.add_css_class("dim-label");
        
        info_box.append(&title_label);
        info_box.append(&desc_label);
        
        // Create action button with spinner for loading state
        let button_box = gtk::Box::new(gtk::Orientation::Horizontal, 4);
        button_box.set_halign(gtk::Align::Center);
        
        let spinner = gtk::Spinner::new();
        spinner.set_visible(false);
        
        let button_icon_img = gtk::Image::from_icon_name("view-refresh-symbolic");
        button_box.append(&spinner);
        button_box.append(&button_icon_img);
        
        let button = gtk::Button::new();
        button.set_child(Some(&button_box));
        button.add_css_class("circular");
        button.add_css_class("accent");
        
        // Set up command execution with loading state
        let command_str = command.to_string();
        
        // Create loading state within button
        button.connect_clicked(move |btn| {
            // Disable button and show spinner
            btn.set_sensitive(false);
            spinner.set_visible(true);
            spinner.start();
            button_icon_img.set_visible(false);
            
            // Clone everything needed for the threaded callback
            let btn_clone = btn.clone();
            let spinner_clone = spinner.clone();
            let button_icon_clone = button_icon_img.clone();
            let command_clone = command_str.clone();
            
            // Execute the command in a separate thread
            glib::MainContext::default().spawn_local(async move {
                // Execute command asynchronously
                let args = &[
                    std::ffi::OsStr::new("sh"),
                    std::ffi::OsStr::new("-c"), 
                    std::ffi::OsStr::new(&command_clone)
                ];
                let result = gio::Subprocess::newv(
                    args,
                    gio::SubprocessFlags::STDOUT_PIPE | gio::SubprocessFlags::STDERR_PIPE,
                );
                
                match result {
                    Ok(subprocess) => {
                        let _ = subprocess.communicate_utf8_future(None).await.unwrap_or((None, None));
                        println!("Successfully executed: {}", command_clone);
                    },
                    Err(e) => println!("Failed to execute: {} - Error: {}", command_clone, e),
                }
                
                // Re-enable button and hide spinner on the main thread
                glib::idle_add_local_once(move || {
                    btn_clone.set_sensitive(true);
                    spinner_clone.stop();
                    spinner_clone.set_visible(false);
                    button_icon_clone.set_visible(true);
                });
            });
        });
        
        action_box.append(&button_icon);
        action_box.append(&info_box);
        action_box.append(&button);
        
        action_box
    };
    
    // Add all the reload actions
    content_box.append(&create_action_button(
        "Reload Hyprland", 
        "application-x-executable-symbolic",
        "Restart Hyprland compositor",
        "hyprctl reload"
    ));
    
    content_box.append(&create_action_button(
        "Reload GTK Themes", 
        "preferences-desktop-theme-symbolic",
        "Reload GTK3 and GTK4 themes",
        "gsettings set org.gnome.desktop.interface gtk-theme \"$(gsettings get org.gnome.desktop.interface gtk-theme)\""
    ));
    
    content_box.append(&create_action_button(
        "Reload Icon Theme", 
        "preferences-desktop-icons-symbolic",
        "Refresh system icon cache",
        "gsettings set org.gnome.desktop.interface icon-theme \"$(gsettings get org.gnome.desktop.interface icon-theme)\""
    ));
    
    content_box.append(&create_action_button(
        "Reload Font Theme", 
        "preferences-desktop-font-symbolic",
        "Reload system fonts",
        "gsettings set org.gnome.desktop.interface font-name \"$(gsettings get org.gnome.desktop.interface font-name)\""
    ));
    
    let home_dir = get_home_dir().display().to_string();
    let color_script_cmd = format!("bash {}/.config/hypr/colorgen/material_extract.sh", home_dir);
    content_box.append(&create_action_button(
        "Reload Colors",
        "preferences-color-symbolic",
        "Generate and apply material colors",
        &format!("hyprctl dispatch exec \"{}\"", color_script_cmd)
    ));
    
    content_box.append(&create_action_button(
        "Reload swww", 
        "preferences-desktop-wallpaper-symbolic",
        "Restart wallpaper daemon",
        "swww query || (swww kill; sleep 0.5; hyprctl dispatch exec swww-daemon)"
    ));
    
    content_box.append(&create_action_button(
        "Reload Swaync", 
        "dialog-information-symbolic",
        "Restart notification daemon",
        "pidof swaync && swaync-client -rs || (pkill swaync; sleep 0.5; hyprctl dispatch exec swaync)"
    ));
    
    content_box.append(&create_action_button(
        "Reload Waybar", 
        "view-grid-symbolic",
        "Restart status bar",
        "pidof waybar && pkill -USR2 waybar || (pkill waybar; sleep 0.5; hyprctl dispatch exec waybar)"
    ));
    
    // Add divider
    let divider = gtk::Separator::new(gtk::Orientation::Horizontal);
    divider.set_margin_top(8);
    divider.set_margin_bottom(8);
    content_box.append(&divider);
    
    // Add a system reload button (more prominent)
    let system_reload_box = gtk::Box::new(gtk::Orientation::Horizontal, 16);
    system_reload_box.set_margin_top(8);
    system_reload_box.add_css_class("card");
    system_reload_box.add_css_class("accent");
    system_reload_box.set_margin_bottom(8);
    
    let reload_icon = gtk::Image::from_icon_name("system-reboot-symbolic");
    reload_icon.set_pixel_size(32);
    reload_icon.set_margin_start(16);
    
    let reload_info = gtk::Box::new(gtk::Orientation::Vertical, 4);
    reload_info.set_margin_start(8);
    reload_info.set_margin_end(16);
    reload_info.set_margin_top(16);
    reload_info.set_margin_bottom(16);
    reload_info.set_hexpand(true);
    
    let reload_title = gtk::Label::new(Some("Reload All Components"));
    reload_title.set_halign(gtk::Align::Start);
    reload_title.add_css_class("title-4");
    
    let reload_desc = gtk::Label::new(Some("Restart all system UI components at once"));
    reload_desc.set_halign(gtk::Align::Start);
    
    reload_info.append(&reload_title);
    reload_info.append(&reload_desc);
    
    let reload_button = gtk::Button::new();
    reload_button.set_label("Reload All");
    reload_button.add_css_class("pill");
    reload_button.add_css_class("suggested-action");
    reload_button.set_margin_end(16);
    reload_button.set_valign(gtk::Align::Center);
    
    // Set up the reload all action
    reload_button.connect_clicked(move |btn| {
        // Disable button
        btn.set_sensitive(false);
        
        // Get the home directory path once to avoid temporary value issues
        let home_dir = get_home_dir().display().to_string();
        
        // Execute a series of commands to reload everything
        let commands = vec![
            "hyprctl reload".to_string(),
            "gsettings set org.gnome.desktop.interface gtk-theme \"$(gsettings get org.gnome.desktop.interface gtk-theme)\"".to_string(),
            "gsettings set org.gnome.desktop.interface icon-theme \"$(gsettings get org.gnome.desktop.interface icon-theme)\"".to_string(),
            "gsettings set org.gnome.desktop.interface font-name \"$(gsettings get org.gnome.desktop.interface font-name)\"".to_string(),
            format!("hyprctl dispatch exec \"bash {}/.config/hypr/colorgen/material_extract.sh\"", home_dir),
            "swww query || (swww kill; sleep 0.5; hyprctl dispatch exec swww-daemon)".to_string(),
            "pidof swaync && swaync-client -rs || (pkill swaync; sleep 0.5; hyprctl dispatch exec swaync)".to_string(),
            "pidof waybar && pkill -USR2 waybar || (pkill waybar; sleep 0.5; hyprctl dispatch exec waybar)".to_string()
        ];
        
        // Use a separate thread for executing commands
        let btn_clone = btn.clone();
        let commands_clone = commands.clone();
        glib::MainContext::default().spawn_local(async move {
            for cmd in &commands_clone {
                // Execute each command and wait for completion
                let args = &[
                    std::ffi::OsStr::new("sh"),
                    std::ffi::OsStr::new("-c"), 
                    std::ffi::OsStr::new(cmd)
                ];
                match gio::Subprocess::newv(
                    args,
                    gio::SubprocessFlags::STDOUT_PIPE | gio::SubprocessFlags::STDERR_PIPE,
                ) {
                    Ok(subprocess) => {
                        let _ = subprocess.communicate_utf8_future(None).await.unwrap_or((None, None));
                        println!("Successfully executed: {}", cmd);
                    },
                    Err(e) => println!("Failed to execute: {} - Error: {}", cmd, e),
                }
            }
            
            // Re-enable button when all commands complete
            glib::idle_add_local_once(move || {
                btn_clone.set_sensitive(true);
            });
        });
    });
    
    system_reload_box.append(&reload_icon);
    system_reload_box.append(&reload_info);
    system_reload_box.append(&reload_button);
    
    content_box.append(&system_reload_box);
    
    // Add info note
    let info_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    info_box.set_margin_top(16);
    info_box.add_css_class("card");
    
    let info_icon = gtk::Image::from_icon_name("dialog-information-symbolic");
    info_icon.set_margin_start(16);
    info_icon.set_margin_top(16);
    info_icon.set_margin_bottom(16);
    
    let info_label = gtk::Label::new(Some("Some services might take a moment to reload. Background services may briefly disappear during the restart process."));
    info_label.set_wrap(true);
    info_label.set_margin_end(16);
    info_label.set_margin_top(16);
    info_label.set_margin_bottom(16);
    info_label.set_xalign(0.0);
    
    info_box.append(&info_icon);
    info_box.append(&info_label);
    
    content_box.append(&info_box);
    
    // Add content to scroll area
    scroll.set_child(Some(&content_box));
    container.append(&scroll);
    
    // Add container to the main content
    content.append(&container);
    
    content.into()
} 