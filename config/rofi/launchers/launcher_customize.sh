#!/bin/bash

# Config
launcher_style_changer="$HOME/.config/rofi/launchers/launcher_style_changer.sh"
color_scheme_changer="$HOME/.config/rofi/colors/rofi_color_scheme_changer.sh"
# rofi menu file
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

# --- Main Menu ---
main_options="Layout\nColor_scheme"
main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Rofi Customize</b>" -theme "$horizontal_menu")

# --- Handle the choice with a case statement ---
case "$main_choice" in
    "Layout")
        "$launcher_style_changer"
        ;;

    "Color_scheme")
        "$color_scheme_changer"
        ;;
    *)
    exit 0
        ;;
esac
