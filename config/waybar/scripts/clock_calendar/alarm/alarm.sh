#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# Configuration
config_dir="$HOME/.config/waybar/scripts/clock_calendar/alarm"
db_file="$config_dir/alarms.json"
sound_file="$config_dir/beep.wav"
pid_file="$config_dir/alarm_daemon.pid"
monitor_script="$config_dir/alarm_monitor.py"
alarm_icon="$config_dir/clock.png"
snoozed_icon="$config_dir/snooze.png"

# Rofi script path
rofi_script="$HOME/.config/waybar/scripts/clock_calendar/alarm/alarm_rofi.sh"

# Color Extraction
source "$HOME/.config/waybar/scripts/css_color_extraction.sh" 2>/dev/null
term_primary="${term_primary:-\033[0;37m}"
term_secondary="${term_secondary:-\033[0;90m}"
reset="\033[0m"

# Ensure config exists
mkdir -p "$config_dir"
if [ ! -f "$db_file" ]; then echo "[]" >"$db_file"; fi

###########################################################
# DAEMON MANAGEMENT (Fix: Process Management) #############
############################################################

is_daemon_running() {
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        # Check if process exists AND contains "alarm_monitor.py" in command
        if ps -p "$pid" -o args= 2>/dev/null | grep -q "alarm_monitor.py"; then
            return 0
        fi
    fi
    return 1
}

start_daemon() {
    if is_daemon_running; then
        echo "Daemon is already running."
        return
    fi
    # Remove stale pid file if it exists but process is dead
    rm -f "$pid_file"

    python3 "$monitor_script" >/dev/null 2>&1 &
    echo $! >"$pid_file"
    echo "Daemon started."
}

stop_daemon() {
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if ps -p "$pid" >/dev/null 2>&1; then
            kill "$pid" 2>/dev/null
        fi
        rm -f "$pid_file"
        echo "Daemon stopped."
    fi
}

get_next_id() {
    # Stable Internal ID: Max ID + 1
    jq '[.[] | .id] | max + 1 // 1' "$db_file"
}

add_alarm_entry() {
    local raw_time="$1"
    local raw_days="$2"
    local raw_label="$3"

    if ! LC_TIME=C date -d "$raw_time" >/dev/null 2>&1; then
        echo "Error: Invalid time format '$raw_time'. Please use format like '14:30' or '2:30pm'."
        return 1
    fi

    local days="${raw_days:-once}"
    days=$(echo "$days" | tr '[:upper:]' '[:lower:]')

    if [[ ! "$days" =~ ^(mon|tue|wed|thu|fri|sat|sun|daily|once)(,(mon|tue|wed|thu|fri|sat|sun))*$ ]]; then
        echo "Error: Invalid days format '$days'."
        return 1
    fi

    # Check Daemon
    if ! is_daemon_running; then
        echo "Error: Daemon is not active.."
        read -r -p "Do you want to start the daemon now? [Y/n] " response
        response=${response:-y}
        case "$response" in
        [yY] | [yY][eE][sS])
            start_daemon
            if ! is_daemon_running; then
                echo "Critical: Failed to start daemon. Alarm not added."
                return 1
            fi
            ;;
        *)
            echo "Operation cancelled. Alarm NOT added."
            return 1
            ;;
        esac
    fi
    local fmt_time
    fmt_time=$(LC_TIME=C date -d "$raw_time" +%H:%M:%S)

    local label="${raw_label:-Alarm}"
    local new_id
    new_id=$(get_next_id)
    jq --arg id "$new_id" --arg time "$fmt_time" \
        --arg days "$days" --arg label "$label" --arg display "$raw_time" \
        '. += [{"id": ($id|tonumber), "time": $time, "display": $display, "days": $days, "status": "on", "label": $label}]' \
        "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"

    echo "Alarm added: ID $new_id | $raw_time | $days | $label"
    return 0
}

#########################################
# SOUND & NOTIFICATION LOGIC ############
#########################################
play_sound() {
    local mode="$1"
    case "$mode" in
    "bee-beep")
        aplay -q "$sound_file" &
        sleep 0.3
        aplay -q "$sound_file" &
        ;;
    "alarm")
        (for i in {1..30}; do
            aplay -q "$sound_file" &
            sleep 0.2
            aplay -q "$sound_file" &
            sleep 0.8
        done) &
        return $!
        ;;
    esac
}

