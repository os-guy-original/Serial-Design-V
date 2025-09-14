use gtk;
use crate::ui::mpris_controller::MprisController;
use crate::ui::custom_button::create_custom_primary_button;
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

// Fade in elements with smooth opacity animation
fn fade_in_elements(
    tabs_scroll: &gtk::ScrolledWindow,
    header_label: &gtk::Label,
    about_button: &gtk::Button,
    power_menu: &gtk::MenuButton,
    mpris: &gtk::Box,
    is_animating: Rc<RefCell<bool>>,
) {
    // Set elements visible but transparent first
    tabs_scroll.set_visible(true);
    header_label.set_visible(true);
    about_button.set_visible(true);
    power_menu.set_visible(true);
    mpris.set_visible(true);
    
    // Set initial opacity to 0
    tabs_scroll.set_opacity(0.0);
    header_label.set_opacity(0.0);
    about_button.set_opacity(0.0);
    power_menu.set_opacity(0.0);
    mpris.set_opacity(0.0);
    
    // Small delay to let paned animation start, then fade in
    glib::timeout_add_local(std::time::Duration::from_millis(50), {
        let tabs_scroll = tabs_scroll.clone();
        let header_label = header_label.clone();
        let about_button = about_button.clone();
        let power_menu = power_menu.clone();
        let mpris = mpris.clone();
        let is_animating = is_animating.clone();
        
        move || {
            // Animate opacity from 0 to 1
            let elements = vec![
                tabs_scroll.clone().upcast::<gtk::Widget>(),
                header_label.clone().upcast::<gtk::Widget>(),
                about_button.clone().upcast::<gtk::Widget>(),
                power_menu.clone().upcast::<gtk::Widget>(),
                mpris.clone().upcast::<gtk::Widget>(),
            ];
            
            animate_opacity(elements, 0.0, 1.0, 180, is_animating.clone());
            glib::Continue(false)
        }
    });
}

// Fade out elements with smooth opacity animation
fn fade_out_elements(
    tabs_scroll: &gtk::ScrolledWindow,
    header_label: &gtk::Label,
    about_button: &gtk::Button,
    power_menu: &gtk::MenuButton,
    mpris: &gtk::Box,
    paned: &gtk::Paned,
    collapsed_width: i32,
    is_animating: Rc<RefCell<bool>>,
) {
    let elements = vec![
        tabs_scroll.clone().upcast::<gtk::Widget>(),
        header_label.clone().upcast::<gtk::Widget>(),
        about_button.clone().upcast::<gtk::Widget>(),
        power_menu.clone().upcast::<gtk::Widget>(),
        mpris.clone().upcast::<gtk::Widget>(),
    ];
    
    let paned_clone = paned.clone();
    let tabs_scroll_clone = tabs_scroll.clone();
    let header_label_clone = header_label.clone();
    let about_button_clone = about_button.clone();
    let power_menu_clone = power_menu.clone();
    let mpris_clone = mpris.clone();
    let is_animating_clone = is_animating.clone();
    
    // Animate opacity from 1 to 0, then hide and collapse
    animate_opacity_with_callback(elements, 1.0, 0.0, 120, move || {
        // Hide elements after fade out
        tabs_scroll_clone.set_visible(false);
        header_label_clone.set_visible(false);
        about_button_clone.set_visible(false);
        power_menu_clone.set_visible(false);
        mpris_clone.set_visible(false);
        
        // Start paned collapse and reset flag when it's done
        let is_animating_final = is_animating_clone.clone();
        animate_paned_position_with_callback(&paned_clone, collapsed_width, move || {
            *is_animating_final.borrow_mut() = false;
        });
    });
}

// Generic opacity animation function
fn animate_opacity(
    elements: Vec<gtk::Widget>,
    start_opacity: f64,
    end_opacity: f64,
    duration_ms: u64,
    is_animating: Rc<RefCell<bool>>,
) {
    animate_opacity_with_callback(elements, start_opacity, end_opacity, duration_ms, move || {
        *is_animating.borrow_mut() = false;
    });
}

