#!/usr/bin/env python3

import os
import sys
import subprocess
import threading
import time

# Add debug output
DEBUG = True

# Global variable to store wallpaper path
WALLPAPER_PATH = None

def debug(message):
    if DEBUG:
        print(f"[PYTHON DEBUG] {message}", file=sys.stderr)
        # Also log to file
        try:
            home = os.path.expanduser("~")
            log_dir = os.path.join(home, ".config", "hypr", "cache", "logs")
            os.makedirs(log_dir, exist_ok=True)
            log_file = os.path.join(log_dir, "theme_selector.log")
            with open(log_file, "a") as f:
                f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}\n")
        except Exception as e:
            print(f"[PYTHON DEBUG] Error writing to log file: {e}", file=sys.stderr)

debug("Starting Python theme selector script")
debug(f"Python version: {sys.version}")
debug(f"Process ID: {os.getpid()}")
debug(f"Parent Process ID: {os.getppid()}")
debug(f"Command line arguments: {sys.argv}")

try:
    debug("Attempting to import gi module")
    import gi
    debug("Successfully imported gi module")
    
    # Require GTK 3.0
    debug("Setting GTK version requirement")
    gi.require_version("Gtk", "3.0")
    debug("Successfully set GTK version requirement")
    
    # Try to import GTK Layer Shell if available
    try:
        debug("Attempting to import GTK Layer Shell")
        gi.require_version('GtkLayerShell', '0.1')
        from gi.repository import GtkLayerShell
        HAS_LAYER_SHELL = True
        debug("Successfully imported GTK Layer Shell")
    except (ImportError, ValueError):
        HAS_LAYER_SHELL = False
        debug("GTK Layer Shell not available, falling back to regular window")
    
    debug("Importing Gtk and related modules")
    from gi.repository import Gtk, Gdk, GLib, GdkPixbuf
    import cairo
    debug("Successfully imported Gtk and related modules")
except ImportError as e:
    debug(f"Import error: {e}")
    print(f"Error importing GTK libraries: {e}", file=sys.stderr)
    print("Please install PyGObject: sudo [your-package-manager] install python3-gobject", file=sys.stderr)
    sys.exit(0)  # Exit with 0 to fall back to default theme
except Exception as e:
    debug(f"Unexpected error during imports: {e}")
    print(f"Unexpected error: {e}", file=sys.stderr)
    sys.exit(0)  # Exit with 0 to fall back to default theme

