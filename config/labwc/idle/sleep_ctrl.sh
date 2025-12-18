#!/bin/bash

# Get the list of all controllable players
players_list=$(playerctl -l 2>/dev/null)

# Loop through the list of players
while IFS= read -r player; do
    # Skip if the line is empty
    if [ -z "$player" ]; then continue; fi

    # Check the status of player
    status=$(playerctl -p "$player" status 2>/dev/null)
    
    # If the player is currently playing, pause it
    if [[ "$status" == "Playing" ]]; then
        echo "Found active player: $player. Pausing..."
        playerctl -p "$player" pause
    else
        echo "Player $player is already $status."
    fi

done <<< "$players_list"

# Lock and sleep after pausing all players
# Don't use sleep command here swaylidle will handle sleeping...

# Dim the screen before sleeping
bash ~/.config/labwc/idle/brightness_ctrl.sh --fade-out &
loginctl lock-session
# Give some time for the lock to take effect because if sleep too quick, device may not lock properly
sleep 2
echo "Suspending system..."
exit 0

