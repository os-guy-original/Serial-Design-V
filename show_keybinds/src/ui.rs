use gtk::prelude::*;
use gtk::{
    Box as GtkBox, Label, ListBox, ListBoxRow, Orientation, ScrolledWindow, 
    SearchEntry, SelectionMode,
};
use log::{debug, info};

use crate::config_parser::Keybind;

/// Create the main content box
pub fn create_content_box() -> (GtkBox, ListBox) {
    // Create a vertical box for our main content
    let content_box = GtkBox::new(Orientation::Vertical, 12);
    content_box.set_margin_top(12);
    content_box.set_margin_bottom(12);
    content_box.set_margin_start(12);
    content_box.set_margin_end(12);
    
    // Create search entry
    let search_entry = SearchEntry::new();
    search_entry.set_placeholder_text(Some("Search keybinds..."));
    content_box.append(&search_entry);
    
    // Create scrolled window for keybinds list
    let scrolled_window = ScrolledWindow::new();
    scrolled_window.set_hexpand(true);
    scrolled_window.set_vexpand(true);
    
    // Create list box for keybinds
    let list_box = ListBox::new();
    list_box.set_selection_mode(SelectionMode::None);
    
    scrolled_window.set_child(Some(&list_box));
    content_box.append(&scrolled_window);
    
    // Store the list_box for later reference in the search handler
    let list_box_ref = list_box.clone();
    
    // Connect search entry to update visibility of rows
    search_entry.connect_search_changed(move |entry| {
        let text = entry.text().to_string().to_lowercase();
        
        // We need to iterate over all rows and check each one
        let n_rows = list_box_ref.observe_children().n_items();
        for i in 0..n_rows {
            if let Some(item) = list_box_ref.observe_children().item(i) {
                if let Some(row) = item.downcast_ref::<ListBoxRow>() {
                    let visible = if text.is_empty() {
                        true
                    } else {
                        let mut found = false;
                        
                        if let Some(keybind_box) = row.child() {
                            if let Some(keybind_box) = keybind_box.downcast_ref::<GtkBox>() {
                                // Check each child widget in the box
                                if let Some(first) = keybind_box.first_child() {
                                    if let Some(label) = first.downcast_ref::<Label>() {
                                        if label.text().to_string().to_lowercase().contains(&text) {
                                            found = true;
                                        }
                                    }
                                }
                                
                                if !found {
                                    if let Some(last) = keybind_box.last_child() {
                                        if let Some(label) = last.downcast_ref::<Label>() {
                                            if label.text().to_string().to_lowercase().contains(&text) {
                                                found = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        found
                    };
                    
                    row.set_visible(visible);
                }
            }
        }
    });
    
    (content_box, list_box)
}

/// Populate the list box with keybinds
pub fn populate_keybinds(list_box: &ListBox, keybinds: &[Keybind]) {
    info!("Populating list box with {} keybinds", keybinds.len());
    
    for (i, keybind) in keybinds.iter().enumerate() {
        let row = ListBoxRow::new();
        let row_box = GtkBox::new(Orientation::Horizontal, 12);
        row_box.set_margin_top(6);
        row_box.set_margin_bottom(6);
        row_box.set_margin_start(6);
        row_box.set_margin_end(6);
        
        // Format key combination
        let key_combo = if keybind.modifiers.is_empty() {
            keybind.key.clone()
        } else {
            // Join modifiers with "+" for clearer display
            format!("{} + {}", keybind.modifiers.join(" + "), keybind.key)
        };
        
        debug!("Adding keybind {}: {} => {}", i, key_combo, keybind.action);
        
        // Create labels
        let key_label = Label::new(Some(&key_combo));
        key_label.add_css_class("keybind-key");
        key_label.set_xalign(0.0);
        key_label.set_width_chars(30); // Wider to accommodate longer key combinations
        
        // For better display, show the command part of the action if it's an "exec"
        let display_action = if keybind.action.starts_with("exec") {
            let parts: Vec<&str> = keybind.action.splitn(2, ',').collect();
            if parts.len() > 1 {
                format!("{}: {}", parts[0].trim(), parts[1].trim())
            } else {
                keybind.action.clone()
            }
        } else {
            keybind.action.clone()
        };
        
        let action_label = Label::new(Some(&display_action));
        action_label.add_css_class("keybind-action");
        action_label.set_xalign(0.0);
        action_label.set_hexpand(true);
        action_label.set_wrap(true);
        
        // Add to row
        row_box.append(&key_label);
        row_box.append(&action_label);
        
        row.set_child(Some(&row_box));
        list_box.append(&row);
    }
    
    info!("Finished populating the list box");
} 