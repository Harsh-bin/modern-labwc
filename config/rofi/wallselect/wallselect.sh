#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# Change path to wallpaper
wall_dir="/home/init_harsh/Templates/wallpapers/"

rofi_img="$HOME/.config/rofi/images/"
wall_cache="$HOME/.config/labwc/wallpaper/"
# rofi menu file
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

# used for setting color scheme from wallpaper
rofi_colors="$HOME/.config/rofi/shared/colors.rasi"
waybar_css="$HOME/.config/waybar/style.css"
# Hyprlock 
hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"
hyprlock_dir="$HOME/.config/hypr/hyprlock"

# Script to toggle dark/light theme
GTK_THEME_SWITCHER="$HOME/.config/labwc/gtk.sh"
# Gtk configs
GTK3_SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS_FILE="$HOME/.config/gtk-4.0/settings.ini"

# Check if GTK3 settings file exists
if [ ! -f "$GTK3_SETTINGS_FILE" ]; then
    echo "Error: $GTK3_SETTINGS_FILE not found."
    exit 1
fi

selected=$(find "$wall_dir" \
  -type f -iregex '.*\.\(jpg\|jpeg\|png\|webp\|gif\)' |
  shuf |
  while read -r img; do
    echo -en "$img\0icon\x1f$img\n"
  done |
  rofi -dmenu -mesg "<big><b>Select Wallpaper</b></big>" -show-icons -theme "$HOME/.config/rofi/wallselect/style.rasi")

# Exit if no wallpaper is selected
if [ -z "$selected" ]; then
    exit 0
fi

# Function to set wallpaper
set_wallpaper() {
    swww img --transition-type random --transition-duration 3 --transition-fps 60 --transition-bezier 0.99,0.99,0.99,0.99 "$selected" &
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
                matugen image "$selected" -m "light"                
                sleep 0.2s
                sed -i "3s|.*|@import \"~/.config/rofi/colors/wallpaper.rasi\"|" "$rofi_colors"
                sed -i "8s|.*|@import \"colors/wallpaper.css\";|" "$waybar_css"
                set_wallpaper
                # Sets light theme for gtk apps
                sed -i 's/gtk-application-prefer-dark-theme=1/gtk-application-prefer-dark-theme=0/' "$GTK3_SETTINGS_FILE"
                sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$GTK4_SETTINGS_FILE"
                sed -i '3c gtk-icon-theme-name=Papirus-Light' "$GTK3_SETTINGS_FILE"
                "$GTK_THEME_SWITCHER"
                echo "Switched to light theme."
                ;;
              "Dark")
                matugen image "$selected" -m "dark"
                sleep 0.2s
                sed -i "3s|.*|@import \"~/.config/rofi/colors/wallpaper.rasi\"|" "$rofi_colors"
                sed -i "8s|.*|@import \"colors/wallpaper.css\";|" "$waybar_css"
                set_wallpaper
                # Sets dark theme for gtk apps
                sed -i 's/gtk-application-prefer-dark-theme=0/gtk-application-prefer-dark-theme=1/' "$GTK3_SETTINGS_FILE"
                sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$GTK4_SETTINGS_FILE"
                sed -i '3c gtk-icon-theme-name=Papirus-Dark' "$GTK3_SETTINGS_FILE"
                echo "Switched to dark theme."
                "$GTK_THEME_SWITCHER"
                 ;;
        esac
        ;;

    "No")
        # Sets wallpaper only
        set_wallpaper        
        ;;
esac

# Copy the selected wallpaper other directories
# Rofi doesn't care about file extension 
cp "$selected" "$rofi_img/wallpaper.png"

extension=$(echo "$selected" | sed -E 's/.*(\.[a-zA-Z0-9]+)$/\1/')
# cp the wallpaper for hyprlock background
if [ ${extension} = ".gif" ]; then
    # Extracts 4th frame of the gif and set it as hyprlock background.
    ffmpeg -y -i $selected -vf "select=eq(n\,3)" -vframes 1 $hyprlock_dir/background.png &>/dev/null &
    sed -i "6s|.*|    path = ~/.config/hypr/hyprlock/background.png|" "$hyprlock_conf"    
else
    sed -i "6s|.*|    path = ~/.config/hypr/hyprlock/wallpaper${extension}|" "$hyprlock_conf"    
fi
# stores the current background path in cache file, will be used with `toggle-theme.sh` as toggling theme generates template for hyprlock
# which uses `path = ~/.config/hypr/hyprlock/background.png` by default so 'wallpaper.extension' will not be used
sed -n '6p' "$hyprlock_conf" > "$hyprlock_dir/background.cache"

new_wallpaper_file="${wall_cache}/wallpaper${extension}"
find "$wall_cache" -maxdepth 1 -type f -name 'wallpaper.*' -delete
find "$hyprlock_dir" -maxdepth 1 -type f -name 'wallpaper.*' -delete
cp "$selected" "$new_wallpaper_file"
cp "$new_wallpaper_file" "$hyprlock_dir"