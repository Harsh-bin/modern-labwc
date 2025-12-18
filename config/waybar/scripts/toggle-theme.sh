#!/usr/bin/env bash
# Toggles between light and dark themes

# Script to apply theme
GTK_THEME_SWITCHER="$HOME/.config/labwc/gtk.sh"

GTK3_SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS_FILE="$HOME/.config/gtk-4.0/settings.ini"
wall_dir="$HOME/.config/labwc/wallpaper"
waybar_css="$HOME/.config/waybar/style.css"
# Hyprlock 
hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"
hyprlock_bg="$HOME/.config/hypr/hyprlock/background.cache"

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
    sed -i '3c gtk-icon-theme-name=Papirus-Light' "$GTK3_SETTINGS_FILE"
    matugen image "$wall_cache" -m "light"
    sleep 0.2
    sed -i "4s|.*|/** just to triggre css refresh **/|" "$waybar_css"
    sed -i "6s|.*|$(cat $hyprlock_bg)|" "$hyprlock_conf"
    if [ -f "$GTK4_SETTINGS_FILE" ]; then
        sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$GTK4_SETTINGS_FILE"
    fi
    "$GTK_THEME_SWITCHER"
    echo "Switched to light theme."
else
    # Switch to dark theme
    sed -i 's/gtk-application-prefer-dark-theme=0/gtk-application-prefer-dark-theme=1/' "$GTK3_SETTINGS_FILE"
    sed -i '3c gtk-icon-theme-name=Papirus-Dark' "$GTK3_SETTINGS_FILE"
    matugen image "$wall_cache" -m "dark"
    sleep 0.2
    sed -i "4s|.*|/** just to triggre css refresh **/|" "$waybar_css"
    sed -i "6s|.*|$(cat $hyprlock_bg)|" "$hyprlock_conf"
    if [ -f "$GTK4_SETTINGS_FILE" ]; then
        sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$GTK4_SETTINGS_FILE"
    fi
    echo "Switched to dark theme."
    "$GTK_THEME_SWITCHER"
fi