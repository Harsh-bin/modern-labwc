# sourced by clock_calendar.sh

theme_main="$script_dir/clock_calendar.rasi"
theme_input="$script_dir/placeholder.rasi"
theme_list="$script_dir/list.rasi"
theme_delete="$script_dir/delete.rasi"

generate_categorized_list() {
    local show_id="${1:-false}"
    local i=1
    local rows_upcoming=""
    local rows_past=""

    while IFS=$'\t' read -r date desc status; do
        local row_str=""

        if [[ "$show_id" == "true" ]]; then
            row_str="$i.|[$date]|$desc"
        else
            row_str="[$date]|$desc"
        fi

        if [[ "$status" == "U" ]]; then
            rows_upcoming+=$'\n'"U|$row_str"
        else
            rows_past+=$'\n'"P|$row_str"
        fi
        ((i++))
    done < <(get_ordered_events)

    local raw_data=""
    local gap_str=""

    if [[ "$show_id" == "true" ]]; then
        raw_data="H|ID|DATE|EVENT"
        gap_str="G|_|_|_"
    else
        raw_data="H|DATE|EVENT"
        gap_str="G|_|_"
    fi

    if [ -n "$rows_upcoming" ]; then raw_data+="$rows_upcoming"; fi

    if [ -n "$rows_upcoming" ] && [ -n "$rows_past" ]; then
        raw_data+=$'\n'"$gap_str"
    fi

    if [ -n "$rows_past" ]; then raw_data+="$rows_past"; fi

    echo "$raw_data" | column -t -s '|' | awk -v pc="$past_color" -v sc="$event_color" '
    BEGIN { }
    /^H/ { 
        sub(/^H  /, ""); 
        print "<tt><b>" $0 "</b></tt>"
        print "<tt> </tt>"
        next 
    }
    /^G/ {
        print "" 
        next
    }
    /^U/ { 
        sub(/^U  /, ""); 
        print "<tt>" $0 "</tt>" 
    }
    /^P/ { 
        sub(/^P  /, ""); 
        print "<span foreground=\"" pc "\"><tt>" $0 "</tt></span>" 
    }
    END {
        print "<tt> </tt>"
    }
    '
}

add_event() {
    local date_in=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "Enter Date (YYYY-MM-DD):")
    if [[ "$date_in" == " Back" || -z "$date_in" ]]; then return; fi
    if [[ ! "$date_in" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        rofi -e "Invalid Date"
        return
    fi

    local desc_in=$(rofi -dmenu -theme "$theme_input" -mesg "Enter Description:")
    if [ -z "$desc_in" ]; then return; fi

    json_add_event "$date_in" "$desc_in"
    notify-send "Event Added" "$desc_in\n$date_in"
}

delete_event() {
    local event_count=$(jq '.events | length' "$config_file")
    if [[ "$event_count" == "0" ]]; then
        echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "No events to delete." >/dev/null
        return
    fi
    local list_view=$(generate_categorized_list "true")
    local msg_del=$'Enter ID to Delete\n\n'"$list_view"

    local del_choice=$(echo -e " Back" | rofi -dmenu -mesg "$msg_del" -theme "$theme_delete")
    if [[ "$del_choice" == " Back" || -z "$del_choice" ]]; then return; fi

    if [[ "$del_choice" =~ ^[0-9]+$ ]] && [ "$del_choice" -ge 1 ] && [ "$del_choice" -le "$event_count" ]; then
        local idx=$((del_choice - 1))
        json_delete_event "$idx"
    fi
}

list_events() {
    local list_content=$(generate_categorized_list "false")
    if ! jq -e '.events | length > 0' "$config_file" >/dev/null; then
        list_content="No events found."
    fi
    echo -e " Back" | rofi -dmenu -mesg "$list_content" -theme "$theme_list" >/dev/null
}

change_format_generic() {
    local fmt=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "$2")
    if [[ "$fmt" != " Back" && -n "$fmt" ]]; then set_setting "$1" "$fmt"; fi
}

change_time_format() {
    local msg=$'<b>Time Reference:</b>\n\n%H (24h) | %I (12h) | %M (Min) | %p (AM/PM)\n\n'
    msg+="<span size='small' style='italic'> Tip! Use separators: <span color='$event_color'>(%I<span color='$today_color'>*</span>%M -> 04<span color='$today_color'>*</span>30)</span></span>"$'\n\nCreate new format:'
    change_format_generic "time_format" "$msg"
}

change_date_format() {
    local msg=$'<b>Date Reference:</b>\n\n%d (01) | %a (Mon) | %A (Monday)\n%m (01) | %b (Jan) | %B (January)\n%y (24) | %Y (2024)\n\n'
    msg+="<span size='small' style='italic'>Tip! Use separators: <span color='$event_color'>(%a <span color='$today_color'>,</span> %d %b -> Mon <span color='$today_color'>,</span> 19 Jan)</span></span>"$'\n\nCreate new format:'
    change_format_generic "date_format" "$msg"
}

run_rofi_main() {
    while true; do
        local tf=$(get_setting time_format)
        local df=$(get_setting date_format)
        local status_msg=$'<b>Waybar Clock-Calendar Manager</b>\n\n'
        status_msg+="Time:   $tf       --->  $(date +"$tf")"$'\n'
        status_msg+="Date:   $df       --->  $(date +"$df")"$''

        local options="  Add Event\n  Change Time Format\n  List Events\n  Change Date Format\n  Delete Event\n󰗼  Quit"
        local choice=$(echo -e "$options" | rofi -dmenu -i -mesg "$status_msg" -theme "$theme_main" -markup-rows)

        case "$choice" in
        *"Add Event") add_event ;;
        *"Delete Event") delete_event ;;
        *"List Events") list_events ;;
        *"Change Time Format") change_time_format ;;
        *"Change Date Format") change_date_format ;;
        *"Quit" | "") break ;;
        esac
    done
}
