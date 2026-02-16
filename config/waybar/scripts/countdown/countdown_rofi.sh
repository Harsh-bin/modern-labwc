# this script is sourced by the main countdown.sh

theme_main="$script_dir/countdown.rasi"
theme_input="$script_dir/placeholder.rasi"
theme_input2="$script_dir/placeholder2.rasi"
theme_confirm="$script_dir/horizontal_menu.rasi"

generate_categorized_list() {
    local show_id="${1:-false}"
    if [ ! -f "$data_file" ]; then return; fi

    local now_secs=$(date +%s)
    local i=1

    local rows_active=""
    local rows_expired=""

    while IFS=$'\t' read -r label start end fmt; do
        local start_secs=$(date -d "$start" +%s 2>/dev/null)
        local end_secs=$(date -d "$end" +%s 2>/dev/null)
        local status_str=""
        local is_expired=0

        if [[ -z "$start_secs" || -z "$end_secs" ]]; then
            status_str="Invalid"
        elif [ "$now_secs" -ge "$end_secs" ]; then
            status_str="Expired!"
            is_expired=1
        else
            local total_secs=$((end_secs - start_secs))
            local rem_secs=$((end_secs - now_secs))
            local rem_days=$((rem_secs / 86400))
            local pct=0
            if [ "$total_secs" -gt 0 ]; then pct=$(echo "scale=0; ($rem_secs * 100) / $total_secs" | bc); fi
            [ "$pct" -gt 100 ] && pct=100
            [ "$pct" -lt 0 ] && pct=0
            status_str="$rem_days days ($pct%)"
        fi

        local row_str=""
        if [[ "$show_id" == "true" ]]; then
            row_str="$i.|$label|$end|$status_str"
        else
            row_str="$label|$end|$status_str"
        fi

        if [ "$is_expired" -eq 1 ]; then
            rows_expired+=$'\n'"E|$row_str"
        else
            rows_active+=$'\n'"A|$row_str"
        fi
        ((i++))
    done < <(jq -r '.countdowns[] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")

    local raw_data=""
    local gap_str=""

    if [[ "$show_id" == "true" ]]; then
        raw_data="H|ID|LABEL|DATE|LEFT"
        gap_str="G|_|_|_|_"
    else
        raw_data="H|LABEL|DATE|LEFT"
        gap_str="G|_|_|_"
    fi

    if [ -n "$rows_active" ]; then raw_data+="$rows_active"; fi

    if [ -n "$rows_active" ] && [ -n "$rows_expired" ]; then
        raw_data+=$'\n'"$gap_str"
    fi

    if [ -n "$rows_expired" ]; then raw_data+="$rows_expired"; fi

    echo "$raw_data" | column -t -s '|' | awk -v ec="$expired_color" -v sc="$seperator_color" '
    BEGIN { }
    /^H/ { 
        sub(/^H  /, ""); 
        print "<tt><b>" $0 "</b></tt>"
        print "<tt> </tt>"
        next 
    }
    /^G/ {
        # Gap Line
        print ""
        next
    }
    /^A/ { 
        sub(/^A  /, ""); 
        print "<tt>" $0 "</tt>"
    }
    /^E/ { 
        sub(/^E  /, ""); 
        print "<span foreground=\"" ec "\"><tt>" $0 "</tt></span>"
    }
    END {
        print "<tt> </tt>"
    }
    '
}

select_countdown_id() {
    local action_verb="$1"
    local count=$(get_countdown_count)

    if [ "$count" -eq 0 ]; then
        echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "No countdowns to $action_verb." >/dev/null
        echo "0"
        return
    fi

    local list_view=$(generate_categorized_list "true")
    local msg=$'<b>Enter ID to '"$action_verb"$'</b>\n\n'
    msg+="$list_view"

    local id_in=$(echo -e " Back" | rofi -dmenu -theme "$theme_input2" -mesg "$msg")

    if [[ "$id_in" == " Back" ]]; then id_in=""; fi

    if [[ "$id_in" =~ ^[0-9]+$ ]]; then
        if [ "$id_in" -ge 1 ] && [ "$id_in" -le "$count" ]; then
            echo "$id_in"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# --- Main Functions ---

add_countdown_rofi() {
    local new_label=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "Enter Name of the countdown:")
    if [[ "$new_label" == " Back" || -z "$new_label" ]]; then return; fi

    local today=$(date +%Y-%m-%d)
    local msg_date=$'<b>Format:</b> YYYY-MM-DD\n'
    msg_date+="Default: Today ($today)"

    local new_start_date=$(rofi -dmenu -theme "$theme_input" -mesg "$msg_date")
    [ -z "$new_start_date" ] && new_start_date="$today"

    local msg_end=$'<b>Format:</b> YYYY-MM-DD\n'
    msg_end+="Enter the target date:"

    local new_end_date=$(rofi -dmenu -theme "$theme_input" -mesg "$msg_end")
    if [[ "$new_end_date" == "" || -z "$new_end_date" ]]; then return; fi

    local format_opts="Days\nPercentage"
    local new_format=$(echo -e "$format_opts" | rofi -dmenu -mesg "Choose display format" -theme "$theme_confirm")

    if [[ -z "$new_format" ]]; then
        return
    elif [[ "$new_format" == "Percentage" ]]; then
        new_format="percentage"
    else new_format="days"; fi

    json_add_countdown "$new_label" "$new_start_date" "$new_end_date" "$new_format"
}

edit_countdown_rofi() {
    local choice=$(select_countdown_id "Edit")
    if [ "$choice" -eq 0 ]; then return; fi

    local idx=$((choice - 1))
    IFS=$'\t' read -r current_label current_start_date current_end_date current_format < <(jq -r --argjson i "$idx" '.countdowns[$i] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")

    local msg_label="Current Label: <b>$current_label</b> (Leave empty to keep)"
    local new_label=$(rofi -dmenu -theme "$theme_input" -mesg "$msg_label")
    [ -z "$new_label" ] && new_label="$current_label"

    local msg_start="Current Start Date: <b>$current_start_date</b> (Leave empty to keep)"
    local new_start_date=$(rofi -dmenu -theme "$theme_input" -mesg "$msg_start")
    [ -z "$new_start_date" ] && new_start_date="$current_start_date"

    local msg_end="Current End Date: <b>$current_end_date</b> (Leave empty to keep)"
    local new_end_date=$(rofi -dmenu -theme "$theme_input" -mesg "$msg_end")
    [ -z "$new_end_date" ] && new_end_date="$current_end_date"

    local new_format="days"
    local format_display="Days"
    [[ "$current_format" == "percentage" ]] && format_display="Percentage"

    local format_choice=$(echo -e "Days\nPercentage" | rofi -dmenu -mesg "Current Format: $format_display" -theme "$theme_confirm")

    if [[ "$format_choice" == "Percentage" ]]; then
        new_format="percentage"
    elif [[ "$format_choice" == "Days" ]]; then
        new_format="days"
    elif [[ -z "$format_choice" ]]; then
        return
    else new_format="$current_format"; fi

    json_edit_countdown "$idx" "$new_label" "$new_start_date" "$new_end_date" "$new_format"
}

delete_countdown_rofi() {
    local choice=$(select_countdown_id "Delete")
    if [ "$choice" -eq 0 ]; then return; fi

    local idx=$((choice - 1))
    local label_to_delete=$(jq -r --argjson i "$idx" '.countdowns[$i].label' "$data_file")

    local msg_confirm=$'Are you sure you want to delete:\n'
    msg_confirm+="<b>$label_to_delete</b>?"

    local confirm=$(echo -e "No\nYes" | rofi -dmenu -mesg "$msg_confirm" -theme "$theme_confirm")

    if [[ "$confirm" == "Yes" ]]; then
        json_delete_countdown "$idx"
    fi
}

show_rofi_menu() {
    while true; do
        local count=$(get_countdown_count)
        local msg=$'<b>Waybar Countdown Manager</b>\n\n'

        if [ "$count" -gt 0 ]; then
            local list_text=$(generate_categorized_list "false")
            msg+="$list_text"
        else
            msg+=$'<span style="italic">No countdowns set.</span>'
        fi

        local options="  Add Countdown"
        if [ "$count" -gt 0 ]; then
            options+="\n  Edit Countdown\n  Delete Countdown"
        fi
        options+="\n󰗼  Quit"

        local choice=$(echo -e "$options" | rofi -dmenu -mesg "$msg" -theme "$theme_main")

        case "$choice" in
        *"Add Countdown") add_countdown_rofi ;;
        *"Edit Countdown") edit_countdown_rofi ;;
        *"Delete Countdown") delete_countdown_rofi ;;
        *"Quit" | *) exit 0 ;;
        esac
    done
}
