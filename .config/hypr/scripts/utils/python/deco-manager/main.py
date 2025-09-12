#!/usr/bin/env python3

import os
import sys
import fcntl
import tempfile
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf

try:
    gi.require_version('GtkLayerShell', '0.1')
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ImportError, ValueError):
    HAS_LAYER_SHELL = False

def is_already_running():
    pid_file = os.path.join(tempfile.gettempdir(), "deco_changer.pid")

    # Try to open and lock the PID file
    try:
        pid_fd = os.open(pid_file, os.O_CREAT | os.O_RDWR)
        fcntl.flock(pid_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        # File is already locked, another instance is running
        print("Another instance of deco-changer is already running.")
        return True

    # If we got here, we successfully locked the file. Write our PID.
    os.ftruncate(pid_fd, 0)
    os.write(os.dup(pid_fd), str(os.getpid()).encode()) # Use os.dup to avoid issues with fcntl.flock and os.write
    os.close(pid_fd) # Close the file descriptor after writing

    # Register a cleanup function to remove the PID file on exit
    import atexit
    atexit.register(lambda: os.remove(pid_file))

    return False

# Call this at the very beginning of your script
if is_already_running():
    sys.exit(0)

class DecorationChanger(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Decoration Changer")

        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, False)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, False)
            GtkLayerShell.set_exclusive_zone(self, -1)
        else:
            self.set_position(Gtk.WindowPosition.CENTER)

        self.set_resizable(False)

        # Make window transparent to allow for rounded corners
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
            self.set_app_paintable(True)
            self.connect("draw", self.on_draw)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_border_width(10)
        self.add(vbox)

        title_label = Gtk.Label(label="Choose A Decoration Type")
        title_label.get_style_context().add_class("title-label")
        vbox.pack_start(title_label, False, False, 0)

        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        vbox.pack_start(hbox, True, True, 0)

        self.description_label = Gtk.Label(label="Hover The Mode To See It's Description Here")
        self.description_label.set_line_wrap(True)
        self.description_label.set_max_width_chars(50)
        vbox.pack_start(self.description_label, False, False, 0)

        cancel_button = Gtk.Button(label="Cancel")
        cancel_button.connect("clicked", lambda w: Gtk.main_quit())
        cancel_button.get_style_context().add_class("cancel-button")
        cancel_button.set_size_request(120, -1)

        self.decorations = self.get_decorations()
        self.script_dir = os.path.dirname(os.path.realpath(__file__))

        icon_mapping = {
            "performance.conf": "⚡",
            "balanced.conf": "⚖️",
            "full.conf": "✨",
        }

        decoration_descriptions = {
            "performance.conf": "Low blur, high performance.",
            "balanced.conf": "Medium blur, balanced performance and visuals.",
            "full.conf": "High blur, best visuals.",
        }
        self.decoration_descriptions = decoration_descriptions

        for decoration in self.decorations:
            button = Gtk.Button()
            button.connect("clicked", self.on_button_clicked, decoration)
            button.get_style_context().add_class("pill-button")
            button.set_size_request(120, -1)
            button.connect("enter-notify-event", self.on_button_enter, decoration)
            button.connect("leave-notify-event", self.on_button_leave)

            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            box.set_border_width(5)

            emoji = icon_mapping.get(decoration, "")
            if emoji:
                emoji_label = Gtk.Label(label=emoji)
                emoji_label.get_style_context().add_class("emoji-icon") # Add a class for potential styling
                box.pack_start(emoji_label, False, False, 0)

            label = Gtk.Label(label=decoration.replace(".conf", ""))
            box.pack_start(label, False, False, 0)

            button.add(box)
            hbox.pack_start(button, True, True, 0)

        hbox.pack_end(cancel_button, False, False, 0)
        hbox.pack_end(Gtk.Separator(orientation=Gtk.Orientation.VERTICAL), False, False, 0)

        self.apply_css()

    def on_draw(self, widget, cr):
        # Draw rounded rectangle for window background
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        radius = height / 2  # Half height for perfect pill shape
        
        # Get style context to use default GTK theme colors
        style_context = widget.get_style_context()
        bg_color = style_context.get_background_color(Gtk.StateFlags.NORMAL)
        
        # Use the default GTK theme background color with full opacity
        cr.set_source_rgba(bg_color.red, bg_color.green, bg_color.blue, 1.0)
        
        # Draw rounded rectangle
        degrees = 3.14159 / 180.0
        cr.new_sub_path()
        cr.arc(width - radius, radius, radius, -90 * degrees, 0 * degrees)
        cr.arc(width - radius, height - radius, radius, 0 * degrees, 90 * degrees)
        cr.arc(radius, height - radius, radius, 90 * degrees, 180 * degrees)
        cr.arc(radius, radius, radius, 180 * degrees, 270 * degrees)
        cr.close_path()
        
        cr.fill()
        
        return False

    def get_decorations(self):
        decorations_path = os.path.expanduser("~/.config/hypr/decorations")
        if os.path.isdir(decorations_path):
            return sorted([f for f in os.listdir(decorations_path) if f.endswith(".conf")])
        return []

    def on_button_clicked(self, widget, decoration):
        self.change_decoration(decoration)
        Gtk.main_quit()

    def change_decoration(self, decoration):
        hyprland_conf_path = os.path.expanduser("~/.config/hypr/hyprland.conf")
        if not os.path.isfile(hyprland_conf_path):
            return

        with open(hyprland_conf_path, "r") as f:
            lines = f.readlines()

        with open(hyprland_conf_path, "w") as f:
            for line in lines:
                if "source = ~/.config/hypr/decorations/" in line:
                    f.write(f"source =  ~/.config/hypr/decorations/{decoration}\n")
                else:
                    f.write(line)

    def apply_css(self):
        css_provider = Gtk.CssProvider()
        css_file = os.path.join(self.script_dir, "style.css")
        if os.path.exists(css_file):
            css_provider.load_from_path(css_file)
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

    def on_button_enter(self, widget, event, decoration):
        description = self.decoration_descriptions.get(decoration, "")
        self.description_label.set_text(description)

    def on_button_leave(self, widget, event):
        self.description_label.set_text("Hover The Mode To See It's Description Here")

if __name__ == "__main__":
    win = DecorationChanger()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()