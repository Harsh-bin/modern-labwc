#!/bin/bash

# Prevents double locking when device goes to sleep
if pgrep -x "hyprlock" >/dev/null; then
    echo "Session Already Locked"
    exit 0
else
    echo "Locking Session"
    # start nowplaying.sh so that everytime ui is clean and updated
    bash "$HOME/.config/hypr/hyprlock/nowplaying/nowplaying.sh" >/dev/null 2>&1 & # don't wait for albumart to download ( in case of spotify )
    # give some time to clean the art file if no player is running (personal experience)
    sleep 0.05
    hyprlock >/dev/null 2>&1 &
fi
