import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk, Gio

class ControlCenter(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='org.example.controlcenter')
        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        self.win = Gtk.ApplicationWindow(application=app)
        self.win.set_title('Control Center')
        self.win.set_default_size(800, 600)

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.win.set_child(main_box)

        # Sidebar
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        sidebar.set_size_request(200, -1)
        sidebar.add_css_class('sidebar')
        main_box.append(sidebar)

        # Content area
        self.content = Gtk.Stack()
        self.content.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        main_box.append(self.content)

        # Add sidebar items
        categories = [
            ('System', 'system-settings-symbolic'),
            ('Display', 'video-display-symbolic'),
            ('Sound', 'audio-volume-high-symbolic'),
            ('Network', 'network-wireless-symbolic'),
        ]

        for name, icon_name in categories:
            button = Gtk.Button()
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            icon = Gtk.Image.new_from_icon_name(icon_name)
            label = Gtk.Label(label=name)
            
            box.append(icon)
            box.append(label)
            button.set_child(box)
            
            sidebar.append(button)

        self.win.present()

if __name__ == '__main__':
    app = ControlCenter()
    app.run(None)