class WallpaperPreviewWindow(Gtk.Window):
    def __init__(self, wallpaper_path):
        try:
            debug(f"Initializing WallpaperPreviewWindow with wallpaper: {wallpaper_path}")
            Gtk.Window.__init__(self, title="Wallpaper Preview")
            
            # Set window name for WM identification
            self.set_name("wallpaper-preview")
            self.set_wmclass("wallpaper-preview", "wallpaper-preview")
            
            # Make window transparent
            screen = self.get_screen()
            visual = screen.get_rgba_visual()
            if visual and screen.is_composited():
                self.set_visual(visual)
                self.set_app_paintable(True)
                self.connect("draw", self.on_draw)
            
            # Set up window properties - rounded rectangle
            self.set_default_size(300, 200)  # Rectangular for wallpaper aspect ratio
            self.set_resizable(False)
            self.set_decorated(False)  # Remove window decorations
            
            # Animation properties
            self.opacity = 0.0
            self.set_opacity(self.opacity)
            self.animation_active = True
            self.animation_start_time = None
            
            # Get monitor dimensions for positioning
            self.display = Gdk.Display.get_default()
            self.monitor = self.display.get_primary_monitor() or self.display.get_monitor(0)
            if self.monitor:
                self.monitor_geometry = self.monitor.get_geometry()
            else:
                screen = Gdk.Screen.get_default()
                self.monitor_geometry = Gdk.Rectangle()
                self.monitor_geometry.width = screen.get_width()
                self.monitor_geometry.height = screen.get_height()
            
            # If we have layer shell, configure it
            if HAS_LAYER_SHELL:
                GtkLayerShell.init_for_window(self)
                GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, False)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, False)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, False)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, False)
                GtkLayerShell.set_exclusive_zone(self, -1)
            else:
                self.set_position(Gtk.WindowPosition.NONE)  # We'll position manually
            
            # Create the wallpaper image
            self.create_wallpaper_image(wallpaper_path)
            
            # Connect size-allocate to position window
            self.connect("size-allocate", self.on_size_allocate)
            
            debug("WallpaperPreviewWindow initialized successfully")
        except Exception as e:
            debug(f"Error initializing WallpaperPreviewWindow: {e}")
            raise
    
    def create_wallpaper_image(self, wallpaper_path):
        try:
            # Store wallpaper path for drawing
            self.wallpaper_path = wallpaper_path
            self.wallpaper_pixbuf = None
            
            # Load and prepare the wallpaper
            if os.path.exists(wallpaper_path):
                try:
                    # Load the image
                    pixbuf = GdkPixbuf.Pixbuf.new_from_file(wallpaper_path)
                    
                    # Scale to fit the rounded window (300x200)
                    original_width = pixbuf.get_width()
                    original_height = pixbuf.get_height()
                    target_width = 300
                    target_height = 200
                    
                    # Calculate scale to fill the window (crop to fit)
                    scale_x = target_width / original_width
                    scale_y = target_height / original_height
                    scale = max(scale_x, scale_y)  # Use max to fill, not fit
                    
                    # Calculate new dimensions
                    new_width = int(original_width * scale)
                    new_height = int(original_height * scale)
                    
                    # Scale the pixbuf
                    scaled_pixbuf = pixbuf.scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)
                    
                    # Crop to center if needed
                    if new_width > target_width or new_height > target_height:
                        crop_x = max(0, (new_width - target_width) // 2)
                        crop_y = max(0, (new_height - target_height) // 2)
                        self.wallpaper_pixbuf = scaled_pixbuf.new_subpixbuf(crop_x, crop_y, 
                                                                           min(target_width, new_width), 
                                                                           min(target_height, new_height))
                    else:
                        self.wallpaper_pixbuf = scaled_pixbuf
                    
                    debug(f"Loaded wallpaper for rounded preview: {self.wallpaper_pixbuf.get_width()}x{self.wallpaper_pixbuf.get_height()}")
                except Exception as e:
                    debug(f"Error loading wallpaper image: {e}")
                    self.wallpaper_pixbuf = None
            else:
                debug(f"Wallpaper file not found: {wallpaper_path}")
                self.wallpaper_pixbuf = None
            
            # Apply CSS for the circular window
            self.apply_preview_css()
            
        except Exception as e:
            debug(f"Error creating wallpaper image: {e}")
            self.wallpaper_pixbuf = None
    
    def apply_preview_css(self):
        try:
            css_provider = Gtk.CssProvider()
            css = """
            window.wallpaper-preview {
                border-radius: 20px;
                background: transparent;
            }
            """
            
            css_provider.load_from_data(css.encode())
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            
            # Add CSS class to window
            self.get_style_context().add_class("wallpaper-preview")
        except Exception as e:
            debug(f"Error applying preview CSS: {e}")
    
    def on_draw(self, widget, cr):
        # Draw rounded rectangle wallpaper background
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        radius = 20  # Corner radius for rounded rectangle
        
        # Create rounded rectangle clipping path
        degrees = 3.14159 / 180.0
        cr.new_sub_path()
        cr.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees)
        cr.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees)
        cr.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees)
        cr.arc(radius, radius, radius, 180 * degrees, 270 * degrees)
        cr.close_path()
        cr.clip()
        
        if self.wallpaper_pixbuf:
            # Draw the wallpaper as background
            Gdk.cairo_set_source_pixbuf(cr, self.wallpaper_pixbuf, 
                                       (width - self.wallpaper_pixbuf.get_width()) / 2,
                                       (height - self.wallpaper_pixbuf.get_height()) / 2)
            cr.paint_with_alpha(self.opacity)
        else:
            # Fallback: draw a gradient background
            pattern = cairo.LinearGradient(0, 0, width, height)
            pattern.add_color_stop_rgba(0, 0.3, 0.3, 0.3, self.opacity)
            pattern.add_color_stop_rgba(1, 0.1, 0.1, 0.1, self.opacity)
            cr.set_source(pattern)
            cr.paint()
        
        # Add a subtle border
        cr.reset_clip()
        cr.new_sub_path()
        cr.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees)
        cr.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees)
        cr.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees)
        cr.arc(radius, radius, radius, 180 * degrees, 270 * degrees)
        cr.close_path()
        cr.set_source_rgba(1, 1, 1, 0.3 * self.opacity)
        cr.set_line_width(2)
        cr.stroke()
        
        return False
    
    def on_size_allocate(self, widget, allocation):
        if self.animation_active and self.animation_start_time is None:
            # Position the window above where the theme selector will appear
            window_width, window_height = self.get_size()
            
            # Calculate position: center horizontally, and above the theme selector
            # Theme selector appears at bottom with 20px margin, so position this higher
            target_x = (self.monitor_geometry.width - window_width) // 2
            target_y = self.monitor_geometry.height - 200 - window_height  # 200px above bottom
            
            if not HAS_LAYER_SHELL:
                self.move(target_x, target_y)
            
            # Start fade-in animation
            self.animation_start_time = time.time() * 1000
            GLib.timeout_add(16, self.update_animation)
    
    def update_animation(self):
        if not self.animation_active:
            return False
        
        current_time = time.time() * 1000
        elapsed = current_time - self.animation_start_time
        duration = 300
        
        if elapsed >= duration:
            self.animation_active = False
            self.opacity = 1.0
            self.set_opacity(self.opacity)
            self.queue_draw()
            return False
        else:
            progress = elapsed / duration
            t = progress
            ease_factor = 1 - (1 - t) * (1 - t) * (1 - t)
            self.opacity = ease_factor
            self.set_opacity(self.opacity)
            self.queue_draw()
            return True
    
    def start_fade_out(self):
        """Start fade-out animation"""
        self.animation_active = True
        self.animation_start_time = time.time() * 1000
        GLib.timeout_add(16, self.update_fade_out)
    
    def update_fade_out(self):
        if not self.animation_active:
            return False
        
        current_time = time.time() * 1000
        elapsed = current_time - self.animation_start_time
        duration = 200
        
        if elapsed >= duration:
            self.animation_active = False
            self.hide()
            return False
        else:
            progress = elapsed / duration
            self.opacity = 1.0 - progress
            self.set_opacity(self.opacity)
            self.queue_draw()
            return True

