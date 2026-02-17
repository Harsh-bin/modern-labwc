#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# rofi menu file
rofi_menu="$HOME/.config/rofi/screen-tool/screen-tool.rasi"
# Define the directory for saving files
img_dir="$HOME/Pictures"
vid_dir="$HOME/Videos"
mkdir -p "$img_dir" "$vid_dir"

# --- Main Menu ---
# Check if wf-recorder is running
if pgrep -x "wf-recorder" >/dev/null; then
    main_options="Screenshot\nStop-recording"
    mesg="<big><b>Screen Tool (Recording ON)</b></big>"
else
    main_options="Screenshot\nStart-recording"
    mesg="<big><b>Screen Tool</b></big>"
fi

# Run Rofi
main_choice=$(echo -e "$main_options" |
    rofi -dmenu \
        -mesg "$(printf '%s\n\n<b>Usage:</b>\n● Esc to cancel selection\n● Hold spacebar to drag selection' "$mesg")" \
        -theme "$rofi_menu")

# Function to take screenshot
screenshot() {
    # New freeze mode to capture the screen more precisely like tooltips, popups etc..
    frozen_img="/tmp/frozen_screen.png"
    grim "$frozen_img"                         # capture whole screen
    swayimg -f -c info.show=no "$frozen_img" & # show the captured screen in full screen without info of img
    view_id=$!                                 # Trap the process id of swayimg
    sleep 0.15

    # Now run the normal screenshot function
    region=$(slurp)
    if [ -n "$region" ]; then

        # Capture to a temporary file
        tmp_file="/tmp/screenshot_$(date +%s).png"
        grim -g "$region" "$tmp_file"

        # Run Rofi
        option=$(echo -e "Save\nCopy to clipboard" |
            rofi -dmenu \
                -mesg $'<big><b>Screenshot</b></big>\n\nEsc to cancel' \
                -theme "$rofi_menu")

        case "$option" in
        "Save")
            # Move temp file to actual directory
            filename="$img_dir/Screenshot_$(date +%Y%m%d-%H%M%S).png"
            mv "$tmp_file" "$filename"
            notify-send "Screenshot Taken" "Saved to: $img_dir" --icon="$filename"
            kill $view_id # kills the swayimg process
            sleep 0.2
            rm "$frozen_img"
            ;;
        "Copy to clipboard")
            # Copy to clipboard and delete temp file
            if command -v wl-copy >/dev/null; then
                wl-copy <"$tmp_file"
                notify-send "Screenshot Copied" "Image copied to clipboard" --icon="$tmp_file"
            else
                notify-send "Error" "wl-copy is missing"
            fi
            rm "$tmp_file"
            kill $view_id # kills the swayimg process
            sleep 0.2
            rm "$frozen_img"
            ;;
        *)
            # Clean up on pressing esc
            kill $view_id # kills the swayimg process
            sleep 0.2
            rm "$frozen_img"
            rm "$tmp_file"
            notify-send "Screenshot Discarded..."
            ;;
        esac
    else
        kill $view_id # kills the swayimg process
        sleep 0.2
        rm "$frozen_img"
        notify-send "Screenshot Cancelled..."
    fi
}

screen_record() {
    # New recording with audio
    audio_source=$(pactl list short sources | grep 'monitor' | grep 'RUNNING' | awk '{print $2}' | head -n 1)
    # If no source is running, grab the first available monitor source
    if [ -z "$audio_source" ]; then
        audio_source=$(pactl list short sources | grep 'monitor' | awk '{print $2}' | head -n 1)
    fi
    filename="$vid_dir/Recording_$(date +%Y%m%d-%H%M%S).mp4"
    region=$(slurp)
    if [ -n "$region" ]; then

        # Run Rofi
        option=$(echo -e "Yes\nNo" |
            rofi -dmenu \
                -mesg $'<big><b>Record with audio? </b></big>\n\nEsc to cancel' \
                -theme "$rofi_menu")

        case "$option" in
        "Yes")
            wf-recorder -g "$region" --audio="$audio_source" -r 60 -f "$filename" &>/dev/null &
            # Saves the recording name to a tmp file
            echo "$filename" >"/tmp/recording.name"
            notify-send -t 1500 "Screen Record" "Recording Started with audio..."
            ;;
        "No")
            wf-recorder -g "$region" -r 60 -f "$filename" &>/dev/null &
            # Saves the recording name to a tmp file
            echo "$filename" >"/tmp/recording.name"
            notify-send -t 1500 "Screen Record" "Recording Started without audio..."
            ;;
        *)
            notify-send "Screen-recording Cancelled..."
            ;;
        esac
    else
        notify-send "Screen-recording Cancelled..."
    fi
}

# --- Handle the choice ---
case "$main_choice" in
"Screenshot")
    screenshot
    ;;
"Start-recording")
    screen_record
    ;;
"Stop-recording")
    # Stops recording and generates beautifull..... thumbnail for notification icon
    pkill -SIGINT wf-recorder
    play_button="$HOME/.config/rofi/screen-tool/play-icon.png"
    file=$(<"/tmp/recording.name")
    temp_thumb="/tmp/temp_thumb.png"
    thumbnail="/tmp/thumbnail.png"
    ffmpegthumbnailer -i "$file" -o "$temp_thumb" &>/dev/null
    sleep 0.05
    magick "$temp_thumb" -fill black -colorize 30% "$play_button" -gravity center -composite "$thumbnail"
    sleep 0.05
    notify-send "Screen Record" "Saved to: $vid_dir" --icon "$thumbnail"
    sleep 0.5
    rm "$thumbnail" "$temp_thumb" "/tmp/recording.name"
    ;;
*)
    exit 0
    ;;
esac
