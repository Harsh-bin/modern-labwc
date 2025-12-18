#!/bin/bash

# Toggle mute for both speakers and microphone 
pactl set-sink-mute @DEFAULT_SINK@ toggle
pactl set-source-mute @DEFAULT_SOURCE@ toggle

# Check the mute status 
is_muted=$(pamixer --get-mute)
is_mic_muted=$(pamixer --default-source --get-mute)

# Prepare the notification message based on the new state
if [ "$is_muted" = "true" ]; then
    notify-send -u normal "Muted" "Speakers and microphone are now muted."
else
    notify-send -u normal "Unmuted" "Speakers and microphone are now active."
fi
