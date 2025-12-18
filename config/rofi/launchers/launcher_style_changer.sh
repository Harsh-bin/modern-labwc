#!/bin/bash

# Path to the launcher file
launcher_file="$HOME/.config/rofi/launchers/launcher.sh"
launcher_dir="$HOME/.config/rofi/launchers/"
# rofi menu file
vertical_style_menu="$HOME/.config/rofi/vertical_style_menu.rasi"


# Generate a list of styles available in launcher_dir
options=$(find "$launcher_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sort | sed 's/\.rasi$//')
selected_style=$(echo -e "$options" | rofi -dmenu -mesg "<b>Select Layout</b>" -theme $vertical_style_menu)


# update the 4th line of the launcher file
if [ -n "$selected_style" ]; then
    sed -i "4s/.*/theme='${selected_style}'/" "$launcher_file"
fi