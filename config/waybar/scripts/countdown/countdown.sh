#!/bin/bash

# --- configuration ---
script_dir="$HOME/.config/waybar/scripts/countdown"
data_file="$script_dir/countdown.json"

# script paths
rofi_script="$script_dir/countdown_rofi.sh"
tui_script="$script_dir/countdown_tui.sh"

# source color extraction script
source "$HOME/.config/waybar/scripts/css_color_extraction.sh"
# define colors
expired_color="$secondary_color"
seperator_color="$primary_color"

ensure_json_exists() {
    if [ ! -f "$data_file" ]; then
        echo '{
  "state": {
    "current_index": 0
  },
  "countdowns": []
}' >"$data_file"
    fi
}

get_countdown_count() {
    jq '.countdowns | length' "$data_file"
}

get_current_index() {
    jq -r '.state.current_index // 0' "$data_file"
}

update_state_index() {
    local new_idx=$1
    local tmp_file=$(mktemp)
    jq --argjson idx "$new_idx" '.state.current_index = $idx' "$data_file" >"$tmp_file" && mv "$tmp_file" "$data_file"
}

json_add_countdown() {
    local lbl="$1"
    local start="$2"
    local end="$3"
    local fmt="$4"
    local tmp_file=$(mktemp)

    jq --arg l "$lbl" --arg s "$start" --arg e "$end" --arg f "$fmt" \
        '.countdowns += [{"label": $l, "start": $s, "end": $e, "format": $f}]' "$data_file" >"$tmp_file" && mv "$tmp_file" "$data_file"
}

json_edit_countdown() {
    local idx="$1"
    local lbl="$2"
    local start="$3"
    local end="$4"
    local fmt="$5"
    local tmp_file=$(mktemp)

    jq --argjson i "$idx" --arg l "$lbl" --arg s "$start" --arg e "$end" --arg f "$fmt" \
        '.countdowns[$i] = {"label": $l, "start": $s, "end": $e, "format": $f}' "$data_file" >"$tmp_file" && mv "$tmp_file" "$data_file"
}

json_delete_countdown() {
    local idx="$1"
    local tmp_file=$(mktemp)
    jq --argjson i "$idx" 'del(.countdowns[$i])' "$data_file" >"$tmp_file" && mv "$tmp_file" "$data_file"

    local count
    count=$(get_countdown_count)
    local curr
    curr=$(get_current_index)

    if [ "$curr" -ge "$count" ] && [ "$count" -gt 0 ]; then
        update_state_index 0
    fi
}

handle_scroll() {
    local direction=$1
    local count=$(get_countdown_count)
    if [ "$count" -le 1 ]; then return; fi

    local current=$(get_current_index)
    local new_index=$current

    if [[ "$direction" == "up" ]]; then
        new_index=$((current - 1))
        if [ "$new_index" -lt 0 ]; then new_index=$((count - 1)); fi
    elif [[ "$direction" == "down" ]]; then
        new_index=$((current + 1))
        if [ "$new_index" -ge "$count" ]; then new_index=0; fi
    fi

    update_state_index "$new_index"
}

# Waybar Output

