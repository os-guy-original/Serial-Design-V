use gtk::prelude::*;
use gtk;
use crate::ui::system_info::SystemInfo;
use crate::ui::tabs::ui_utils::{create_card, set_card_content, create_usage_bar_widget, get_level_bar, get_value_label};
use std::rc::Rc;
use std::cell::RefCell;
use glib;

pub fn create_dashboard_content() -> gtk::Widget {
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
    container.set_margin_bottom(20);
    
    // Create header with icon
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_top(16);
    header_box.set_margin_start(16);
    header_box.set_margin_end(16);
    
    let header = gtk::Label::new(Some("System Information"));
    header.add_css_class("title-2");
    header.set_halign(gtk::Align::Start);
    header.set_hexpand(true);
    
    // Add a refresh button
    let refresh_button = gtk::Button::new();
    refresh_button.set_icon_name("view-refresh-symbolic");
    refresh_button.add_css_class("circular");
    refresh_button.set_tooltip_text(Some("Refresh system information"));
    
    header_box.append(&header);
    header_box.append(&refresh_button);
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
    
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_bottom(16);
    content_box.set_margin_top(10);
    
    // System info section
    let info_frame = create_card("System");
    info_frame.set_margin_top(15);
    
    let info_box = gtk::Box::new(gtk::Orientation::Vertical, 10);
    info_box.set_margin_start(16);
    info_box.set_margin_end(16);
    info_box.set_margin_top(16);
    info_box.set_margin_bottom(16);
    
    // Get system information
    let system_info = Rc::new(RefCell::new(SystemInfo::new()));
    
    // Show system information
    let info_grid = gtk::Grid::new();
    info_grid.set_row_spacing(12);
    info_grid.set_column_spacing(24);
    
    // Helper function to add info rows
    let mut row = 0;
    let add_info_row = |grid: &gtk::Grid, label: &str, value: &str, row: i32| {
        let label_widget = gtk::Label::new(Some(label));
        label_widget.add_css_class("heading");
        label_widget.set_halign(gtk::Align::Start);
        
        let value_widget = gtk::Label::new(Some(value));
        value_widget.set_halign(gtk::Align::Start);
        value_widget.set_selectable(true);
        
        grid.attach(&label_widget, 0, row, 1, 1);
        grid.attach(&value_widget, 1, row, 1, 1);
        
        value_widget
    };
    
    // Store widgets that need to be updated
    let system_info_clone = system_info.clone();
    let hostname_label = add_info_row(&info_grid, "Hostname", &system_info.borrow().hostname, row);
    row += 1;
    let hyprland_label = add_info_row(&info_grid, "Hyprland", &system_info.borrow().hyprland_version, row);
    row += 1;
    let kernel_label = add_info_row(&info_grid, "Kernel", &system_info.borrow().kernel_version, row);
    row += 1;
    let cpu_model_label = add_info_row(&info_grid, "CPU", &system_info.borrow().cpu_info, row);
    
    info_box.append(&info_grid);
    set_card_content(&info_frame, &info_box);
    content_box.append(&info_frame);
    
    // Usage section
    let usage_frame = create_card("Usage");
    usage_frame.set_margin_top(15);
    
    let usage_box = gtk::Box::new(gtk::Orientation::Vertical, 16);
    usage_box.set_margin_start(16);
    usage_box.set_margin_end(16);
    usage_box.set_margin_top(16);
    usage_box.set_margin_bottom(16);
    
    // CPU usage bar
    let cpu_bar_box = create_usage_bar_widget(
        "CPU",
        "processor",
        system_info.borrow().cpu_usage,
        &format!("{:.1}%", system_info.borrow().cpu_usage)
    );
    
    // Memory usage bar
    let mem_bar_box = create_usage_bar_widget(
        "Memory",
        "memory",
        system_info.borrow().memory_percent,
        &format!("{} / {}", system_info.borrow().memory_used, system_info.borrow().memory_total)
    );
    
    // Disk usage bar
    let disk_bar_box = create_usage_bar_widget(
        "Disk",
        "drive-harddisk",
        system_info.borrow().disk_usage,
        &format!("{}% of {}", system_info.borrow().disk_usage as i32, system_info.borrow().disk_total)
    );
    
    usage_box.append(&cpu_bar_box);
    usage_box.append(&mem_bar_box);
    usage_box.append(&disk_bar_box);
    
    // Get references to the progress bars for updates - using a safer approach
    let cpu_bar = get_level_bar(&cpu_bar_box);
    let cpu_label = get_value_label(&cpu_bar_box);
    
    let mem_bar = get_level_bar(&mem_bar_box);
    let mem_label = get_value_label(&mem_bar_box);
    
    let disk_bar = get_level_bar(&disk_bar_box);
    let disk_label = get_value_label(&disk_bar_box);
    
    set_card_content(&usage_frame, &usage_box);
    content_box.append(&usage_frame);
    
    scroll.set_child(Some(&content_box));
    container.append(&scroll);
    
    content.append(&container);
    
    // Set up the refresh timer to update system information
    // Connect the refresh button directly
    refresh_button.connect_clicked(glib::clone!(@strong system_info_clone, @strong hostname_label, 
                                              @strong hyprland_label, @strong kernel_label, 
                                              @strong cpu_model_label, @strong cpu_bar, 
                                              @strong cpu_label, @strong mem_bar, 
                                              @strong mem_label, @strong disk_bar, 
                                              @strong disk_label => move |_| {
        let mut info = system_info_clone.borrow_mut();
        *info = SystemInfo::new();
        
        // Update all labels and progress bars
        hostname_label.set_text(&info.hostname);
        hyprland_label.set_text(&info.hyprland_version);
        kernel_label.set_text(&info.kernel_version);
        cpu_model_label.set_text(&info.cpu_info);
        
        cpu_bar.set_value(info.cpu_usage / 100.0);
        cpu_label.set_text(&format!("{:.1}%", info.cpu_usage));
        
        mem_bar.set_value(info.memory_percent / 100.0);
        mem_label.set_text(&format!("{} / {}", info.memory_used, info.memory_total));
        
        disk_bar.set_value(info.disk_usage / 100.0);
        disk_label.set_text(&format!("{}% of {}", info.disk_usage as i32, info.disk_total));
    }));

    // Set up periodic updates with less resource usage
    let _timer_id = SystemInfo::create_updater(glib::clone!(@strong system_info_clone, 
                                                         @strong cpu_bar, @strong cpu_label, 
                                                         @strong mem_bar, @strong mem_label,
                                                         @strong disk_bar, @strong disk_label => move || {
        let mut info = system_info_clone.borrow_mut();
        
        // Use the optimized update method instead of creating a new instance
        info.update_dynamic_info();
        
        // Update UI elements with minimal redraws
        // For CPU usage
        let cpu_value = info.cpu_usage / 100.0;
        if (cpu_bar.value() - cpu_value).abs() > 0.01 {  // Only update if changed significantly
            cpu_bar.set_value(cpu_value);
            cpu_label.set_text(&format!("{:.1}%", info.cpu_usage));
        }
        
        // For memory usage
        let mem_value = info.memory_percent / 100.0;
        if (mem_bar.value() - mem_value).abs() > 0.01 {  // Only update if changed significantly
            mem_bar.set_value(mem_value);
            mem_label.set_text(&format!("{} / {}", info.memory_used, info.memory_total));
        }
        
        // For disk usage (updated less frequently internally)
        let disk_value = info.disk_usage / 100.0;
        if (disk_bar.value() - disk_value).abs() > 0.01 {  // Only update if changed significantly
            disk_bar.set_value(disk_value);
            disk_label.set_text(&format!("{}% of {}", info.disk_usage as i32, info.disk_total));
        }
    }));
    
    content.into()
}