# Define paths for theme-to-apply file
HOME_DIR = os.path.expanduser("~")
CACHE_DIR = os.path.join(HOME_DIR, ".config", "hypr", "cache")
TEMP_DIR = os.path.join(CACHE_DIR, "temp")
THEME_TO_APPLY_FILE = os.path.join(TEMP_DIR, "theme-to-apply")

# Ensure temp directory exists
os.makedirs(TEMP_DIR, exist_ok=True)

debug(f"Theme-to-apply file path: {THEME_TO_APPLY_FILE}")
debug(f"Checking if theme-to-apply file exists: {os.path.exists(THEME_TO_APPLY_FILE)}")

class ThemeSelectorDialog(Gtk.Window):
    def __init__(self, wallpaper_preview_window=None):
        try:
            debug("Initializing ThemeSelectorDialog")
            Gtk.Window.__init__(self, title="Theme Selection")
            
            # Store reference to wallpaper preview window
            self.wallpaper_preview_window = wallpaper_preview_window
            
            # Set window name for WM identification
            self.set_name("serialdesignv")
            self.set_wmclass("serialdesignv", "serialdesignv")
            debug("Set window name to 'serialdesignv'")
            
            # Make window transparent to allow for rounded corners and fade effect
            screen = self.get_screen()
            visual = screen.get_rgba_visual()
            if visual and screen.is_composited():
                self.set_visual(visual)
                self.set_app_paintable(True)
                self.connect("draw", self.on_draw)
                debug("Set window to use RGBA visual for transparency")
            
            # Set up window properties
            self.set_default_size(500, 100)  # Wider and shorter for the new layout
            self.set_resizable(False)
            
            # Animation properties
            self.animation_active = True
            self.animation_progress = 0.0
            self.animation_duration = 300  # milliseconds
            self.animation_start_time = None
            self.bottom_margin = 20  # Distance from bottom of screen
            self.opacity = 0.0  # Start fully transparent
            self.set_opacity(self.opacity)
            
            # Fade-out animation properties
            self.fade_out_active = False
            self.fade_out_start_time = None
            self.selected_theme = None
            
            # Get monitor dimensions for positioning
            self.display = Gdk.Display.get_default()
            self.monitor = self.display.get_primary_monitor() or self.display.get_monitor(0)
            if self.monitor:
                self.monitor_geometry = self.monitor.get_geometry()
                debug(f"Monitor geometry: {self.monitor_geometry.width}x{self.monitor_geometry.height}")
            else:
                # Fallback for older systems
                screen = Gdk.Screen.get_default()
                self.monitor_geometry = Gdk.Rectangle()
                self.monitor_geometry.width = screen.get_width()
                self.monitor_geometry.height = screen.get_height()
                debug(f"Using fallback monitor geometry: {self.monitor_geometry.width}x{self.monitor_geometry.height}")
            
            # If we have layer shell, configure it
            if HAS_LAYER_SHELL:
                debug("Configuring as layer shell surface")
                GtkLayerShell.init_for_window(self)
                GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)  # Anchor to bottom
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, False)
                GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, False)
                GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, self.bottom_margin)
                GtkLayerShell.set_exclusive_zone(self, -1)  # Don't reserve space
                self.is_layer_shell = True
            else:
                debug("Using regular window positioning")
                self.set_position(Gtk.WindowPosition.NONE)  # We'll position manually
                self.is_layer_shell = False
            
            self.set_border_width(12)
            
            # Detect current theme (light or dark)
            self.is_dark_theme = self.detect_dark_theme()
            debug(f"Detected dark theme: {self.is_dark_theme}")
            
            # Check if we're being called from material_extract.sh
            self.from_material_extract = self.check_material_extract_process()
            debug(f"Called from material_extract: {self.from_material_extract}")
            
            # Set window icon
            try:
                self.set_icon_name("preferences-desktop-theme")
                debug("Set window icon")
            except Exception as e:
                debug(f"Failed to set window icon: {e}")
                pass  # Icon not found, ignore
            
            # Main container with some padding
            outer_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            outer_box.set_border_width(8)  # Add some padding around the edges
            self.add(outer_box)
            
            # Create a horizontal box for the buttons (MD3 style)
            button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            button_box.set_homogeneous(False)  # Allow different widths
            outer_box.pack_start(button_box, True, True, 0)
            
            # Dark theme button (left)
            self.dark_button = self.create_theme_button("Dark", "weather-clear-night", False)
            button_box.pack_start(self.dark_button, True, True, 0)
            
            # Light theme button (middle)
            self.light_button = self.create_theme_button("Light", "weather-clear", True)
            button_box.pack_start(self.light_button, True, True, 0)
            
            # Cancel button (right)
            cancel_button = Gtk.Button.new_with_label("Cancel")
            cancel_button.connect("clicked", self.on_cancel_clicked)
            cancel_button.get_style_context().add_class("pill-button")
            cancel_button.get_style_context().add_class("cancel-button")
            cancel_button.set_size_request(80, -1)  # Set a fixed width for the cancel button
            button_box.pack_end(cancel_button, False, False, 0)
            
            # Apply CSS styling
            self.apply_css()
            
            # Connect size-allocate to get the window's final size
            self.connect("size-allocate", self.on_size_allocate)
            
            debug("ThemeSelectorDialog initialized successfully")
        except Exception as e:
            debug(f"Error initializing ThemeSelectorDialog: {e}")
            raise
    
    def on_draw(self, widget, cr):
        # Draw rounded rectangle for window background
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        
        # Get style context to use default GTK theme colors
        style_context = widget.get_style_context()
        bg_color = style_context.get_background_color(Gtk.StateFlags.NORMAL)
        
        # Use the default GTK theme background color with transparency
        cr.set_source_rgba(bg_color.red, bg_color.green, bg_color.blue, 0.95 * self.opacity)
        
        # Draw pill-shaped background
        radius = height / 2  # Half height for perfect pill shape
        degrees = 3.14159 / 180.0
        
        # Draw rounded rectangle (pill shape)
        cr.new_sub_path()
        cr.arc(width - radius, radius, radius, -90 * degrees, 90 * degrees)
        cr.arc(width - radius, height - radius, radius, 0, 90 * degrees)
        cr.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees)
        cr.arc(radius, radius, radius, 180 * degrees, 270 * degrees)
        cr.close_path()
        
        cr.fill()
        
        return False
    
    def on_size_allocate(self, widget, allocation):
        # This is called when the window size is allocated
        # We use this to position the window and start the fade-in animation
        if self.animation_active and self.animation_start_time is None:
            # Start the fade-in animation
            self.animation_start_time = time.time() * 1000
            
            # Position the window properly
            if not self.is_layer_shell:
                window_width, window_height = self.get_size()
                target_y = self.monitor_geometry.height - window_height - self.bottom_margin
                self.move((self.monitor_geometry.width - window_width) // 2, target_y)
            
            # Start fade-in animation
            GLib.timeout_add(16, self.update_fade_in_animation)
            
            debug(f"Starting fade-in animation")
    
    def update_fade_in_animation(self):
        if not self.animation_active:
            return False
            
        # Calculate animation progress
        current_time = time.time() * 1000
        elapsed = current_time - self.animation_start_time
        
        if elapsed >= self.animation_duration:
            # Animation complete
            self.animation_active = False
            self.animation_progress = 1.0
            self.opacity = 1.0
            
            # Set final opacity
            self.set_opacity(self.opacity)
            
            # Force a final redraw
            self.queue_draw()
            
            debug("Fade-in animation complete")
            return False
        else:
            # Animation in progress
            self.animation_progress = elapsed / self.animation_duration
            
            # Use ease-out cubic function for smoother animation
            t = self.animation_progress
            ease_factor = 1 - (1 - t) * (1 - t) * (1 - t)
            
            # Calculate current opacity
            self.opacity = ease_factor
            
            # Update opacity
            self.set_opacity(self.opacity)
            
            # Force redraw during animation
            self.queue_draw()
            
            debug(f"Fade-in animation progress: {self.animation_progress:.2f}, opacity={self.opacity:.2f}")
            
            # Continue animation
            return True
    
    def start_fade_out_animation(self, theme=None):
        # Start fade-out animation before closing
        if self.fade_out_active:
            return
        
        self.fade_out_active = True
        self.fade_out_start_time = time.time() * 1000
        self.selected_theme = theme
        
        # If theme is selected, write it to the theme-to-apply file
        if theme:
            try:
                debug(f"Writing theme '{theme}' to {THEME_TO_APPLY_FILE}")
                with open(THEME_TO_APPLY_FILE, 'w') as f:
                    f.write(theme)
                debug(f"Successfully wrote theme '{theme}' to {THEME_TO_APPLY_FILE}")
                debug(f"File exists after write: {os.path.exists(THEME_TO_APPLY_FILE)}")
                debug(f"File permissions: {oct(os.stat(THEME_TO_APPLY_FILE).st_mode & 0o777)}")
                debug(f"File content: {open(THEME_TO_APPLY_FILE, 'r').read()}")
            except Exception as e:
                debug(f"Error writing theme to file: {e}")
        
        # Start fade-out animation for wallpaper preview window
        if self.wallpaper_preview_window:
            self.wallpaper_preview_window.start_fade_out()
        
        # Start fade-out animation
        GLib.timeout_add(16, self.update_fade_out_animation)
        
        debug(f"Starting fade-out animation with theme: {theme}")
    
    def update_fade_out_animation(self):
        if not self.fade_out_active:
            return False
            
        # Calculate animation progress
        current_time = time.time() * 1000
        elapsed = current_time - self.fade_out_start_time
        
        if elapsed >= self.animation_duration:
            # Animation complete - close window and return selected theme
            self.fade_out_active = False
            
            # Exit with selected theme
            if self.selected_theme:
                print(self.selected_theme)
                Gtk.main_quit()
                sys.exit(0)
            else:
                # If no theme selected, exit with cancel code
                Gtk.main_quit()
                sys.exit(1)
                
            return False
        else:
            # Animation in progress
            progress = elapsed / self.animation_duration
            
            # Use ease-in cubic function for smoother animation
            t = progress
            ease_factor = t * t * t
            
            # Calculate current opacity (fade out)
            self.opacity = 1.0 - ease_factor
            
            # Update opacity
            self.set_opacity(self.opacity)
            
            # Force redraw during animation
            self.queue_draw()
            
            debug(f"Fade-out animation progress: {progress:.2f}, opacity={self.opacity:.2f}")
            
            # Continue animation
            return True
    
    def check_material_extract_process(self):
        """Check if we're being called from material_extract.sh"""
        try:
            # Check if material_extract.sh is in the parent process tree
            result = subprocess.run(
                ["ps", "-o", "cmd", "--ppid", str(os.getppid()), "-p", str(os.getppid())],
                capture_output=True, text=True
            )
            return "material_extract" in result.stdout or os.path.exists("/tmp/material_extract_running")
        except Exception as e:
            debug(f"Error checking material_extract process: {e}")
            return False
        
    def create_theme_button(self, label_text, icon_name, is_light):
        try:
            # Create a button with an icon and label
            button = Gtk.Button()
            button.set_name("theme-button")
            
            # Add custom classes for styling
            button.get_style_context().add_class("pill-button")
            if is_light:
                button.get_style_context().add_class("light-button")
            else:
                button.get_style_context().add_class("dark-button")
            
            # Create a container for the button content
            button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            button.add(button_box)
            
            # Add icon with rounded corners using CSS
            icon = Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.LARGE_TOOLBAR)
            icon.get_style_context().add_class("super-rounded-icon")
            button_box.pack_start(icon, False, False, 0)
            
            # Add label
            label = Gtk.Label(label=label_text)
            button_box.pack_start(label, False, False, 0)
            
            # Add experimental label for light theme
            if is_light:
                experimental_label = Gtk.Label()
                experimental_label.set_markup("<span size='small' style='italic' foreground='#FF5555'> (Experimental)</span>")
                button_box.pack_start(experimental_label, False, False, 0)
            
            # Connect click handler
            if is_light:
                button.connect("clicked", self.on_light_clicked)
            else:
                button.connect("clicked", self.on_dark_clicked)
            
            return button
        except Exception as e:
            debug(f"Error creating theme button: {e}")
            raise
    
    def detect_dark_theme(self):
        # Try to detect if the current theme is dark
        try:
            # Check if a dark theme is currently in use
            settings = Gtk.Settings.get_default()
            theme_name = settings.get_property("gtk-theme-name").lower()
            return "dark" in theme_name
        except Exception as e:
            debug(f"Error detecting dark theme: {e}")
            # Default to assuming a light theme
            return False
    
    def apply_css(self):
        try:
            # Apply custom CSS styling
            css_provider = Gtk.CssProvider()
            
            # Determine icon color based on current theme
            icon_color = "white" if self.is_dark_theme else "black"
            accent_color = "#7aa2f7"  # Blue accent color
            cancel_text_color = "white" if self.is_dark_theme else "#333333"  # Dark text for light mode
            
            css = f"""
            button {{
                padding: 8px 12px;
            }}
            
            .pill-button {{
                border-radius: 9999px;  /* Very large value creates pill shape */
                transition: all 200ms ease;
            }}
            
            #theme-button {{
                min-width: 120px;
            }}
            
            /* Theme-specific button styles */
            .light-button {{
                background-color: rgba(255, 255, 255, 0.1);
                color: {icon_color};
                border: 1px solid rgba(255, 255, 255, 0.2);
            }}
            
            .dark-button {{
                background-color: rgba(0, 0, 0, 0.1);
                color: {icon_color};
                border: 1px solid rgba(0, 0, 0, 0.2);
            }}
            
            .cancel-button {{
                background-color: rgba(255, 80, 80, 0.1);
                border: 1px solid rgba(255, 80, 80, 0.2);
                color: {cancel_text_color};
            }}
            
            /* Hover effects */
            .light-button:hover {{
                background-color: rgba(255, 255, 255, 0.2);
                border-color: rgba(255, 255, 255, 0.3);
            }}
            
            .dark-button:hover {{
                background-color: rgba(0, 0, 0, 0.2);
                border-color: rgba(0, 0, 0, 0.3);
            }}
            
            .cancel-button:hover {{
                background-color: rgba(255, 80, 80, 0.2);
                border-color: rgba(255, 80, 80, 0.3);
                color: {cancel_text_color};
            }}
            
            /* Active effects */
            .light-button:active {{
                background-color: rgba(255, 255, 255, 0.3);
            }}
            
            .dark-button:active {{
                background-color: rgba(0, 0, 0, 0.3);
            }}
            
            .cancel-button:active {{
                background-color: rgba(255, 80, 80, 0.3);
                color: {cancel_text_color};
            }}
            
            .rounded-icon {{
                border-radius: 50%;
                background-color: rgba(0, 0, 0, 0.1);
                padding: 4px;
                min-width: 24px;
                min-height: 24px;
            }}
            
            .super-rounded-icon {{
                border-radius: 50%;
                background-color: rgba(0, 0, 0, 0.1);
                padding: 8px;
                min-width: 32px;
                min-height: 32px;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
            }}
            
            .dark-button .rounded-icon,
            .dark-button .super-rounded-icon {{
                background-color: rgba(255, 255, 255, 0.1);
            }}
            
            .light-button .rounded-icon,
            .light-button .super-rounded-icon {{
                background-color: rgba(0, 0, 0, 0.1);
            }}
            
            image {{
                -gtk-icon-shadow: 0 1px 2px rgba(0,0,0,0.3);
                color: {icon_color};
            }}
            """
            
            debug("Loading CSS data")
            css_provider.load_from_data(css.encode())
            
            debug("Adding CSS provider to screen")
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            debug("CSS applied successfully")
        except Exception as e:
            debug(f"Error applying CSS: {e}")
            # Continue without CSS if there's an error
            pass
    
    def on_light_clicked(self, button):
        # Start fade-out animation with "light" theme
        debug("Light theme button clicked")
        self.start_fade_out_animation("light")
    
    def on_dark_clicked(self, button):
        # Start fade-out animation with "dark" theme
        debug("Dark theme button clicked")
        self.start_fade_out_animation("dark")
    
    def on_cancel_clicked(self, button):
        # Kill empty area finder processes when user cancels
        debug("Cancel button clicked - killing empty area finder processes")
        try:
            import subprocess
            subprocess.run(["/bin/bash", os.path.expanduser("~/.config/hypr/colorgen/kill_empty_area_finder.sh")], 
                         capture_output=True)
            debug("Empty area finder processes killed")
        except Exception as e:
            debug(f"Error killing empty area finder processes: {e}")
        
        # Start fade-out animation with no theme (cancel)
        debug("Cancel button clicked")
        self.start_fade_out_animation()
    
    def apply_theme_and_exit(self, theme_flag):
        # Extract the theme name from the flag
        theme = "dark" if theme_flag == "--force-dark" else "light"
        debug(f"Selected theme: {theme}")
        
        # Write theme to theme-to-apply file
        try:
            debug(f"Writing theme '{theme}' to {THEME_TO_APPLY_FILE}")
            with open(THEME_TO_APPLY_FILE, 'w') as f:
                f.write(theme)
            debug(f"Successfully wrote theme '{theme}' to {THEME_TO_APPLY_FILE}")
            debug(f"File exists after write: {os.path.exists(THEME_TO_APPLY_FILE)}")
            debug(f"File permissions: {oct(os.stat(THEME_TO_APPLY_FILE).st_mode & 0o777)}")
            debug(f"File content: {open(THEME_TO_APPLY_FILE, 'r').read()}")
        except Exception as e:
            debug(f"Error writing theme to file: {e}")
        
        # Print the theme name to stdout and exit
        print(theme)
        Gtk.main_quit()
        sys.exit(0)

