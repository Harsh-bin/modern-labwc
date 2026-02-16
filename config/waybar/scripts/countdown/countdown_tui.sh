# this script is sourced by the main countdown.sh
term_primary="${term_primary:-\033[0;37m}"
term_secondary="${term_secondary:-\033[0;90m}"
reset="\033[0m"

 
get_processed_data() {
    local now_secs=$(date +%s)
    local i=1

    local active_rows=""
    local expired_rows=""
 
    while IFS=$'\t' read -r label start end fmt; do
        local start_secs=$(date -d "$start" +%s 2>/dev/null)
        local end_secs=$(date -d "$end" +%s 2>/dev/null)
        local status_str=""
        local is_expired=0

        if [[ -z "$start_secs" || -z "$end_secs" ]]; then
            status_str="Invalid"
        elif [ "$now_secs" -ge "$end_secs" ]; then
            status_str="Expired"
            is_expired=1
        else
            local total_secs=$((end_secs - start_secs))
            local rem_secs=$((end_secs - now_secs))
            local rem_days=$((rem_secs / 86400))

            if [[ "$fmt" == "percentage" ]]; then
                local pct=0
                if [ "$total_secs" -gt 0 ]; then
                    pct=$(echo "scale=0; ($rem_secs * 100) / $total_secs" | bc)
                fi
                [ "$pct" -gt 100 ] && pct=100
                [ "$pct" -lt 0 ] && pct=0
                status_str="${rem_days}d (${pct}%)"
            else
                status_str="${rem_days} Days"
            fi
        fi
 
        local row=""
        if [ "$is_expired" -eq 1 ]; then
            row="2_EXP\t$i\t$label\t$end\t$status_str"
            expired_rows+="${row}\n"
        else
            row="1_ACT\t$i\t$label\t$end\t$status_str"
            active_rows+="${row}\n"
        fi
        ((i++))
    done < <(jq -r '.countdowns[] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")
 
    if [ -n "$active_rows" ]; then
        echo -e -n "$active_rows"
    fi

    if [ -n "$active_rows" ] && [ -n "$expired_rows" ]; then
        echo -e "GAP_LINE\t\t\t\t"
    fi

    if [ -n "$expired_rows" ]; then
        echo -e -n "$expired_rows"
    fi
}
 
print_aligned_table() {
    local show_id="${1:-false}"
    local raw_data
    raw_data=$(get_processed_data)

    if [ -z "$raw_data" ]; then
        echo -e "${term_secondary}   (No countdowns set)${reset}"
        return
    fi
 
    local header=""
    local table_data=""
    if [[ "$show_id" == "true" ]]; then 
        header="HEAD\tID\tLABEL\tTARGET\tLEFT"
        table_data="$raw_data"
    else 
        header="HEAD\tLABEL\tTARGET\tLEFT"
        table_data=$(echo "$raw_data" | cut -f1,3-)
    fi

    local full_content
    full_content=$(printf "%s\n%s" "$header" "$table_data")    
    local aligned_table
    aligned_table=$(echo -e "$full_content" | column -t -s $'\t')

    while IFS= read -r line; do
        read -r status content <<< "$line"

        if [[ "$status" == "HEAD" ]]; then
            echo "$content"
            echo "$content" | sed 's/./-/g'
        elif [[ "$status" == "GAP_LINE" ]]; then
            echo ""  
        elif [[ "$status" == "1_ACT" ]]; then
            echo -e "${term_primary}${content}${reset}"
        elif [[ "$status" == "2_EXP" ]]; then
            echo -e "${term_secondary}${content}${reset}"
        else
            echo "$line"
        fi
    done <<<"$aligned_table"
}
 
add_countdown_logic() {
    read -r -p "Label: " new_label
    read -e -r -p "Start Date (YYYY-MM-DD) [$(date +%Y-%m-%d)]: " new_start
    [ -z "$new_start" ] && new_start=$(date +%Y-%m-%d)
    read -r -p "End Date (YYYY-MM-DD): " new_end
    read -e -r -p "Format (days or percentage): " -i "days" new_fmt

    if [[ -z "$new_label" || -z "$new_end" ]]; then
        echo "Error: Missing required fields."
        sleep 2
        return
    fi
    [[ "$new_fmt" == "%" ]] && new_fmt="percentage"

    json_add_countdown "$new_label" "$new_start" "$new_end" "$new_fmt"
}

edit_countdown_logic() {
    clear
    echo "EDIT COUNTDOWN"
    echo "-------------------------"
    print_aligned_table "true"  
    echo ""
    read -r -p "Enter ID to edit (or 'c' to cancel): " choice

    if [[ "$choice" == "c" || -z "$choice" ]]; then return; fi

    local count=$(get_countdown_count)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        echo "Error: Invalid ID."
        sleep 2
        return
    fi

    local idx=$((choice - 1))
    IFS=$'\t' read -r cur_lbl cur_start cur_end cur_fmt < <(jq -r --argjson i "$idx" '.countdowns[$i] | "\(.label)\t\(.start)\t\(.end)\t\(.format)"' "$data_file")

    echo ""
    echo "Editing item $choice. Press Enter to keep current value."
    read -e -r -p "Label [$cur_lbl]: " -i "$cur_lbl" new_lbl
    read -e -r -p "Start [$cur_start]: " -i "$cur_start" new_start
    read -e -r -p "End   [$cur_end]: " -i "$cur_end" new_end
    read -e -r -p "Format [$cur_fmt]: " -i "$cur_fmt" new_fmt

    json_edit_countdown "$idx" "$new_lbl" "$new_start" "$new_end" "$new_fmt"

    echo "Info: Countdown updated."
    sleep 1
}

delete_countdown_logic() {
    clear
    echo "DELETE COUNTDOWN"
    echo "-------------------------"
    print_aligned_table "true"  
    echo ""
    read -r -p "Enter ID to delete (or 'c' to cancel): " choice

    if [[ "$choice" == "c" || -z "$choice" ]]; then return; fi

    local count=$(get_countdown_count)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        echo "Error: Invalid ID."
        sleep 2
        return
    fi

    local idx=$((choice - 1))
    json_delete_countdown "$idx"

    echo "Info: Countdown deleted."
    sleep 1
}

# Main TUI Loop

show_tui_menu() {
    while true; do
        clear
        echo "COUNTDOWN MANAGER"
        echo "-----------------"
        echo ""
        print_aligned_table "false"  
        echo ""
        echo "(a)dd  (e)dit  (d)elete  (q)uit"
        read -r -p "> " choice

        case "${choice,,}" in
        a)
            clear
            echo "ADD NEW COUNTDOWN"
            echo "-----------------"
            add_countdown_logic
            ;;
        e)
            if [ "$(get_countdown_count)" -gt 0 ]; then
                edit_countdown_logic
            fi
            ;;
        d)
            if [ "$(get_countdown_count)" -gt 0 ]; then
                delete_countdown_logic
            fi
            ;;
        q)
            clear
            exit 0
            ;;
        *) ;;
        esac
    done
}
