#!/usr/bin/env bash
# Toggles between light and dark themes

# Script to apply theme
GTK_THEME_SWITCHER="$HOME/.config/labwc/gtk.sh"

GTK3_SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS_FILE="$HOME/.config/gtk-4.0/settings.ini"
wall_dir="$HOME/.config/labwc/wallpaper"
waybar_css="$HOME/.config/waybar/style.css"

# labwc theme
labwc_theme_file="$HOME/.config/labwc/themerc-override"
labwc_theme_dir="$HOME/.config/labwc/colors"

# Nowplaying 
nowplaying_script="$HOME/.config/rofi/nowplaying/nowplaying.sh"
source "$HOME/.config/rofi/nowplaying/overlay.sh"

# Notification icon color changer
update_notification_icon_color="$HOME/.config/dunst/change_icon_color.sh"

wall_cache=$(find "$wall_dir" -maxdepth 1 -type f -name "wallpaper.*")

# Check if GTK3 settings file exists
if [ ! -f "$GTK3_SETTINGS_FILE" ]; then
    echo "Error: $GTK3_SETTINGS_FILE not found."
    exit 1
fi

# Toggle theme based on current setting in GTK3 file
if grep -q "gtk-application-prefer-dark-theme=1" "$GTK3_SETTINGS_FILE"; then
    # Switch to light theme
    sed -i 's/gtk-application-prefer-dark-theme=1/gtk-application-prefer-dark-theme=0/' "$GTK3_SETTINGS_FILE"
    sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Papirus-Light/' "$GTK3_SETTINGS_FILE"
    matugen image "$wall_cache" -m "light"
    sleep 0.2
    # To triggre css refresh
    touch "$waybar_css"
    if [ -f "$GTK4_SETTINGS_FILE" ]; then
        sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$GTK4_SETTINGS_FILE"
    fi
    # Rofi nowplaying
    apply_light_overlay
    sed -i -E 's/trap apply_(light|dark)_overlay EXIT/trap apply_light_overlay EXIT/' "$nowplaying_script"
    "$GTK_THEME_SWITCHER"
    echo "Switched to light theme."
else
    # Switch to dark theme
    sed -i 's/gtk-application-prefer-dark-theme=0/gtk-application-prefer-dark-theme=1/' "$GTK3_SETTINGS_FILE"
    sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Papirus-Dark/' "$GTK3_SETTINGS_FILE"
    matugen image "$wall_cache" -m "dark"
    sleep 0.2
    # To triggre css refresh
    touch "$waybar_css"
    if [ -f "$GTK4_SETTINGS_FILE" ]; then
        sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$GTK4_SETTINGS_FILE"
    fi
    # Rofi nowplaying
    apply_dark_overlay
    sed -i -E 's/trap apply_(light|dark)_overlay EXIT/trap apply_dark_overlay EXIT/' "$nowplaying_script"
    "$GTK_THEME_SWITCHER"
    echo "Switched to dark theme."
fi

# Only matugen theme contails "General" 
if grep -q "General" "$labwc_theme_file"; then
    cp "$labwc_theme_dir/wallpaper.color" "$labwc_theme_file"
    # Reloads labwc
    pgrep -x labwc >/dev/null && labwc --reconfigure
fi

# updates the notification icon color
"$update_notification_icon_color"
exit 0



