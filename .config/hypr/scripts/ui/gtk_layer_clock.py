#!/usr/bin/env python3

"""
GTK Layer Shell Clock

A desktop clock that uses GTK Layer Shell to display above wallpaper but below windows.
Uses a fully transparent fullscreen window with a positioned clock widget inside.

The clock automatically positions itself using the empty area finder that
avoids complex instant color change areas for better readability.
"""

import gi
import argparse
import sys
import os
import json
import time
from datetime import datetime

gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')

from gi.repository import Gtk, Gdk, GLib
from gi.repository import GtkLayerShell

class LayerClock(Gtk.Window):
    def __init__(self, x=100, y=100, primary_color="#6750a4", 
                 text_color="#ffffff", bg_color="#1c1b1f"):
        super().__init__()
        
        # Initial positions and colors
        self.clock_x = int(x)
        self.clock_y = int(y)
        self.initial_primary_color = primary_color
        self.primary_color = primary_color
        self.text_color = text_color
        self.bg_color = bg_color
        
        self.target_x = self.clock_x
        self.target_y = self.clock_y
        self.animation_active = False
        self.last_adaptive_color = None
        
        # Define file paths for external configurations
        self.empty_areas_file = os.path.expanduser("~/.config/hypr/colorgen/empty_areas.json")
        self.colors_file = os.path.expanduser("~/.config/hypr/colorgen/colors.json")
        
        self.setup_layer_shell()
        self.setup_ui()
        self.start_clock_update()
        
    def setup_layer_shell(self):
        """Configure GTK Layer Shell for a fullscreen transparent overlay."""
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_namespace(self, "gtk-layer-clock")
        
        # Anchor to all edges to make it fullscreen
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        
        GtkLayerShell.set_exclusive_zone(self, 0)
    
    def setup_ui(self):
        """Setup the transparent fullscreen UI with a positioned clock widget."""
        self.set_title("Layer Clock")
        self.set_decorated(False)
        self.set_resizable(False)
        
        # The main overlay for the entire window
        self.overlay = Gtk.Overlay()
        
        # Invisible base widget to fill the screen
        self.base = Gtk.Box()
        self.base.set_size_request(1, 1) # Set minimum size to ensure it fills
        self.base.set_halign(Gtk.Align.FILL)
        self.base.set_valign(Gtk.Align.FILL)
        
        # Clock container with vertical orientation for time and date labels
        self.clock_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.clock_container.set_halign(Gtk.Align.START)
        self.clock_container.set_valign(Gtk.Align.START)
        
        # Time label (Material Design style)
        self.time_label = Gtk.Label()
        self.time_label.set_markup(f'<span font="64" weight="bold" color="{self.primary_color}">00:00</span>')
        
        # Date label (Material Design style)
        self.date_label = Gtk.Label()
        self.date_label.set_markup(f'<span font="24" color="{self.primary_color}">Monday, January 1</span>')
        
        # Main content container - no centering, use absolute positioning
        self.content_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.content_container.set_halign(Gtk.Align.START)
        self.content_container.set_valign(Gtk.Align.START)
        self.content_container.pack_start(self.time_label, False, False, 0)
        self.content_container.pack_start(self.date_label, False, False, 0)
        
        # 3-dot menu button
        self.menu_button = Gtk.Button()
        self.menu_button.set_label("⋯")
        self.menu_button.set_relief(Gtk.ReliefStyle.NONE)
        self.menu_button.get_style_context().add_class("menu-button")
        self.menu_button.connect("clicked", self.on_menu_clicked)
        self.menu_button.set_halign(Gtk.Align.START)
        self.menu_button.set_valign(Gtk.Align.END)
        
        # Overlay for menu button positioning
        self.clock_overlay = Gtk.Overlay()
        self.clock_overlay.add(self.content_container)
        self.clock_overlay.add_overlay(self.menu_button)
        
        self.clock_container.pack_start(self.clock_overlay, True, True, 0)
        
        self.clock_overlay.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK)
        self.clock_overlay.connect("enter-notify-event", self.on_hover_enter)
        self.clock_overlay.connect("leave-notify-event", self.on_hover_leave)
        
        self.overlay.add(self.base)
        self.overlay.add_overlay(self.clock_container)
        self.add(self.overlay)
        
        self.apply_css_styling()
        
        # Connect signals
        self.connect("destroy", Gtk.main_quit)
        self.connect("realize", self.on_realize)
        
        # Start monitoring for position and color changes
        self.start_position_monitoring()
        
    def on_realize(self, widget):
        """Trigger initial positioning after the window is fully realized."""
        # Use GLib.idle_add for positioning after the main loop starts
        GLib.idle_add(self.position_clock)
        return False
    
    def position_clock(self):
        """Position the clock based on stored coordinates with smooth animation."""
        allocation = self.clock_container.get_allocation()
        actual_width = allocation.width
        actual_height = allocation.height
        
        # Sanity check for dimensions
        if actual_width < 50 or actual_height < 20:
            # Re-queue if size is not yet allocated properly
            GLib.idle_add(self.position_clock)
            return False
        
        # Get screen dimensions for visibility check
        screen = Gdk.Screen.get_default()
        if screen:
            monitor = screen.get_primary_monitor()
            if monitor is not None:
                geometry = screen.get_monitor_geometry(monitor)
                screen_width = geometry.width
                screen_height = geometry.height
            else: # fallback for no primary monitor
                screen_width = screen.get_width()
                screen_height = screen.get_height()
        else:
            # Fallback screen dimensions
            screen_width = 1920
            screen_height = 1080
        
        # Calculate position from center coordinates
        pos_x = self.clock_x - actual_width // 2
        pos_y = self.clock_y - actual_height // 2 - 50 # Move up by 50 pixels
        
        # Ensure the clock stays within screen bounds
        margin = 10  # Small margin to avoid edge clipping
        pos_x = max(margin, min(pos_x, screen_width - actual_width - margin))
        pos_y = max(margin, min(pos_y, screen_height - actual_height - margin))
        
        # Animate to new position if it changed
        if pos_x != self.target_x or pos_y != self.target_y:
            self.animate_to_position(pos_x, pos_y)
        
        return False
        
    def apply_dynamic_styling(self, color):
        """Apply dynamic styling without shadows, using brightness-based colors."""
        css_provider = Gtk.CssProvider()
        css = f"""
        label {{
            color: {color};
        }}
        
        .menu-button {{
            color: {color};
            font-size: 14px;
            font-weight: bold;
            opacity: 0.0;
            transition: opacity 0.3s ease;
            padding: 4px 8px;
            border-radius: 6px;
            margin-top: 4px;
            min-width: 20px;
            min-height: 20px;
        }}
        
        .menu-button:hover {{
            background-color: rgba(128, 128, 128, 0.2);
            opacity: 0.9;
        }}
        """
        css_provider.load_from_data(css.encode())
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(
                screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
    
    def apply_css_styling(self):
        """Apply basic CSS styling."""
        css_provider = Gtk.CssProvider()
        css = """
        window, overlay, box, label, button {
            background-color: transparent;
            border: none;
        }
        """
        css_provider.load_from_data(css.encode())
        screen = Gdk.Screen.get_default()
        if screen:
            Gtk.StyleContext.add_provider_for_screen(
                screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            
    def get_background_analysis(self):
        """Read background analysis from external file."""
        try:
            if os.path.exists(self.empty_areas_file):
                with open(self.empty_areas_file, 'r') as f:
                    data = json.load(f)
                    if 'analysis' in data:
                        return {
                            'brightness': float(data['analysis'].get('background_brightness', 0.5)),
                            'is_bright': data['analysis'].get('is_bright_background', False),
                            'is_dark': data['analysis'].get('is_dark_background', False)
                        }
        except (IOError, json.JSONDecodeError, KeyError, ValueError):
            pass
        return {'brightness': 0.5, 'is_bright': False, 'is_dark': False}
    
    def adapt_color_for_background(self, hex_color, background_analysis):
        """Dynamically adapt color based on actual background brightness."""
        brightness = background_analysis['brightness']
        is_bright = background_analysis['is_bright']
        is_dark = background_analysis['is_dark']
        
        if is_bright or brightness > 0.7:
            # For bright backgrounds, use a darker but not black color
            return self.darken_color(hex_color, 0.6)  # Darken the primary color
        elif is_dark or brightness < 0.3:
            # For dark backgrounds, use a lighter but not pure white color
            return self.lighten_color(hex_color, 0.4)  # Lighten the primary color
        elif brightness > 0.5:
            # Medium-bright background - slightly darker primary
            return self.darken_color(hex_color, 0.2)
        else:
            # Medium-dark background - slightly lighter primary
            return self.lighten_color(hex_color, 0.2)
    
    def darken_color(self, hex_color, factor):
        """Darken a hex color by the given factor (0-1)."""
        try:
            # Remove # if present
            hex_color = hex_color.lstrip('#')
            
            # Convert to RGB
            r = int(hex_color[0:2], 16)
            g = int(hex_color[2:4], 16)
            b = int(hex_color[4:6], 16)
            
            # Darken by factor, but ensure it doesn't go too dark
            r = max(30, int(r * (1 - factor)))  # Minimum 30 to avoid pure black
            g = max(30, int(g * (1 - factor)))
            b = max(30, int(b * (1 - factor)))
            
            # Convert back to hex
            return f"#{r:02x}{g:02x}{b:02x}"
        except (ValueError, IndexError):
            return "#404040"  # Fallback to medium dark color
    
    def lighten_color(self, hex_color, factor):
        """Lighten a hex color by the given factor (0-1)."""
        try:
            # Remove # if present
            hex_color = hex_color.lstrip('#')
            
            # Convert to RGB
            r = int(hex_color[0:2], 16)
            g = int(hex_color[2:4], 16)
            b = int(hex_color[4:6], 16)
            
            # Lighten by factor, but ensure it doesn't go too bright
            r = min(225, int(r + (255 - r) * factor))  # Maximum 225 to avoid pure white
            g = min(225, int(g + (255 - g) * factor))
            b = min(225, int(b + (255 - b) * factor))
            
            # Convert back to hex
            return f"#{r:02x}{g:02x}{b:02x}"
        except (ValueError, IndexError):
            return "#c0c0c0"  # Fallback to medium light color

    def update_color_styling(self):
        """Update the clock's color based on background analysis."""
        background_analysis = self.get_background_analysis()
        adaptive_color = self.adapt_color_for_background(self.initial_primary_color, background_analysis)
        
        if adaptive_color != self.last_adaptive_color:
            self.apply_dynamic_styling(adaptive_color)
            self.last_adaptive_color = adaptive_color

    def update_time(self):
        """Update the time display."""
        now = datetime.now()
        
        # Use the last calculated adaptive color
        adaptive_color = self.last_adaptive_color or self.initial_primary_color
        
        time_str = now.strftime("%H:%M")
        self.time_label.set_markup(f'<span font="64" weight="bold" color="{adaptive_color}">{time_str}</span>')
        
        date_str = now.strftime("%A, %B %d")
        self.date_label.set_markup(f'<span font="24" color="{adaptive_color}">{date_str}</span>')
        
        return True
    
    def start_clock_update(self):
        """Start the clock update timer."""
        self.update_color_styling()
        self.update_time()
        GLib.timeout_add_seconds(1, self.update_time)
    
    def start_position_monitoring(self):
        """Monitor for position and color changes by watching file modification times."""
        self.last_empty_mtime = os.path.getmtime(self.empty_areas_file) if os.path.exists(self.empty_areas_file) else 0
        self.last_colors_mtime = os.path.getmtime(self.colors_file) if os.path.exists(self.colors_file) else 0
        
        GLib.timeout_add_seconds(5, self.check_updates)
    
    def check_updates(self):
        """Check if position or colors have been updated and refresh the UI."""
        position_updated = False
        colors_updated = False
        
        try:
            if os.path.exists(self.empty_areas_file):
                current_empty_mtime = os.path.getmtime(self.empty_areas_file)
                if current_empty_mtime > self.last_empty_mtime:
                    self.last_empty_mtime = current_empty_mtime
                    position_updated = True
                    
                    with open(self.empty_areas_file, 'r') as f:
                        data = json.load(f)
                        new_x_center = int(float(data['suggested_clock_position']['x']))
                        new_y_center = int(float(data['suggested_clock_position']['y']))
                        
                        # Only update if position actually changed
                        if new_x_center != self.clock_x or new_y_center != self.clock_y:
                            self.clock_x = new_x_center
                            self.clock_y = new_y_center
                        
            if os.path.exists(self.colors_file):
                current_colors_mtime = os.path.getmtime(self.colors_file)
                if current_colors_mtime > self.last_colors_mtime:
                    self.last_colors_mtime = current_colors_mtime
                    colors_updated = True
                    
                    with open(self.colors_file, 'r') as f:
                        data = json.load(f)
                        new_primary = data['colors']['dark']['primary']
                        if new_primary != self.initial_primary_color:
                            self.initial_primary_color = new_primary
                            
        except (IOError, json.JSONDecodeError, KeyError) as e:
            print(f"Error checking updates: {e}", file=sys.stderr)
            
        # If any of the configurations were updated, refresh the entire UI
        if position_updated or colors_updated:
            self.refresh_ui()
            
        return True
    
    def refresh_ui(self):
        """
        Forces a full UI refresh. This method handles both repositioning
        and recoloring to fix potential display issues.
        """
        self.position_clock()  # Re-position the clock with smooth animation
        self.update_color_styling() # Re-apply adaptive colors
        self.update_time()     # Re-render with new colors
    
    def animate_to_position(self, new_x, new_y):
        """Animate the clock to a new position with smooth easing."""
        if self.animation_active:
            return
            
        self.animation_active = True
        self.target_x = new_x
        self.target_y = new_y
        
        # Get current position
        start_x = self.clock_container.get_margin_start()
        start_y = self.clock_container.get_margin_top()
        
        # If positions are very close, just set directly
        if abs(new_x - start_x) < 5 and abs(new_y - start_y) < 5:
            self.clock_container.set_margin_start(new_x)
            self.clock_container.set_margin_top(new_y)
            self.animation_active = False
            return
        
        self.animation_duration = 1.5  # Smoother animation
        self.animation_start_time = time.time()
        self.animation_start_x = start_x
        self.animation_start_y = start_y
        
        GLib.timeout_add(16, self.animate_step_smooth)
    
    def ease_in_out_quart(self, t):
        """Quartic easing function for a more pronounced smooth animation."""
        if t < 0.5:
            return 8 * t * t * t * t
        else:
            return 1 - pow(-2 * t + 2, 4) / 2
    
    def animate_step_smooth(self):
        """Performs a single step of the smooth animation."""
        current_time = time.time()
        elapsed = current_time - self.animation_start_time
        progress = min(elapsed / self.animation_duration, 1.0)
        
        if progress >= 1.0:
            # Set final position exactly
            self.clock_container.set_margin_start(self.target_x)
            self.clock_container.set_margin_top(self.target_y)
            self.animation_active = False
            return False
        
        eased_progress = self.ease_in_out_quart(progress)
        
        current_x = int(self.animation_start_x + (self.target_x - self.animation_start_x) * eased_progress)
        current_y = int(self.animation_start_y + (self.target_y - self.animation_start_y) * eased_progress)
        
        self.clock_container.set_margin_start(current_x)
        self.clock_container.set_margin_top(current_y)
        
        return True
    
    def on_hover_enter(self, widget, event):
        """Show the menu button on hover."""
        self.menu_button.set_opacity(0.7)
        return False
    
    def on_hover_leave(self, widget, event):
        """Hide the menu button when not hovering."""
        self.menu_button.set_opacity(0.0)
        return False
    

    
    def on_menu_clicked(self, button):
        """Handle menu button click - opens a simple dialog."""
        dialog = Gtk.Window()
        dialog.set_title("Clock Menu")
        dialog.set_default_size(300, 200)
        dialog.set_position(Gtk.WindowPosition.CENTER)
        dialog.set_transient_for(self)
        
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        box.set_margin_start(20)
        box.set_margin_end(20)
        
        label = Gtk.Label("Clock Settings")
        label.get_style_context().add_class("title")
        box.pack_start(label, False, False, 0)
        
        placeholder_label = Gtk.Label("Menu options will be added here")
        box.pack_start(placeholder_label, True, True, 0)
        
        close_button = Gtk.Button.new_with_label("Close")
        close_button.connect("clicked", lambda x: dialog.destroy())
        box.pack_start(close_button, False, False, 0)
        
        dialog.add(box)
        dialog.show_all()
        return True

def main():
    parser = argparse.ArgumentParser(description='GTK Layer Shell Clock')
    parser.add_argument('--x', type=int, default=100, help='X position')
    parser.add_argument('--y', type=int, default=100, help='Y position')
    parser.add_argument('--anchor', default='center', help='Anchor position (ignored in fullscreen mode)')
    parser.add_argument('--primary-color', default='#6750a4', help='Primary color')
    parser.add_argument('--text-color', default='#ffffff', help='Text color')
    parser.add_argument('--bg-color', default='#1c1b1f', help='Background color')
    
    args = parser.parse_args()
    
    clock = LayerClock(
        x=args.x,
        y=args.y,
        primary_color=args.primary_color,
        text_color=args.text_color,
        bg_color=args.bg_color
    )
    
    clock.show_all()
    
    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("\nClock stopped by user")
        sys.exit(0)

if __name__ == "__main__":
    main()