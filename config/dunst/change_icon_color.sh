#!/bin/bash

waybar_config_dir="$HOME/.config/waybar"
style_file="$waybar_config_dir/style.css"
dunstrc="$HOME/.config/dunst/dunstrc"

# --- COLOR EXTRACTION LOGIC ---

# Default Fallbacks
bg_color="#121318"
fg_color="#e3e1e9"
icon_color="#b7c4ff" # icon color will be used for text color too
mute_color="#ffb4ab" # will be used for critical highlight in notification

# Find the active color file from style.css
imported_file=$(sed -n 's/.*@import "colors\/\(.*\)";.*/\1/p' "$style_file" | head -n 1)

if [ -n "$imported_file" ]; then
    full_color_path="$waybar_config_dir/colors/$imported_file"
    if [ -f "$full_color_path" ]; then
        extracted_bg_color=$(grep "@define-color bar_bg" "$full_color_path" | awk '{print $3}' | tr -d ';')
        extracted_fg_color=$(grep "@define-color bar_fg" "$full_color_path" | awk '{print $3}' | tr -d ';')
        extracted_icon_color=$(grep "@define-color primary" "$full_color_path" | awk '{print $3}' | tr -d ';')
        extracted_mute_color=$(grep "@define-color power" "$full_color_path" | awk '{print $3}' | tr -d ';')
        if [ -n "$extracted_bg_color" ]; then bg_color="$extracted_bg_color"; fi
        if [ -n "$extracted_fg_color" ]; then fg_color="$extracted_fg_color"; fi
        if [ -n "$extracted_icon_color" ]; then icon_color="$extracted_icon_color"; fi
        if [ -n "$extracted_mute_color" ]; then mute_color="$extracted_mute_color"; fi
    fi
else
    notify-send "Warning failed to extract colors using fallback!"
fi

# directories to look into
dirs=(
    "$HOME/.config/dunst/brightness-icon"
    "$HOME/.config/dunst/volume-icon"
)

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        # Iterate over every png file in the directory
        for img in "$dir"/*.png; do
            if [ -f "$img" ]; then
                # Run ImageMagick
                magick "$img" -channel RGB -fill "$icon_color" -colorize 100 "$img"
                echo "Recolored: $(basename "$img") to $icon_color"
            fi
        done
    else
        echo "Directory not found: $dir"
    fi
done

# mute icons
mute_icons=(
    "$HOME/.config/dunst/volume-icon/mute.png"
    "$HOME/.config/dunst/volume-icon/mute-microphone.png"
    "$HOME/.config/dunst/volume-icon/mute-both.png"
)

for mute_icons in "${mute_icons[@]}"; do
    if [[ -f "$mute_icons" ]]; then
        magick "$mute_icons" -channel RGB -fill "$mute_color" -colorize 100 "$mute_icons"
        echo "Recolored: $(basename "$mute_icons") to $mute_color"
    else
        echo "Warning: $mute_icons not found."
    fi
done

# applies color to alarm icons
alarm="$HOME/.config/waybar/scripts/clock_calendar/alarm/clock.png"
snooze="$HOME/.config/waybar/scripts/clock_calendar/alarm/snooze.png"
magick "$alarm" -channel RGB -fill "$mute_color" -colorize 100 "$alarm"
magick "$snooze" -channel RGB -fill "$icon_color" -colorize 100 "$snooze"

# applies color to rofi nowplaying icon
rofi_albumart_icon="$HOME/.config/rofi/nowplaying/fallback_album_art.png"
magick "$rofi_albumart_icon" -channel RGB -fill "$icon_color" -colorize 100 "$rofi_albumart_icon"
echo "Recolored: $(basename "$rofi_albumart_icon") to $icon_color"

# applies color to hyprlock nowplaying icon
hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"
hyprlock_albumart_icon="$HOME/.config/hypr/hyprlock/nowplaying/fallback_album_art.png"
# extracts rgba color value from config file
hyprlock_icon_color=$(sed -n '63s/.*= //p' "$hyprlock_conf")
magick "$hyprlock_albumart_icon" -channel RGB -fill "$hyprlock_icon_color" -colorize 100 "$hyprlock_albumart_icon"
echo "Recolored: $(basename "$hyprlock_icon_color") to $hyprlock_icon_color"

# seed color to dunstrc file and reloads the daemon

if [ -f "$dunstrc" ]; then
    sed -i \
        -e "s/^\s*frame_color\s*=.*/    frame_color = \"${icon_color}33\"/" \
        -e "s/^\s*separator_color\s*=.*/    separator_color = \"$icon_color\"/" \
        -e "s/^\s*foreground\s*=.*/    foreground = \"$fg_color\"/" \
        -e "s/^\s*highlight\s*=.*/    highlight = \"$icon_color\"/" \
        -e "s/^\s*background\s*=.*/    background = \"$bg_color\"/" \
        -e "71s/^\s*foreground\s*=.*/    foreground = \"$mute_color\"/" \
        -e "72s/^\s*highlight\s*=.*/    highlight = \"$mute_color\"/" \
        "$dunstrc"
    # reloads daemon
    pgrep -x dunst >/dev/null && dunstctl reload
else
    echo "File not found! $dunstrc"
fi

exit 0
