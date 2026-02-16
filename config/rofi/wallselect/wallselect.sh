#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# Change path to wallpaper
wall_dir="/usr/share/backgrounds/images/"

# Wallselect theme file
wallselect_theme="$HOME/.config/rofi/wallselect/style-1.rasi"
# Directories to copy wallpaper
rofi_img="$HOME/.config/rofi/images/"
wall_cache="$HOME/.config/labwc/wallpaper/"
# rofi menu file
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

# Path to the files that imports the color scheme
rofi_colors="$HOME/.config/rofi/shared/colors.rasi"
waybar_css="$HOME/.config/waybar/style.css"
gtk3_css="$HOME/.config/gtk-3.0/gtk.css"
gtk4_css="$HOME/.config/gtk-4.0/gtk.css"
labwc_theme_file="$HOME/.config/labwc/themerc-override"
labwc_theme_dir="$HOME/.config/labwc/colors"
swaync_css="$HOME/.config/swaync/style.css"

# Hyprlock
hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"
hyprlock_dir="$HOME/.config/hypr/hyprlock"

# Script to toggle dark/light theme
GTK_THEME_SWITCHER="$HOME/.config/labwc/gtk.sh"
# Gtk configs
GTK3_SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS_FILE="$HOME/.config/gtk-4.0/settings.ini"

# Notification icon color changer
update_notification_icon_color="$HOME/.config/dunst/change_icon_color.sh"

# Nowplaying
nowplaying_script="$HOME/.config/rofi/nowplaying/nowplaying.sh"
source "$HOME/.config/rofi/nowplaying/overlay.sh"

# Check if GTK3 settings file exists
if [ ! -f "$GTK3_SETTINGS_FILE" ]; then
    echo "Error: $GTK3_SETTINGS_FILE not found."
    exit 1
fi
# Check if the wallpaper directory exists
if [ ! -d "$wall_dir" ]; then
    echo "Error: Wallpaper directory $wall_dir not found."
    exit 0
fi

# New selection logic, now can apply wallpaper with image path without showing rofi window
valid_exts="jpg|jpeg|png|webp|gif"
selected=""

if [ -n "$1" ]; then
    if [ ! -f "$1" ]; then
        echo "Error: File '$1' not found."
        exit 0
    fi
    if ! echo "$1" | grep -q -iE "\.(${valid_exts})$"; then
        echo "Error: File '$1' is not a valid image type ($valid_exts)."
        exit 0
    fi
    selected="$1"
else
    # If no argument is provided, run the rofi
    selected=$(find "$wall_dir" \
        -type f \
        -regextype posix-extended \
        -iregex ".*\.(${valid_exts})" |
        shuf |
        while read -r img; do
            echo -en "${img}\0icon\x1f${img}\n"
        done |
        rofi -dmenu -mesg "<big><b>󰸉 Select Wallpaper</b></big>" \
            -show-icons -theme "$wallselect_theme")
fi

# Exit if no wallpaper is selected by rofi
if [ -z "$selected" ]; then
    exit 0
fi

# Function to set wallpaper, added support for awww and swww both
set_wallpaper() {
    transition="--transition-type random \
                --transition-duration 3 \
                --transition-fps 60 \
                --transition-bezier 0.99,0.99,0.99,0.99"

    if pgrep -x swww-daemon >/dev/null; then
        swww img $transition "$selected" &
    elif pgrep -x awww-daemon >/dev/null; then
        awww img $transition "$selected" &
    fi
}

# Function to change color scheme to wallpaper
change_color_scheme_to_wallpaper() {
    # Apply only wallpaper color scheme
    for file in "$waybar_css" "$gtk3_css" "$gtk4_css" "$swaync_css"; do
        sed -i "s|@import \"colors/.*\.css\";|@import \"colors/wallpaper.css\";|" "$file"
    done
    sed -i "s|@import \".*colors/.*\.rasi\"|@import \"~/.config/rofi/colors/wallpaper.rasi\"|" "$rofi_colors"

    cp "$labwc_theme_dir/wallpaper.color" "$labwc_theme_file"
    # Reloads labwc
    pgrep -x labwc >/dev/null && labwc --reconfigure
    # Reloads swaync css
    pgrep -x swaync >/dev/null && swaync-client -rs
}

