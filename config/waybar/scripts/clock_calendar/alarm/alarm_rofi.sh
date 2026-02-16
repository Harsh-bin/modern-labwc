#!/bin/bash

# Configuration
script_dir="$HOME/.config/waybar/scripts/clock_calendar"
theme_main="$script_dir/clock_calendar.rasi"
theme_input="$script_dir/placeholder.rasi"
theme_list="$script_dir/list.rasi"
theme_delete="$script_dir/delete.rasi"
config_dir="$script_dir/alarm"
db_file="$script_dir/alarm/alarms.json"
pid_file="$config_dir/alarm_daemon.pid"

# Colors (Defaults)
active_color="#a6e3a1"   # Green (Primary)
inactive_color="#9399b2" # Grey (Secondary)
urgent_color="#f38ba8"   # Red

# Source color extraction if available
if [ -f "$HOME/.config/waybar/scripts/css_color_extraction.sh" ]; then
    source "$HOME/.config/waybar/scripts/css_color_extraction.sh" >/dev/null 2>&1
    active_color="$primary_color"
    inactive_color="$secondary_color"
    urgent_color="$secondary_color"
fi

# Global feedback variable
ROFI_FEEDBACK=""
# Global ID Map for Rofi interactions
declare -a ROFI_ID_MAP

validate_days() {
    local input="$1"
    if [ -z "$input" ]; then
        echo "once"
        return 0
    fi
    local clean_input
    clean_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    if [[ "$clean_input" =~ ^(mon|tue|wed|thu|fri|sat|sun|daily|once)(,(mon|tue|wed|thu|fri|sat|sun))*$ ]]; then
        echo "$clean_input"
        return 0
    else
        return 1
    fi
}

rebuild_map() {
    ROFI_ID_MAP=()
    local idx=1
	
    while IFS=$'\t' read -r id; do
        ROFI_ID_MAP[$idx]="$id"
        ((idx++))
    done < <(jq -r '.[] | select(.status == "on") | "\(.id)\t\(.time)"' "$db_file" | sort -k2 | cut -f1)

    while IFS=$'\t' read -r id; do
        ROFI_ID_MAP[$idx]="$id"
        ((idx++))
    done < <(jq -r '.[] | select(.status == "off") | "\(.id)\t\(.time)"' "$db_file" | sort -k2 | cut -f1)
}

generate_categorized_alarm_list() {
    local show_id="${1:-false}"
    local visual_idx=1
    local buffer_active=""
    local buffer_inactive=""

    # Active Alarms
    while IFS=$'\t' read -r id display days label sort_time; do
        local row_str="A"
        if [[ "$show_id" == "true" ]]; then
            row_str+="\t$visual_idx."
        fi
        row_str+="\t[${display}]\t${days}\t${label}"

        buffer_active+="${row_str}\n"
        ((visual_idx++))
    done < <(jq -r '.[] | select(.status == "on") | "\(.id)\t\(.display // .time)\t\(.days)\t\(.label)\t\(.time)"' "$db_file" | sort -k5)

    # Inactive Alarms
    while IFS=$'\t' read -r id display days label sort_time; do
        local row_str="I"
        if [[ "$show_id" == "true" ]]; then
            row_str+="\t$visual_idx."
        fi
        row_str+="\t[${display}]\t${days}\t${label}"

        buffer_inactive+="${row_str}\n"
        ((visual_idx++))
    done < <(jq -r '.[] | select(.status == "off") | "\(.id)\t\(.display // .time)\t\(.days)\t\(.label)\t\(.time)"' "$db_file" | sort -k5)

    # Combine with Gap
    local raw_input=""
    if [ -n "$buffer_active" ]; then
        raw_input+="$buffer_active"
    fi

    if [ -n "$buffer_active" ] && [ -n "$buffer_inactive" ]; then
        if [[ "$show_id" == "true" ]]; then
            raw_input+="G\t\t\t\t\n"
        else
            raw_input+="G\t\t\t\n"
        fi
    fi

    if [ -n "$buffer_inactive" ]; then
        raw_input+="$buffer_inactive"
    fi

    if [ -z "$raw_input" ]; then
        echo "No alarms set."
        return
    fi

    local header="H"
    if [[ "$show_id" == "true" ]]; then
        header+="\tID"
    fi
    header+="\tTIME\tDAYS\tLABEL"

    {
        echo -e "$header"
        echo -e "$raw_input"
    } | column -t -s $'\t' | awk -v ac="$active_color" -v ic="$inactive_color" '
    BEGIN { }
    /^H/ { 
        sub(/^H  /, ""); 
        print "<tt><b>" $0 "</b></tt>"
        print "<tt> </tt>"
        next 
    }
    /^G/ { print ""; next } 
    /^A/ {
        sub(/^A  /, "");
        print "<tt><span foreground=\"" ac "\">" $0 "</span></tt>"
    }
    /^I/ {
        sub(/^I  /, "");
        print "<tt><span foreground=\"" ic "\">" $0 "</span></tt>"
    }
    END {
        print "<tt> </tt>"
    }
    '
}

