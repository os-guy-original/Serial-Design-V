use gtk::prelude::*;
use gtk::{self, glib};
use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader};
use std::thread;
use glib::MainContext;
use zbus::dbus_proxy;
use std::collections::HashMap;
use zbus::zvariant::Value;
use chrono;

#[dbus_proxy(
    interface = "org.freedesktop.Notifications",
    default_service = "org.freedesktop.Notifications",
    default_path = "/org/freedesktop/Notifications"
)]
trait Notifications {
    #[dbus_proxy(signal)]
    fn notification_closed(&self, id: u32, reason: u32) -> zbus::Result<()>;

    #[dbus_proxy(signal)]
    fn action_invoked(&self, id: u32, action_key: &str) -> zbus::Result<()>;

    fn get_capabilities(&self) -> zbus::Result<Vec<String>>;

    fn notify(
        &self,
        app_name: &str,
        replaces_id: u32,
        app_icon: &str,
        summary: &str,
        body: &str,
        actions: &[&str],
        hints: HashMap<&str, Value<'_>>,
        expire_timeout: i32,
    ) -> zbus::Result<u32>;

    fn get_server_information(&self) -> zbus::Result<(String, String, String, String)>;

    fn close_notification(&self, id: u32) -> zbus::Result<()>;
}

#[derive(Clone)]
pub struct Sidebar {
    pub widget: gtk::Box,
    pub notification_list: gtk::ListBox,
}

impl Sidebar {
    pub fn new() -> Self {
        // Create main sidebar container
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.set_width_request(250);
        widget.add_css_class("sidebar");
        
        // Create header for the sidebar
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        header.set_margin_top(10);
        header.set_margin_bottom(10);
        header.set_margin_start(10);
        header.set_margin_end(10);
        
        let header_label = gtk::Label::new(Some("System Notifications"));
        header_label.add_css_class("title-3");
        header.append(&header_label);
        
        // Add a notification list inside a scrolled window
        let scroll = gtk::ScrolledWindow::new();
        scroll.set_vexpand(true);
        
        let notification_list = gtk::ListBox::new();
        notification_list.set_selection_mode(gtk::SelectionMode::None);
        notification_list.add_css_class("boxed-list");
        
        // Add initial notification
        let initial_message = create_notification_row("Waiting for notifications...");
        notification_list.append(&initial_message);
        
        scroll.set_child(Some(&notification_list));
        
        // Add components to the sidebar
        widget.append(&header);
        widget.append(&scroll);
        
        // Create a clear button
        let button = gtk::Button::new();
        button.set_label("Clear Notifications");
        button.set_margin_top(10);
        button.set_margin_bottom(10);
        button.set_margin_start(10);
        button.set_margin_end(10);
        
        let notification_list_clone = notification_list.clone();
        button.connect_clicked(move |_| {
            // Clear all notifications
            while let Some(child) = notification_list_clone.first_child() {
                notification_list_clone.remove(&child);
            }
        });
        
        widget.append(&button);
        
        let sidebar = Sidebar {
            widget,
            notification_list,
        };
        
        // Start the notification monitor
        sidebar.start_notification_monitor();
        
        sidebar
    }
    
    fn start_notification_monitor(&self) {
        let notification_list = self.notification_list.clone();
        
        // Create a channel to send notifications from the thread to the UI
        let (sender, receiver) = MainContext::channel(glib::PRIORITY_DEFAULT);
        
        // Spawn a thread to monitor D-Bus notifications
        thread::spawn(move || {
            println!("DEBUG: Starting D-Bus notification monitor");
            
            // Use dbus-monitor directly to capture notifications
            let dbus_cmd = Command::new("dbus-monitor")
                .args(["interface='org.freedesktop.Notifications',member='Notify'"])
                .stdout(Stdio::piped())
                .spawn();
                
            match dbus_cmd {
                Ok(mut child) => {
                    if let Some(stdout) = child.stdout.take() {
                        let reader = BufReader::new(stdout);
                        println!("DEBUG: Connected to DBus notifications monitor");
                        
                        // Track notification state
                        let mut in_notification = false;
                        let mut app_name = String::new();
                        let mut summary = String::new();
                        let mut body = String::new();
                        let mut string_count = 0;
                        
                        for line in reader.lines() {
                            if let Ok(line) = line {
                                // Print raw dbus output to console for debugging
                                println!("DEBUG: {}", line);
                                
                                // Check if this is the start of a new notification
                                if line.contains("member=Notify") {
                                    in_notification = true;
                                    app_name.clear();
                                    summary.clear();
                                    body.clear();
                                    string_count = 0;
                                    continue;
                                }
                                
                                // Only process strings when actively tracking a notification
                                if in_notification && line.contains("string") {
                                    if let Some(content) = extract_notification_content(&line) {
                                        string_count += 1;
                                        
                                        // We're interested in the first 4 strings: 
                                        // app_name, icon, summary, body
                                        match string_count {
                                            1 => app_name = content,  // App name
                                            3 => summary = content,   // Summary (title)
                                            4 => {                    // Body
                                                body = content;
                                                
                                                // When we have all needed fields, send the notification
                                                if !app_name.is_empty() && !summary.is_empty() {
                                                    let notification_text = if !body.is_empty() {
                                                        format!("{}: {} - {}", app_name, summary, body)
                                                    } else {
                                                        format!("{}: {}", app_name, summary)
                                                    };
                                                    
                                                    println!("DEBUG: Sending notification: {}", notification_text);
                                                    let _ = sender.send(notification_text);
                                                    
                                                    // Don't process more strings for this notification
                                                    in_notification = false;
                                                }
                                            }
                                            _ => {} // Ignore other strings like icon or array entries
                                        }
                                    }
                                }
                                
                                // End of a notification block
                                if line.contains("method return") {
                                    in_notification = false;
                                }
                            }
                        }
                    }
                },
                Err(e) => {
                    println!("ERROR: Failed to start dbus-monitor: {}", e);
                }
            }
        });
        
        // Set up the channel to receive notifications and update the UI
        receiver.attach(None, move |notification_text| {
            let row = create_notification_row(&notification_text);
            notification_list.append(&row);
            
            // Scroll to the bottom if possible
            if let Some(parent) = notification_list.parent() {
                if let Some(scroll) = parent.downcast_ref::<gtk::ScrolledWindow>() {
                    let adj = scroll.vadjustment();
                    adj.set_value(adj.upper() - adj.page_size());
                }
            }
            
            // Keep the channel alive
            glib::Continue(true)
        });
    }
    
