#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# configuration
icon_dir="$HOME/.config/dunst/volume-icon"
# notification id
notify_id=$(if pgrep -x "swaync" >/dev/null; then echo "-h string:x-canonical-private-synchronous:volume"; else echo "-r 3456"; fi)

# check for dependencies
if ! command -v pamixer >/dev/null 2>&1; then
    echo "Install pamixer"
    exit 0
fi

# default urgency
urgency="low"

# function to get speaker icon based on volume and mute status
get_speaker_icon() {
    local vol=$1
    local muted=$2

    if [ "$muted" == "true" ] || [ "$vol" -eq 0 ]; then
        echo "$icon_dir/mute.png"
    elif [ "$vol" -lt 34 ]; then
        echo "$icon_dir/vol-low.png"
    elif [ "$vol" -lt 67 ]; then
        echo "$icon_dir/vol-mid.png"
    else
        echo "$icon_dir/vol-high.png"
    fi
}

# --- toggle mute logic  ---
if [ "$1" == "--toggle-mute" ]; then
    target="$2"

    # toggle both (if no target is specified)
    if [ -z "$target" ]; then
        pamixer --toggle-mute
        pamixer --default-source --toggle-mute

        is_muted=$(pamixer --get-mute)
        vol=$(pamixer --get-volume)

        if [ "$is_muted" == "true" ]; then
            icon="$icon_dir/mute-both.png"
            text="System Muted"
            body="Speakers and microphone are now muted."
            urgency="critical"
        else
            icon="$icon_dir/unmute-both.png"
            text="System Unmuted"
            body="Speakers and microphone are now active."
        fi

    # toggle microphone only
    elif [ "$target" == "microphone" ]; then
        pamixer --default-source --toggle-mute
        is_mic_muted=$(pamixer --default-source --get-mute)

        if [ "$is_mic_muted" == "true" ]; then
            icon="$icon_dir/mute-microphone.png"
            text="Microphone Muted"
            urgency="critical"
        else
            icon="$icon_dir/microphone.png"
            text="Microphone Active"
        fi
        # for mic don't show a volume bar
        vol_bar_val=""

    # toggle speaker only
    elif [ "$target" == "speaker" ]; then
        pamixer --toggle-mute
        is_muted=$(pamixer --get-mute)
        vol=$(pamixer --get-volume)

        icon=$(get_speaker_icon "$vol" "$is_muted")
        if [ "$is_muted" == "true" ]; then
            text="Speakers Muted"
            urgency="critical"
        else
            text="Speakers Active"
        fi
        vol_bar_val="-h int:value:$vol"

    else
        echo "Error: usage is --toggle-mute [optional: speaker|microphone]"
        exit 1
    fi

# --- volume adjustment (argument number+/-) ---
elif [[ "$1" =~ ^[0-9]+[+-]$ ]]; then
    # parse input
    step="${1//[^0-9]/}" # remove everything that isn't a number
    sign="${1//[0-9]/}"  # remove everything that isn't a sign

    if [ "$sign" == "+" ]; then
        pamixer --increase "$step"
        pamixer --unmute # ensure unmute when turning volume up
    elif [ "$sign" == "-" ]; then
        pamixer --decrease "$step"
    fi

    # get status
    vol=$(pamixer --get-volume)
    is_muted=$(pamixer --get-mute)

    # get icon and text
    icon=$(get_speaker_icon "$vol" "$is_muted")
    text="Volume: ${vol}%"
    vol_bar_val="-h int:value:$vol"

    # if volume is 0 or still muted, treat as critical
    if [ "$is_muted" == "true" ] || [ "$vol" -eq 0 ]; then
        urgency="critical"
    fi

# --- help ---
else
    echo "Usage:"
    echo "  $(basename "$0") --toggle-mute              (Toggle Mute for BOTH Speaker & Mic)"
    echo "  $(basename "$0") --toggle-mute speaker      (Toggle Mute for Speaker only)"
    echo "  $(basename "$0") --toggle-mute microphone   (Toggle Mute for Microphone only)"
    echo "  $(basename "$0") 5+                         (Increase volume by 5%)"
    echo "  $(basename "$0") 10-                        (Decrease volume by 10%)"
    exit 1
fi

# --- notification ---
if [ -n "$body" ]; then
    notify-send -t 3000 $notify_id -u "$urgency" -i "$icon" "$text" "$body" $vol_bar_val
else
    notify-send -t 3000 $notify_id -u "$urgency" -i "$icon" "$text" $vol_bar_val
fi