rofi_add_alarm() {
    # 1. TIME
    local time_in
    local msg="Enter Time (e.g. 07:30am, 14:00):"
    while true; do
        time_in=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "$msg")
        if [[ "$time_in" == " Back" || -z "$time_in" ]]; then return; fi
        if LC_TIME=C date -d "$time_in" >/dev/null 2>&1; then break; else
            msg="<span color='$urgent_color'><b>Invalid Time!</b></span> Try again:"
        fi
    done

    local days_in
    local base_msg="Enter Days: <span size='small' >(daily, once, mon,tue...)</span>"
    local days_msg="$base_msg"
    while true; do
        days_in=$(rofi -dmenu -theme "$theme_input" -mesg "$days_msg")
        if [ -z "$days_in" ]; then days_in="once"; fi
        local valid_days
        if valid_days=$(validate_days "$days_in"); then
            days_in="$valid_days"
            break
        else
            days_msg="<span color='$urgent_color'><b>Invalid Days!</b></span> $base_msg"
        fi
    done

    local label_in=$(rofi -dmenu -theme "$theme_input" -mesg "Enter Label:")
    if [ -z "$label_in" ]; then label_in="Alarm"; fi

    if add_alarm_entry "$time_in" "$days_in" "$label_in"; then
        ROFI_FEEDBACK="<span color='$active_color'>Added: $time_in</span>"
    else
        ROFI_FEEDBACK="<span color='$urgent_color'>Failed to add alarm.</span>"
    fi
}

rofi_toggle_alarm() {
    local list_view
    list_view=$(generate_categorized_alarm_list "true")

    if [[ "$list_view" == "No alarms set." ]]; then
        ROFI_FEEDBACK="<span color='$urgent_color'>No alarms to toggle.</span>"
        return
    fi

    local msg_toggle="<b>Toggle Alarm Status</b>"$'\n\n'"$list_view"

    local choice_str=$(echo -e " Back" | rofi -dmenu -theme "$theme_delete" -mesg "$msg_toggle" -markup-rows)
    if [[ "$choice_str" == ""* || -z "$choice_str" ]]; then return; fi

    rebuild_map

    local visual_id=$(echo "$choice_str" | sed 's/<[^>]*>//g' | awk '{print $1}' | sed 's/\.//')

    if [[ -n "$visual_id" && -n "${ROFI_ID_MAP[$visual_id]}" ]]; then
        local real_id="${ROFI_ID_MAP[$visual_id]}"
        jq --arg id "$real_id" \
            'map(if .id == ($id|tonumber) then .status = (if .status=="on" then "off" else "on" end) else . end)' \
            "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
        ROFI_FEEDBACK="<span color='$active_color'>Alarm status toggled.</span>"
    else
        ROFI_FEEDBACK="<span color='$urgent_color'>Invalid selection.</span>"
    fi
}

rofi_delete_alarm() {
    local list_view
    list_view=$(generate_categorized_alarm_list "true")

    if [[ "$list_view" == "No alarms set." ]]; then
        ROFI_FEEDBACK="<span color='$urgent_color'>No alarms to delete.</span>"
        return
    fi

    local msg_del="<b>Select Alarm to Delete</b>"$'\n\n'"$list_view"

    local choice_str=$(echo -e " Back" | rofi -dmenu -theme "$theme_delete" -mesg "$msg_del" -markup-rows)
    if [[ "$choice_str" == ""* || -z "$choice_str" ]]; then return; fi

    rebuild_map

    local visual_id=$(echo "$choice_str" | sed 's/<[^>]*>//g' | awk '{print $1}' | sed 's/\.//')

    if [[ -n "$visual_id" && -n "${ROFI_ID_MAP[$visual_id]}" ]]; then
        local real_id="${ROFI_ID_MAP[$visual_id]}"
        jq --arg id "$real_id" 'map(select(.id != ($id|tonumber)))' \
            "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
        ROFI_FEEDBACK="<span color='$urgent_color'>Alarm deleted.</span>"
    else
        ROFI_FEEDBACK="<span color='$urgent_color'>Invalid selection.</span>"
    fi
}

rofi_list_alarms() {
    local list_view
    list_view=$(generate_categorized_alarm_list "false")

    local full_msg="<b>Current Alarms:</b>"$'\n\n'"$list_view"

    echo -e " Back" | rofi -dmenu -mesg "$full_msg" -theme "$theme_list" -markup-rows >/dev/null
}

run_rofi_main() {
    ROFI_FEEDBACK=""

    while true; do
        # Daemon Check
        local d_status="STOPPED"
        local d_color_tag="$inactive_color"
        if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
            d_status="RUNNING"
            d_color_tag="$active_color"
        fi

        local count_active=$(jq '[.[] | select(.status=="on")] | length' "$db_file")
        local count_total=$(jq '. | length' "$db_file")

        # Header
        local status_msg="<b>Alarm Manager</b>

<b>Daemon:</b>        <span color='$d_color_tag' weight='bold'>$d_status</span>
<b>Active Alarms:</b> $count_active / $count_total"

        if [ -n "$ROFI_FEEDBACK" ]; then
            status_msg="$status_msg"$'\n\n'"<b>Message:</b>       $ROFI_FEEDBACK"
        fi

        local options="  Add Alarm\n  Toggle Status\n  List Alarms\n  Delete Alarm\n"
        if [ "$d_status" == "RUNNING" ]; then
            options+="  Restart Daemon\n"
        else
            options+="  Start Daemon\n"
        fi
        options+="󰗼  Quit"

        local choice=$(echo -e "$options" | rofi -dmenu -i -mesg "$status_msg" -theme "$theme_main" -markup-rows)
        ROFI_FEEDBACK=""

        case "$choice" in
        *"Add Alarm") rofi_add_alarm ;;
        *"Toggle Status") rofi_toggle_alarm ;;
        *"List Alarms") rofi_list_alarms ;;
        *"Delete Alarm") rofi_delete_alarm ;;
        *"Start Daemon")
            start_daemon
            sleep 0.5
            ROFI_FEEDBACK="Daemon Started."
            ;;
        *"Restart Daemon")
            stop_daemon
            sleep 0.2
            start_daemon
            sleep 0.5
            ROFI_FEEDBACK="Daemon Restarted."
            ;;
        *"Quit" | "") break ;;
        esac
    done
}