// Generic opacity animation with callback
fn animate_opacity_with_callback<F>(
    elements: Vec<gtk::Widget>,
    start_opacity: f64,
    end_opacity: f64,
    duration_ms: u64,
    callback: F,
) where
    F: Fn() + 'static,
{
    let steps = (duration_ms / 16) as i32; // 60fps
    let opacity_step = (end_opacity - start_opacity) / steps as f64;
    let step_count = Rc::new(RefCell::new(0));
    
    glib::timeout_add_local(std::time::Duration::from_millis(16), move || {
        let current_step = *step_count.borrow();
        
        if current_step >= steps {
            // Animation complete - set final opacity and call callback
            for element in &elements {
                element.set_opacity(end_opacity);
            }
            callback();
            return glib::Continue(false);
        }
        
        // Update opacity for all elements
        let current_opacity = start_opacity + (opacity_step * current_step as f64);
        for element in &elements {
            element.set_opacity(current_opacity);
        }
        
        *step_count.borrow_mut() += 1;
        glib::Continue(true)
    });
}

// Animation function for smooth paned position changes
fn animate_paned_position(paned: &gtk::Paned, target_position: i32) {
    animate_paned_position_with_callback(paned, target_position, || {});
}

// Animation function for smooth paned position changes with callback
fn animate_paned_position_with_callback<F>(paned: &gtk::Paned, target_position: i32, callback: F)
where
    F: Fn() + 'static,
{
    let current_position = paned.position();
    let distance = target_position - current_position;
    
    // If already at target or very close, don't animate
    if distance.abs() <= 1 {
        paned.set_position(target_position);
        callback();
        return;
    }
    
    let paned_clone = paned.clone();
    let max_steps = 60; // Maximum animation steps to prevent infinite loops
    let step_count = Rc::new(RefCell::new(0));
    
    glib::timeout_add_local(std::time::Duration::from_millis(16), move || {
        let current = paned_clone.position();
        let remaining = target_position - current;
        let current_step = *step_count.borrow();
        
        // Stop if we've reached the target, are very close, or hit max steps
        if remaining.abs() <= 1 || current_step >= max_steps {
            paned_clone.set_position(target_position);
            callback();
            return glib::Continue(false);
        }
        
        // Use easing for smoother animation, but be more conservative
        let step = (remaining as f32 * 0.12).round() as i32;
        
        // Only move if the step is meaningful (at least 1 pixel)
        if step.abs() >= 1 {
            let new_position = current + step;
            
            // Ensure we don't overshoot the target
            let final_position = if remaining > 0 {
                std::cmp::min(new_position, target_position)
            } else {
                std::cmp::max(new_position, target_position)
            };
            
            paned_clone.set_position(final_position);
        } else {
            // If step is too small, just jump to target
            paned_clone.set_position(target_position);
            callback();
            return glib::Continue(false);
        }
        
        *step_count.borrow_mut() += 1;
        glib::Continue(true)
    });
}

pub struct Tabs {
    pub widget: gtk::Box,
    stack: gtk::Stack,
    tabs_sidebar: gtk::Box,
    is_expanded: Rc<RefCell<bool>>,
}

