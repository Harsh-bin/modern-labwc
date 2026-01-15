#!/bin/bash

# Generates desktop menu for labwc using python script
menu_generator="$HOME/.config/labwc/menu-generator.py"
menu_file="$HOME/.config/labwc/menu.xml"
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

if command -v rofi &> /dev/null; then
    main_options="Yes\nNo"
    main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Footer in menu?</b>" -theme "$horizontal_menu")
    
    case "$main_choice" in
        "Yes")
            python3 "$menu_generator" -o "$menu_file"
            notify-send "SUCCESS" "Desktop menu generated with Footer"
            ;;
        
        "No")
            python3 "$menu_generator" -f false -o "$menu_file"
            notify-send "SUCCESS" "Desktop menu generated without Footer"
            ;;
        
        *)
            exit 0
            ;;
    esac
else
    read -p "Include footer in menu? (y/n): " choice
    case "$choice" in
        y|Y|yes|Yes|YES)
            python3 "$menu_generator" -o "$menu_file"
            notify-send "SUCCESS" "Desktop menu generated with Footer"
            ;;
        n|N|no|No|NO)
            python3 "$menu_generator" -f false -o "$menu_file"
            notify-send "SUCCESS" "Desktop menu generated without Footer"
            ;;
        *)
            echo "Invalid selection!"
            exit 0
            ;;
    esac
fi
