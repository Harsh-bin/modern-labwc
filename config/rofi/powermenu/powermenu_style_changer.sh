#!/bin/bash

# Path to the powermenu script file
powermenu_dir="$HOME/.config/rofi/powermenu/"
powermenu_file="$HOME/.config/rofi/powermenu/powermenu.sh"
vertical_style_menu_2="$HOME/.config/rofi/vertical_style_menu.rasi"

# Generate a list of styles available
options=$(find "$powermenu_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sed 's/\.rasi$//' | sort -t '-' -k2n)
selected_style=$(echo -e "$options" | rofi -dmenu -mesg "<b>Select Powermenu Style</b>" -theme $vertical_style_menu_2)
 
if [ -n "$selected_style" ]; then
    sed -i "s/^theme=.*/theme='${selected_style}'/" "$powermenu_file"
fi
