#!/bin/bash

dir="$HOME/.config/rofi/launchers/"
theme='style-10'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi \
    -me-select-entry "" \
    -me-accept-entry "MousePrimary"