generate_waybar_output() {
    local count=$(get_countdown_count)
    if [ "$count" -eq 0 ]; then
        echo '{"text": "No Countdowns", "tooltip": "Right-click to add a new countdown", "percentage": 0}'
        return
    fi

    local current_index=$(get_current_index)
    if [ "$current_index" -ge "$count" ]; then
        current_index=0
        update_state_index 0
    fi

    local rows_active=""
    local rows_expired=""
    local now_secs=$(date +%s)

    while IFS=$'\t' read -r label start_date end_date fmt; do
        local start_secs=$(date -d "$start_date" +%s 2>/dev/null)
        local end_secs=$(date -d "$end_date" +%s 2>/dev/null)
        local left_info=""
        local is_expired=0

        if [[ -z "$start_secs" || -z "$end_secs" ]]; then
            left_info="Invalid Date"
        elif [ "$now_secs" -ge "$end_secs" ]; then
            left_info="Expired!"
            is_expired=1
        else
            local remaining_secs=$((end_secs - now_secs))
            local remaining_days=$((remaining_secs / 86400))
            local total_secs=$((end_secs - start_secs))
            local pct=0
            if [ "$total_secs" -gt 0 ]; then pct=$(echo "scale=0; ($remaining_secs * 100) / $total_secs" | bc); fi
            [ "$pct" -gt 100 ] && pct=100
            [ "$pct" -lt 0 ] && pct=0
            left_info="$remaining_days days ($pct%)"
        fi

        local row="|$label|$end_date|$left_info"

        if [ "$is_expired" -eq 1 ]; then
            rows_expired+=$'\n'"E${row}"
        else
            rows_active+=$'\n'"A${row}"
        fi
    done < <(jq -r '.countdowns[] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")

    local raw_data="H|Labels|Date|Left"
    if [ -n "$rows_active" ]; then raw_data+="$rows_active"; fi

    if [ -n "$rows_active" ] && [ -n "$rows_expired" ]; then
        raw_data+=$'\n'"G|_|_|_"
    fi

    if [ -n "$rows_expired" ]; then raw_data+="$rows_expired"; fi

    local tooltip_body
    tooltip_body=$(echo "$raw_data" | column -t -s '|' | awk -v ec="$expired_color" '
    BEGIN { }
    /^H/ { 
        sub(/^H  /, ""); 
        print "<b>" $0 "</b>"
        next 
    }
    /^G/ { 
        print ""
        next
    }
    /^A/ { 
        sub(/^A  /, ""); 
        print $0 
    }
    /^E/ { 
        sub(/^E  /, ""); 
        print "<span foreground=\"" ec "\">" $0 "</span>"
    }
    ')

    local tooltip="<b><u>Countdowns</u></b>\n\n<tt>${tooltip_body}</tt>"

    IFS=$'\t' read -r label start_date end_date format < <(jq -r --argjson idx "$current_index" '.countdowns[$idx] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")

    local start_secs=$(date -d "$start_date" +%s 2>/dev/null)
    local end_secs=$(date -d "$end_date" +%s 2>/dev/null)
    local now_secs=$(date +%s)
    local short_label=$(echo "$label" | sed -E "s/^(.{16}).+/\1.../")
    local tooltip_json=$(echo -e "$tooltip" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    if [ "$now_secs" -ge "$end_secs" ]; then
        echo "{\"text\": \"$short_label - Expired!\", \"tooltip\": \"$tooltip_json\", \"percentage\": 100, \"class\": \"expired\"}"
        return
    fi

    local total_secs=$((end_secs - start_secs))
    local remaining_secs=$((end_secs - now_secs))
    local remaining_days=$((remaining_secs / 86400))
    local json_percentage=0
    local display_percentage=0

    if [ "$total_secs" -gt 0 ]; then
        local completed_secs=$((now_secs - start_secs))
        json_percentage=$(echo "scale=0; ($completed_secs * 100) / $total_secs" | bc)
        display_percentage=$(echo "scale=2; ($remaining_secs * 100) / $total_secs" | bc)
    fi

    [ $(echo "$json_percentage > 100" | bc -l) -eq 1 ] && json_percentage="100"
    [ $(echo "$json_percentage < 0" | bc -l) -eq 1 ] && json_percentage="0"

    local text=""
    if [ "$format" == "percentage" ]; then
        local text_percentage=$(echo "$display_percentage" | sed 's/\.00$//')
        text="$short_label - $text_percentage% left"
    else
        text="$short_label - $remaining_days days left"
    fi

    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip_json\", \"percentage\": $json_percentage}"
}

ensure_json_exists

# --- Argument Handling ---
case "$1" in
--show-rofi)
    if [[ -f "$rofi_script" ]]; then
        source "$rofi_script"
        show_rofi_menu
    else
        echo "Error: Rofi script not found."
    fi
    exit 0
    ;;
--show-tui)
    if [[ -f "$tui_script" ]]; then
        source "$tui_script"
        show_tui_menu
    else
        echo "Error: TUI script not found."
    fi
    exit 0
    ;;
--scroll-up)
    handle_scroll "up"
    exit 0
    ;;
--scroll-down)
    handle_scroll "down"
    exit 0
    ;;
esac

generate_waybar_output