def main():
    try:
        debug("Starting main function")
        
        # Check for wallpaper path argument
        wallpaper_path = None
        for i, arg in enumerate(sys.argv):
            if arg == "--wallpaper" and i + 1 < len(sys.argv):
                wallpaper_path = sys.argv[i + 1]
                debug(f"Wallpaper path provided: {wallpaper_path}")
                break
        
        # Check for command-line arguments
        if len(sys.argv) > 1:
            debug(f"Command-line arguments: {sys.argv[1:]}")
            if "--force-dark" in sys.argv:
                debug("Force dark theme detected")
                # Write theme to theme-to-apply file
                try:
                    debug(f"Writing theme 'dark' to {THEME_TO_APPLY_FILE}")
                    with open(THEME_TO_APPLY_FILE, 'w') as f:
                        f.write("dark")
                    debug(f"Successfully wrote theme 'dark' to {THEME_TO_APPLY_FILE}")
                    debug(f"File exists after write: {os.path.exists(THEME_TO_APPLY_FILE)}")
                except Exception as e:
                    debug(f"Error writing theme to file: {e}")
                
                print("dark")
                sys.exit(0)  # Exit with success code
            elif "--force-light" in sys.argv:
                debug("Force light theme detected")
                # Write theme to theme-to-apply file
                try:
                    debug(f"Writing theme 'light' to {THEME_TO_APPLY_FILE}")
                    with open(THEME_TO_APPLY_FILE, 'w') as f:
                        f.write("light")
                    debug(f"Successfully wrote theme 'light' to {THEME_TO_APPLY_FILE}")
                    debug(f"File exists after write: {os.path.exists(THEME_TO_APPLY_FILE)}")
                except Exception as e:
                    debug(f"Error writing theme to file: {e}")
                
                print("light")
                sys.exit(0)  # Exit with success code
        
        # Create wallpaper preview window if wallpaper path is provided
        wallpaper_preview_window = None
        if wallpaper_path and os.path.exists(wallpaper_path):
            debug(f"Creating wallpaper preview window for: {wallpaper_path}")
            wallpaper_preview_window = WallpaperPreviewWindow(wallpaper_path)
            wallpaper_preview_window.show_all()
        
        debug("Creating ThemeSelectorDialog")
        # Create and show the dialog
        dialog = ThemeSelectorDialog(wallpaper_preview_window)
        dialog.connect("destroy", Gtk.main_quit)
        debug("Showing dialog")
        dialog.show_all()
        
        debug("Starting Gtk main loop")
        Gtk.main()
    except Exception as e:
        debug(f"Error in main: {e}")
        print(f"Error running theme selector: {e}", file=sys.stderr)
        sys.exit(0)  # Exit with 0 to fall back to default theme

if __name__ == "__main__":
    main()