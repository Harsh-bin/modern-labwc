#!/bin/bash

dir="$HOME/.config/rofi/launchers/"
theme='style-6'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
