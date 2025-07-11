#!/usr/bin/env python3

import gi
import sys
import subprocess
import threading
import time
import argparse
import os
import cairo
import signal
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell, GLib, Gdk, GObject, Gio

class SystemMonitor(threading.Thread):
    def __init__(self, callback, monitor_type="volume"):
        threading.Thread.__init__(self, daemon=True)
        self.callback = callback
        self.running = True
        self.monitor_type = monitor_type
        
        if monitor_type == "volume":
            self.current_value = self.get_volume()
            self.current_mute = self.is_muted()
        else:  # brightness
            self.current_value = self.get_brightness()
            self.current_mute = False
        
        # Use an event to avoid busy waiting
        self.event = threading.Event()
    
    def run(self):
        while self.running:
            if self.monitor_type == "volume":
                value = self.get_volume()
                is_muted = self.is_muted()
                
                if value != self.current_value or is_muted != self.current_mute:
                    self.current_value = value
                    self.current_mute = is_muted
                    GLib.idle_add(self.callback, value, is_muted)
            else:  # brightness
                value = self.get_brightness()
                
                if value != self.current_value:
                    self.current_value = value
                    GLib.idle_add(self.callback, value, False)
            
            # Sleep for a shorter time but use an event to allow interruption
            self.event.wait(0.2)
    
    def get_volume(self):
        try:
            # Get volume using pactl
            cmd = ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
            output = subprocess.check_output(cmd).decode('utf-8')
            # Parse volume percentage
            for line in output.splitlines():
                if "%" in line:
                    volume = int(line.split("%")[0].split()[-1])
                    return volume
        except Exception as e:
            print(f"Error getting volume: {e}", file=sys.stderr)
        return 0
    
    def is_muted(self):
        try:
            cmd = ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
            output = subprocess.check_output(cmd).decode('utf-8')
            return "yes" in output.lower()
        except Exception as e:
            print(f"Error checking mute status: {e}", file=sys.stderr)
        return False
    
    def get_brightness(self):
        try:
            # Get brightness using brightnessctl
            cmd = ["brightnessctl", "info"]
            output = subprocess.check_output(cmd).decode('utf-8')
            # Parse brightness percentage
            for line in output.splitlines():
                if "%" in line:
                    # Extract percentage value
                    parts = line.split("(")
                    if len(parts) >= 2:
                        percent_part = parts[1].split("%")[0]
                        brightness = int(percent_part)
                        return brightness
        except Exception as e:
            print(f"Error getting brightness: {e}", file=sys.stderr)
        return 0
    
    def set_volume(self, volume):
        try:
            if volume < 0:
                volume = 0
            elif volume > 100:
                volume = 100
                
            subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{volume}%"])
            # Wake up the monitoring thread immediately
            self.event.set()
            self.event.clear()
            return True
        except Exception as e:
            print(f"Error setting volume: {e}", file=sys.stderr)
            return False
    
    def toggle_mute(self):
        try:
            subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
            # Wake up the monitoring thread immediately
            self.event.set()
            self.event.clear()
            return True
        except Exception as e:
            print(f"Error toggling mute: {e}", file=sys.stderr)
            return False
    
    def set_brightness(self, brightness):
        try:
            if brightness < 0:
                brightness = 0
            elif brightness > 100:
                brightness = 100
                
            subprocess.run(["brightnessctl", "set", f"{brightness}%"])
            # Wake up the monitoring thread immediately
            self.event.set()
            self.event.clear()
            return True
        except Exception as e:
            print(f"Error setting brightness: {e}", file=sys.stderr)
            return False
    
    def stop(self):
        self.running = False
        # Wake up the thread to exit
        self.event.set()

