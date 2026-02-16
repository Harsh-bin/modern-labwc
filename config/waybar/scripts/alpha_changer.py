import os
import re
import glob
import gi
import ctypes

for path in ("libgtk4-layer-shell.so", "/usr/lib/libgtk4-layer-shell.so"):
    try:
        ctypes.CDLL(path)
        break
    except OSError:
        pass

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gdk, Gtk4LayerShell

# Paths
WAYBAR_DIR = os.path.expanduser("~/.config/waybar")
STYLE_FILE = os.path.join(WAYBAR_DIR, "style.css")
COLORS_DIR = os.path.join(WAYBAR_DIR, "colors")


# GTK CSS (uses theme colors to follow the system theme)
css_provider = Gtk.CssProvider()
css_provider.load_from_string(
    """
window, .overlay { background: transparent; }

.card {
    background: @theme_bg_color;
    color: @theme_fg_color;
    border-radius: 12px;
    padding: 24px;
    border: 1px solid shade(@theme_bg_color, 0.85);
}

label { font-weight: bold; margin-bottom: 5px; }
scale { margin-bottom: 20px; }
scale trough { min-height: 4px; border-radius: 4px; }
switch { margin-bottom: 20px; }
"""
)

Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default(),
    css_provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
)


class TransparencyApp(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.wallpaper_css_path = os.path.join(COLORS_DIR, "wallpaper.css")
        self.style_css_path = STYLE_FILE
        self.matugen_wallpaper_path = os.path.expanduser(
            "~/.config/matugen/templates/waybar.css"
        )
        self.alpha_values = self.read_initial_alphas()
        self.init_layer_shell()
        self.build_ui()

    def read_initial_alphas(self):
        alphas = {
            "bar": 0.8,
            "module": 0.8,
            "tray": 0.8,
            "hover": 0.8,
            "special": 0.8,
            "tooltip": 0.0,
        }
        # Read wallpaper.css for slider positions
        if os.path.exists(self.wallpaper_css_path):
            with open(self.wallpaper_css_path) as f:
                content = f.read()

                def find_alpha(target):
                    m = re.search(
                        rf"@define-color {target} alpha\([^,]+,\s*([\d\.]+)\)", content
                    )
                    return float(m.group(1)) if m else None

                for key, css_key in [
                    ("module", "module_bg"),
                    ("tray", "tray"),
                    ("hover", "hover_bg"),
                    ("special", "special"),
                ]:
                    val = find_alpha(css_key)
                    if val is not None:
                        alphas[key] = val
        # Read style.css for bar background and tooltip slider position
        if os.path.exists(self.style_css_path):
            with open(self.style_css_path) as f:
                content = f.read()
                m = re.search(r"background: alpha\(@bar_bg,\s*([\d\.]+)\);", content)
                if m:
                    alphas["bar"] = float(m.group(1))
                m = re.search(
                    r"tooltip\s*\{[^}]*background-color: alpha\(@bar_bg,\s*([\d\.]+)\);",
                    content,
                    re.DOTALL,
                )
                if m:
                    alphas["tooltip"] = float(m.group(1))
                else:
                    alphas["tooltip"] = 0.0
        return alphas

    def init_layer_shell(self):
        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.EXCLUSIVE)
        for edge in (
            Gtk4LayerShell.Edge.TOP,
            Gtk4LayerShell.Edge.BOTTOM,
            Gtk4LayerShell.Edge.LEFT,
            Gtk4LayerShell.Edge.RIGHT,
        ):
            Gtk4LayerShell.set_anchor(self, edge, True)

    # UI
    def build_ui(self):
        self.overlay_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.overlay_box.add_css_class("overlay")

        center_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        center_box.set_halign(Gtk.Align.CENTER)
        center_box.set_valign(Gtk.Align.CENTER)
        center_box.set_hexpand(True)
        center_box.set_vexpand(True)

        self.card_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.card_box.set_size_request(350, -1)
        self.card_box.add_css_class("card")

        click = Gtk.GestureClick()
        click.connect("pressed", self.on_click)
        self.overlay_box.add_controller(click)

        self.add_tooltip_toggle()
        self.bar_slider = self.create_slider(
            "Bar Background", self.update_bar, self.alpha_values["bar"]
        )
        self.module_slider = self.create_slider(
            "Module / Tray", self.update_module_and_tray, self.alpha_values["module"]
        )
        self.hover_slider = self.create_slider(
            "Hover / Special", self.update_hover_and_special, self.alpha_values["hover"]
        )
        self.tooltip_slider = self.create_slider(
            "Tooltip Opacity", self.update_tooltip, self.alpha_values["tooltip"]
        )

        center_box.append(self.card_box)
        self.overlay_box.append(center_box)
        self.set_child(self.overlay_box)

    def add_tooltip_toggle(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        label = Gtk.Label(label="Tooltip", xalign=0)
        label.set_hexpand(True)

        self.tooltip_switch = Gtk.Switch()
        self.tooltip_switch.set_valign(Gtk.Align.CENTER)
        self.check_tooltip_state()
        self.tooltip_switch.connect("state-set", self.on_tooltip_toggled)

        box.append(label)
        box.append(self.tooltip_switch)
        self.card_box.append(box)

    def create_slider(self, title, callback, initial_value=0.8):
        label = Gtk.Label(label=title, xalign=0)
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.05)
        scale.set_value(initial_value)
        scale.connect("value-changed", lambda w: callback(round(w.get_value(), 2)))
        self.card_box.append(label)
        self.card_box.append(scale)
        return scale

    def update_file_regex(self, file_path, pattern, replacement):
        if not os.path.exists(file_path):
            return
        try:
            with open(file_path) as f:
                content = f.read()
            new_content = re.sub(pattern, replacement, content)
            if content != new_content:
                with open(file_path, "w") as f:
                    f.write(new_content)
        except Exception as e:
            print(f"Error updating {file_path}: {e}")

    def check_tooltip_state(self):
        if not os.path.exists(STYLE_FILE):
            return
        with open(STYLE_FILE) as f:
            self.tooltip_switch.set_active("tooltip {" in f.read())

    def on_tooltip_toggled(self, switch, state):
        if state:
            css = "\ntooltip {\n    background-color: alpha(@bar_bg, 0.25);\n}\n"
            with open(STYLE_FILE, "a") as f:
                f.write(css)
        else:
            pattern = r"tooltip\s*\{[^}]*\}"
            self.update_file_regex(STYLE_FILE, pattern, "")

    def update_tooltip(self, value):
        # Only update tooltip alpha, not bar background
        pattern = (
            r"(tooltip\s*\{[^}]*background-color:\s*alpha\(@bar_bg,\s*)([\d\.]+)(\);)"
        )
        self.update_file_regex(STYLE_FILE, pattern, rf"\g<1>{value}\g<3>")
        self.update_matugen_wallpaper("tooltip", value)

    def update_bar(self, value):
        pattern = r"(background:\s*alpha\(@bar_bg,\s*)([\d\.]+)(\);)"
        self.update_file_regex(STYLE_FILE, pattern, rf"\g<1>{value}\g<3>")
        self.update_matugen_wallpaper("bar", value)

    def update_group(self, targets, value):
        for t in targets:
            pattern = rf"(@define-color\s+{t}\s+alpha\([^,]+,\s*)([\d\.]+)(\);)"
            repl = rf"\g<1>{value}\g<3>"
            for css_file in glob.glob(os.path.join(COLORS_DIR, "*.css")):
                self.update_file_regex(css_file, pattern, repl)
            self.update_matugen_wallpaper(t, value)

    def update_matugen_wallpaper(self, target, value):
        # Read and update ~/.config/matugen/templates/waybar.css
        if not os.path.exists(self.matugen_wallpaper_path):
            return
        try:
            with open(self.matugen_wallpaper_path) as f:
                content = f.read()
            # Map slider to template keys
            mapping = {
                "bar": r"(@define-color bar_bg [^;]+;)",
                "module_bg": r"(@define-color module_bg alpha\([^,]+,\s*)([\d\.]+)(\);)",
                "tray": r"(@define-color tray alpha\([^,]+,\s*)([\d\.]+)(\);)",
                "hover_bg": r"(@define-color hover_bg alpha\([^,]+,\s*)([\d\.]+)(\);)",
                "special": r"(@define-color special alpha\([^,]+,\s*)([\d\.]+)(\);)",
                "tooltip": r"(tooltip \{[^}]*background-color: alpha\(@bar_bg,\s*)([\d\.]+)(\);[^}]*\})",
            }
            # Determine which pattern to use
            pat = None
            if target == "bar":
                pat = r"(background: alpha\(@bar_bg,\s*)([\d\.]+)(\);)"
            elif target == "module_bg" or target == "module":
                pat = mapping["module_bg"]
            elif target == "tray":
                pat = mapping["tray"]
            elif target == "hover_bg" or target == "hover":
                pat = mapping["hover_bg"]
            elif target == "special":
                pat = mapping["special"]
            elif target == "tooltip":
                pat = mapping["tooltip"]
            else:
                return

            # Replace alpha value
            def repl(m):
                if len(m.groups()) == 3:
                    return f"{m.group(1)}{value}{m.group(3)}"
                return m.group(0)

            new_content = re.sub(pat, repl, content)
            with open(self.matugen_wallpaper_path, "w") as f:
                f.write(new_content)
        except Exception as e:
            print(f"Error updating matugen wallpaper: {e}")

    def update_module_and_tray(self, value):
        self.update_group(["module_bg", "tray"], value)

    def update_hover_and_special(self, value):
        self.update_group(["hover_bg", "special"], value)

    # Click outside close
    def on_click(self, gesture, n_press, x, y):
        target = self.overlay_box.pick(x, y, Gtk.PickFlags.DEFAULT)
        if not (target == self.card_box or target.is_ancestor(self.card_box)):
            self.close()


def on_activate(app):
    TransparencyApp(app).present()


if __name__ == "__main__":
    app = Gtk.Application(application_id="com.waybar.transparency")
    app.connect("activate", on_activate)
    app.run(None)
