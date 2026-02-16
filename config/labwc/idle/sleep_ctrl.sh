#!/bin/bash

# Pause all media players before sleep
playerctl --all-players pause &
echo "Paused all media players."

# Lock and sleep after pausing all players
# Don't use sleep command here swaylidle will handle sleeping...

# Get the current brightness of screen
current_val=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

if [ "$current_val" -gt "0" ]; then
   "$HOME/.config/labwc/idle/brightness_ctrl.sh" --fade-out &
else
   echo "Screen brightness already 0. Not fadding screen.."
fi

# Lock the session
loginctl lock-session
exit 0
