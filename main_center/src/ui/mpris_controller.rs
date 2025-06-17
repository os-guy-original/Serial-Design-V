use gtk::{self, glib};
use libadwaita as adw;
use libadwaita::prelude::*;
use std::rc::Rc;
use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;
use zbus::dbus_proxy;
use crate::ui::async_utils::run_command_async;

#[dbus_proxy(
    interface = "org.mpris.MediaPlayer2.Player",
    default_service = "org.mpris.MediaPlayer2.spotify",
    default_path = "/org/mpris/MediaPlayer2"
)]
trait Player {
    #[dbus_proxy(property)]
    fn playback_status(&self) -> zbus::Result<String>;
    
    #[dbus_proxy(property)]
    fn metadata(&self) -> zbus::Result<HashMap<String, zbus::zvariant::Value>>;
    
    fn play_pause(&self) -> zbus::Result<()>;
    fn previous(&self) -> zbus::Result<()>;
    fn next(&self) -> zbus::Result<()>;
}

pub struct MprisController {
    pub widget: gtk::Box,
    expanded: Rc<RefCell<bool>>,
    main_container: gtk::Box,
    expanded_container: gtk::Box,
    art_cache_path: PathBuf,
    tabview: adw::TabView,
    player_tabs: Rc<RefCell<HashMap<String, adw::TabPage>>>,
    current_player: Rc<RefCell<Option<String>>>,
    dominant_color: Rc<RefCell<(u8, u8, u8)>>,
}

impl MprisController {
    pub fn new() -> Self {
        // Setup cache directory for artwork
        let cache_dir = glib::user_cache_dir().join("main_center");
        std::fs::create_dir_all(&cache_dir).unwrap_or_else(|_| {});
        let art_cache_path = cache_dir.join("current_art.png");

        // Create main container
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 10);
        widget.set_margin_top(15);
        widget.set_margin_bottom(15);
        widget.set_margin_start(15);
        widget.set_margin_end(15);
        
        // Create main content container that will be moved when expanded
        let main_container = gtk::Box::new(gtk::Orientation::Vertical, 10);
        widget.append(&main_container);
        
        // Create label for the controller
        let header_box = gtk::Box::new(gtk::Orientation::Horizontal, 5);
        header_box.add_css_class("clickable-header");
        
        let label = gtk::Label::new(Some("Media Controls"));
        label.add_css_class("heading");
        label.set_halign(gtk::Align::Start);
        label.set_hexpand(true);
        header_box.append(&label);
        
        // Add a small indicator that the header is clickable
        let expand_indicator = gtk::Image::from_icon_name("pan-up-symbolic");
        expand_indicator.set_pixel_size(16);
        // Add accent color to the indicator
        expand_indicator.add_css_class("accent");
        expand_indicator.add_css_class("dim-label");
        header_box.append(&expand_indicator);
        
        main_container.append(&header_box);
        
        // Now playing info
        let now_playing_box = gtk::Box::new(gtk::Orientation::Horizontal, 5);
        now_playing_box.set_margin_top(10);
        
        let now_playing_label = gtk::Label::new(Some("Now Playing"));
        now_playing_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        now_playing_label.set_halign(gtk::Align::Start);
        now_playing_label.set_hexpand(true);
        now_playing_box.append(&now_playing_label);
        
        main_container.append(&now_playing_box);
        
        // Controller buttons
        let controls_box = gtk::Box::new(gtk::Orientation::Horizontal, 5);
        controls_box.set_margin_top(10);
        controls_box.set_halign(gtk::Align::Center);
        
        // Previous button
        let prev_button = gtk::Button::new();
        prev_button.set_icon_name("media-skip-backward-symbolic");
        prev_button.add_css_class("circular");
        prev_button.add_css_class("flat");
        
        // Play/Pause button
        let play_button = gtk::Button::new();
        play_button.set_icon_name("media-playback-start-symbolic");
        play_button.add_css_class("circular");
        play_button.add_css_class("suggested-action");
        
        // Next button
        let next_button = gtk::Button::new();
        next_button.set_icon_name("media-skip-forward-symbolic");
        next_button.add_css_class("circular");
        next_button.add_css_class("flat");
        
        // Add buttons to control box
        controls_box.append(&prev_button);
        controls_box.append(&play_button);
        controls_box.append(&next_button);
        
        main_container.append(&controls_box);
        
        // Create the expanded container (hidden by default)
        let expanded_container = gtk::Box::new(gtk::Orientation::Vertical, 10);
        expanded_container.set_visible(false);
        expanded_container.add_css_class("card");
        expanded_container.add_css_class("media-expanded");
        expanded_container.set_margin_top(15);
        expanded_container.set_margin_bottom(15);
        
        // Create a TabView for multi-app support in expanded view
        let tabview = adw::TabView::new();
        tabview.set_vexpand(true);
        