# --- Main Menu ---
main_options="Yes\nNo"
main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Set Color Scheme from wallpaper?</b>" -theme "$horizontal_menu")

# --- Handle the choice with a case statement ---
case "$main_choice" in
"Yes")
    options="Light\nDark"
    choice=$(echo -e "$options" | rofi -dmenu -mesg "<b>Select Color Scheme</b>" -theme "$horizontal_menu")
    case "$choice" in
    "Light")
        # Generates light color scheme from wallpaper
        matugen image "$selected" -m "light"
        sleep 0.2s
        # Sets color scheme to wallpaper
        change_color_scheme_to_wallpaper
        # Applies wallpaper
        set_wallpaper
        # Sets light System theme
        sed -i 's/gtk-application-prefer-dark-theme=1/gtk-application-prefer-dark-theme=0/' "$GTK3_SETTINGS_FILE"
        sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$GTK4_SETTINGS_FILE"
        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Papirus-Light/' "$GTK3_SETTINGS_FILE"
        "$GTK_THEME_SWITCHER"
        # Rofi nowplaying
        apply_light_overlay
        sed -i -E 's/trap apply_(light|dark)_overlay EXIT/trap apply_light_overlay EXIT/' "$nowplaying_script"
        echo "Switched to light theme."
        ;;
    "Dark")
        # Generates dark color scheme from wallpaper
        matugen image "$selected" -m "dark"
        sleep 0.2s
        # Sets color scheme to wallpaper
        change_color_scheme_to_wallpaper
        # Applies wallpaper
        set_wallpaper
        # Sets dark System theme
        sed -i 's/gtk-application-prefer-dark-theme=0/gtk-application-prefer-dark-theme=1/' "$GTK3_SETTINGS_FILE"
        sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$GTK4_SETTINGS_FILE"
        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Papirus-Dark/' "$GTK3_SETTINGS_FILE"
        "$GTK_THEME_SWITCHER"
        # Rofi nowplaying
        apply_dark_overlay
        sed -i -E 's/trap apply_(light|dark)_overlay EXIT/trap apply_dark_overlay EXIT/' "$nowplaying_script"
        echo "Switched to dark theme."
        ;;
    *)
        exit 0
        ;;
    esac
    ;;

"No")
    # Sets wallpaper only
    set_wallpaper
    ;;
*)
    exit 0
    ;;
esac

# Copy the selected wallpaper to other directories
# Rofi doesn't care about file extension
cp "$selected" "$rofi_img/wallpaper.png"

# Get the file extension of the selected wallpaper
extension=$(echo "$selected" | sed -E 's/.*(\.[a-zA-Z0-9]+)$/\1/')
new_wallpaper_file="${wall_cache}/wallpaper${extension}"
find "$wall_cache" -maxdepth 1 -type f -name 'wallpaper.*' -delete
find "$hyprlock_dir" -maxdepth 1 -type f -name 'wallpaper.*' -delete
cp "$selected" "$new_wallpaper_file"
cp "$new_wallpaper_file" "$hyprlock_dir"

# Hyprlock specific color generation
if [ "${extension}" = ".gif" ]; then
    # Extracts 4th frame of the gif and set it as hyprlock background.
    ffmpeg -y -i "$selected" -vf "select=eq(n\,3)" -vframes 1 "$hyprlock_dir/background.png" &>/dev/null &
    new_path="~/.config/hypr/hyprlock/background.png"
else
    new_path="~/.config/hypr/hyprlock/wallpaper${extension}"
fi
# Remove 'path = ' and any spaces
clean_path="${new_path##*= }"
hyprlock_background="${clean_path/\~/$HOME}"
wall_brightness=$(magick "$hyprlock_background" -colorspace Gray -format "%[fx:100*mean]" info: | tr -d ',')

# Compare the brightness of wallpaper and then generates hyprlock color accordingly
# This is intensional and also correct
if (($(echo "$wall_brightness > 50" | bc -l))); then
    matugen -c "$HOME/.config/matugen/hyprlock.toml" image "$hyprlock_background" -m "light"
else
    matugen -c "$HOME/.config/matugen/hyprlock.toml" image "$hyprlock_background" -m "dark"
fi
# Restores the wallpaper after generating matugen colors
sed -i "/background {/,/}/ s|path = .*|path = $new_path|" "$hyprlock_conf"

# updates the notification icon color
"$update_notification_icon_color"
exit 0