class AnimatedProgressBar(Gtk.ProgressBar):
    def __init__(self):
        super().__init__()
        self.target_fraction = 0.0
        self.current_fraction = 0.0
        self.animation_active = False
        self.animation_timer = None
        self.animation_speed = 0.08  # Higher values = faster animation
    
    def set_fraction_animated(self, fraction):
        # Set the target fraction
        self.target_fraction = fraction
        
        # Start animation if not already active
        if not self.animation_active:
            self.animation_active = True
            self.animation_timer = GLib.timeout_add(16, self.animate_progress)  # ~60fps
    
    def animate_progress(self):
        # Calculate the step size based on the difference
        diff = self.target_fraction - self.current_fraction
        step = diff * self.animation_speed
        
        # If we're close enough to the target, snap to it
        if abs(diff) < 0.01:
            self.current_fraction = self.target_fraction
            super().set_fraction(self.current_fraction)
            self.animation_active = False
            self.animation_timer = None
            return False
        
        # Update the current fraction
        self.current_fraction += step
        super().set_fraction(self.current_fraction)
        
        # Continue animation
        return True

class OSDWidget(Gtk.Box):
    def __init__(self, controller, osd_type="volume"):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        
        # Store controller and type
        self.controller = controller
        self.osd_type = osd_type
        
        # Animation properties for bounce effect
        self.bounce_animation_active = False
        self.bounce_direction = None
        self.bounce_start_time = None
        self.bounce_duration = 150  # milliseconds
        self.bounce_distance = 10  # pixels
        self.original_y = 0
        
        # Make the main widget itself handle scroll events
        self.add_events(Gdk.EventMask.SCROLL_MASK)
        self.connect("scroll-event", self.on_scroll)
        
        # Create an event box to capture mouse wheel events for the entire widget
        self.main_event_box = Gtk.EventBox()
        self.main_event_box.add_events(Gdk.EventMask.SCROLL_MASK)
        self.main_event_box.connect("scroll-event", self.on_scroll)
        
        # Create inner box for content
        self.inner_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        self.inner_box.set_halign(Gtk.Align.CENTER)
        self.inner_box.set_margin_start(15)
        self.inner_box.set_margin_end(15)
        self.inner_box.set_margin_top(15)
        self.inner_box.set_margin_bottom(15)
        self.inner_box.add_events(Gdk.EventMask.SCROLL_MASK)
        self.inner_box.connect("scroll-event", self.on_scroll)
        
        # Add icon based on type
        if osd_type == "volume":
            self.icon_names = {
                "muted": "audio-volume-muted",
                "low": "audio-volume-low",
                "medium": "audio-volume-medium",
                "high": "audio-volume-high"
            }
            self.icon = Gtk.Image.new_from_icon_name(self.icon_names["high"], Gtk.IconSize.LARGE_TOOLBAR)
        else:  # brightness
            self.icon_names = {
                "low": "display-brightness-low-symbolic",
                "medium": "display-brightness-medium-symbolic",
                "high": "display-brightness-high-symbolic"
            }
            self.icon = Gtk.Image.new_from_icon_name(self.icon_names["high"], Gtk.IconSize.LARGE_TOOLBAR)
        self.icon.set_halign(Gtk.Align.CENTER)
        self.inner_box.pack_start(self.icon, False, False, 0)
        
        # Create a box to hold the progress bar to ensure it's centered
        progress_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        progress_box.set_halign(Gtk.Align.CENTER)
        progress_box.add_events(Gdk.EventMask.SCROLL_MASK)
        progress_box.connect("scroll-event", self.on_scroll)
        
        # Add a progress bar for level indication (use our animated version)
        self.progress_bar = AnimatedProgressBar()
        self.progress_bar.set_orientation(Gtk.Orientation.VERTICAL)
        self.progress_bar.set_inverted(True)  # Make 0% at bottom, 100% at top
        self.progress_bar.set_fraction(1.0)
        # Set minimum size to match icon width
        self.progress_bar.set_size_request(24, 100)
        
        # Add the progress bar to the progress box
        progress_box.pack_start(self.progress_bar, True, True, 0)
        
        # Add the progress box to the inner box
        self.inner_box.pack_start(progress_box, True, True, 0)
        
        # Add the inner box to the event box
        self.main_event_box.add(self.inner_box)
        
        # Add the event box to the main widget
        self.pack_start(self.main_event_box, True, True, 0)
        
        # Store current values
        self.current_value = 100
        self.is_muted = False
        
        # Show all widgets
        self.show_all()
        self.hide()  # Initially hidden
    
    def on_scroll(self, widget, event):
        print(f"Scroll event received in {self.osd_type} OSD: {event.direction}")
        
        if self.osd_type == "volume":
            current_value = self.controller.get_volume()
            
            if event.direction == Gdk.ScrollDirection.UP:
                # Check if already at max volume
                if current_value >= 100:
                    self.start_bounce_animation("up")
                    return True
                self.controller.set_volume(current_value + 5)
                
            elif event.direction == Gdk.ScrollDirection.DOWN:
                # Check if already at min volume
                if current_value <= 0:
                    self.start_bounce_animation("down")
                    return True
                self.controller.set_volume(current_value - 5)
                
        else:  # brightness
            current_value = self.controller.get_brightness()
            
            if event.direction == Gdk.ScrollDirection.UP:
                # Check if already at max brightness
                if current_value >= 100:
                    self.start_bounce_animation("up")
                    return True
                self.controller.set_brightness(current_value + 5)
                
            elif event.direction == Gdk.ScrollDirection.DOWN:
                # Check if already at min brightness
                if current_value <= 0:
                    self.start_bounce_animation("down")
                    return True
                self.controller.set_brightness(current_value - 5)
        
        return True  # Stop event propagation
    
    def start_bounce_animation(self, direction):
        # Store the original y position if not already in an animation
        if not self.bounce_animation_active:
            allocation = self.get_allocation()
            self.original_y = allocation.y
        
        # Set animation parameters
        self.bounce_animation_active = True
        self.bounce_direction = direction
        self.bounce_start_time = time.time() * 1000
        
        # Start the animation
        GLib.timeout_add(16, self.update_bounce_animation)  # ~60fps
    
    def update_bounce_animation(self):
        if not self.bounce_animation_active:
            return False
        
        current_time = time.time() * 1000
        elapsed = current_time - self.bounce_start_time
        
        # Calculate progress (0.0 to 1.0)
        progress = min(elapsed / self.bounce_duration, 1.0)
        
        # Calculate bounce offset using sine function for smooth bounce
        # First half moves away, second half returns
        bounce_offset = 0
        if progress < 0.5:
            # Moving away
            bounce_factor = progress * 2  # 0 to 1
            bounce_offset = self.bounce_distance * bounce_factor
        else:
            # Returning
            bounce_factor = (1 - progress) * 2  # 1 to 0
            bounce_offset = self.bounce_distance * bounce_factor
        
        # Apply the offset based on direction
        if self.bounce_direction == "up":
            # Move up (negative y offset)
            self.inner_box.set_margin_top(15 - bounce_offset)
            self.inner_box.set_margin_bottom(15 + bounce_offset)
        else:  # down
            # Move down (positive y offset)
            self.inner_box.set_margin_top(15 + bounce_offset)
            self.inner_box.set_margin_bottom(15 - bounce_offset)
        
        # Force redraw
        self.queue_draw()
        
        # Check if animation is complete
        if progress >= 1.0:
            # Reset position
            self.inner_box.set_margin_top(15)
            self.inner_box.set_margin_bottom(15)
            self.bounce_animation_active = False
            return False
        
        # Continue animation
        return True
    
    def update_display(self, value, is_muted=False):
        # Store current values
        self.current_value = value
        self.is_muted = is_muted
        
        # Update the display values
        if self.osd_type == "volume":
            if is_muted:
                self.progress_bar.set_fraction_animated(0.0)
                self.icon.set_from_icon_name(self.icon_names["muted"], Gtk.IconSize.LARGE_TOOLBAR)
                self.get_style_context().add_class("muted")
            else:
                self.progress_bar.set_fraction_animated(value / 100.0)
                self.get_style_context().remove_class("muted")
                
                # Update icon based on volume level
                if value == 0:
                    icon_name = self.icon_names["muted"]
                elif value < 33:
                    icon_name = self.icon_names["low"]
                elif value < 66:
                    icon_name = self.icon_names["medium"]
                else:
                    icon_name = self.icon_names["high"]
                
                self.icon.set_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
        else:  # brightness
            self.progress_bar.set_fraction_animated(value / 100.0)
            
            # Update icon based on brightness level
            if value < 33:
                icon_name = self.icon_names["low"]
            elif value < 66:
                icon_name = self.icon_names["medium"]
            else:
                icon_name = self.icon_names["high"]
            
            self.icon.set_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
        
        # Show the widget
        self.show()

    def refresh(self):
        """Refresh the widget with current values."""
        # Update the widget's style context - remove deprecated call
        # style_context = self.get_style_context()
        # style_context.invalidate()
        
        # Update the display values
        self.update_display(self.current_value, self.is_muted)
        
        # Force redraw
        self.queue_draw()

