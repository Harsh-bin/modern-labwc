#!/bin/bash

# Define the target CSS file and the Rofi themes to use
waybar_config_dir="$HOME/.config/waybar"
waybar_config="$waybar_config_dir/config.jsonc"
waybar_css="$waybar_config_dir/style.css"
waybar_css_dir="$waybar_config_dir/colors/"
waybar_layout_dir="$waybar_config_dir/layouts/"
change_alpha="$waybar_config_dir/scripts/alpha_changer.py"

# rofi menu styles
rofi_vertical_menu="$HOME/.config/rofi/vertical_style_menu.rasi"
rofi_vertical_menu_2="$HOME/.config/rofi/vertical_style_menu_2.rasi"
rofi_horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"

# --- Main Menu ---
main_options="Style\nColor_scheme"
main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Waybar Customize</b>" -theme "$rofi_horizontal_menu")

# Rofi launchers
clip="$HOME/.config/rofi/clipboard/clipboard.rasi"
clip_img="$HOME/.config/rofi/clipboard/clipboard_img.rasi"
nightlight="$HOME/.config/rofi/nightlight/night-light.rasi"
wifi="$HOME/.config/rofi/wifi/list.rasi"
# nowplaying styles
nowplay_style_dir="$HOME/.config/rofi/nowplaying/styles"
style1="$nowplay_style_dir/style-1.rasi"
style2="$nowplay_style_dir/style-2.rasi"
style3="$nowplay_style_dir/style-3.rasi"
style4="$nowplay_style_dir/style-4.rasi"
style5="$nowplay_style_dir/style-5.rasi"

rofi_position() {
    local loc_val=""
    local off_val=""

    # change rofi position based on bar's position
    case "$1" in
    top)
        loc_val="northeast"
        off_val="5px"
        sed -i '32s|.*|    children:                    [ "input-wrapper", "listview" ];|' "$nightlight"
        ;;
    bottom)
        loc_val="southeast"
        off_val="-5px"
        sed -i '32s|.*|    children:                    [ "listview", "input-wrapper" ];|' "$nightlight"
        ;;
    *)
        return 1
        ;;
    esac

    local files=("$clip" "$clip_img" "$style1" "$style2" "$style3" "$style4" "$style5" "$nightlight" "$wifi")

    # Loop through files and apply sed
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Replace location
            sed -i "s/^\s*location:.*/    location:                    $loc_val;/g" "$file"
            # Replace y-offset
            sed -i "s/^\s*y-offset:.*/    y-offset:                    $off_val;/g" "$file"
        fi
    done
}

bar_position() {
    position_options="top\nbottom"
    selected_position=$(echo -e "$position_options" | rofi -dmenu -mesg "<b>Select Position</b>" -theme "$rofi_horizontal_menu")

    if [ -n "$selected_position" ]; then
        # Changes bar position
        sed -i "s/^\s*\"position\":.*/      \"position\": \"${selected_position}\",/" "$waybar_config"
        # Changes rofi position
        rofi_position "$selected_position"

        # Killall Waybar
        killall waybar >/dev/null &
        sleep 0.2
        # Changes directory to home as opening filemanage eg thunar will open ~/.config/waybar/scripts as home directory.
        cd "$HOME"
        waybar --log-level off &>/dev/null &
        notify-send "Waybar Position Changed to $selected_position"
    fi
}

bar_style_menu() {
    layout_options=$(find "$waybar_layout_dir" -maxdepth 1 -type f -name "*.css" -printf "%f\n" | sort | sed 's/\.css$//')
    style_options="Bar Position\nTransparency\n$layout_options"
    selected_option=$(echo -e "$style_options" | rofi -dmenu -mesg "<b>Select Options</b>" -theme "$rofi_vertical_menu_2")

    case "$selected_option" in
    "Bar Position")
        bar_position
        ;;
    "Transparency")
        python3 "$change_alpha"
        ;;
    *)
        if [ -n "$selected_option" ]; then
            sed -i "s|@import \"layouts/.*\";|@import \"layouts/${selected_option}.css\";|" "$waybar_css"
        fi
        ;;
    esac
}

# --- Handle the choice with a case statement ---
case "$main_choice" in
"Style")
    bar_style_menu
    ;;

"Color_scheme")
    # Dynamically find all .css files in the colors directory
    color_files=$(find "$waybar_css_dir" -maxdepth 1 -type f -name "*.css" -printf "%f\n" | sort | sed 's/\.css$//')
    # Shows wallpaer color at top of list
    color_options="wallpaper\n$color_files"
    selected_color=$(echo -e "$color_options" | rofi -dmenu -mesg "<b>Select Color Scheme</b>" -theme "$rofi_vertical_menu")

    if [ -n "$selected_color" ]; then
        sed -i "s|@import \"colors/.*\";|@import \"colors/${selected_color}.css\";|" "$waybar_css"
    fi
    ;;
*)
    exit 0
    ;;
esac
