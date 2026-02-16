#!/bin/bash

# --- GLOBAL CONFIGURATION ---
script_dir="$HOME/.config/waybar/scripts/clock_calendar"
config_file="$script_dir/config.json"
state_file="$script_dir/calendar.state"
style_file="$HOME/.config/waybar/style.css"

# source color extraction script
source "$HOME/.config/waybar/scripts/css_color_extraction.sh"

# define colors
event_color="$primary_color"
today_color="$secondary_color"
past_color="$secondary_color"

if [ ! -f "$config_file" ]; then
    mkdir -p "$(dirname "$config_file")"
    echo "{ \"time_format\": \"%I:%M %p\", \"date_format\": \"%d/%m/%y\", \"events\": [] }" >"$config_file"
fi

get_setting() {
    val=$(jq -r ".$1" "$config_file")
    if [[ "$val" == "null" || -z "$val" ]]; then
        case "$1" in
        "time_format") echo "%I:%M %p" ;;
        "date_format") echo "%d/%m/%y" ;;
        *) echo "" ;;
        esac
    else
        echo "$val"
    fi
}

set_setting() {
    tmp=$(mktemp)
    jq --arg v "$2" ".$1 = \$v" "$config_file" >"$tmp" && mv "$tmp" "$config_file"
}

get_ordered_events() {
    local today=$(date +%Y-%m-%d)
    jq -r --arg d "$today" '
        .events | 
        # Sort by: Is Past? (False=0, True=1), then Date
        sort_by(.date < $d, .date)[] | 
        "\(.date)\t\(.desc)\t\(if .date < $d then "P" else "U" end)"
    ' "$config_file"
}

json_add_event() {
    local date_in="$1"
    local desc_in="$2"
    local tmp=$(mktemp)
    jq --arg d "$date_in" --arg t "$desc_in" \
        '.events += [{"date": $d, "desc": $t}]' "$config_file" >"$tmp" && mv "$tmp" "$config_file"
}

json_delete_event() {
    local idx="$1"
    local today=$(date +%Y-%m-%d)
    local tmp=$(mktemp)

    jq --arg d "$today" --argjson i "$idx" '
      .events |= (
        sort_by(.date < $d, .date) | 
        del(.[$i])
      )
    ' "$config_file" >"$tmp" && mv "$tmp" "$config_file"
}

get_offset() {
    if [ ! -f "$state_file" ]; then
        echo "0" >"$state_file"
        echo "0"
        return
    fi
    if [ $(($(date +%s) - $(stat -c %Y "$state_file"))) -gt 30 ]; then
        echo "0" >"$state_file"
        echo "0"
    else
        cat "$state_file"
    fi
}

update_offset() {
    current=$(cat "$state_file" 2>/dev/null || echo "0")
    echo $((current + $1)) >"$state_file"
}

# Waybar Output
output_mode() {
    time_fmt=$(get_setting time_format)
    date_fmt=$(get_setting date_format)
    offset=$(get_offset)

    target_date=$(date -d "$(date +%Y-%m-01) $offset months" +%Y-%m-%d)
    current_month_str=$(date -d "$target_date" +%Y-%m)
    today_day=$(date +%-d)

    cal_raw=$(cal $(date -d "$target_date" "+%m %Y") --color=never | sed "1d")

    # Highlight Events
    event_days=$(jq -r --arg m "$current_month_str" \
        '.events[] | select(.date | startswith($m)) | .date | split("-")[2] | sub("^0";"")' \
        "$config_file" | sort -u)

    cal_formatted="$cal_raw"

    for day in $event_days; do
        if [ "$offset" -eq 0 ] && [ "$day" -eq "$today_day" ]; then continue; fi
        cal_formatted=$(echo "$cal_formatted" | sed -E "s/(^| )($day)($| )/\1<span color='$event_color' weight='bold'>\2<\/span>\3/g")
    done

    if [ "$offset" -eq 0 ]; then
        cal_formatted=$(echo "$cal_formatted" | sed -E "s/(^| )($today_day)($| )/\1<span color='$today_color' weight='bold'>\2<\/span>\3/")
    fi

    # Tooltip Construction

    # Get current full date for comparison (YYYY-MM-DD)
    current_full_date=$(date +%Y-%m-%d)

    # Generate list with conditional formatting for past events
    month_events=$(jq -r --arg m "$current_month_str" --arg today "$current_full_date" --arg sc "$today_color" '
      [ .events[] | select(.date | startswith($m)) ] | sort_by(.date | split("-")[2] | tonumber)             
      | .[] | 
      (.date | split("-")[2]) as $day |
      if .date < $today then
          "<span color=\"" + $sc + "\"><s>• [" + $day + "] " + .desc + "</s></span>"
      else
          "• [" + $day + "] " + .desc
      end
    ' "$config_file")

    nl=$'\n'
    tooltip="<b>$(date -d "$target_date" "+%B %Y")</b>${nl}<tt>$cal_formatted</tt>${nl}<span color='$event_color'>══════════════════</span>${nl}"

    if [ "$offset" -eq 0 ]; then
        today_events=$(jq -r --arg d "$(date +%Y-%m-%d)" '.events[] | select(.date == $d) | "• " + .desc' "$config_file")
        if [ -n "$today_events" ]; then
            tooltip+="<span color='$today_color'><b>Today:</b></span>${nl}$today_events${nl}${nl}"
        fi
    fi

    if [ -n "$month_events" ]; then
        tooltip+="<span color='$event_color'><b>Month Events:</b></span>${nl}$month_events"
    else
        tooltip+="<span color='$event_color'><b>Month Events:</b></span> None"
    fi

    jq -n --unbuffered --compact-output \
        --arg text "$(date +"$time_fmt")" \
        --arg alt "$(date +"$date_fmt")" \
        --arg tool "$tooltip" \
        '{text: $text, alt: $alt, tooltip: $tool, class: "custom-clock"}'
}

# --- ARGUMENT HANDLING ---
case "$1" in
"--show-rofi")
    source "$script_dir/clock_calendar_rofi.sh"
    run_rofi_main
    ;;
"--show-tui")
    source "$script_dir/clock_calendar_tui.sh"
    run_tui_main
    ;;
"--scroll-up") update_offset 1 ;;
"--scroll-down") update_offset -1 ;;
*) output_mode ;;
esac
