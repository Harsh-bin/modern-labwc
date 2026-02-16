#!/bin/bash

# Path to the file that imports the color scheme
rofi_colors_dir="$HOME/.config/rofi/colors"
rofi_colors="$HOME/.config/rofi/shared/colors.rasi"
waybar_css="$HOME/.config/waybar/style.css"
gtk3_css="$HOME/.config/gtk-3.0/gtk.css"
gtk4_css="$HOME/.config/gtk-4.0/gtk.css"
labwc_theme_file="$HOME/.config/labwc/themerc-override"
labwc_theme_dir="$HOME/.config/labwc/colors"
swaync_css="$HOME/.config/swaync/style.css"
# Wallpaper cache
wall_dir="$HOME/.config/labwc/wallpaper"
wall_cache=$(find "$wall_dir" -maxdepth 1 -type f -name "wallpaper.*")
# New functions to change system theme when applying color scheme
GTK_THEME_SWITCHER="$HOME/.config/labwc/gtk.sh"
GTK3_SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS_FILE="$HOME/.config/gtk-4.0/settings.ini"

# Nowplaying 
nowplaying_script="$HOME/.config/rofi/nowplaying/nowplaying.sh"
source "$HOME/.config/rofi/nowplaying/overlay.sh"

apply_light_theme() {
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
}
apply_dark_theme() {
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
}

# Notification icon color changer
update_notification_icon_color="$HOME/.config/dunst/change_icon_color.sh"
# rofi vertical menu
rofi_vertical_menu="$HOME/.config/rofi/vertical_style_menu.rasi"

# Dynamically find all .rasi files in the colors directory "waybar and gtk also have same names so..."
color_files=$(find "$rofi_colors_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sort | sed 's/\.rasi$//')
# Shows wallpaer color at top of list
color_options="wallpaper\n$color_files"
# Display the Rofi menu
selected_color=$(echo -e "$color_options" | rofi -dmenu -mesg "<b>Select Color Scheme</b>" -theme $rofi_vertical_menu)

# Updates everything
if [ -n "$selected_color" ]; then
    # Update all config files
    for file in "$waybar_css" "$gtk3_css" "$gtk4_css" "$swaync_css"; do
        sed -i "s|@import \"colors/.*\.css\";|@import \"colors/${selected_color}.css\";|" "$file"
    done
    sed -i "s|@import \".*colors/.*\.rasi\"|@import \"~/.config/rofi/colors/${selected_color}.rasi\"|" "$rofi_colors"

    # Applies dark/light theme accordingly
    case "$selected_color" in
    "paper" | "lavender-pastel" | "everforest-light")
        apply_light_theme
        ;;
    "wallpaper")
        if grep -q "gtk-application-prefer-dark-theme=1" "$GTK3_SETTINGS_FILE"; then
            apply_dark_theme
        else
            apply_light_theme
        fi
        ;;
    *)
        apply_dark_theme
        ;;
    esac
    # Reloads swaync css
    pgrep -x swaync >/dev/null && swaync-client -rs
    # Reloads labwc
    cp "$labwc_theme_dir/${selected_color}".color "$labwc_theme_file"
    pgrep -x labwc >/dev/null && labwc --reconfigure
    # updates the notification icon color
    "$update_notification_icon_color"
    # send notification
    notify-send "Color scheme changed to ( ${selected_color^^} )"
fi
