use gtk4::{
    prelude::*,
    Application,
    Button,
    Image,
};

pub fn build_buttons(app: &Application) -> (Button, Button, Button) {
    // Create buttons for closing, copying and refreshing
    let close_button = Button::builder()
        .css_classes(["circular-button", "white-button"])
        .has_frame(false)
        .build();
    
    let copy_button = Button::builder()
        .css_classes(["circular-button", "white-button"])
        .has_frame(false)
        .build();
    
    let refresh_button = Button::builder()
        .css_classes(["circular-button", "white-button"])
        .has_frame(false)
        .build();

    // Add X icon to close button
    let close_icon = Image::from_icon_name("window-close-symbolic");
    close_icon.set_pixel_size(16);
    close_button.set_child(Some(&close_icon));
    
    // Add Copy icon to copy button
    let copy_icon = Image::from_icon_name("edit-copy-symbolic");
    copy_icon.set_pixel_size(16);
    copy_button.set_child(Some(&copy_icon));
    
    // Add Refresh icon to refresh button
    let refresh_icon = Image::from_icon_name("view-refresh-symbolic");
    refresh_icon.set_pixel_size(16);
    refresh_button.set_child(Some(&refresh_icon));
    
    // Button tooltips
    close_button.set_tooltip_text(Some("Close"));
    copy_button.set_tooltip_text(Some("Copy to Clipboard"));
    refresh_button.set_tooltip_text(Some("Refresh Keybindings"));

    (close_button, copy_button, refresh_button)
} 