trigger_action() {
    local id="$1"
    local label="$2"
    local days="$3"
    local trigger_time="$4"

    play_sound "alarm"
    local sound_pid=$!
    trap 'kill $sound_pid 2>/dev/null' EXIT

    local action
    action=$(notify-send "Alarm!" "${label}" \
        --icon="$alarm_icon" \
        --urgency=critical \
        -t 0 \
        --action="snooze=Snooze (5m)" \
        --wait)

    kill "$sound_pid" 2>/dev/null
    pkill -P "$sound_pid" 2>/dev/null
    trap - EXIT

    if [[ "$action" == "snooze" ]]; then
        sleep 0.2
        play_sound "bee-beep" &
        notify-send "Alarm!" "Rescheduled for 5 minutes." -t 3000 --icon="$snoozed_icon"

        local new_time
        new_time=$(LC_TIME=C date -d "+5 minutes" +%H:%M:%S)

        if [[ "$days" == "once" ]]; then
            jq --arg id "$id" --arg time "$new_time" \
                'map(if .id == ($id|tonumber) then .time = $time | .display = $time else . end)' \
                "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
        else
            local snooze_id=$(date +%s)
            jq --arg id "$snooze_id" --arg time "$new_time" --arg label "$label (Snoozed)" --arg display "$new_time" \
                '. += [{"id": ($id|tonumber), "time": $time, "display": $display, "days": "once", "status": "on", "label": $label}]' \
                "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
        fi
    else
        if [[ "$days" == "once" ]]; then
            jq --arg id "$id" 'map(select(.id != ($id|tonumber)))' \
                "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
        fi
    fi
}

#################################################
# TUI - NEW UNIFIED STYLE  ######################
################################################

declare -a ID_MAP

get_ordered_alarms() {
    jq -r '.[] | select(.status == "on") | "\(.id)\t\(.display // .time)\t\(.days)\t\(.label)\t\(.status)\t\(.time)"' "$db_file" |
        sort -k6 | cut -f1-5

    echo "GAP"

    jq -r '.[] | select(.status == "off") | "\(.id)\t\(.display // .time)\t\(.days)\t\(.label)\t\(.status)\t\(.time)"' "$db_file" |
        sort -k6 | cut -f1-5
}

print_aligned_table() {
    local show_id="${1:-false}"
    local idx=1

    ID_MAP=()

    local rows_active=""
    local rows_inactive=""
    local is_inactive_section=0

    while IFS=$'\t' read -r id time days label status; do
        if [[ "$id" == "GAP" ]]; then
            is_inactive_section=1
            continue
        fi
        ID_MAP[$idx]="$id"

        local row=""
        if [[ "$show_id" == "true" ]]; then
            row="$idx\t[$time]\t$days\t$label"
        else
            row="[$time]\t$days\t$label"
        fi

        if [[ "$is_inactive_section" -eq 0 ]]; then
            rows_active+="ACTIVE_TAG\t$row\n"
        else
            rows_inactive+="INACTIVE_TAG\t$row\n"
        fi

        ((idx++))
    done < <(get_ordered_alarms)

    local raw_data=""
    if [ -n "$rows_active" ]; then raw_data+="$rows_active"; fi

    if [ -n "$rows_active" ] && [ -n "$rows_inactive" ]; then
        if [[ "$show_id" == "true" ]]; then
            raw_data+="GAP_LINE\t\t\t\t\n"
        else
            raw_data+="GAP_LINE\t\t\t\n"
        fi
    fi

    if [ -n "$rows_inactive" ]; then raw_data+="$rows_inactive"; fi

    if [ -z "$raw_data" ]; then
        echo -e "${term_secondary}   (No alarms found)${reset}"
        return
    fi
    local header=""
    if [[ "$show_id" == "true" ]]; then
        header="ID\tTIME\tDAYS\tLABEL"
    else
        header="TIME\tDAYS\tLABEL"
    fi

    local full_content=$(printf "HEADER\t%s\n%s" "$header" "$raw_data")
    local aligned=$(echo -e "$full_content" | column -t -s $'\t')

    # Render Colors
    echo "$aligned" | while IFS= read -r line; do
        local tag=$(echo "$line" | awk '{print $1}')
        local content=$(echo "$line" | sed 's/^[^[:space:]]*[[:space:]]*//')

        if [[ "$tag" == "HEADER" ]]; then
            echo -e "$content"
            echo -e "$content" | sed 's/./-/g'
        elif [[ "$tag" == "GAP_LINE" ]]; then
            echo ""
        elif [[ "$tag" == "ACTIVE_TAG" ]]; then
            echo -e "${term_primary}${content}${reset}"
        elif [[ "$tag" == "INACTIVE_TAG" ]]; then
            echo -e "${term_secondary}${content}${reset}"
        fi
    done
}

