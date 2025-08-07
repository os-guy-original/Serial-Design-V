use gtk::prelude::*;
use libadwaita as adw;
use libadwaita::prelude::*;

pub fn create_custom_primary_button(label: &str) -> gtk::Button {
    let button = gtk::Button::with_label(label);
    
    // Add CSS for custom styling with primary color
    let css_provider = gtk::CssProvider::new();
    css_provider.load_from_data("
        .custom-primary-button {
            background: @accent_color;
            color: shade(@accent_color, 0.3);
            border-radius: 12px;
            border: none;
            outline: none;
            padding: 12px 20px;
            font-weight: 600;
            min-height: 48px;
            /* Remove fixed width - let it size based on text */
            transition: all 150ms ease-out;
        }
        
        .custom-primary-button:hover {
            background: shade(@accent_color, 0.9);
            color: shade(@accent_color, 0.25);
            border: none;
            outline: none;
        }
        
        .custom-primary-button:active {
            background: shade(@accent_color, 0.7);
            color: shade(@accent_color, 0.2);
            border: none;
            outline: none;
        }
        
        .custom-primary-button:focus {
            border: none;
            outline: 2px solid alpha(@accent_color, 0.5);
            outline-offset: 2px;
        }
        
        .custom-primary-button:focus:not(:focus-visible) {
            outline: none;
        }
        
        .custom-primary-button:disabled {
            background: @insensitive_bg_color;
            color: @insensitive_fg_color;
            border: none;
            outline: none;
        }
        
        /* Tab-specific buttons - keep original size */
        .custom-primary-button.tab-button {
            min-width: auto; /* Auto width based on text */
            padding: 10px 16px;
            min-height: 40px;
        }
    ");
    
    // Apply CSS to the button
    if let Some(display) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &css_provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
    
    button.add_css_class("custom-primary-button");
    button
}

pub fn create_test_window() -> adw::Window {
    let window = adw::Window::new();
    window.set_title(Some("Custom Button Test"));
    window.set_default_size(500, 400);
    window.set_modal(true);
    window.set_resizable(true);
    
    // Create main content box
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
    
    // Add header bar
    let header_bar = adw::HeaderBar::new();
    header_bar.set_title_widget(Some(&gtk::Label::new(Some("Custom Button Preview"))));
    content_box.append(&header_bar);
    
    // Create scrolled window for content
    let scroll = gtk::ScrolledWindow::new();
    scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
    scroll.set_vexpand(true);
    scroll.set_hexpand(true);
    
    // Main content area
    let main_box = gtk::Box::new(gtk::Orientation::Vertical, 30);
    main_box.set_margin_top(40);
    main_box.set_margin_bottom(40);
    main_box.set_margin_start(40);
    main_box.set_margin_end(40);
    main_box.set_halign(gtk::Align::Center);
    main_box.set_valign(gtk::Align::Center);
    
    // Title
    let title = gtk::Label::new(Some("Custom Primary Button"));
    title.add_css_class("title-1");
    title.set_margin_bottom(10);
    main_box.append(&title);
    
    // Description
    let description = gtk::Label::new(Some("This button uses GTK's primary accent color with custom styling"));
    description.add_css_class("body");
    description.add_css_class("dim-label");
    description.set_margin_bottom(30);
    main_box.append(&description);
    
    // Create the custom button
    let custom_button = create_custom_primary_button("Primary Action");
    custom_button.set_halign(gtk::Align::Center);
    
    // Add click handler
    custom_button.connect_clicked(move |_| {
        println!("Custom primary button clicked!");
        
        // Show a toast notification
        let toast = adw::Toast::new("Custom button clicked!");
        toast.set_timeout(2);
        
        // You could add the toast to a toast overlay if available
        // For now, just print to console
    });
    
    main_box.append(&custom_button);
    
    // Add some spacing
    let spacer = gtk::Box::new(gtk::Orientation::Vertical, 0);
    spacer.set_vexpand(true);
    main_box.append(&spacer);
    
    // Add variations section
    let variations_title = gtk::Label::new(Some("Button Variations"));
    variations_title.add_css_class("title-3");
    variations_title.set_margin_bottom(20);
    main_box.append(&variations_title);
    
    // Button variations box
    let variations_box = gtk::Box::new(gtk::Orientation::Horizontal, 15);
    variations_box.set_halign(gtk::Align::Center);
    
    // Different button variations
    let buttons = vec![
        ("Action", "Primary action button", false),
        ("Save", "Save button example", false),
        ("Continue", "Continue button example", false),
        ("Disabled", "Disabled button example", true),
    ];
    
    for (label, tooltip, disabled) in buttons {
        let btn = create_custom_primary_button(label);
        btn.set_tooltip_text(Some(tooltip));
        btn.set_sensitive(!disabled);
        
        if !disabled {
            btn.connect_clicked(move |button| {
                if let Some(label) = button.label() {
                    println!("Button '{}' clicked!", label);
                }
            });
        }
        
        variations_box.append(&btn);
    }
    
    main_box.append(&variations_box);
    
    // Set up the scroll and window
    scroll.set_child(Some(&main_box));
    content_box.append(&scroll);
    window.set_content(Some(&content_box));
    
    window
}