class OSDContainerWindow(Gtk.Window):
    def __init__(self, volume_monitor, brightness_monitor):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        
        # Store monitors for scroll events
        self.volume_monitor = volume_monitor
        self.brightness_monitor = brightness_monitor
        
        # Set up the window
        self.set_title("OSD Container")
        self.set_default_size(60, 400)  # Further reduced width for narrower OSD
        self.set_app_paintable(True)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_resizable(False)  # Prevent resizing
        
        # Enable scroll events on the window itself
        self.add_events(Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.POINTER_MOTION_MASK | 
                       Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK)
        self.connect("scroll-event", self.on_scroll)
        
        # Make the window a layer shell surface
        GtkLayerShell.init_for_window(self)
        
        # Set layer shell properties
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        
        # Set layer shell to receive input events
        GtkLayerShell.set_exclusive_zone(self, -1)  # Don't reserve space
        GtkLayerShell.set_keyboard_interactivity(self, False)  # Don't need keyboard input
        
        # Position at the right-center of the screen
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, False)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, False)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, False)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 50)
        
        # Create an event box to capture mouse wheel events for the entire window
        self.event_box = Gtk.EventBox()
        self.event_box.add_events(Gdk.EventMask.SCROLL_MASK | Gdk.EventMask.POINTER_MOTION_MASK | 
                                 Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK)
        self.event_box.connect("scroll-event", self.on_scroll)
        
        # Create a box to hold our OSDs
        self.box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.box.set_halign(Gtk.Align.CENTER)  # Center horizontally
        self.box.set_valign(Gtk.Align.CENTER)  # Center vertically
        self.box.set_margin_start(5)
        self.box.set_margin_end(5)
        self.box.set_margin_top(10)
        self.box.set_margin_bottom(10)
        self.box.add_events(Gdk.EventMask.SCROLL_MASK)
        self.box.connect("scroll-event", self.on_scroll)
        
        # Create OSD widgets
        self.volume_osd = OSDWidget(volume_monitor, "volume")
        self.brightness_osd = OSDWidget(brightness_monitor, "brightness")
        
        # Add OSDs to box - volume on top, brightness below
        self.box.pack_start(self.volume_osd, False, False, 0)
        self.box.pack_start(self.brightness_osd, False, False, 0)
        
        # Add the box to the event box
        self.event_box.add(self.box)
        
        # Add the event box to the window
        self.add(self.event_box)
        
        # Set up CSS provider
        self.screen = Gdk.Screen.get_default()
        self.css_provider = Gtk.CssProvider()
        self.load_css()
        
        # Connect signals
        self.connect("draw", self.on_draw)
        self.connect("style-updated", self.on_style_updated)
        
        # Hide timer
        self.hide_timer = None
        
        # Track which OSD was last used
        self.last_used_osd = "volume"
        
        # Show all widgets
        self.show_all()
        self.hide()  # Initially hidden
    
    def on_style_updated(self, widget):
        """Handle style-updated signal."""
        print("Style updated, refreshing...")
        try:
            # Delay refresh to avoid conflicts with ongoing style updates
            GLib.timeout_add(100, self.delayed_refresh)
        except Exception as e:
            print(f"Error in style-updated handler: {e}", file=sys.stderr)
    
    def delayed_refresh(self):
        """Perform delayed refresh to avoid conflicts with style updates."""
        try:
            self.refresh_css()
        except Exception as e:
            print(f"Error refreshing CSS: {e}", file=sys.stderr)
        return False  # Don't repeat the timeout
    
    def load_css(self):
        """Load CSS styling."""
        css_data = """
            window {
                border-radius: 30px;
            }
            progressbar {
                min-width: 24px;
            }
            progressbar trough {
                min-width: 24px;
                border-radius: 12px;
                background-color: alpha(@theme_bg_color, 0.3);
            }
            progressbar progress {
                min-width: 24px;
                border-radius: 12px;
                background-color: @theme_selected_bg_color;
            }
            .muted progressbar trough {
                opacity: 0.5;
            }
        """
        
        try:
            self.css_provider.load_from_data(css_data.encode('utf-8'))
            
            Gtk.StyleContext.add_provider_for_screen(
                self.screen,
                self.css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
        except Exception as e:
            print(f"Error loading CSS: {e}", file=sys.stderr)
    
    def refresh_css(self):
        """Refresh CSS styling to reflect theme changes."""
        try:
            # Remove old provider
            Gtk.StyleContext.remove_provider_for_screen(
                self.screen,
                self.css_provider
            )
            
            # Create a new CSS provider
            self.css_provider = Gtk.CssProvider()
            self.load_css()
            
            # Force widget redraw
            self.volume_osd.refresh()
            self.brightness_osd.refresh()
            
            # Invalidate the window to force a redraw
            self.queue_draw()
            
            # Force style refresh - remove the problematic line
            # self.style_context = self.get_style_context()
            # self.style_context.changed()
            
            print("CSS refreshed successfully")
        except Exception as e:
            print(f"Error refreshing CSS: {e}", file=sys.stderr)
    
    def on_draw(self, widget, cr):
        # Create a semi-transparent background for the container
        width = self.get_allocated_width()
        height = self.get_allocated_height()
        
        # Use maximum radius for true pill shape
        radius = width / 2
        
        # Get theme background color with fallback
        style_context = self.get_style_context()
        try:
            # Use lookup_color instead of deprecated get_background_color
            success, bg_color = style_context.lookup_color("theme_bg_color")
            if not success:
                # Fallback to a dark color
                bg_color = Gdk.RGBA()
                bg_color.red = 0.2
                bg_color.green = 0.2
                bg_color.blue = 0.2
                bg_color.alpha = 1.0
        except:
            # Fallback to a dark color if lookup_color is not available
            bg_color = Gdk.RGBA()
            bg_color.red = 0.2
            bg_color.green = 0.2
            bg_color.blue = 0.2
            bg_color.alpha = 1.0
        
        # Draw rounded rectangle with semi-transparent theme background color
        cr.set_source_rgba(bg_color.red, bg_color.green, bg_color.blue, 0.9)
        
        # Create rounded rectangle path
        degrees = 3.14159 / 180.0
        cr.new_sub_path()
        cr.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees)
        cr.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees)
        cr.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees)
        cr.arc(radius, radius, radius, 180 * degrees, 270 * degrees)
        cr.close_path()
        
        cr.fill()
        
        return False
    
    def update_volume_display(self, value, is_muted=False):
        self.volume_osd.update_display(value, is_muted)
        self.last_used_osd = "volume"
        self.show_and_reset_timer()
    
    def update_brightness_display(self, value, is_muted=False):
        self.brightness_osd.update_display(value, is_muted)
        self.last_used_osd = "brightness"
        self.show_and_reset_timer()
    
    def on_scroll(self, widget, event):
        print(f"Scroll event received in container window: {event.direction}")
        # Determine which OSD to scroll based on last used
        if self.last_used_osd == "volume":
            current_value = self.volume_monitor.get_volume()
            
            if event.direction == Gdk.ScrollDirection.UP:
                # Check if already at max volume
                if current_value >= 100:
                    self.volume_osd.start_bounce_animation("up")
                    return True
                self.volume_monitor.set_volume(current_value + 5)
                
            elif event.direction == Gdk.ScrollDirection.DOWN:
                # Check if already at min volume
                if current_value <= 0:
                    self.volume_osd.start_bounce_animation("down")
                    return True
                self.volume_monitor.set_volume(current_value - 5)
                
        else:  # brightness
            current_value = self.brightness_monitor.get_brightness()
            
            if event.direction == Gdk.ScrollDirection.UP:
                # Check if already at max brightness
                if current_value >= 100:
                    self.brightness_osd.start_bounce_animation("up")
                    return True
                self.brightness_monitor.set_brightness(current_value + 5)
                
            elif event.direction == Gdk.ScrollDirection.DOWN:
                # Check if already at min brightness
                if current_value <= 0:
                    self.brightness_osd.start_bounce_animation("down")
                    return True
                self.brightness_monitor.set_brightness(current_value - 5)
        
        # Reset the hide timer
        self.show_and_reset_timer()
        return True  # Stop event propagation
    
    def show_and_reset_timer(self):
        # Show the window
        self.show_all()
        
        # Cancel any existing hide timer
        if self.hide_timer is not None:
            GLib.source_remove(self.hide_timer)
            self.hide_timer = None
        
        # Set a timer to hide the window after 3 seconds (increased from default)
        self.hide_timer = GLib.timeout_add(3000, self.hide_osd)
    
    def hide_osd(self):
        self.hide()
        self.hide_timer = None
        return False

