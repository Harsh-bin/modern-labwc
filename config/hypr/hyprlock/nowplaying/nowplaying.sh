#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# --- Configuration ---
config_dir="$HOME/.config/hypr/hyprlock/nowplaying"
art_file="$config_dir/album_art.png"
fallback_art_file="$config_dir/fallback_album_art.png"
title_cache_file="$config_dir/song_title.cache"
player_cache_file="$config_dir/player.cache"

# --- Functions ---

# Determine active player

players_list=$(playerctl -l 2>/dev/null)
active_player=""
active_player_priority=0

if [ -f "$player_cache_file" ]; then
    cached_player_name=$(cat "$player_cache_file")
fi

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

# play-pause toggle
if [[ "$1" == "--toggle" ]]; then
    if [[ -n "$active_player" ]]; then
        playerctl -p "$active_player" play-pause
        echo "$active_player" >"$player_cache_file"
    fi
    exit 0
fi

# Art clean up if no valid player found for clean look on hyprlock screen.
if [[ -z "$active_player" ]]; then
    rm "$art_file" 2>/dev/null
    rm "$title_cache_file" 2>/dev/null
    rm "$player_cache_file" 2>/dev/null
    echo "$active_player" >"$player_cache_file"
    exit 0
fi

# Function to escape special characters
escape_characters() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}
url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

if [[ -n "$active_player" ]]; then
    # Retrieve metadata
    raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
    raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

    # Escape special characters
    clean_name="${active_player%%.*}"
    clean_name="$(tr '[:lower:]' '[:upper:]' <<<${clean_name:0:1})${clean_name:1}"
    player_display_name=$(escape_characters "$clean_name")
    song_title=$(escape_characters "$raw_title")
    song_artist=$(escape_characters "$raw_artist")

    # Handle album_art_url output
    cached_title=""
    if [[ -f "$title_cache_file" ]]; then
        cached_title=$(cat "$title_cache_file")
    fi
    if [[ "$raw_title" != "$cached_title" ]] || [[ ! -f "$art_file" ]]; then
        echo "$raw_title" >"$title_cache_file"

        album_art_url=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)

        if [[ -z "$album_art_url" ]]; then
            # Case 0: No art URL found -> use fallback art file
            cp "$fallback_art_file" "$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^data:image ]]; then
            # Case 1: Base64 Data URI
            base64_data=$(echo "$album_art_url" | cut -d',' -f2)
            echo "$base64_data" | base64 -d >"$art_file" 2>/dev/null
        elif [[ "$album_art_url" =~ ^file:// ]]; then
            # Case 2: Standard URL (file://) for browsers
            raw_path="${album_art_url#file://}"
            decoded_path="$(url_decode "$raw_path")"
            cp "$decoded_path" "$art_file"
        elif [[ "$album_art_url" =~ ^https:// ]]; then
            # Case 3: Web URL
            curl -s "$album_art_url" --output "$art_file"
        fi
        # c
        echo "Converting file to png"
        magick "$art_file" "$art_file"
    fi
fi

# Print Output
status=$(playerctl -p "$active_player" status 2>/dev/null)
if [[ "$status" != "Playing" ]]; then
    player_status="Paused"
else
    player_status=""
fi

# Added truncate function for song title
short_title=$(echo "$song_title" | sed -E "s/^(.{60}).+/\1.../")
# Print Output
echo -e "<span font_weight='light' size='small'>${player_display_name} <small>${player_status}</small> \
</span>\n<b>${short_title}</b>\n<span size='small' style='italic'>${song_artist}</span>"