        // Add a tab bar to control tabs
        let tabbar = adw::TabBar::new();
        tabbar.set_view(Some(&tabview));
        expanded_container.append(&tabbar);
        expanded_container.append(&tabview);
        
        // Add expanded container to main widget
        widget.append(&expanded_container);
        
        // State to keep track of player tabs
        let player_tabs = Rc::new(RefCell::new(HashMap::new()));
        let current_player = Rc::new(RefCell::new(None::<String>));
        
        // Create a shared state for expansion
        let expanded = Rc::new(RefCell::new(false));
        
        // Make the header clickable to expand
        let click_controller = gtk::GestureClick::new();
        click_controller.set_button(1); // Left mouse button
        
        let expanded_clone = expanded.clone();
        let main_container_clone = main_container.clone();
        let expanded_container_clone = expanded_container.clone();
        
        click_controller.connect_released(move |_, _, _, _| {
            // Hata ayıklaması için güvenlik kontrolü
            let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                // Güvenli kodlar
                if let Ok(mut is_expanded) = expanded_clone.try_borrow_mut() {
            *is_expanded = true;
            
            // Hide the compact view
            main_container_clone.set_visible(false);
            
            // Show the expanded view
            expanded_container_clone.set_visible(true);
            
            // Set up animation
            expanded_container_clone.set_opacity(0.0);
            
            // Animate the expanded container
            let expanded_container_animate = expanded_container_clone.clone();
            
            // For animation smoothness, use elapsed time
            let start_time = std::time::Instant::now();
            
            glib::timeout_add_local(Duration::from_millis(16), move || {
                // Calculate progress based on elapsed time
                let elapsed = start_time.elapsed().as_millis() as f64;
                let progress = (elapsed / 300.0).min(1.0); // 300ms total animation
                
                // Ease-in-out function for smoother animation
                let eased = if progress < 0.5 {
                    2.0 * progress * progress
                } else {
                    -1.0 + (4.0 - 2.0 * progress) * progress
                };
                
                // Update opacity
                expanded_container_animate.set_opacity(eased); // Fade in (not out)
                
                // When complete, stop animation
                if progress >= 1.0 {
                    return glib::Continue(false);
                }
                
                glib::Continue(true)
            });
                }
            }));
            
            if result.is_err() {
                println!("Genişletme sırasında hata oluştu, güvenli şekilde yakalandı");
            }
        });
        
        // Add the click gesture to the header box only
        header_box.add_controller(click_controller);
        
        // Visual indicator that the header is clickable
        header_box.set_tooltip_text(Some("Click to expand media player"));
        // Change cursor to pointer on hover 
        header_box.add_css_class("clickable-container");
        
        // Setup collapse button (will be added to each player's content)
        let _expanded_clone = expanded.clone();
        let _main_container_clone = main_container.clone();
        let _expanded_container_clone = expanded_container.clone();
        
        // Setup click events using playerctl commands
        // Connect the regular play button
        let play_button_clone = play_button.clone();
        play_button.connect_clicked(move |button| {
            // Toggle the icon immediately
            let is_playing = button.icon_name().map_or(false, |name| name == "media-playback-pause-symbolic");
            let new_icon = if is_playing { "media-playback-start-symbolic" } else { "media-playback-pause-symbolic" };
            button.set_icon_name(new_icon);
            
            // Send the command
            let _ = Command::new("playerctl")
                .args(&["play-pause"])
                .spawn();
        });
        
        // Connect previous button in compact view
        let play_button_clone_for_prev = play_button.clone();
        prev_button.connect_clicked(move |_| {
            // Use spawn to avoid blocking UI thread
            match Command::new("playerctl")
                .args(&["previous"])
                .spawn() {
                Ok(_) => {
                    println!("Previous command sent successfully");
                },
                Err(e) => {
                    println!("Failed to execute previous command: {}", e);
                }
            }
                
            // Check status after changing track and update button
            let play_button_for_update = play_button_clone_for_prev.clone();
            glib::timeout_add_local(Duration::from_millis(300), move || {
                match Command::new("playerctl")
                    .args(&["status"])
                    .output() {
                    Ok(status_output) => {
                        let status = String::from_utf8_lossy(&status_output.stdout).trim().to_string();
                        if status == "Playing" {
                            play_button_for_update.set_icon_name("media-playback-pause-symbolic");
                        } else if !status.is_empty() {
                            play_button_for_update.set_icon_name("media-playback-start-symbolic");
                        }
                    },
                    Err(e) => {
                        println!("Failed to get status: {}", e);
                    }
                }
                
                glib::Continue(false)
            });
        });
        
        // Connect next button in compact view
        let play_button_clone_for_next = play_button.clone();
        next_button.connect_clicked(move |_| {
            // Use spawn to avoid blocking UI thread
            match Command::new("playerctl")
                .args(&["next"])
                .spawn() {
                Ok(_) => {
                    println!("Next command sent successfully");
                },
                Err(e) => {
                    println!("Failed to execute next command: {}", e);
                }
            }
                
            // Check status after changing track and update button
            let play_button_for_update = play_button_clone_for_next.clone();
            glib::timeout_add_local(Duration::from_millis(300), move || {
                match Command::new("playerctl")
                    .args(&["status"])
                    .output() {
                    Ok(status_output) => {
                        let status = String::from_utf8_lossy(&status_output.stdout).trim().to_string();
                        if status == "Playing" {
                            play_button_for_update.set_icon_name("media-playback-pause-symbolic");
                        } else if !status.is_empty() {
                            play_button_for_update.set_icon_name("media-playback-start-symbolic");
                        }
                    },
                    Err(e) => {
                        println!("Failed to get status: {}", e);
                    }
                }
                
                glib::Continue(false)
            });
        });
        
        // Set up a timer to update now playing info and available players
        let now_playing_label_clone = now_playing_label.clone();
        let play_button_update = play_button_clone.clone();
        let player_tabs_clone = player_tabs.clone();
        let tabview_clone = tabview.clone();
        let current_player_clone = current_player.clone();
        let expanded_clone = expanded.clone();
        let main_container_final = main_container.clone();
        let expanded_container_final = expanded_container.clone();
        let art_cache_path_clone = art_cache_path.clone();

        // Add a separate timer specifically for updating the play/pause button state
        // This ensures the button state is always in sync with actual playback state
        let play_button_status_update = play_button_clone.clone();
        let current_player_status_clone = current_player.clone();
        
        glib::timeout_add_local(Duration::from_millis(1000), move || {
            // Only check if we have an active player
            if let Some(active_player) = current_player_status_clone.borrow().as_ref() {
                // Get current playback status asynchronously to avoid blocking the UI
                let play_button_clone = play_button_status_update.clone();
                let player_name = active_player.clone();
                run_command_async(
                    "playerctl",
                    vec!["-p".to_string(), player_name, "status".to_string()],
                    move |output| {
                        if let Some(status) = output {
                            let status_trimmed = status.trim();
                            let icon = if status_trimmed == "Playing" {
                                "media-playback-pause-symbolic"
                            } else {
                                "media-playback-start-symbolic"
                            };
                            play_button_clone.set_icon_name(icon);
                        }
                    },
                );
            }
            
            // Continue the timer
            glib::Continue(true)
        });
        
        // Main update timer for player list and metadata (runs every 2 s)
        glib::timeout_add_local(Duration::from_millis(2000), move || {
            let now_playing_label_clone = now_playing_label_clone.clone();
            let play_button_update = play_button_update.clone();
            let player_tabs_clone_inner = player_tabs_clone.clone();
            let tabview_clone = tabview_clone.clone();
            let current_player_clone = current_player_clone.clone();
            let expanded_clone = expanded_clone.clone();
            let main_container_final = main_container_final.clone();
            let expanded_container_final = expanded_container_final.clone();
            let art_cache_path_clone = art_cache_path_clone.clone();

            // Run the potentially blocking `playerctl -l` in the background.
            run_command_async("playerctl", vec!["-l".to_string()], move |output| {
                let players_output = output.unwrap_or_default();
                let players: Vec<String> = players_output.trim()
                    .split('\n')
                    .filter(|s| !s.is_empty())
                    .map(|s| s.to_string())
                    .collect();

                // Identify the current active player (we'll use the first one if there are many)
                let current_active = if !players.is_empty() {
                    Some(players[0].clone())
                } else {
                    None
                };

                if players.is_empty() {
                    // No players available
                    now_playing_label_clone.set_text("No media players available");
                    play_button_update.set_icon_name("media-playback-start-symbolic");

                    // Clear tabs if needed
                    let mut tabs = player_tabs_clone_inner.borrow_mut();
                    if !tabs.is_empty() {
                        tabs.clear();

                        // Hide expanded view if it's open and no players
                        if *expanded_clone.borrow() {
                            expanded_container_final.set_visible(false);
                            main_container_final.set_visible(true);
                            *expanded_clone.borrow_mut() = false;
                        }
                    }

                    *current_player_clone.borrow_mut() = None;
                } else {
                    // Players available - update tabs
                    let mut tabs = player_tabs_clone_inner.borrow_mut();
                    
                    // Remove tabs for players that no longer exist
                    let existing_players: Vec<String> = tabs.keys().cloned().collect();
                    for existing_player in existing_players {
                        if !players.contains(&existing_player) {
                            if let Some(page) = tabs.remove(&existing_player) {
                                tabview_clone.close_page(&page);
                            }
                        }
                    }
                    
                    // Add tabs for new players (more efficiently)
                    for player in &players {
                        if !tabs.contains_key(player) {
                            let player_content = Self::create_player_tab_content(
                                player,
                                &expanded_container_final,
                                &main_container_final,
                                &expanded_clone,
                                &art_cache_path_clone,
                            );
                            let page = tabview_clone.append(&player_content);
                            page.set_title(&Self::get_player_display_name(player));
                            page.set_icon(Some(&gtk::gio::ThemedIcon::new(&Self::get_player_icon_name(player))));
                            tabs.insert(player.clone(), page);
                        }
                    }

                    // Update current player if needed
                    if let Some(active_player) = &current_active {
                        if current_player_clone.borrow().as_ref() != Some(active_player) {
                            *current_player_clone.borrow_mut() = Some(active_player.clone());
                            if let Some(page) = tabs.get(active_player) {
                                tabview_clone.set_selected_page(page);
                            }

                            // Fetch metadata asynchronously (artist-title) to avoid blocking.
                            let label_clone = now_playing_label_clone.clone();
                            let play_button_update_clone = play_button_update.clone();
                            let active_pl_meta = active_player.clone();
                            run_command_async(
                                "playerctl",
                                vec!["-p".to_string(), active_pl_meta.clone(), "metadata".to_string(), "--format".to_string(), "{{ artist }} - {{ title }}".to_string()],
                                move |meta_out| {
                                    let text = meta_out.unwrap_or_default();
                                    if !text.is_empty() {
                                        label_clone.set_text(&format!("{}: {}", Self::get_player_display_name(&active_pl_meta), text.trim()));
                                    }
                                },
                            );

                            // Fetch status asynchronously
                            let play_btn_clone = play_button_update_clone.clone();
                            let active_pl_status = active_player.clone();
                            run_command_async(
                                "playerctl",
                                vec!["-p".to_string(), active_pl_status.clone(), "status".to_string()],
                                move |stat_out| {
                                    let status = stat_out.unwrap_or_default();
                                    let icon = if status.trim() == "Playing" {
                                        "media-playback-pause-symbolic"
                                    } else {
                                        "media-playback-start-symbolic"
                                    };
                                    play_btn_clone.set_icon_name(icon);
                                },
                            );
                        }
                    }
                }
            });
            // Continue the timer
            glib::Continue(true)
        });
        
        MprisController {
            widget,
            expanded,
            main_container,
            expanded_container,
            art_cache_path,
            tabview,
            player_tabs,
            current_player,
            dominant_color: Rc::new(RefCell::new((78, 154, 240))),
        }
    }
    
    // Helper function to create player tab content
    fn create_player_tab_content(
        player: &str, 
        expanded_container: &gtk::Box,
        main_container: &gtk::Box,
        expanded: &Rc<RefCell<bool>>,
        art_cache_path: &PathBuf
    ) -> gtk::Box {
        // Get a owned copy of player string for closures that need 'static lifetime
        let player_owned = player.to_string();
        
        // Create the content for a player tab
        let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
        content.add_css_class("content");
        content.add_css_class("card");  // Use GTK's card styling
        content.set_margin_top(5);
        content.set_margin_bottom(5);
        content.set_margin_start(5);
        content.set_margin_end(5);
        
        // Create CSS provider for the progress background
        let css_provider = gtk::CssProvider::new();
        
        // Load the CSS file for media player styling
        let media_css = std::path::Path::new("assets/media_player.css");
        if media_css.exists() {
            css_provider.load_from_file(&gtk::gio::File::for_path(media_css));
            println!("Loaded media CSS from assets directory");
        } else {
            // Fallback to embedded minimal styling if file not found
            css_provider.load_from_data(
                "box.content { position: relative; border-radius: 12px; }"
            );
            println!("Using fallback media CSS");
        }
        
        // Apply the CSS provider to the content
        let style_context = content.style_context();
        style_context.add_provider(
            &css_provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        
        // Set initial progress to make it visible
        css_provider.load_from_data("box.content::before { width: 20%; border-color: currentColor; background-color: rgba(0, 0, 0, 0.1); }");
        
        // Create a container for content
        let inner_content = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        inner_content.set_hexpand(true);
        inner_content.set_vexpand(true);
        
        // Create left side with album art
        let art_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
        art_container.set_size_request(180, 180);
        art_container.set_halign(gtk::Align::Center);
        art_container.set_valign(gtk::Align::Center);
        art_container.add_css_class("card");
        art_container.add_css_class("album-art");
        art_container.add_css_class("accent");  // Use system accent for the border
        art_container.set_margin_top(10);
        art_container.set_margin_bottom(10);
        art_container.set_margin_start(10);
        art_container.set_margin_end(10);
        
        // Create a container for the artwork that can be updated
        let artwork_container = gtk::Box::new(gtk::Orientation::Vertical, 0);
        artwork_container.set_halign(gtk::Align::Fill);
        artwork_container.set_valign(gtk::Align::Fill);
        artwork_container.set_hexpand(true);
        artwork_container.set_vexpand(true);
        
        // Set a custom CSS class to ensure proper z-index
        artwork_container.add_css_class("artwork-container");
        
        // Default art icon as fallback
        let art_icon = gtk::Image::from_icon_name("audio-x-generic-symbolic");
        art_icon.set_pixel_size(128);
        art_icon.set_halign(gtk::Align::Center);
        art_icon.set_valign(gtk::Align::Center);
        art_icon.set_hexpand(true);
        art_icon.set_vexpand(true);
        artwork_container.append(&art_icon);
        
        art_container.append(&artwork_container);
        
        // Create right side with details and controls
        let details_container = gtk::Box::new(gtk::Orientation::Vertical, 10);
        details_container.set_margin_top(10);
        details_container.set_margin_bottom(10);
        details_container.set_margin_start(10);
        details_container.set_margin_end(10);
        details_container.set_hexpand(true);
        
        // Create track info
        let title_label = gtk::Label::new(Some("Not playing"));
        title_label.add_css_class("title-4");
        title_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        title_label.set_halign(gtk::Align::Start);
        
        let artist_label = gtk::Label::new(Some("No artist"));
        artist_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        artist_label.set_halign(gtk::Align::Start);
        artist_label.add_css_class("dim-label");
        
        // Create expanded controls
        let expanded_controls = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        expanded_controls.set_halign(gtk::Align::Center);
        expanded_controls.set_margin_top(15);
        
        // Previous button
        let expanded_prev = gtk::Button::new();
        expanded_prev.set_icon_name("media-skip-backward-symbolic");
        expanded_prev.add_css_class("circular");
        expanded_prev.add_css_class("flat");
        
        // Play/Pause button
        let expanded_play = gtk::Button::new();
        expanded_play.set_icon_name("media-playback-start-symbolic");
        expanded_play.add_css_class("circular");
        expanded_play.add_css_class("suggested-action");
        expanded_play.set_size_request(48, 48); // Make it bigger
        
        // Next button
        let expanded_next = gtk::Button::new();
        expanded_next.set_icon_name("media-skip-forward-symbolic");
        expanded_next.add_css_class("circular");
        expanded_next.add_css_class("flat");
        
        // Collapse button
        let collapse_button = gtk::Button::new();
        collapse_button.set_icon_name("view-restore-symbolic");
        collapse_button.set_halign(gtk::Align::End);
        collapse_button.add_css_class("circular");
        collapse_button.add_css_class("flat");
        collapse_button.set_tooltip_text(Some("Collapse media player"));
        
        // Add buttons to control box
        expanded_controls.append(&expanded_prev);
        expanded_controls.append(&expanded_play);
        expanded_controls.append(&expanded_next);
        
        // Add everything to details container
        details_container.append(&collapse_button);
        details_container.append(&title_label);
        details_container.append(&artist_label);
        details_container.append(&expanded_controls);
        
        // Add containers to inner content view
        inner_content.append(&art_container);
        inner_content.append(&details_container);
        
        // Add the inner content to the main container
        content.append(&inner_content);
        
        // Setup play/pause button in expanded view with player-specific control
        let player_clone = player_owned.clone();
        
        expanded_play.connect_clicked(move |button| {
            // Toggle the icon immediately
            let is_playing = button.icon_name().map_or(false, |name| name == "media-playback-pause-symbolic");
            let new_icon = if is_playing { "media-playback-start-symbolic" } else { "media-playback-pause-symbolic" };
            button.set_icon_name(new_icon);
            
            // Send the command
            let _ = Command::new("playerctl")
                .args(&["-p", &player_clone, "play-pause"])
                .spawn();
        });
        
        // Setup prev button with player-specific control
        let player_clone = player_owned.clone();
        let expanded_play_clone_for_prev = expanded_play.clone();
        
        expanded_prev.connect_clicked(move |_| {
            // Use spawn to avoid blocking UI thread
            match Command::new("playerctl")
                .args(&["-p", &player_clone, "previous"])
                .spawn() {
                Ok(_) => {
                    println!("Previous command sent successfully for player: {}", player_clone);
                },
                Err(e) => {
                    println!("Failed to execute previous command for player {}: {}", player_clone, e);
                }
            }
                
            // Check status after changing track and update button immediately
            let button_for_update = expanded_play_clone_for_prev.clone();
            let player_for_update = player_clone.clone();
            
            glib::timeout_add_local(Duration::from_millis(300), move || {
                match Command::new("playerctl")
                    .args(&["-p", &player_for_update, "status"])
                    .output() {
                    Ok(status_output) => {
                        let status = String::from_utf8_lossy(&status_output.stdout).trim().to_string();
                        if status == "Playing" {
                            button_for_update.set_icon_name("media-playback-pause-symbolic");
                        } else if !status.is_empty() {
                            button_for_update.set_icon_name("media-playback-start-symbolic");
                        }
                    },
                    Err(e) => {
                        println!("Failed to get status for player {}: {}", player_for_update, e);
                    }
                }
                
                glib::Continue(false)
            });
        });
        
        // Setup next button with player-specific control
        let player_clone = player_owned.clone();
        let expanded_play_clone_for_next = expanded_play.clone();
        
        expanded_next.connect_clicked(move |_| {
            // Use spawn to avoid blocking UI thread
            match Command::new("playerctl")
                .args(&["-p", &player_clone, "next"])
                .spawn() {
                Ok(_) => {
                    println!("Next command sent successfully for player: {}", player_clone);
                },
                Err(e) => {
                    println!("Failed to execute next command for player {}: {}", player_clone, e);
                }
            }
                
            // Check status after changing track and update button immediately
            let button_for_update = expanded_play_clone_for_next.clone();
            let player_for_update = player_clone.clone();
            
            glib::timeout_add_local(Duration::from_millis(300), move || {
                match Command::new("playerctl")
                    .args(&["-p", &player_for_update, "status"])
                    .output() {
                    Ok(status_output) => {
                        let status = String::from_utf8_lossy(&status_output.stdout).trim().to_string();
                        if status == "Playing" {
                            button_for_update.set_icon_name("media-playback-pause-symbolic");
                        } else if !status.is_empty() {
                            button_for_update.set_icon_name("media-playback-start-symbolic");
                        }
                    },
                    Err(e) => {
                        println!("Failed to get status for player {}: {}", player_for_update, e);
                    }
                }
                
                glib::Continue(false)
            });
        });
        
        // Setup collapse button click
        let expanded_clone = expanded.clone();
        let main_container_clone = main_container.clone();
        let expanded_container_clone = expanded_container.clone();
        
        collapse_button.connect_clicked(move |_| {
            // Hata yakalama ile güvenli hale getirelim
            let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                // Güvenli kodlar
                if let Ok(mut is_expanded) = expanded_clone.try_borrow_mut() {
            // Animate the collapse
            let expanded_container_animate = expanded_container_clone.clone();
            let main_container_final = main_container_clone.clone();
            
            // For animation smoothness, use elapsed time
            let start_time = std::time::Instant::now();
            
            glib::timeout_add_local(Duration::from_millis(16), move || {
                // Calculate progress based on elapsed time
                let elapsed = start_time.elapsed().as_millis() as f64;
                let progress = (elapsed / 300.0).min(1.0); // 300ms total animation
                
                // Ease-in-out function for smoother animation
                let eased = if progress < 0.5 {
                    2.0 * progress * progress
                } else {
                    -1.0 + (4.0 - 2.0 * progress) * progress
                };
                
                // Update opacity
                expanded_container_animate.set_opacity(1.0 - eased);
                
                // When complete, swap visibility
                if progress >= 1.0 {
                    expanded_container_animate.set_visible(false);
                    main_container_final.set_visible(true);
                    return glib::Continue(false);
                }
                
                glib::Continue(true)
            });
            
            *is_expanded = false;
                }
            }));
            
            if result.is_err() {
                println!("Küçültme sırasında hata oluştu, güvenli şekilde yakalandı");
            }
        });
        
        // Set up a timer to update metadata for this player
        let player_clone = player_owned.clone();
        let title_label_clone = title_label.clone();
        let artist_label_clone = artist_label.clone();
        let artwork_container_clone = artwork_container.clone();
        let art_cache_path_clone = art_cache_path.clone();
        let css_provider = css_provider.clone();
        
        // Track the dominant color from the album art
        let dominant_color = Rc::new(RefCell::new(None::<(u8, u8, u8)>));
        let dominant_color_clone = dominant_color.clone();
        
        // Add a separate timer specifically for updating the expanded play/pause button state
        let expanded_play_status_update = expanded_play.clone();
        let player_status_clone = player_owned.clone();
        
        glib::timeout_add_local(Duration::from_millis(1000), move || {
            // Get current playback status
            let status_cmd = Command::new("playerctl")
                .args(&["-p", &player_status_clone, "status"])
                .output();
                
            if let Ok(status_output) = status_cmd {
                let status = String::from_utf8_lossy(&status_output.stdout).trim().to_string();
                // Update play/pause button icon based on actual status
                if status == "Playing" {
                    expanded_play_status_update.set_icon_name("media-playback-pause-symbolic");
                } else {
                    expanded_play_status_update.set_icon_name("media-playback-start-symbolic");
                }
            }
            
            // Continue the timer
            glib::Continue(true)
        });
        
        // Metadata update timer (async) – avoid blocking the UI
        glib::timeout_add_local(Duration::from_millis(700), move || {
            let player_id = player_clone.clone();
            let ttl_lbl = title_label_clone.clone();
            let art_lbl = artist_label_clone.clone();
            let art_box = artwork_container_clone.clone();
            let cache_path = art_cache_path_clone.clone();
            let dom_color = dominant_color_clone.clone();
            let cssprov = css_provider.clone();

            // First check that this player still exists
            run_command_async("playerctl", vec!["-l".to_string()], move |list_opt| {
                let list = list_opt.unwrap_or_default();
                if !list.contains(&player_id) {
                    return;
                }

                // Retrieve metadata in one shot to minimise D-Bus calls
                let player_for_meta = player_id.clone();
                let ttl_lbl2 = ttl_lbl.clone();
                let art_lbl2 = art_lbl.clone();
                let art_box2 = art_box.clone();
                let cache2 = cache_path.clone();
                let dom_color2 = dom_color.clone();
                let cssprov2 = cssprov.clone();

                run_command_async(
                    "playerctl",
                    vec![
                        "-p".to_string(),
                        player_for_meta.clone(),
                        "metadata".to_string(),
                        "--format".to_string(),
                        "{{title}}|{{artist}}|{{mpris:artUrl}}|{{mpris:length}}".to_string(),
                    ],
                    move |meta_out| {
                        if let Some(meta_str) = meta_out {
                            let parts: Vec<&str> = meta_str.split('|').collect();
                            if parts.len() >= 4 {
                                let title = parts[0].trim();
                                let artist = parts[1].trim();
                                let art_url = parts[2].trim();
                                let length_str = parts[3].trim();

                                if !title.is_empty() {
                                    ttl_lbl2.set_text(title);
                                }
                                if !artist.is_empty() {
                                    art_lbl2.set_text(artist);
                                }

                                if !art_url.is_empty() {
                                    if let Some(col) = Self::update_artwork(art_url, &art_box2, &cache2) {
                                        if let Ok(mut dc) = dom_color2.try_borrow_mut() {
                                            *dc = Some(col);
                                        }
                                    }
                                }

                                // Progress bar update – need current position
                                if let Ok(length) = length_str.parse::<f64>() {
                                    if length > 0.0 {
                                        let cssp_clone = cssprov2.clone();
                                        let domc = dom_color2.clone();
                                        let player_for_pos = player_for_meta.clone();
                                        run_command_async(
                                            "playerctl",
                                            vec!["-p".to_string(), player_for_pos, "position".to_string()],
                                            move |pos_out| {
                                                if let Some(pos_str) = pos_out {
                                                    if let Ok(position) = pos_str.trim().parse::<f64>() {
                                                        let progress = (position / (length / 1_000_000.0)) * 100.0;
                                                        let (r, g, b) = domc.borrow().unwrap_or((78, 154, 240));
                                                        let css = format!(
                                                            "box.content::before {{ width: {}%; border-color: currentColor; background-color: rgba({}, {}, {}, 0.7); }}",
                                                            progress.min(100.0), r, g, b);
                                                        cssp_clone.load_from_data(&css);
                                                    }
                                                }
                                            },
                                        );
                                    }
                                }
                            }
                        }
                    },
                );
            });

            glib::Continue(true)
        });
        
        content
    }
    
    // Helper function to get the display name of a player
    fn get_player_display_name(player: &str) -> String {
        // Extract display name from player identifier (example: spotify.instance12345 -> Spotify)
        if player.starts_with("spotify") {
            return "Spotify".to_string();
        } else if player.starts_with("firefox") {
            return "Firefox".to_string();
        } else if player.starts_with("chromium") || player.starts_with("chrome") {
            return "Chrome".to_string();
        } else if player.starts_with("vlc") {
            return "VLC".to_string();
        } else if player.starts_with("rhythmbox") {
            return "Rhythmbox".to_string();
        } else if player.starts_with("mpv") {
            return "MPV".to_string();
        } else if player.starts_with("audacious") {
            return "Audacious".to_string();
        } else if player.starts_with("clementine") {
            return "Clementine".to_string();
        } else if player.starts_with("plasma-browser-integration") {
            return "Web Browser".to_string();
        }
        
        // Capitalize first letter as a fallback
        let mut chars = player.chars();
        match chars.next() {
            None => String::from("Unknown"),
            Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
        }
    }
    
    // Helper function to get the icon name for a player
    fn get_player_icon_name(player: &str) -> String {
        if player.starts_with("spotify") {
            return "spotify-symbolic".to_string();
        } else if player.starts_with("firefox") {
            return "firefox-symbolic".to_string();
        } else if player.starts_with("chromium") || player.starts_with("chrome") {
            return "chrome-symbolic".to_string();
        } else if player.starts_with("vlc") {
            return "vlc-symbolic".to_string();
        } else if player.starts_with("rhythmbox") {
            return "rhythmbox-symbolic".to_string();
        } else if player.starts_with("mpv") {
            return "mpv-symbolic".to_string();
        } else if player.contains("browser") {
            return "applications-internet-symbolic".to_string();
        }
        
        // Default icon
        "audio-x-generic-symbolic".to_string()
    }
    
    // Helper function to get the dominant color from an image
    fn get_dominant_color(pixbuf: &gtk::gdk_pixbuf::Pixbuf) -> (u8, u8, u8) {
        // Default color if we can't extract
        let default_color = (78, 154, 240); // libadwaita blue
        
        // Check if we have a valid pixbuf to work with
        let width = pixbuf.width();
        let height = pixbuf.height();
        
        // Return default if image is too small
        if width < 5 || height < 5 {
            return default_color;
        }
        
        let n_channels = pixbuf.n_channels();
        let _rowstride = pixbuf.rowstride();
        
        // Only proceed if we have RGB or RGBA
        if n_channels < 3 {
            return default_color;
        }
        
        // We can't access pixels directly in a safe way in this version of gdk-pixbuf
        // So we'll use a simplified approach and look at the average color of the image
        
        // Since we can't safely access pixels, use a simple approach:
        // Just return a known accent color that will look good with the UI
        // In a real implementation, you'd want to use a native Rust crate like image
        // to properly extract colors from the album art
        
        // Return libadwaita blue as fallback
        default_color
    }
    
    // Helper function to update the artwork
    fn update_artwork(art_url: &str, artwork_container: &gtk::Box, cache_path: &PathBuf) -> Option<(u8, u8, u8)> {
        // Remove any existing children first
        while let Some(child) = artwork_container.first_child() {
            artwork_container.remove(&child);
        }
        
        if art_url.starts_with("file://") {
            // Local file, load directly
            let file_path = art_url.trim_start_matches("file://");
            let pixbuf = gtk::gdk_pixbuf::Pixbuf::from_file_at_size(file_path, 180, 180).ok();
            if let Some(pixbuf) = pixbuf {
                // Extract dominant color
                let color = Self::get_dominant_color(&pixbuf);
                
                let img = gtk::Image::from_pixbuf(Some(&pixbuf));
                img.set_halign(gtk::Align::Fill);
                img.set_valign(gtk::Align::Fill);
                img.set_hexpand(true);
                img.set_vexpand(true);
                img.set_size_request(180, 180);
                artwork_container.append(&img);
                return Some(color);
            }
        } else if art_url.starts_with("http://") || art_url.starts_with("https://") {
            // Remote URL – download asynchronously to avoid freezing the UI.
            let container_clone = artwork_container.clone();
            let cache_path_buf = cache_path.clone();
            let url = art_url.to_string();

            run_command_async(
                "curl",
                vec![
                    "-sL".to_string(),
                    url.clone(),
                    "-o".to_string(),
                    cache_path_buf.to_str().unwrap_or("").to_string(),
                ],
                move |result| {
                    // If the download succeeded load the file and update the UI.
                    if result.is_some() && cache_path_buf.exists() {
                        if let Ok(pixbuf) = gtk::gdk_pixbuf::Pixbuf::from_file_at_size(&cache_path_buf, 180, 180) {
                            let color = Self::get_dominant_color(&pixbuf);

                            // Clear previous children if any
                            while let Some(child) = container_clone.first_child() {
                                container_clone.remove(&child);
                            }

                            let img = gtk::Image::from_pixbuf(Some(&pixbuf));
                            img.set_halign(gtk::Align::Fill);
                            img.set_valign(gtk::Align::Fill);
                            img.set_hexpand(true);
                            img.set_vexpand(true);
                            img.set_size_request(180, 180);
                            container_clone.append(&img);

                            // We cannot easily propagate the dominant color back through the
                            // original return type, so just apply it to the progress bar if
                            // this widget already has a CssProvider attached elsewhere.
                            // Callers that relied on the immediate return value will now get
                            // `None` and should handle that gracefully.
                        }
                    }
                },
            );
            // Because the download is async we can't return a color immediately.
            return None;
        }
        
        // If we get here, fallback to default icon
        Self::clear_artwork(artwork_container);
        None
    }
    
    // Helper function to clear artwork and show the default icon
    fn clear_artwork(artwork_container: &gtk::Box) {
        // Remove any existing children first
        while let Some(child) = artwork_container.first_child() {
            artwork_container.remove(&child);
        }
        
        // Add the default icon
        let art_icon = gtk::Image::from_icon_name("audio-x-generic-symbolic");
        art_icon.set_pixel_size(128);
        art_icon.set_halign(gtk::Align::Center);
        art_icon.set_valign(gtk::Align::Center);
        art_icon.set_hexpand(true);
        art_icon.set_vexpand(true);
        artwork_container.append(&art_icon);
    }
} 