show_delete_ui() {
    local msg=""
    while true; do
        clear
        echo "=== DELETE ALARM ==="
        if [ -n "$msg" ]; then
            echo -e "$msg"
            echo "--------------------"
        fi

        print_aligned_table "true"

        echo ""
        echo "Enter ID to delete (or 'c' to cancel):"
        read -r -p "> " choice

        if [[ "$choice" == "c" || -z "$choice" ]]; then return 1; fi

        # Validate Map
        if [[ -z "${ID_MAP[$choice]}" ]]; then
            msg="${term_secondary}[!] Invalid ID selected.${reset}"
        else
            local real_id="${ID_MAP[$choice]}"
            jq --arg id "$real_id" 'map(select(.id != ($id|tonumber)))' \
                "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
            return 0
        fi
    done
}

show_toggle_ui() {
    local msg=""
    while true; do
        clear
        echo "=== TOGGLE ALARM ==="
        if [ -n "$msg" ]; then
            echo -e "$msg"
            echo "--------------------"
        fi

        print_aligned_table "true"

        echo ""
        echo "Enter ID to toggle (or 'c' to cancel):"
        read -r -p "> " choice

        if [[ "$choice" == "c" || -z "$choice" ]]; then return 1; fi

        if [[ -z "${ID_MAP[$choice]}" ]]; then
            msg="${term_secondary}[!] Invalid ID selected.${reset}"
        else
            local real_id="${ID_MAP[$choice]}"
            jq --arg id "$real_id" \
                'map(if .id == ($id|tonumber) then .status = (if .status=="on" then "off" else "on" end) else . end)' \
                "$db_file" >"${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
            msg="${term_primary}[i] Toggled alarm #${choice}.${reset}"
        fi
    done
}

show_tui() {
    local feedback=""
    while true; do
        clear
        echo "=== ALARM MANAGER ==="
        if is_daemon_running; then
            echo -e " Daemon: ${term_primary}RUNNING${reset}"
        else
            echo -e " Daemon: ${term_secondary}STOPPED${reset}"
        fi

        if [ -n "$feedback" ]; then
            echo "---------------------"
            echo -e "$feedback"
            feedback=""
        fi
        echo "====================="

        print_aligned_table "false"

        echo ""
        echo "(A)dd  (T)oggle  (D)elete  (R)estart Daemon  (Q)uit"
        read -r -p "> " choice

        case "${choice,,}" in
        a)
            read -r -p "Time (e.g. 14:30 or 2:30pm): " raw_time
            read -r -p "Days (daily/once or mon,tue,sat..): " raw_days
            read -r -p "Label: " label
            if output=$(add_alarm_entry "$raw_time" "$raw_days" "$label"); then
                feedback="${term_primary}[+] Alarm Added.${reset}"
            else
                feedback="${term_secondary}[!] Failed to add alarm.${reset}"
            fi
            ;;
        t)
            show_toggle_ui
            ;;
        d)
            if show_delete_ui; then
                feedback="${term_primary}[-] Alarm deleted.${reset}"
            else
                feedback="${term_secondary}[i] Deletion cancelled.${reset}"
            fi
            ;;
        r)
            stop_daemon
            sleep 0.2
            start_daemon
            feedback="${term_primary}[i] Daemon restarted.${reset}"
            ;;
        q)
            clear
            exit 0
            ;;
        *) feedback="${term_secondary}[!] Invalid option.${reset}" ;;
        esac
    done
}

#######################################
# ARGUMENT PARSING ####################
########################################

case "$1" in
"start-daemon") start_daemon ;;
"stop-daemon") stop_daemon ;;
"trigger_action") trigger_action "$2" "$3" "$4" "$5" ;;
"list") print_aligned_table "false" ;;
"show-rofi")
    if [ -f "$rofi_script" ]; then
        source "$rofi_script"
        run_rofi_main
    else
        notify-send "Error" "alarm_rofi.sh not found in $rofi_script"
    fi
    ;;
"at")
    shift
    if [ -z "$1" ]; then
        echo "Error: You must provide a time."
        exit 1
    fi
    input_time="$1"
    shift

    input_days="once"
    input_label="Alarm"

    while [[ $# -gt 0 ]]; do
        case "$1" in
        title)
            if [ -n "$2" ]; then
                input_label="$2"
                shift 2
            else
                echo "Error: Argument 'title' requires a name."
                exit 1
            fi
            ;;
        *)
            input_days="$1"
            shift
            ;;
        esac
    done
    add_alarm_entry "$input_time" "$input_days" "$input_label"
    ;;
"tui" | "") show_tui ;;
*)
    echo "Usage: alarm {tui | show-rofi | list | at TIME [DAYS] [title LABEL] | start-daemon | stop-daemon}"
    echo ""
    echo "e.g, alarm at +30min title \"Take a break\""
    echo "e.g, alarm at 14:10 daily title \"Take a break\""
    echo "e.g, alarm at 12:30 mon,wed,sat title \"Meetings\""
    echo "e.g, alarm at 1:10am once title \"Go to sleep\""
    ;;
esac
