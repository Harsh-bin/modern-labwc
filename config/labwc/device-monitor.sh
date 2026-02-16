#!/bin/bash

AUDIO_FILE="$HOME/.config/labwc/sound/device-added.wav"

echo "Starting hardware monitor... (Press Ctrl+C to stop)"

while true; do
    # Start udevadm monitor and pipe it into a reading block
    udevadm monitor | {
        while read -r line; do
            # Check if the line contains a '[' character.
            # Actual events look like: UDEV  [350.433478] remove   /devices/...
            if [[ "$line" == *"["* ]]; then
                # We found the first event line!
                # Break out of this inner read loop immediately.
                break
            fi
        done
    }
    aplay -q "$AUDIO_FILE"
    sleep 1
done
