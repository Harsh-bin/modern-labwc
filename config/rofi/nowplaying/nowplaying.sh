#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# --- Configuration ---
config_dir="$HOME/.config/rofi/nowplaying"
art_file="$config_dir/album_art.png"
fallback_art_file="$config_dir/fallback_album_art.png"
rofi_theme="$config_dir/styles/style-5"
# styles directory
styles_dir="$config_dir/styles"
# cache files
title_cache_file="$config_dir/song_title.cache"
player_cache_file="$config_dir/player.cache"
# notification id
notify_id=$(if pgrep -x "swaync" >/dev/null; then echo "-h string:x-canonical-private-synchronous:nowplaying"; else echo "-r 3453"; fi)

# --- Functions ---

# Function to escape special characters
escape_characters() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}
url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# script to apply and remove overlay effects from style-2, 3 and 5
source "$config_dir/overlay.sh"

###################################################
# Function to determine active player   ###########
# new and better with last player cache ###########
###################################################

active_player=""
cached_player_name=""
active_player_priority=0

if [ -f "$player_cache_file" ]; then
    cached_player_name=$(cat "$player_cache_file")
fi

players_list=$(playerctl -l 2>/dev/null)
while IFS= read -r player; do
    if [ -z "$player" ]; then continue; fi

    status=$(playerctl -p "$player" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
    title=$(playerctl -p "$player" metadata title 2>/dev/null)

    # Priority Levels:
    # 3 = Playing
    # 2 = Paused
    # 1 = Stopped (but has media/title)
    # 0 = Ghost / No media like chromium based browsers

    current_priority=0

    if [ "$status" == "playing" ]; then
        current_priority=3
    elif [ "$status" == "paused" ]; then
        current_priority=2
    elif [ -n "$title" ]; then
        current_priority=1
    else
        current_priority=0
    fi

    if [ "$current_priority" -gt "$active_player_priority" ]; then
        active_player="$player"
        active_player_priority=$current_priority
    fi
    # If this is the cached player, save its current priority for later
    if [ "$player" == "$cached_player_name" ]; then
        cached_player_current_priority=$current_priority
    fi

done <<<"$players_list"

# If no player is currently 'Playing', and the cached player
# is alive and has media (Priority >= 1), override the decision.
if [ "$active_player_priority" -lt 3 ] && [ "$cached_player_current_priority" -ge 1 ]; then
    active_player="$cached_player_name"
    active_player_priority=$cached_player_current_priority
fi

######################################################
# Function to fetch media metadata and albumart ######
######################################################

fetch_data() {

    pre=""
    next=""
    toggle=""
    player_status="Paused"

    status=$(playerctl -p "$active_player" status 2>/dev/null)
    if [[ "$status" = "Playing" ]]; then
        toggle=""
        player_status="Playing"
    fi

    # Metadata used by rofi when nothing is playing
    short_title="Nothing Playing"
    song_artist="Unknown"
    player_display_name=""

    if [[ -n "$active_player" ]]; then
        raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
        raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

        clean_name="${active_player%%.*}"
        clean_name="$(tr '[:lower:]' '[:upper:]' <<<${clean_name:0:1})${clean_name:1}"
        player_display_name=$(escape_characters "$clean_name")
        song_title=$(escape_characters "$raw_title")
        song_artist=$(escape_characters "$raw_artist")
        short_title=$(echo "$song_title" | sed -E "s/^(.{80}).+/\1.../")
    fi

    # Function to generate albumart
    # url for fetching albumart
    album_art_url=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)

    # check cache file and generate albumart if needed
    cached_title=""
    if [[ -f "$title_cache_file" ]]; then
        cached_title=$(cat "$title_cache_file")
    fi
    if [[ "$raw_title" != "$cached_title" ]] || [[ ! -f "$art_file" ]]; then
        echo "$raw_title" >"$title_cache_file"

        if [[ -z "$album_art_url" ]]; then
            cp "$fallback_art_file" "$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^data:image ]]; then
            base64_data=$(echo "$album_art_url" | cut -d',' -f2)
            echo "$base64_data" | base64 -d >"$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^file:// ]]; then
            raw_path="${album_art_url#file://}"
            decoded_path="$(url_decode "$raw_path")"
            cp "$decoded_path" "$art_file"
        elif [[ "$album_art_url" =~ ^https:// ]]; then
            curl -s "$album_art_url" --output "$art_file"
        fi
        echo "generating artfile"
    fi

    # Clean up art and cache files if no active player
    if [[ -z "$active_player" ]]; then
        rm "$art_file" 2>/dev/null
        rm "$title_cache_file" 2>/dev/null
        rm "$player_cache_file" 2>/dev/null
        player_status=""
        # removes the overlay
        remove_overlay
    fi
}

# Function to send notification
send_notification() {
    if [[ -n "$active_player" ]]; then
        while true; do
            fetch_data
            # Timeout is needed as if you are using swaync with dnd mode then,
            # each time when notification is generated by rofi action a new process runs (personal experience)
            action=$(timeout 100s notify-send $notify_id "$player_display_name $player_status" \
                "$short_title\n<span style='italic' alpha='85%'>$song_artist</span>" \
                --icon="$art_file" \
                --action="previous=Previous" \
                --action="play-pause=$toggle" \
                --action="next=Next")

            if [ "$action" == "previous" ]; then
                playerctl -p "$active_player" previous
            elif [ "$action" == "play-pause" ]; then
                playerctl -p "$active_player" play-pause
                echo "$active_player" >"$player_cache_file"
                return
            elif [ "$action" == "next" ]; then
                playerctl -p "$active_player" next
            elif [ -z "$action" ]; then
                return
            fi
            wait
        done
    else
        echo "Nothing Playing No Notification Sent..."
    fi
}

# Fetch data for rofi display
fetch_data

# Print Output
display_text="<span weight='light' size='small' alpha='50%'>${player_display_name} \
${player_status}</span>\n\n${short_title}\n\n\
<span size='small' style='italic' alpha='85%'>${song_artist}</span>"

# --- Launch Rofi ---
selected_option=$(echo -e "$pre\n$toggle\n$next" | rofi -dmenu \
    -theme "$rofi_theme" \
    -theme-str "textbox-custom { str: \"$display_text\"; }" \
    -select "$toggle")

case "$selected_option" in
"$pre")
    playerctl -p "$active_player" previous
    fetch_data
    send_notification
    ;;
"$toggle")
    playerctl -p "$active_player" play-pause
    echo "$active_player" >"$player_cache_file"
    fetch_data
    send_notification
    ;;
"$next")
    playerctl -p "$active_player" next
    fetch_data
    send_notification
    ;;
esac

trap apply_light_overlay EXIT
