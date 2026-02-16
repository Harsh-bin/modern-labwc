#!/bin/bash

# Path to the nowplaying file
nowplaying_script="$HOME/.config/rofi/nowplaying/nowplaying.sh"
nowplaying_dir="$HOME/.config/rofi/nowplaying/styles"
# rofi menu file
vertical_style_menu="$HOME/.config/rofi/vertical_style_menu_2.rasi"

# Generate a list of styles available in nowplaying_dir
options=$(find "$nowplaying_dir" -maxdepth 1 -type f -name "*.rasi" -printf "%f\n" | sed 's/\.rasi$//' | sort -t '-' -k2n)
selected_style=$(echo -e "$options" | rofi -dmenu -mesg "<b>Select Style</b>" -theme $vertical_style_menu)
 
if [ -n "$selected_style" ]; then
    sed -i "s|^rofi_theme=.*|rofi_theme=\"\$config_dir/styles/${selected_style}\"|" "$nowplaying_script"
fi
