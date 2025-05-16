use gtk::prelude::*;
use gtk;
use crate::ui::mpris_controller::MprisController;
use crate::ui::tabs::dashboard_tab::create_dashboard_content;
use crate::ui::tabs::volume_tab::create_volume_manager_content;
use crate::ui::tabs::troubleshoot_tab::create_troubleshoot_content;
use crate::ui::tabs::system_update_tab::create_system_update_content;
use libadwaita as adw;
use libadwaita::prelude::*;

pub struct Tabs {
    pub widget: gtk::Box,
    stack: gtk::Stack,
}

impl Tabs {
    pub fn new() -> Self {
        // Create main container for tabs area
        let widget = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        
        // Create sidebar with vertical tabs
        let tabs_sidebar = gtk::Box::new(gtk::Orientation::Vertical, 0);
        tabs_sidebar.set_width_request(200);
        tabs_sidebar.add_css_class("sidebar");
        
        // Create stack to hold different pages
        let stack = gtk::Stack::new();
        stack.set_hexpand(true);
        stack.set_transition_type(gtk::StackTransitionType::Crossfade);
        
        // Create vertical stack switcher
        let stack_sidebar = gtk::StackSidebar::new();
        stack_sidebar.set_stack(&stack);
        stack_sidebar.set_vexpand(true);
        
        // Create header for sidebar
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        header.set_margin_top(10);
        header.set_margin_bottom(10);
        header.set_margin_start(10);
        header.set_margin_end(10);
        
        let header_label = gtk::Label::new(Some("Menu"));
        header_label.add_css_class("title-3");
        header_label.set_hexpand(true);
        header.append(&header_label);
        
        // Add About button
        let about_button = gtk::Button::new();
        about_button.set_icon_name("help-about-symbolic");
        about_button.add_css_class("circular");
        about_button.set_tooltip_text(Some("About Main Center"));
        about_button.set_margin_end(5);
        
        // Create About dialog window with custom animation
        about_button.connect_clicked(move |_| {
            // Create dialog window
            let dialog = adw::Window::new();
            dialog.set_title(Some("About Main Center"));
            dialog.set_default_size(400, 500);
            dialog.set_modal(true);
            dialog.set_resizable(false);
            dialog.set_deletable(true);
            
            // Make the window floating for Wayland/Hyprland
            dialog.set_startup_id("WINDOW_ROLE=floating_window");
            
            // Create content box
            let content_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
            
            // Add a header bar
            let header_bar = adw::HeaderBar::new();
            header_bar.set_show_end_title_buttons(true);
            content_box.append(&header_bar);
            
            // Create scroll view for content
            let scroll = gtk::ScrolledWindow::new();
            scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
            scroll.set_hexpand(true);
            scroll.set_vexpand(true);
            
            // About content box
            let about_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
            about_box.set_margin_top(30);
            about_box.set_margin_bottom(30);
            about_box.set_margin_start(20);
            about_box.set_margin_end(20);
            about_box.set_halign(gtk::Align::Center);
            
            // App icon
            let app_icon = gtk::Image::from_icon_name("preferences-system-symbolic");
            app_icon.set_pixel_size(96);
            app_icon.add_css_class("icon-dropshadow");
            about_box.append(&app_icon);
            
            // App name
            let app_name = gtk::Label::new(Some("Main Center"));
            app_name.add_css_class("title-1");
            app_name.set_margin_top(10);
            about_box.append(&app_name);
            
            // Version
            let version_label = gtk::Label::new(Some("Version 1.0"));
            version_label.add_css_class("dim-label");
            about_box.append(&version_label);
            
            // Description
            let desc_label = gtk::Label::new(Some("A GTK4/Libadwaita control center for Hyprland"));
            desc_label.set_margin_top(10);
            desc_label.set_wrap(true);
            desc_label.set_max_width_chars(40);
            about_box.append(&desc_label);
            
            // Separator
            let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
            separator.set_margin_top(20);
            separator.set_margin_bottom(20);
            about_box.append(&separator);
            
            // Website button
            let website_button = gtk::Button::new();
            website_button.set_label("GitHub Repository");
            website_button.add_css_class("pill");
            website_button.add_css_class("suggested-action");
            website_button.set_halign(gtk::Align::Center);
            website_button.set_margin_top(20);
             
            website_button.connect_clicked(move |_| {
                // Open the GitHub URL in browser
                match std::process::Command::new("xdg-open")
                    .arg("https://github.com/os-guy/Serial-Design-V/tree/main")
                    .spawn() {
                    Ok(_) => println!("Opened website"),
                    Err(e) => println!("Failed to open website: {}", e),
                }
            });
             
            about_box.append(&website_button);
            
            // Add content to scroll view
            scroll.set_child(Some(&about_box));
            content_box.append(&scroll);
            
            // Set dialog content and show with animation
            dialog.set_content(Some(&content_box));
            
            // Add some CSS for animation
            let css_provider = gtk::CssProvider::new();
            css_provider.load_from_data("
                .icon-dropshadow {
                    transition: 300ms ease-in-out;
                }
                .icon-dropshadow:hover {
                    -gtk-icon-transform: scale(1.1);
                }
            ");
            
            // Add CSS to the dialog
            if let Some(display) = gtk::gdk::Display::default() {
                gtk::style_context_add_provider_for_display(
                    &display,
                    &css_provider,
                    gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
                );
            }
            
            dialog.present();
        });
        
        header.append(&about_button);
        
        // Add power dropdown menu
        let power_menu = gtk::MenuButton::new();
        power_menu.set_icon_name("system-shutdown-symbolic");
        power_menu.add_css_class("circular");
        power_menu.set_tooltip_text(Some("Power Options"));
        
        // Create dropdown menu
        let power_popover = gtk::Popover::new();
        let power_box = gtk::Box::new(gtk::Orientation::Vertical, 5);
        power_box.set_margin_top(10);
        power_box.set_margin_bottom(10);
        power_box.set_margin_start(10);
        power_box.set_margin_end(10);
        
        // Add power options buttons
        let create_power_button = |label: &str, icon: &str, command: &str| {
            let button = gtk::Button::new();
            button.set_hexpand(true);
            button.add_css_class("flat");
            
            let button_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
            
            let button_icon = gtk::Image::from_icon_name(icon);
            button_icon.set_pixel_size(16);
            
            let button_label = gtk::Label::new(Some(label));
            button_label.set_halign(gtk::Align::Start);
            button_label.set_hexpand(true);
            
            button_box.append(&button_icon);
            button_box.append(&button_label);
            button.set_child(Some(&button_box));
            
            // Set up command execution when button is clicked
            let cmd_str = command.to_string();
            button.connect_clicked(move |_| {
                // Use shell to execute the command
                match std::process::Command::new("sh")
                    .arg("-c")
                    .arg(&cmd_str)
                    .spawn() {
                    Ok(_) => println!("Executing power command: {}", cmd_str),
                    Err(e) => println!("Failed to execute command: {} - Error: {}", cmd_str, e),
                }
            });
            
            button
        };
        
        // Power off button
        let poweroff_button = create_power_button(
            "Power Off", 
            "system-shutdown-symbolic", 
            "hyprctl dispatch exit && systemctl poweroff"
        );
        
        // Reboot button
        let reboot_button = create_power_button(
            "Reboot", 
            "system-reboot-symbolic", 
            "hyprctl dispatch exit && systemctl reboot"
        );
        
        // Logout button
        let logout_button = create_power_button(
            "Logout", 
            "system-log-out-symbolic", 
            "hyprctl dispatch exit"
        );
        
        // Lock screen button
        let lock_button = create_power_button(
            "Lock Screen", 
            "system-lock-screen-symbolic", 
            "swaylock"
        );
        
        // Add buttons to power menu box
        power_box.append(&poweroff_button);
        power_box.append(&reboot_button);
        power_box.append(&logout_button);
        power_box.append(&lock_button);
        
        // Add separator
        let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
        separator.set_margin_top(5);
        separator.set_margin_bottom(5);
        power_box.append(&separator);
        
        // Add cancel button
        let cancel_button = gtk::Button::with_label("Cancel");
        cancel_button.add_css_class("flat");
        cancel_button.connect_clicked(glib::clone!(@weak power_popover => move |_| {
            power_popover.popdown();
        }));
        power_box.append(&cancel_button);
        
        // Set up the popover
        power_popover.set_child(Some(&power_box));
        power_menu.set_popover(Some(&power_popover));
        
        header.append(&power_menu);
        
        // Create MPRIS music controller widget
        let mpris_controller = MprisController::new();
        
        // Build the layout
        tabs_sidebar.append(&header);
        tabs_sidebar.append(&stack_sidebar);
        tabs_sidebar.append(&mpris_controller.widget);
        
        // Add items to the stack
        add_page(&stack, "dashboard", "Dashboard", create_dashboard_content());
        add_page(&stack, "volume", "Volume Manager", create_volume_manager_content());
        add_page(&stack, "troubleshoot", "Troubleshoot", create_troubleshoot_content());
        add_page(&stack, "system_update", "System Update", create_system_update_content());
        
        widget.append(&tabs_sidebar);
        widget.append(&stack);
        
        Tabs { widget, stack }
    }
    
    #[allow(dead_code)]
    pub fn add_page(&self, id: &str, title: &str, content: gtk::Widget) {
        add_page(&self.stack, id, title, content);
    }
}

fn add_page(stack: &gtk::Stack, id: &str, title: &str, content: gtk::Widget) {
    stack.add_titled(&content, Some(id), title);
} 