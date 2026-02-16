#!/bin/bash

config_dir="$HOME/.config/rofi/nowplaying"
styles_dir="$config_dir/styles"

# Function to apply and remove overlay effects from style-2, 3 and 5

remove_overlay() {
    sed -i \
        -e '35s|background-image:.*;|background-image:      transparent;|' \
        -e '51s|text-color:.*;|text-color:                  @foreground;|' \
        -e '82s|background-color: .*;|background-color:     @background-alt;|' \
        -e '89s|text-color:.*;|text-color:                  @foreground;|' \
        "$styles_dir/style-2.rasi"

    sed -i \
        -e '34s|background-image:.*;|background-image:      transparent;|' \
        -e '41s|text-color:.*;|text-color:                  @foreground;|' \
        -e '57s|text-color:.*;|text-color:                  @foreground;|' \
        "$styles_dir/style-3.rasi"

    sed -i \
        -e '32s|background-image:.*;|background-image:      transparent;|' \
        -e '56s|text-color:.*;|text-color:                  @foreground;|' \
        "$styles_dir/style-5.rasi"
}

# Dark overlay
apply_dark_overlay() {
    sed -i \
        -e '35s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(0,0,0,90%), rgba(6,6,6,95%), rgba(0,0,0,90%));|' \
        -e '51s|text-color:.*;|text-color:                  #ffffff;|' \
        -e '82s|background-color: .*;|background-color:     rgba(0, 0, 0, 0.6);|' \
        -e '89s|text-color:.*;|text-color:                  #ffffff;|' \
        "$styles_dir/style-2.rasi"

    sed -i \
        -e '34s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(0,0,0,95%), rgba(10,10,10,70%), rgba(0,0,0,95%));|' \
        -e '41s|text-color:.*;|text-color:                  #ffffff;|' \
        -e '57s|text-color:.*;|text-color:                  #ffffff;|' \
        "$styles_dir/style-3.rasi"

    sed -i \
        -e '32s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(0,0,0,99%), rgba(10,10,10,90%), rgba(0,0,0,99%));|' \
        -e '56s|text-color:.*;|text-color:                  #ffffff;|' \
        "$styles_dir/style-5.rasi"
}

# Light overlay
apply_light_overlay() {
    sed -i \
        -e '35s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(255,255,255,70%), rgba(245,245,245,85%), rgba(255,255,255,90%));|' \
        -e '51s|text-color:.*;|text-color:                  #000000;|' \
        -e '82s|background-color: .*;|background-color:     rgba(255, 255, 255, 0.6);|' \
        -e '89s|text-color:.*;|text-color:                  #000000;|' \
        "$styles_dir/style-2.rasi"

    sed -i \
        -e '34s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(255,255,255,95%), rgba(240,240,240,70%), rgba(255,255,255,95%));|' \
        -e '41s|text-color:.*;|text-color:                  #000000;|' \
        -e '57s|text-color:.*;|text-color:                  #000000;|' \
        "$styles_dir/style-3.rasi"

    sed -i \
        -e '32s|background-image:.*;|background-image:      linear-gradient(135deg, rgba(255,255,255,95%), rgba(240,240,240,70%), rgba(255,255,255,95%));|' \
        -e '56s|text-color:.*;|text-color:                  #000000;|' \
        "$styles_dir/style-5.rasi"
}
 


