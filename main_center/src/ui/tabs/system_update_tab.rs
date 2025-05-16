use gtk::prelude::*;
use gtk;
use gtk::{glib};
use std::process::Command;
use std::sync::{Arc, Mutex};
use crate::ui::tabs::ui_utils::{create_card, set_card_content};
use crate::ui::system_updater::{self, UpdateResult};
use std::path::Path;
use std::fs::File;
use std::io::Write;

// Function to check if a command exists
fn command_exists(command: &str) -> bool {
    Command::new("which")
        .arg(command)
        .stdout(std::process::Stdio::null())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

// Function to detect AUR helper
fn detect_aur_helper() -> Option<String> {
    let aur_helpers = ["yay", "paru", "trizen", "pamac"];
    
    for helper in &aur_helpers {
        if command_exists(helper) {
            return Some(helper.to_string());
        }
    }
    
    None
}

pub fn create_system_update_content() -> gtk::Widget {
    // Create main container
    let container = gtk::Box::new(gtk::Orientation::Vertical, 15);
    container.set_margin_top(20);
    container.set_margin_bottom(20);
    container.set_margin_start(24);
    container.set_margin_end(24);
    
    // Create a container with a stylish background
    let main_card = gtk::Box::new(gtk::Orientation::Vertical, 15);
    main_card.add_css_class("card");
    main_card.set_margin_bottom(10);
    main_card.set_margin_top(8);
    main_card.set_margin_start(10);
    main_card.set_margin_end(10);
    
    // Create header with icon
    let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    header_box.set_margin_top(12);
    header_box.set_margin_start(16);
    header_box.set_margin_end(16);
    
    let header = gtk::Label::new(Some("System Update"));
    header.add_css_class("title-2");
    header.set_halign(gtk::Align::Start);
    header.set_hexpand(true);
    
    header_box.append(&header);
    main_card.append(&header_box);
    
    // Separator
    let separator = gtk::Separator::new(gtk::Orientation::Horizontal);
    separator.set_margin_start(16);
    separator.set_margin_end(16);
    main_card.append(&separator);
    
    // Create content area inside the main card
    let content_box = gtk::Box::new(gtk::Orientation::Vertical, 15);
    content_box.set_margin_start(16);
    content_box.set_margin_end(16);
    content_box.set_margin_bottom(12);
    content_box.set_margin_top(8);
    
    // Package Manager Updates section
    let updaters_frame = create_card("Package Managers");
    
    // Check package managers
    let has_pacman = system_updater::command_exists("pacman");
    let aur_helper = system_updater::detect_aur_helper();
    let has_flatpak = system_updater::command_exists("flatpak");
    let has_snap = system_updater::command_exists("snap");

    // Create grid for package managers and update buttons
    let grid = gtk::Grid::new();
    grid.set_column_spacing(12);
    grid.set_row_spacing(12);
    grid.set_margin_start(15);
    grid.set_margin_end(15);
    grid.set_margin_top(12);
    grid.set_margin_bottom(12);
    
    // Row 0: Pacman
    if has_pacman {
        let pacman_label = gtk::Label::new(Some("Pacman:"));
        pacman_label.set_halign(gtk::Align::Start);
        pacman_label.set_hexpand(true);
        grid.attach(&pacman_label, 0, 0, 1, 1);
        
        let pacman_status = gtk::Label::new(Some("Available"));
        pacman_status.set_halign(gtk::Align::Start);
        pacman_status.set_hexpand(true);
        grid.attach(&pacman_status, 1, 0, 1, 1);
        
        let pacman_button = gtk::Button::with_label("Update");
        pacman_button.add_css_class("suggested-action");
        pacman_button.add_css_class("pill");
        pacman_button.set_halign(gtk::Align::End);
        grid.attach(&pacman_button, 2, 0, 1, 1);
        
        // Create status dialog for showing update results
        let status_dialog = gtk::MessageDialog::new(
            None::<&gtk::Window>,
            gtk::DialogFlags::MODAL,
            gtk::MessageType::Info,
            gtk::ButtonsType::Close,
            ""
        );
        status_dialog.set_title(Some("Pacman Update"));
        
        // Connect update button handler
        pacman_button.connect_clicked(move |button| {
            button.set_sensitive(false);
            pacman_status.set_text("Updating...");
            
            // Run update in separate thread
            let button_clone = button.clone();
            let pacman_status_clone = pacman_status.clone();
            let status_dialog_clone = status_dialog.clone();
            
            glib::MainContext::default().spawn_local(async move {
                match system_updater::update_pacman() {
                    UpdateResult::Success(msg) => {
                        pacman_status_clone.set_text("Update launched");
                        status_dialog_clone.set_message_type(gtk::MessageType::Info);
                        status_dialog_clone.set_text(Some(&msg));
                    },
                    UpdateResult::Error(err) => {
                        pacman_status_clone.set_text("Update failed");
                        status_dialog_clone.set_message_type(gtk::MessageType::Error);
                        status_dialog_clone.set_text(Some(&err));
                        status_dialog_clone.present();
                    },
                    UpdateResult::NotInstalled => {
                        pacman_status_clone.set_text("Not installed");
                    }
                }
                button_clone.set_sensitive(true);
            });
        });
    }
    
    // Row 1: AUR Helper
    let mut row = 1;
    if let Some(helper) = &aur_helper {
        let aur_label = gtk::Label::new(Some(&format!("AUR Helper ({}):", helper)));
        aur_label.set_halign(gtk::Align::Start);
        aur_label.set_hexpand(true);
        grid.attach(&aur_label, 0, row, 1, 1);
        
        let aur_status = gtk::Label::new(Some("Available"));
        aur_status.set_halign(gtk::Align::Start);
        aur_status.set_hexpand(true);
        grid.attach(&aur_status, 1, row, 1, 1);
        
        let aur_button = gtk::Button::with_label("Update");
        aur_button.add_css_class("suggested-action");
        aur_button.add_css_class("pill");
        aur_button.set_halign(gtk::Align::End);
        grid.attach(&aur_button, 2, row, 1, 1);
        
        // Create status dialog
        let status_dialog = gtk::MessageDialog::new(
            None::<&gtk::Window>,
            gtk::DialogFlags::MODAL,
            gtk::MessageType::Info,
            gtk::ButtonsType::Close,
            ""
        );
        status_dialog.set_title(Some(&format!("{} Update", helper)));
        
        // Connect update button handler
        let helper_clone = helper.clone();
        aur_button.connect_clicked(move |button| {
            button.set_sensitive(false);
            aur_status.set_text("Updating...");
            
            // Run update in separate thread
            let button_clone = button.clone();
            let aur_status_clone = aur_status.clone();
            let status_dialog_clone = status_dialog.clone();
            let helper_clone2 = helper_clone.clone();
            
            glib::MainContext::default().spawn_local(async move {
                match system_updater::update_aur(&helper_clone2) {
                    UpdateResult::Success(msg) => {
                        aur_status_clone.set_text("Update launched");
                        status_dialog_clone.set_message_type(gtk::MessageType::Info);
                        status_dialog_clone.set_text(Some(&msg));
                    },
                    UpdateResult::Error(err) => {
                        aur_status_clone.set_text("Update failed");
                        status_dialog_clone.set_message_type(gtk::MessageType::Error);
                        status_dialog_clone.set_text(Some(&err));
                        status_dialog_clone.present();
                    },
                    UpdateResult::NotInstalled => {
                        aur_status_clone.set_text("Not installed");
                    }
                }
                button_clone.set_sensitive(true);
            });
        });
        
        row += 1;
    }
    
    // Row 2: Flatpak
    if has_flatpak {
        let flatpak_label = gtk::Label::new(Some("Flatpak:"));
        flatpak_label.set_halign(gtk::Align::Start);
        flatpak_label.set_hexpand(true);
        grid.attach(&flatpak_label, 0, row, 1, 1);
        
        let flatpak_status = gtk::Label::new(Some("Available"));
        flatpak_status.set_halign(gtk::Align::Start);
        flatpak_status.set_hexpand(true);
        grid.attach(&flatpak_status, 1, row, 1, 1);
        
        let flatpak_button = gtk::Button::with_label("Update");
        flatpak_button.add_css_class("suggested-action");
        flatpak_button.add_css_class("pill");
        flatpak_button.set_halign(gtk::Align::End);
        grid.attach(&flatpak_button, 2, row, 1, 1);
        
        // Create status dialog
        let status_dialog = gtk::MessageDialog::new(
            None::<&gtk::Window>,
            gtk::DialogFlags::MODAL,
            gtk::MessageType::Info,
            gtk::ButtonsType::Close,
            ""
        );
        status_dialog.set_title(Some("Flatpak Update"));
        
        // Connect update button handler
        flatpak_button.connect_clicked(move |button| {
            button.set_sensitive(false);
            flatpak_status.set_text("Updating...");
            
            // Run update in separate thread
            let button_clone = button.clone();
            let flatpak_status_clone = flatpak_status.clone();
            let status_dialog_clone = status_dialog.clone();
            
            glib::MainContext::default().spawn_local(async move {
                match system_updater::update_flatpak() {
                    UpdateResult::Success(msg) => {
                        flatpak_status_clone.set_text("Update launched");
                        status_dialog_clone.set_message_type(gtk::MessageType::Info);
                        status_dialog_clone.set_text(Some(&msg));
                    },
                    UpdateResult::Error(err) => {
                        flatpak_status_clone.set_text("Update failed");
                        status_dialog_clone.set_message_type(gtk::MessageType::Error);
                        status_dialog_clone.set_text(Some(&err));
                        status_dialog_clone.present();
                    },
                    UpdateResult::NotInstalled => {
                        flatpak_status_clone.set_text("Not installed");
                    }
                }
                button_clone.set_sensitive(true);
            });
        });
        
        row += 1;
    }
    
    // Row 3: Snap
    if has_snap {
        let snap_label = gtk::Label::new(Some("Snap:"));
        snap_label.set_halign(gtk::Align::Start);
        snap_label.set_hexpand(true);
        grid.attach(&snap_label, 0, row, 1, 1);
        
        let snap_status = gtk::Label::new(Some("Available"));
        snap_status.set_halign(gtk::Align::Start);
        snap_status.set_hexpand(true);
        grid.attach(&snap_status, 1, row, 1, 1);
        
        let snap_button = gtk::Button::with_label("Update");
        snap_button.add_css_class("suggested-action");
        snap_button.add_css_class("pill");
        snap_button.set_halign(gtk::Align::End);
        grid.attach(&snap_button, 2, row, 1, 1);
        
        // Create status dialog
        let status_dialog = gtk::MessageDialog::new(
            None::<&gtk::Window>,
            gtk::DialogFlags::MODAL,
            gtk::MessageType::Info,
            gtk::ButtonsType::Close,
            ""
        );
        status_dialog.set_title(Some("Snap Update"));
        
        // Connect update button handler
        snap_button.connect_clicked(move |button| {
            button.set_sensitive(false);
            snap_status.set_text("Updating...");
            
            // Run update in separate thread
            let button_clone = button.clone();
            let snap_status_clone = snap_status.clone();
            let status_dialog_clone = status_dialog.clone();
            
            glib::MainContext::default().spawn_local(async move {
                match system_updater::update_snap() {
                    UpdateResult::Success(msg) => {
                        snap_status_clone.set_text("Update launched");
                        status_dialog_clone.set_message_type(gtk::MessageType::Info);
                        status_dialog_clone.set_text(Some(&msg));
                    },
                    UpdateResult::Error(err) => {
                        snap_status_clone.set_text("Update failed");
                        status_dialog_clone.set_message_type(gtk::MessageType::Error);
                        status_dialog_clone.set_text(Some(&err));
                        status_dialog_clone.present();
                    },
                    UpdateResult::NotInstalled => {
                        snap_status_clone.set_text("Not installed");
                    }
                }
                button_clone.set_sensitive(true);
            });
        });
    }
    
    set_card_content(&updaters_frame, &grid);
    content_box.append(&updaters_frame);
    
    // Add a note about terminal usage
    let note_label = gtk::Label::new(Some("Updates will be executed in an external terminal window"));
    note_label.set_halign(gtk::Align::Start);
    note_label.add_css_class("caption");
    note_label.add_css_class("dim-label");
    note_label.set_margin_top(8);
    note_label.set_margin_start(16);
    content_box.append(&note_label);
    
    main_card.append(&content_box);
    container.append(&main_card);
    
    container.upcast::<gtk::Widget>()
} 