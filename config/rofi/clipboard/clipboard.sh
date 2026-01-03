#!/bin/bash

dir="$HOME/.config/rofi/clipboard"

# The main clipboard ( Added Image History support )
choice=$(echo -e "\t\uf03e   Image History\n\t\uf1f8   Wipe Clipboard\n$(cliphist list)" | rofi -markup-rows -dmenu -display-columns 2 -theme ${dir}/clipboard.rasi \
       -hover-select -me-select-entry '' -me-accept-entry MousePrimary)

if [[ $choice == *"Image History"* ]]; then
  img_choice=$(${dir}/cliphist_rofi_img | rofi -dmenu -theme ${dir}/clipboard_img.rasi)
  if [[ -n "$img_choice" ]]; then
    ${dir}/cliphist_rofi_img "$img_choice"
    notify-send "Clipboard Manager" "Image copied to clipboard"
  fi
  exit
elif [[ $choice == *"Wipe Clipboard"* ]]; then
  yes='Yes'
  no='No'

  confirmation=$(echo -e "$no\n$yes" |
    rofi -dmenu \
    -mesg $'<big><b>Wipe Clipboard Confirmation</b></big>\nAre you sure you want to wipe the clipboard?' \
    -theme ${dir}/confirmation.rasi \
    -hover-select -me-select-entry '' -me-accept-entry MousePrimary) 

if [[ $confirmation == "$yes" ]]; then
    cliphist wipe
    wl-copy -c
    notify-send "Clipboard Manager" "Clipboard has been wiped"
  fi
  exit
elif [[ -n $choice ]]; then
  cliphist decode "$choice" | wl-copy
  wtype -M ctrl -M shift -P v -s 500 -p v -m shift -m ctrl
else
  exit
fi
