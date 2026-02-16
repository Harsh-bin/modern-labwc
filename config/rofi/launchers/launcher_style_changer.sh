#!/bin/bash

# Path to the launcher file
launcher_file="$HOME/.config/rofi/launchers/launcher.sh"
launcher_dir="$HOME/.config/rofi/launchers/"
# rofi menu file
vertical_style_menu="$HOME/.config/rofi/vertical_style_menu.rasi"

# Generate a list of styles available in launcher_dir
options=$(find "$launcher_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sed 's/\.rasi$//' | sort -t '-' -k2n)
selected_style=$(echo -e "$options" | rofi -dmenu -mesg "<b>Select Layout</b>" -theme $vertical_style_menu)
 
if [ -n "$selected_style" ]; then
    sed -i "s/^theme=.*/theme='${selected_style}'/" "$launcher_file"
fi
