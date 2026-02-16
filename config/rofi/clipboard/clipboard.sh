#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# Configuration
dir="$HOME/.config/rofi/clipboard"

# --- Functions ---

image_history() {
  img_choice=$(${dir}/cliphist_rofi_img | rofi -dmenu -theme ${dir}/clipboard_img.rasi)
  if [[ -n "$img_choice" ]]; then
    tmp_img="/tmp/clipboard.png"
    echo "$img_choice" | cliphist decode >"$tmp_img"
    wl-copy <"$tmp_img"
    notify-send "Clipboard Manager" "Image copied to clipboard" --icon="$tmp_img"
    sleep 1
    rm "$tmp_img"
  fi
}

wipe_clipboard() {
  yes='Yes'
  no='No'

  confirmation=$(echo -e "$no\n$yes" |
    rofi -dmenu \
      -mesg $'<big><b>Wipe Clipboard Confirmation</b></big>\nAre you sure you want to wipe the clipboard?' \
      -theme ${dir}/confirmation.rasi)

  if [[ $confirmation == "$yes" ]]; then
    cliphist wipe
    wl-copy -c
    notify-send "Clipboard Manager" "Clipboard has been wiped"
  fi
}

handle_text_selection() {
  local selection="$1"
  cliphist decode "$selection" | wl-copy
  wtype -M ctrl -M shift -P v -s 500 -p v -m shift -m ctrl
  notify-send "Clipboard Manager" "Text copied to clipboard"
}

# Generates clipboard
clipboard=$(echo -e "\t\uf03e   Image History\n\t\uf1f8   Wipe Clipboard\n$(cliphist list)" | rofi -markup-rows -dmenu -display-columns 2 -theme ${dir}/clipboard.rasi)

# Handle Selection
if [[ $clipboard == *"Image History"* ]]; then
  image_history
  exit
elif [[ $clipboard == *"Wipe Clipboard"* ]]; then
  wipe_clipboard
  exit
elif [[ -n $clipboard ]]; then
  handle_text_selection "$clipboard"
else
  exit
fi
