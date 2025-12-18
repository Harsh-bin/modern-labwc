#!/bin/bash

# Path to the file that imports the color scheme
rofi_colors_dir="$HOME/.config/rofi/colors"
rofi_colors="$HOME/.config/rofi/shared/colors.rasi"

# rofi vertical menu
rofi_vertical_menu="$HOME/.config/rofi/vertical_style_menu.rasi"

# Dynamically find all .rasi files in the colors directory
color_files=$(find "$rofi_colors_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sort | sed 's/\.rasi$//')
# Shows wallpaer color at top of list
color_options="wallpaper\n$color_files"
# Display the Rofi menu
selected_color=$(echo -e "$color_options" | rofi -dmenu -mesg "<b>Select Color Scheme</b>" -theme $rofi_vertical_menu)

# Update only color.rasi
if [ -n "$selected_color" ]; then   
    sed -i "3s|.*|@import \"~/.config/rofi/colors/${selected_color}.rasi\"|" "$rofi_colors"
fi