class ThemeMonitor:
    """Monitor GTK theme changes and trigger a reload when needed."""
    def __init__(self, reload_callback):
        self.reload_callback = reload_callback
        self.handler_id = None
        self.restart_pending = False
        
        try:
            self.settings = Gio.Settings.new("org.gnome.desktop.interface")
            self.current_theme = self.settings.get_string("gtk-theme")
            self.handler_id = self.settings.connect("changed::gtk-theme", self.on_theme_changed)
            print(f"Theme monitor started. Current theme: {self.current_theme}")
        except Exception as e:
            print(f"Could not initialize theme monitor: {e}", file=sys.stderr)
            self.settings = None
    
    def on_theme_changed(self, settings, key):
        try:
            # Avoid multiple reloads
            if self.restart_pending:
                return
                
            self.restart_pending = True
            new_theme = settings.get_string(key)
            print(f"Theme changed from {self.current_theme} to {new_theme}")
            self.current_theme = new_theme
            
            # Call the reload callback
            GLib.idle_add(self.reload_callback)
            
            # Reset restart_pending after a short delay
            GLib.timeout_add(1000, self.reset_pending)
        except Exception as e:
            print(f"Error handling theme change: {e}", file=sys.stderr)
            self.restart_pending = False
    
    def reset_pending(self):
        """Reset the restart_pending flag."""
        self.restart_pending = False
        return False  # Don't repeat the timeout
    
    def stop(self):
        if self.settings and self.handler_id:
            try:
                self.settings.disconnect(self.handler_id)
                print("Theme monitor stopped")
            except Exception as e:
                print(f"Error stopping theme monitor: {e}", file=sys.stderr)

class OSDApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.example.osd.container")
        self.container_window = None
        self.volume_monitor = None
        self.brightness_monitor = None
        self.theme_monitor = None
    
    def do_activate(self):
        # Start system monitors
        self.volume_monitor = SystemMonitor(self.on_volume_changed, "volume")
        self.brightness_monitor = SystemMonitor(self.on_brightness_changed, "brightness")
        
        self.volume_monitor.start()
        self.brightness_monitor.start()
        
        # Start theme monitor
        self.theme_monitor = ThemeMonitor(self.reload_theme)
        
        try:
            # Create container window with both OSDs
            self.container_window = OSDContainerWindow(self.volume_monitor, self.brightness_monitor)
            self.container_window.connect("destroy", self.on_quit)
            
            # Show initial values
            volume = self.volume_monitor.get_volume()
            is_muted = self.volume_monitor.is_muted()
            brightness = self.brightness_monitor.get_brightness()
            
            self.container_window.update_volume_display(volume, is_muted)
            self.container_window.update_brightness_display(brightness, False)
        except Exception as e:
            print(f"Error creating window: {e}", file=sys.stderr)
            # Ensure monitors are stopped if window creation fails
            if self.volume_monitor:
                self.volume_monitor.stop()
            if self.brightness_monitor:
                self.brightness_monitor.stop()
            if self.theme_monitor:
                self.theme_monitor.stop()
            sys.exit(1)
    
    def reload_theme(self):
        """Reload theme styling without restarting the application."""
        print("Theme changed - reloading CSS...")
        
        if self.container_window:
            try:
                # Refresh CSS in the container window
                self.container_window.refresh_css()
                print("Theme reloaded successfully")
            except Exception as e:
                print(f"Error reloading theme: {e}", file=sys.stderr)
        
        return False  # Don't repeat the timeout
    
    def on_volume_changed(self, value, is_muted):
        if self.container_window:
            try:
                self.container_window.update_volume_display(value, is_muted)
            except Exception as e:
                print(f"Error updating volume display: {e}", file=sys.stderr)
    
    def on_brightness_changed(self, value, is_muted):
        if self.container_window:
            try:
                self.container_window.update_brightness_display(value, is_muted)
            except Exception as e:
                print(f"Error updating brightness display: {e}", file=sys.stderr)
    
    def on_quit(self, window):
        if self.volume_monitor:
            self.volume_monitor.stop()
        if self.brightness_monitor:
            self.brightness_monitor.stop()
        if self.theme_monitor:
            self.theme_monitor.stop()
        Gtk.main_quit()