impl Tabs {
    pub fn new() -> Self {
        // Create main container for tabs area with size constraints
        let widget = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        widget.set_hexpand(true);
        widget.set_vexpand(true);
        
        // Create sidebar with vertical tabs - start collapsed
        let tabs_sidebar = gtk::Box::new(gtk::Orientation::Vertical, 0);
        tabs_sidebar.set_width_request(50); // Even smaller default width
        tabs_sidebar.set_size_request(50, -1); // Set minimum width
        tabs_sidebar.add_css_class("sidebar");
        
        // Add CSS for smooth transitions
        let css_provider = gtk::CssProvider::new();
        css_provider.load_from_data("
            .sidebar {
                transition: width 200ms ease-in-out;
            }
            .sidebar * {
                transition: opacity 200ms ease-in-out;
            }
            .fade-element {
                transition: opacity 200ms ease-in-out;
            }
            .active-tab {
                background: shade(@accent_color, 0.8) !important;
                color: shade(@accent_color, 0.15) !important;
            }
        ");
        
        if let Some(display) = gtk::gdk::Display::default() {
            gtk::style_context_add_provider_for_display(
                &display,
                &css_provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }
        
        // Track expansion state and remember user's preferred expanded width
        let is_expanded = Rc::new(RefCell::new(false));
        let collapsed_width = 50;
        let default_expanded_width = 200;
        let user_expanded_width = Rc::new(RefCell::new(default_expanded_width));
        
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
        
        // Create custom tab container with our custom buttons
        let custom_tabs_container = gtk::Box::new(gtk::Orientation::Vertical, 8);
        custom_tabs_container.set_vexpand(false); // Don't expand vertically
        custom_tabs_container.set_hexpand(true); // Allow horizontal expansion with sidebar
        custom_tabs_container.set_valign(gtk::Align::Start); // Align to top
        custom_tabs_container.set_margin_top(10);
        custom_tabs_container.set_margin_bottom(10);
        custom_tabs_container.set_margin_start(10);
        custom_tabs_container.set_margin_end(10);
        
        // Wrap the tab container in a scrolled window to prevent window expansion
        let tabs_scroll = gtk::ScrolledWindow::new();
        tabs_scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
        tabs_scroll.set_vexpand(true); // Let scroll area expand
        tabs_scroll.set_hexpand(true); // Allow horizontal expansion with sidebar
        tabs_scroll.set_child(Some(&custom_tabs_container));
        
        // Initially hide the scrolled tabs container (collapsed state)
        tabs_scroll.set_visible(false);
        tabs_scroll.add_css_class("fade-element");
        
        // Create header for sidebar
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 5);
        header.set_margin_top(10);
        header.set_margin_bottom(10);
        header.set_margin_start(10);
        header.set_margin_end(10);
        
        // Toggle button for expand/collapse
        let toggle_button = gtk::Button::new();
        toggle_button.set_icon_name("view-sidebar-symbolic");
        toggle_button.add_css_class("circular");
        toggle_button.add_css_class("flat");
        toggle_button.set_tooltip_text(Some("Toggle sidebar"));
        
        let header_label = gtk::Label::new(Some("Menu"));
        header_label.add_css_class("title-3");
        header_label.set_hexpand(true);
        header_label.set_visible(false); // Start hidden
        header_label.add_css_class("fade-element");
        
        header.append(&toggle_button);
        header.append(&header_label);
        
        // Add About button
        let about_button = gtk::Button::new();
        about_button.set_icon_name("help-about-symbolic");
        about_button.add_css_class("circular");
        about_button.set_tooltip_text(Some("About Main Center"));
        about_button.set_margin_end(5);
        about_button.set_visible(false); // Start hidden
        about_button.add_css_class("fade-element");
        
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
                    .arg("https://github.com/os-guy-original/Serial-Design-V/tree/main")
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
        power_menu.set_visible(false); // Start hidden
        power_menu.add_css_class("fade-element");
        
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
        mpris_controller.widget.set_visible(false); // Start hidden
        mpris_controller.widget.add_css_class("fade-element");
        
        // Build the layout first
        tabs_sidebar.append(&header);
        tabs_sidebar.append(&tabs_scroll);
        tabs_sidebar.append(&mpris_controller.widget);
        
        // Create a paned widget to make the sidebar resizable
        let paned = gtk::Paned::new(gtk::Orientation::Horizontal);
        paned.set_start_child(Some(&tabs_sidebar));
        paned.set_end_child(Some(&stack_scroll));
        paned.set_position(collapsed_width); // Start with collapsed width
        paned.set_resize_start_child(false); // Start with manual resizing disabled
        paned.set_shrink_start_child(false); // Don't allow sidebar to shrink below minimum
        paned.set_wide_handle(true); // Make the handle easier to grab
        
        widget.append(&paned);
        
        // Listen for manual paned position changes to remember user's preferred width
        let is_expanded_for_position = is_expanded.clone();
        let user_expanded_width_for_position = user_expanded_width.clone();
        
        paned.connect_position_notify(move |paned| {
            let current_position = paned.position();
            let is_currently_expanded = *is_expanded_for_position.borrow();
            
            // If we're expanded and user manually resized, remember their preference
            if is_currently_expanded && current_position > collapsed_width + 20 {
                *user_expanded_width_for_position.borrow_mut() = current_position;
            }
        });
        
        // Add debouncing to prevent spam clicking issues
        let is_animating = Rc::new(RefCell::new(false));
        
        // Set up toggle functionality with smooth animation, size memory, and fade effects
        let paned_clone = paned.clone();
        let tabs_scroll_clone = tabs_scroll.clone();
        let header_label_clone = header_label.clone();
        let about_button_clone = about_button.clone();
        let power_menu_clone = power_menu.clone();
        let mpris_clone = mpris_controller.widget.clone();
        let is_expanded_clone = is_expanded.clone();
        let user_expanded_width_clone = user_expanded_width.clone();
        let is_animating_clone = is_animating.clone();
        
        toggle_button.connect_clicked(move |_| {
            // Prevent spam clicking - ignore clicks while animating
            if *is_animating_clone.borrow() {
                return;
            }
            
            *is_animating_clone.borrow_mut() = true;
            
            // Safety timeout to force-reset animation flag if something goes wrong
            let safety_reset = is_animating_clone.clone();
            glib::timeout_add_local(std::time::Duration::from_millis(1000), move || {
                *safety_reset.borrow_mut() = false;
                glib::Continue(false)
            });
            
            let mut expanded = is_expanded_clone.borrow_mut();
            *expanded = !*expanded;
            
            if *expanded {
                // Expand to user's preferred width (or default if never resized)
                let target_width = *user_expanded_width_clone.borrow();
                
                // Enable manual resizing when expanded
                paned_clone.set_resize_start_child(true);
                
                // Start paned animation
                animate_paned_position(&paned_clone, target_width);
                
                // Fade in elements with proper timing
                fade_in_elements(
                    &tabs_scroll_clone,
                    &header_label_clone,
                    &about_button_clone,
                    &power_menu_clone,
                    &mpris_clone,
                    is_animating_clone.clone(),
                );
            } else {
                // Before collapsing, save current width as user preference if it's reasonable
                let current_position = paned_clone.position();
                if current_position > collapsed_width + 20 {
                    *user_expanded_width_clone.borrow_mut() = current_position;
                }
                
                // Disable manual resizing when collapsed
                paned_clone.set_resize_start_child(false);
                
                // Fade out elements first, then collapse
                fade_out_elements(
                    &tabs_scroll_clone,
                    &header_label_clone,
                    &about_button_clone,
                    &power_menu_clone,
                    &mpris_clone,
                    &paned_clone,
                    collapsed_width,
                    is_animating_clone.clone(),
                );
            }
        });
        
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
        
        // Create custom tab buttons
        let tab_buttons = vec![
            ("dashboard", "Dashboard"),
            ("volume", "Volume"),
            ("system-update", "System Update"),
            ("sound-packs", "Sound Packs"),
            ("wallpaper", "Wallpaper"),
            ("troubleshoot", "Troubleshoot"),
            ("cool-facts", "Cool Facts"),
            ("clock-config", "Clock Config"),
            ("default-apps", "Default Apps"),
        ];
        
        let current_tab = Rc::new(RefCell::new("dashboard".to_string()));
        
        for (tab_id, tab_title) in tab_buttons {
            let button = create_custom_primary_button(tab_title);
            button.set_hexpand(false); // Don't expand buttons themselves
            button.set_halign(gtk::Align::Start); // Keep buttons left-aligned
            button.add_css_class("tab-button"); // Add tab-specific styling
            
            // Set initial state - dashboard is active by default
            if tab_id == "dashboard" {
                button.add_css_class("active-tab");
            }
            
            // Handle tab switching
            let stack_clone = stack.clone();
            let current_tab_clone = current_tab.clone();
            let container_clone = custom_tabs_container.clone();
            let tab_id_owned = tab_id.to_string();
            
            button.connect_clicked(move |clicked_button| {
                // Update current tab
                *current_tab_clone.borrow_mut() = tab_id_owned.clone();
                
                // Remove active class from all buttons
                let mut child = container_clone.first_child();
                while let Some(widget) = child {
                    if let Some(btn) = widget.downcast_ref::<gtk::Button>() {
                        btn.remove_css_class("active-tab");
                    }
                    child = widget.next_sibling();
                }
                
                // Add active class to clicked button
                clicked_button.add_css_class("active-tab");
                
                // Switch to the selected page
                stack_clone.set_visible_child_name(&tab_id_owned);
            });
            
            custom_tabs_container.append(&button);
        }
        
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
        
        Tabs { 
            widget, 
            stack,
            tabs_sidebar,
            is_expanded,
        }
    }
    
    #[allow(dead_code)]
    pub fn add_page(&self, id: &str, title: &str, content: gtk::Widget) {
        add_page(&self.stack, id, title, content);
    }
}

fn add_page(stack: &gtk::Stack, id: &str, title: &str, content: gtk::Widget) {
    stack.add_titled(&content, Some(id), title);
} 