#!/bin/bash

menu_generator="$HOME/.config/labwc/menu-generator.py"
menu_file="$HOME/.config/labwc/menu.xml"
# rofi menu file
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

# --- Main Menu ---
main_options="Yes\nNo"
main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Footer in menu?</b>" -theme "$horizontal_menu")

# --- Handle the choice with a case statement ---
case "$main_choice" in
    "Yes")
        python3 "$menu_generator" -o "$menu_file"
        # Notify user about menu generated sometimes it take few seccods to generate menu.
        notify-send "SUCCESS" "Desktop menu generated with Footer"
        ;;

    "No")
        python3 "$menu_generator" -f false -o "$menu_file"
        # Notify user about menu generated
        notify-send "SUCCESS" "Desktop menu generated without Footer"
        ;;
    *)
        exit 0
        ;;

esac
