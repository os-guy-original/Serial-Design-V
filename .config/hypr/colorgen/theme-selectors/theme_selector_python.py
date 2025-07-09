#!/usr/bin/env python3

import os
import sys
import subprocess
import threading
import time

# Add debug output
DEBUG = True

def debug(message):
    if DEBUG:
        print(f"[PYTHON DEBUG] {message}", file=sys.stderr)

debug("Starting Python theme selector script")
debug(f"Python version: {sys.version}")

try:
    debug("Attempting to import gi module")
    import gi
    debug("Successfully imported gi module")
    
    # Require GTK 3.0
    debug("Setting GTK version requirement")
    gi.require_version("Gtk", "3.0")
    debug("Successfully set GTK version requirement")
    
    debug("Importing Gtk and related modules")
    from gi.repository import Gtk, Gdk
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

class ThemeSelectorDialog(Gtk.Window):
    def __init__(self):
        try:
            debug("Initializing ThemeSelectorDialog")
            Gtk.Window.__init__(self, title="Theme Selection")
            
            # Set up window properties
            self.set_default_size(340, 200)
            self.set_resizable(False)
            self.set_position(Gtk.WindowPosition.CENTER)
            self.set_border_width(15)
            
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
            
            # Main container
            main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
            self.add(main_box)
            
            # Title label
            title_label = Gtk.Label()
            title_label.set_markup("<span size='large' weight='bold'>Select your preferred theme</span>")
            main_box.pack_start(title_label, False, False, 0)
            
            # Theme options container
            themes_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
            themes_box.set_homogeneous(True)
            main_box.pack_start(themes_box, True, True, 0)
            
            # Light theme button
            self.light_button = self.create_theme_button("Light Theme", "weather-clear", True)
            themes_box.pack_start(self.light_button, True, True, 0)
            
            # Dark theme button
            self.dark_button = self.create_theme_button("Dark Theme", "weather-clear-night", False)
            themes_box.pack_start(self.dark_button, True, True, 0)
            
            # Cancel button
            cancel_button = Gtk.Button.new_with_label("Cancel")
            cancel_button.connect("clicked", self.on_cancel_clicked)
            main_box.pack_start(cancel_button, False, False, 0)
            
            # Apply CSS styling
            self.apply_css()
            debug("ThemeSelectorDialog initialized successfully")
        except Exception as e:
            debug(f"Error initializing ThemeSelectorDialog: {e}")
            raise
    
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
            
            # Add custom class for light/dark button
            if is_light:
                button.get_style_context().add_class("light-button")
            else:
                button.get_style_context().add_class("dark-button")
            
            # Create a container for the button content
            button_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            button.add(button_box)
            
            # Add icon (always visible)
            icon = Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.DIALOG)
            button_box.pack_start(icon, False, False, 0)
            
            # Add empty space to push label down a bit
            spacer = Gtk.Label(label="")
            spacer.set_size_request(-1, 5)  # 5 pixels of vertical space
            button_box.pack_start(spacer, False, False, 0)
            
            # Add label
            label = Gtk.Label(label=label_text)
            button_box.pack_start(label, False, False, 0)
            
            # Add experimental label for light theme
            if is_light:
                experimental_label = Gtk.Label()
                experimental_label.set_markup("<span size='small' style='italic' foreground='#FF5555'>(Experimental)</span>")
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
            
            css = f"""
            button {{
                padding: 10px;
                border-radius: 8px;
            }}
            
            #theme-button {{
                min-height: 100px;
                transition: all 200ms ease;
            }}
            
            /* Use default GTK button styles by not specifying background/color */
            
            /* Change background on hover to match the theme they represent */
            .light-button:hover {{
                background-color: #ffffff;
                color: #000000;
            }}
            
            .dark-button:hover {{
                background-color: #2d2d2d;
                color: #ffffff;
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
        # Return "light" to stdout and exit
        debug("Light theme button clicked")
        print("light")
        Gtk.main_quit()
        sys.exit(0)
    
    def on_dark_clicked(self, button):
        # Return "dark" to stdout and exit
        debug("Dark theme button clicked")
        print("dark")
        Gtk.main_quit()
        sys.exit(0)
    
    def on_cancel_clicked(self, button):
        # Cancel without changing theme
        debug("Cancel button clicked")
        Gtk.main_quit()
        sys.exit(1)  # Signal that we haven't handled the theme
    
    def apply_theme_and_exit(self, theme_flag):
        # Extract the theme name from the flag
        theme = "dark" if theme_flag == "--force-dark" else "light"
        debug(f"Selected theme: {theme}")
        
        # Print the theme name to stdout and exit
        print(theme)
        Gtk.main_quit()
        sys.exit(0)

def main():
    try:
        debug("Creating ThemeSelectorDialog")
        # Create and show the dialog
        dialog = ThemeSelectorDialog()
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
    try:
        debug("Starting main function")
        main()
    except Exception as e:
        debug(f"Uncaught exception: {e}")
        print(f"Uncaught exception: {e}", file=sys.stderr)
        sys.exit(0)  # Exit with 0 to fall back to default theme 