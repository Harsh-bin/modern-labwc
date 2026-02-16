import sys
import os
import re
import glob
import ctypes
import gi

# Preload gtk4-layer-shell to prevent linker errors
try:
    ctypes.CDLL('libgtk4-layer-shell.so')
except OSError:
    try:
        ctypes.CDLL('/usr/lib/libgtk4-layer-shell.so')
    except OSError:
        pass

gi.require_version('Gtk', '4.0')
gi.require_version('Gtk4LayerShell', '1.0')
from gi.repository import Gtk, Gdk, Gtk4LayerShell

# Configuration
rofi_config_dir = os.path.expanduser("~/.config/rofi/colors")

# CSS Styling
css_provider = Gtk.CssProvider()
css_provider.load_from_string("""
    window { background: transparent; }
    .overlay { background: transparent; }
    .card {
        background: #1e1e2e;
        color: #cdd6f4;
        border-radius: 12px;
        padding: 24px;
        border: 1px solid #313244;
        box-shadow: 0 4px 8px rgba(0,0,0,0.5);
    }
    label { font-weight: bold; margin-bottom: 5px; }
    scale { margin-bottom: 15px; }
    scale trough { min-height: 4px; border-radius: 4px; }
""")
Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

class RofiTransparencyApp(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.init_layer_shell()
        self.init_ui()

    def init_layer_shell(self):
        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.EXCLUSIVE)
        for edge in [Gtk4LayerShell.Edge.TOP, Gtk4LayerShell.Edge.BOTTOM,
                     Gtk4LayerShell.Edge.LEFT, Gtk4LayerShell.Edge.RIGHT]:
            Gtk4LayerShell.set_anchor(self, edge, True)

    def init_ui(self):
        self.overlay_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.overlay_box.set_halign(Gtk.Align.FILL)
        self.overlay_box.set_valign(Gtk.Align.FILL)
        self.overlay_box.add_css_class("overlay")

        center_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        center_box.set_halign(Gtk.Align.CENTER)
        center_box.set_valign(Gtk.Align.CENTER)
        center_box.set_hexpand(True)
        center_box.set_vexpand(True)

        self.card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.card_box.set_size_request(350, -1)
        self.card_box.add_css_class("card")

        click_gesture = Gtk.GestureClick()
        click_gesture.set_button(0)
        click_gesture.connect("pressed", self.on_click)
        self.overlay_box.add_controller(click_gesture)

        # Title
        title_label = Gtk.Label(label="Rofi Colors Transparency")
        title_label.set_margin_bottom(20)
        self.card_box.append(title_label)

        # Create separate sliders for each target key
        # Using lambda to pass the specific key string to the update function
        self.create_slider(self.card_box, "Background", 
                           lambda val: self.update_rasi_alpha("background", val))
        
        self.create_slider(self.card_box, "Background Alt", 
                           lambda val: self.update_rasi_alpha("background-alt", val))
        
        self.create_slider(self.card_box, "Selected", 
                           lambda val: self.update_rasi_alpha("selected", val))
        
        self.create_slider(self.card_box, "Hover", 
                           lambda val: self.update_rasi_alpha("hover", val))

        center_box.append(self.card_box)
        self.overlay_box.append(center_box)
        self.set_child(self.overlay_box)

    def create_slider(self, parent, title, callback):
        label = Gtk.Label(label=title, xalign=0)
        # 0.0 to 1.0 range, step 0.01
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.01)
        scale.set_value(1.0) # Default visual starting point
        scale.connect("value-changed", lambda w: callback(round(w.get_value(), 2)))
        parent.append(label)
        parent.append(scale)

    def on_click(self, gesture, n_press, x, y):
        target = self.overlay_box.pick(x, y, Gtk.PickFlags.DEFAULT)
        if target == self.card_box or target.is_ancestor(self.card_box):
            return
        self.close()

    def update_rasi_alpha(self, target_key, value):
        """
        Updates the alpha value for a specific CSS-like key in all .rasi files.
        Target format: 'key: rgba(r, g, b, alpha);'
        """
        if not os.path.exists(rofi_config_dir):
            return

        rasi_files = glob.glob(os.path.join(rofi_config_dir, "*.rasi"))
        
        for file_path in rasi_files:
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                
                # Regex Explanation:
                # \b{target_key} : Matches the specific key (e.g., 'background')
                # \s*:\s*        : Matches the colon separator
                # rgba\(         : Matches the start of the color definition
                # (?:...){3}     : Matches the first 3 numbers (r, g, b)
                # ([\d\.]+)      : Group 2 captures the current alpha value
                # (\s*\);)       : Group 3 captures the closing syntax
                pattern = rf"(\b{re.escape(target_key)}\s*:\s*rgba\(\s*(?:\d+\s*,\s*){{3}})([\d\.]+)(\s*\);)"
                
                replacement = f"\\g<1>{value}\\g<3>"
                new_content = re.sub(pattern, replacement, content)

                if content != new_content:
                    with open(file_path, 'w') as f:
                        f.write(new_content)
                    # Optional: Print to stdout for debugging
                    # print(f"Updated {target_key} in {os.path.basename(file_path)} to {value}")
                    
            except Exception as e:
                print(f"Error updating {file_path}: {e}")

def on_activate(app):
    win = RofiTransparencyApp(app)
    win.present()

if __name__ == "__main__":
    app = Gtk.Application(application_id="com.rofi.transparency")
    app.connect("activate", on_activate)
    app.run(None)