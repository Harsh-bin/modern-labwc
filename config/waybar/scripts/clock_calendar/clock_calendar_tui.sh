# sourced by clock_calendar.sh

term_primary="${term_primary:-\033[0;37m}"
term_secondary="${term_secondary:-\033[0;90m}"
reset="\033[0m"

print_aligned_table() {
    local show_id="${1:-false}"
    local i=1

    local rows_upcoming=""
    local rows_past=""

    while IFS=$'\t' read -r date desc status; do
        local row=""

        if [[ "$show_id" == "true" ]]; then
            row="$i\t[$date]\t$desc"
        else
            row="[$date]\t$desc"
        fi

        if [[ "$status" == "U" ]]; then
            rows_upcoming+="U_ACT\t$row\n"
        else
            rows_past+="P_EXP\t$row\n"
        fi
        ((i++))
    done < <(get_ordered_events)

    local raw_data=""
    if [ -n "$rows_upcoming" ]; then raw_data+="$rows_upcoming"; fi

    if [ -n "$rows_upcoming" ] && [ -n "$rows_past" ]; then
        if [[ "$show_id" == "true" ]]; then
            raw_data+="GAP_LINE\t\t\t\n"
        else
            raw_data+="GAP_LINE\t\t\n"
        fi
    fi

    if [ -n "$rows_past" ]; then raw_data+="$rows_past"; fi

    if [ -z "$raw_data" ]; then
        echo -e "${term_secondary}   (No events found)${reset}"
        return
    fi

    local header=""
    if [[ "$show_id" == "true" ]]; then
        header="ID\tDATE\tEVENT"
    else
        header="DATE\tEVENT"
    fi

    local full_content=$(printf "HEADER\t%s\n%s" "$header" "$raw_data")
    local aligned=$(echo -e "$full_content" | column -t -s $'\t')

    echo "$aligned" | while IFS= read -r line; do
        local tag=$(echo "$line" | awk '{print $1}')
        local content=$(echo "$line" | sed 's/^[^[:space:]]*[[:space:]]*//')

        if [[ "$tag" == "HEADER" ]]; then
            echo -e "$content"
            echo -e "$content" | sed 's/./-/g'
        elif [[ "$tag" == "GAP_LINE" ]]; then
            echo ""
        elif [[ "$tag" == "U_ACT" ]]; then
            echo -e "${term_primary}${content}${reset}"
        elif [[ "$tag" == "P_EXP" ]]; then
            echo -e "${term_secondary}${content}${reset}"
        fi
    done
}

show_list_ui() {
    clear
    echo "EVENT LIST"
    echo "=========="
    print_aligned_table "false"
    echo ""
    echo "-----------------------"
    read -r -p "Press Enter to return..." dummy
}

show_delete_ui() {
    local msg=""
    while true; do
        clear
        echo "DELETE EVENT"
        echo "============"
        if [ -n "$msg" ]; then
            echo -e "$msg"
            echo "--------------------"
        fi

        print_aligned_table "true"

        echo ""
        echo "Enter ID to delete (or 'c' to cancel):"
        read -r -p "> " del_choice

        if [[ "$del_choice" == "c" || -z "$del_choice" ]]; then return 1; fi

        local event_count=$(jq '.events | length' "$config_file")
        if [[ ! "$del_choice" =~ ^[0-9]+$ ]]; then
            msg="${term_secondary}[!] Invalid number.${reset}"
        elif [[ "$del_choice" -gt "$event_count" || "$del_choice" -eq 0 ]]; then
            msg="${term_secondary}[!] ID not found.${reset}"
        else
            local idx=$((del_choice - 1))
            json_delete_event "$idx"
            msg="${term_primary}[+] Event deleted.${reset}"
        fi
    done
}

change_fmt_ui() {
    clear
    echo "$1"
    echo "====================="
    echo -e "$3"
    echo ""
    echo "Current: $(get_setting $2)"
    echo ""
    read -r -p "Enter new format (or enter to skip): " fmt
    [ -n "$fmt" ] && set_setting "$2" "$fmt"
}

# Main TUI Loop

run_tui_main() {
    local feedback=""
    while true; do
        clear
        local c_time_fmt=$(get_setting time_format)
        local c_date_fmt=$(get_setting date_format)

        echo "CLOCK & CALENDAR MANAGER"
        echo "========================"
        echo -e "Time: ${term_primary}$c_time_fmt${reset} -> $(date +"$c_time_fmt")"
        echo -e "Date: ${term_primary}$c_date_fmt${reset} -> $(date +"$c_date_fmt")"

        if [ -n "$feedback" ]; then
            echo "--------------------------"
            echo -e "$feedback"
            feedback=""
        fi
        echo "=========================="

        echo "(a) Add Event"
        echo "(l) List Events"
        echo "(d) Delete Event"
        echo "(tf) Change Time Format"
        echo "(df) Change Date Format"
        echo "(q) Quit"
        echo ""

        read -r -p "> " choice

        case "${choice,,}" in
        a)
            clear
            echo "ADD NEW EVENT"
            echo "-------------"
            read -r -p "Date (YYYY-MM-DD): " date_in
            if [[ ! "$date_in" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                feedback="${term_secondary}[!] Invalid date format.${reset}"
            else
                read -r -p "Description: " desc_in
                if [ -z "$desc_in" ]; then
                    feedback="${term_secondary}[!] Description empty.${reset}"
                else
                    json_add_event "$date_in" "$desc_in"
                    feedback="${term_primary}[+] Event added.${reset}"
                fi
            fi
            ;;
        l)
            show_list_ui
            ;;
        d)
            if jq -e '.events | length > 0' "$config_file" >/dev/null; then
                if show_delete_ui; then
                    feedback="${term_primary}[i] Returned to menu.${reset}"
                else
                    feedback="${term_secondary}[i] Deletion cancelled.${reset}"
                fi
            else
                feedback="${term_secondary}[!] No events to delete.${reset}"
            fi
            ;;
        tf)
            change_fmt_ui "TIME FORMAT REFERENCE" "time_format" " %H (24h) | %I (12h)\n %M (Min) | %p (AM/PM)"
            feedback="${term_primary}[i] Time format updated.${reset}"
            ;;
        df)
            change_fmt_ui "DATE FORMAT REFERENCE" "date_format" " %d (01) | %a (Mon)\n %m (01) | %b (Jan)\n %y (24) | %Y (2024)"
            feedback="${term_primary}[i] Date format updated.${reset}"
            ;;
        q)
            clear
            exit 0
            ;;
        *)
            feedback="${term_secondary}[!] Invalid option selected.${reset}"
            ;;
        esac
    done
}
