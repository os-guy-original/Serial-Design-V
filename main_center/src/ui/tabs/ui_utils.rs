use gtk::prelude::*;
use gtk;

// Helper function to create a settings card with big title
pub fn create_card(title: &str) -> gtk::Frame {
    // Create a frame without title
    let card = gtk::Frame::new(None);
    card.add_css_class("view");
    card.set_margin_top(8);
    card.set_margin_bottom(8);
    
    // Create a vertical box to hold the title and content
    let box_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
    
    // Create a horizontal box for the header with title
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_start(16);
    header_box.set_margin_top(16);
    header_box.set_margin_end(16);
    
    // Create a prominent title
    let title_label = gtk::Label::new(Some(title));
    title_label.add_css_class("title-1");
    title_label.set_halign(gtk::Align::Start);
    title_label.set_hexpand(true);
    title_label.set_valign(gtk::Align::Center);
    header_box.append(&title_label);
    
    header_box.append(&title_label);
    box_container.append(&header_box);
    
    // Add a separator below the title
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_top(4);
    separator.set_margin_bottom(12);
    box_container.append(&separator);
    
    // Create a container for the content that will be set later
    let content_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
    content_container.set_hexpand(true);
    content_container.set_vexpand(true);
    box_container.append(&content_container);
    
    // Set the box container as the card's child
    card.set_child(Some(&box_container));
    
    // Return the frame
    card
}

// Update the set_child method to work with our custom card layout
pub fn set_card_content(card: &gtk::Frame, content: &impl IsA<gtk::Widget>) {
    if let Some(box_container) = card.child() {
        if let Some(box_widget) = box_container.downcast_ref::<gtk::Box>() {
            // The content container is the last child (after title and separator)
            if let Some(content_container) = box_widget.last_child() {
                if let Some(content_box) = content_container.downcast_ref::<gtk::Box>() {
                    content_box.append(content);
                }
            }
        }
    }
}

pub fn create_usage_bar_widget(title: &str, icon_name: &str, value: f64, label_text: &str) -> gtk::Box {
    let outer_box = gtk::Box::new(gtk::Orientation::Vertical, 8);
    
    // Header with icon and title
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    
    let icon = gtk::Image::from_icon_name(icon_name);
    icon.add_css_class("dim-label");
    
    let title_label = gtk::Label::new(Some(title));
    title_label.add_css_class("heading");
    title_label.set_halign(gtk::Align::Start);
    
    header_box.append(&icon);
    header_box.append(&title_label);
    
    // Progress bar
    let level_bar = gtk::LevelBar::for_interval(0.0, 1.0);
    level_bar.set_value(value / 100.0);
    
    // Use GTK's default accent color instead of custom classes
    level_bar.add_css_class("accent");
    
    // Value label
    let value_label = gtk::Label::new(Some(label_text));
    value_label.set_halign(gtk::Align::End);
    value_label.add_css_class("caption");
    value_label.set_margin_top(4);
    
    outer_box.append(&header_box);
    outer_box.append(&level_bar);
    outer_box.append(&value_label);
    
    outer_box
}

// Helper function to safely get the level bar from a usage widget
pub fn get_level_bar(widget: &gtk::Box) -> gtk::LevelBar {
    // The structure is:
    // outer_box -> [header_box, level_bar, value_label]
    // First, get the header_box
    if let Some(first_child) = widget.first_child() {
        // Get the level_bar (next sibling of header_box)
        if let Some(level_bar) = first_child.next_sibling() {
            return level_bar.downcast::<gtk::LevelBar>().expect("Widget is not a LevelBar");
        }
    }
    panic!("Could not find level bar")
}

// Helper function to safely get the value label from a usage widget
pub fn get_value_label(widget: &gtk::Box) -> gtk::Label {
    // The structure is:
    // outer_box -> [header_box, level_bar, value_label]
    // First, get the header_box
    if let Some(first_child) = widget.first_child() {
        // Get the level_bar
        if let Some(level_bar) = first_child.next_sibling() {
            // Get the value_label (next sibling of level_bar)
            if let Some(value_label) = level_bar.next_sibling() {
                return value_label.downcast::<gtk::Label>().expect("Widget is not a Label");
            }
        }
    }
    panic!("Could not find value label")
} 