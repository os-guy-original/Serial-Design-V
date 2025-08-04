use gtk;
use crate::ui::mpris_controller::MprisController;
use crate::ui::tabs::dashboard_tab::create_dashboard_content;
use crate::ui::tabs::volume_tab::create_volume_manager_content;
use crate::ui::tabs::troubleshoot_tab::create_troubleshoot_content;
use crate::ui::tabs::system_update_tab::create_system_update_content;
use crate::ui::tabs::sound_packs_tab::create_sound_packs_content;
use crate::ui::tabs::wallpaper_tab::create_wallpaper_content;
use crate::ui::tabs::cool_facts_tab::create_cool_facts_content;
use crate::ui::tabs::default_apps_tab::create_default_apps_content;
use crate::ui::tabs::clock_config_tab::create_clock_config_content;
use libadwaita as adw;
use libadwaita::prelude::*;
use std::collections::HashMap;
use std::cell::RefCell;
use std::rc::Rc;
use gtk::prelude::*;
use glib::Cast;

pub struct Tabs {
    pub widget: gtk::Box,
    stack: gtk::Stack,
}

impl Tabs {
    pub fn new() -> Self {
        // Create main container for tabs area with size constraints
        let widget = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        widget.set_hexpand(true);
        widget.set_vexpand(true);
        
        // Create sidebar with vertical tabs
        let tabs_sidebar = gtk::Box::new(gtk::Orientation::Vertical, 0);
        tabs_sidebar.set_width_request(180);
        tabs_sidebar.add_css_class("sidebar");
        
        // Create stack to hold different pages
        let stack = gtk::Stack::new();
        stack.set_hexpand(true);
        stack.set_vexpand(true);
        stack.set_transition_type(gtk::StackTransitionType::Crossfade);
        
        // Wrap stack in scrolled window to prevent content overflow
        let stack_scroll = gtk::ScrolledWindow::new();
        stack_scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
        stack_scroll.set_hexpand(true);
        stack_scroll.set_vexpand(true);
        stack_scroll.set_child(Some(&stack));
        
        // ------- Lazy page infrastructure ---------
        // Map of page id -> (title, builder func). When a page is shown the first
        // time, we swap the lightweight placeholder with the real widget built
        // by its builder. This avoids running many external commands during
        // startup (e.g. pactl, pacman) which previously caused the UI to hang.
        let lazy_pages: Rc<RefCell<HashMap<String, (String, Box<dyn Fn() -> gtk::Widget>)>>> = Rc::new(RefCell::new(HashMap::new()));
        
        // Small helper to add a lazily-built page.
        let add_lazy_page = |id: &str, title: &str, builder: Box<dyn Fn() -> gtk::Widget>| {
            let placeholder = gtk::Box::new(gtk::Orientation::Vertical, 0);
            // Give the placeholder some minimal size so the UI does not look empty
            placeholder.set_vexpand(true);
            stack.add_titled(&placeholder, Some(id), title);
            lazy_pages.borrow_mut().insert(id.to_string(), (title.to_string(), builder));
        };
        
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
            
            // Add compatibility note
            let compatibility_label = gtk::Label::new(Some("This app is made for Serial Design V Hyprland configuration.\nIt may not work on others."));
            compatibility_label.set_margin_top(10);
            compatibility_label.set_wrap(true);
            compatibility_label.set_max_width_chars(40);
            compatibility_label.add_css_class("dim-label");
            about_box.append(&compatibility_label);
            
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
        
        // Eagerly build only the dashboard since it is the default visible page.
        add_page(&stack, "dashboard", "Dashboard", create_dashboard_content());
        
        // All other heavy pages are loaded lazily when first visited.
        add_lazy_page("volume", "Volume", Box::new(|| create_volume_manager_content()));
        add_lazy_page("system-update", "System Update", Box::new(|| create_system_update_content()));
        add_lazy_page("sound-packs", "Sound Packs", Box::new(|| create_sound_packs_content()));
        add_lazy_page("wallpaper", "Wallpaper", Box::new(|| create_wallpaper_content()));
        add_lazy_page("troubleshoot", "Troubleshoot", Box::new(|| create_troubleshoot_content()));
        add_lazy_page("cool-facts", "Cool Facts", Box::new(|| create_cool_facts_content()));
        add_lazy_page("clock-config", "Clock Config", Box::new(|| create_clock_config_content()));
        add_lazy_page("default-apps", "Default Apps", Box::new(|| create_default_apps_content()));
        
        // Hook that swaps placeholders with real pages the first time they are shown.
        {
            let lazy_pages_clone = lazy_pages.clone();
            stack.connect_visible_child_notify(move |s| {
                if let Some(name_g) = s.visible_child_name() {
                    let page_name = name_g.as_str().to_owned();
                    let mut map = lazy_pages_clone.borrow_mut();
                    if let Some((title, builder)) = map.remove(&page_name) {
                        // The current visible child is the lightweight placeholder box.
                        if let Some(placeholder_widget) = s.visible_child() {
                            // Build the real content.
                            let real_content = builder();

                            // Attempt to downcast placeholder to a gtk::Box so we can add the real content inside.
                            if let Ok(placeholder_box) = placeholder_widget.clone().downcast::<gtk::Box>() {
                                // Insert the real page widget and ensure it expands.
                                placeholder_box.append(&real_content);
                                placeholder_box.set_vexpand(true);
                                placeholder_box.set_hexpand(true);
                            } else {
                                // Fallback: if the downcast fails (unexpected), replace the child entirely.
                                s.remove(&placeholder_widget);
                                s.add_titled(&real_content, Some(&page_name), &title);
                                if let Some(real_child) = s.child_by_name(&page_name) {
                                    s.set_visible_child(&real_child);
                                }
                            }
                        }
                    }
                }
            });
        }
        
        widget.append(&tabs_sidebar);
        widget.append(&stack_scroll);
        
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