#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# CONFIGURATION
icon_dir="$HOME/.config/dunst/brightness-icon"
# Using same notification id as in volume_ctrl script, it looks good
notify_id=$(if pgrep -x "swaync" >/dev/null; then echo "-h string:x-canonical-private-synchronous:volume"; else echo "-r 3456"; fi)

if [[ -z "$1" ]] || [[ ! "$1" =~ ^[0-9]+[+-]$ ]]; then
    echo "Usage:"
    echo "   $(basename "$0") 5+   (Increase brightness by 5%)"
    echo "   $(basename "$0") 10-  (Decrease brightness by 10%)"
    exit 1
fi

# Parse Input
step="${1//[^0-9]/}" # Remove everything that isn't a number
sign="${1//[0-9]/}"  # Remove everything that isn't a sign

# Changes brightness value
if [ "$sign" == "+" ]; then
    brightnessctl set "${step}%+" -q
elif [ "$sign" == "-" ]; then
    brightnessctl set "${step}%-" -q
fi

# Get the current brightness of screen
brightness=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

# Select icon based on screen brightness
if [ "$brightness" -lt 34 ]; then
    icon="$icon_dir/brightness-low.png"
elif [ "$brightness" -lt 67 ]; then
    icon="$icon_dir/brightness-mid.png"
else
    icon="$icon_dir/brightness-high.png"
fi

text="Brightness: ${brightness}%"

# NOTIFICATION
notify-send -t 3000 $notify_id -u low -i "$icon" "$text" -h int:value:"$brightness"
