#!/bin/bash

# Config Paths
vertical_style_menu_2="$HOME/.config/rofi/vertical_style_menu_2.rasi"
color_scheme_changer="$HOME/.config/waybar/scripts/global_color_scheme_changer.sh"
waybar_customize="$HOME/.config/waybar/scripts/waybar_customize.sh"
launcher_customize="$HOME/.config/rofi/launchers/launcher_customize.sh"
powermenu_customize="$HOME/.config/rofi/powermenu/powermenu_style_changer.sh"
wallpaper_selector="$HOME/.config/rofi/wallselect/wallselect.sh"
menu_generator="$HOME/.config/labwc/menu-generator.sh"

# --- Define Menu Options ---
menu_options="Color_Scheme\nWallpaper\nWaybar\nLauncher\nPowermenu\nGenerate desktop-menu"

# --- Show the Rofi Menu ---
chosen_option=$(echo -e "$menu_options" | rofi -dmenu -mesg "<b>Customization</b>" -theme "vertical_style_menu_2")

# --- Process the User's Choice ---
case "$chosen_option" in
    "Color_Scheme")
        "$color_scheme_changer"        
        ;;
    "Wallpaper")
        "$wallpaper_selector"
        ;;
    "Waybar")
        "$waybar_customize"        
        ;;
    "Launcher")
        "$launcher_customize"
        ;;
    "Powermenu")
        "$powermenu_customize"
        ;;
    "Generate desktop-menu")
        "$menu_generator"
        ;;
    *)
    exit 0
    ;;
esac 