# Global reference to the app for signal handlers
app = None

def main():
    # Create a lock file to prevent multiple instances
    lock_file = "/tmp/osd-container.lock"
    
    global app
    
    # Set up signal handling for clean shutdown and theme reload
    def signal_handler(sig, frame):
        if sig == signal.SIGUSR1:
            print("Received SIGUSR1, reloading theme...")
            if app and hasattr(app, 'reload_theme'):
                GLib.idle_add(app.reload_theme)
            return
        
        print(f"Received signal {sig}, shutting down...")
        # Clean up lock file
        if os.path.exists(lock_file):
            try:
                os.remove(lock_file)
            except OSError:
                pass
        sys.exit(0)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGUSR1, signal_handler)
    
    if os.path.exists(lock_file):
        try:
            # Check if the process is still running
            with open(lock_file, 'r') as f:
                pid = int(f.read().strip())
            
            # Try to send a signal to the process
            os.kill(pid, 0)
            print("OSD container is already running")
            sys.exit(1)
        except (OSError, ValueError):
            # Process is not running or invalid PID, remove the stale lock file if it exists
            try:
                if os.path.exists(lock_file):
                    os.remove(lock_file)
            except OSError:
                # Handle case where lock file can't be removed
                pass
    
    # Create lock file with current PID
    try:
        with open(lock_file, 'w') as f:
            f.write(str(os.getpid()))
    except OSError:
        # If we can't create the lock file, continue anyway
        print("Warning: Could not create lock file")
    
    try:
        app = OSDApp()
        
        # Try to register the app, but continue even if it fails
        try:
            app.register()
        except Exception as e:
            print(f"Warning: Could not register application: {e}", file=sys.stderr)
            print("Continuing without registration...", file=sys.stderr)
        
        app.activate()
        Gtk.main()
    finally:
        # Clean up lock file on exit
        try:
            if os.path.exists(lock_file):
                os.remove(lock_file)
        except OSError:
            # Handle case where lock file can't be removed
            pass

if __name__ == "__main__":
    main() 