    pub fn add_notification(&self, title: &str) {
        let notification = create_notification_row(title);
        self.notification_list.append(&notification);
    }
    
    pub fn clear_notifications(&self) {
        while let Some(child) = self.notification_list.first_child() {
            self.notification_list.remove(&child);
        }
    }
}

fn extract_notification_content(line: &str) -> Option<String> {
    if let Some(start_pos) = line.find("\"") {
        if let Some(end_pos) = line[start_pos + 1..].find("\"") {
            let content = line[start_pos + 1..start_pos + 1 + end_pos].to_string();
            if !content.is_empty() && content != ":" {
                return Some(content);
            }
        }
    }
    None
}

fn create_notification_row(title: &str) -> gtk::ListBoxRow {
    let row = gtk::ListBoxRow::new();
    let box_container = gtk::Box::new(gtk::Orientation::Vertical, 5);
    box_container.set_margin_top(10);
    box_container.set_margin_bottom(10);
    box_container.set_margin_start(10);
    box_container.set_margin_end(10);
    
    // Create the main content area
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 5);
    
    // Create the title label with the full notification text
    let title_label = gtk::Label::new(Some(title));
    title_label.set_halign(gtk::Align::Start);
    title_label.add_css_class("heading");
    title_label.set_wrap(true);
    title_label.set_wrap_mode(gtk::pango::WrapMode::WordChar);
    title_label.set_max_width_chars(30);
    
    // Add a timestamp
    let timestamp = gtk::Label::new(Some(&chrono::Local::now().format("%H:%M:%S").to_string()));
    timestamp.set_halign(gtk::Align::Start);
    timestamp.add_css_class("caption");
    timestamp.add_css_class("dim-label");
    
    // Add all elements to the content box
    content_box.append(&title_label);
    content_box.append(&timestamp);
    
    // Check if we need the expand/collapse functionality
    let line_count = title.matches('\n').count() + 1;
    if line_count > 2 || title.len() > 100 {
        // Create an expandable view
        
        // Create a preview that shows only the first two lines or part of the text
        let preview_text = if line_count > 2 {
            // Extract first two lines
            let mut lines = title.lines();
            let first = lines.next().unwrap_or("");
            let _second = lines.next().unwrap_or("");
            format!("{}...", first) 
        } else {
            // Long line without line breaks
            format!("{}...", &title[..90])
        };
        
        // Create a container for the preview and full text
        let full_box = gtk::Box::new(gtk::Orientation::Vertical, 5);
        
        // Preview label (initially visible)
        let preview_label = gtk::Label::new(Some(&preview_text));
        preview_label.set_halign(gtk::Align::Start);
        preview_label.add_css_class("heading");
        preview_label.set_wrap(true);
        preview_label.set_wrap_mode(gtk::pango::WrapMode::WordChar);
        preview_label.set_max_width_chars(30);
        
        // Full text label (initially hidden)
        let full_label = gtk::Label::new(Some(title));
        full_label.set_halign(gtk::Align::Start);
        full_label.add_css_class("heading");
        full_label.set_wrap(true);
        full_label.set_wrap_mode(gtk::pango::WrapMode::WordChar);
        full_label.set_max_width_chars(30);
        full_label.set_visible(false);
        
        // Add both to the container
        full_box.append(&preview_label);
        full_box.append(&full_label);
        
        // Create the expand/collapse button
        let button = gtk::Button::new();
        button.set_label("Expand");
        button.set_halign(gtk::Align::Start);
        button.add_css_class("flat");
        
        // Button click handler - toggle visibility
        let preview_label_clone = preview_label.clone();
        let full_label_clone = full_label.clone();
        button.connect_clicked(move |btn| {
            let is_expanded = full_label_clone.is_visible();
            
            if is_expanded {
                // Collapse
                preview_label_clone.set_visible(true);
                full_label_clone.set_visible(false);
                btn.set_label("Expand");
            } else {
                // Expand
                preview_label_clone.set_visible(false);
                full_label_clone.set_visible(true);
                btn.set_label("Collapse");
            }
        });
        
        // Replace the title with the expandable view
        content_box.remove(&title_label);
        content_box.prepend(&full_box);
        content_box.append(&button);
    }
    
    // Add the content to the main container
    box_container.append(&content_box);
    
    // Set the box container as the child of the row
    row.set_child(Some(&box_container));
    row
} 