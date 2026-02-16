# this script is sourced by the main todo.sh

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Added show_id parameter (true/false)
show_colored_list() {
    local show_id="${1:-false}"

    local jq_query
    if [[ "$show_id" == "true" ]]; then
        jq_query='.tasks | sort_by(.status, .priority) | to_entries[] | (.value.status | tostring) + "\t" + "\(.key + 1)\t" + (if .value.status == 1 then "[X]" else "[ ]" end) + "\t" + .value.description'
    else
        jq_query='.tasks | sort_by(.status, .priority) | to_entries[] | (.value.status | tostring) + "\t" + (if .value.status == 1 then "[X]" else "[ ]" end) + "\t" + .value.description'
    fi

    local raw_data
    raw_data=$(jq -r "$jq_query" "$json_file")

    if [ -z "$raw_data" ]; then
        echo "   (No tasks found)"
        return
    fi

    local statuses
    statuses=$(echo "$raw_data" | cut -f1)
    local table_content
    table_content=$(echo "$raw_data" | cut -f2-)

    local header
    if [[ "$show_id" == "true" ]]; then
        header="ID\tSTATUS\tTASK"
    else
        header="STATUS\tTASK"
    fi

    local full_content_for_column
    full_content_for_column=$(printf "%s\n%s" "$header" "$table_content")

    local aligned_table
    aligned_table=$(echo -e "$full_content_for_column" | column -t -s $'\t')

    local line_num=0
    while IFS= read -r line; do
        if [ "$line_num" -eq 0 ]; then
            echo "$line"
            echo "$line" | sed 's/./-/g'
        else
            local current_status
            current_status=$(echo "$statuses" | sed -n "${line_num}p")
            if [[ "$current_status" == "0" ]]; then
                echo -e "${term_primary}${line}${reset}"
            else
                echo -e "${term_secondary}${line}${reset}"
            fi
        fi
        ((line_num++))
    done <<<"$aligned_table"
}

add_task_logic() {
    read -r -p "Description: " desc
    if [[ -z "$desc" ]]; then
        echo "Error: Description cannot be empty."
        sleep 2
        return
    fi

    read -r -p "Priority (number): " prio
    if ! [[ "$prio" =~ ^[0-9]+$ ]]; then
        echo "Error: Priority must be a number."
        sleep 2
        return
    fi

    read -r conflict_desc < <(jq -r --argjson p "$prio" '.tasks[] | select(.priority == $p) | .description' "$json_file")
    local insert_mode="false"

    if [[ -n "$conflict_desc" ]]; then
        echo "Conflict: '$conflict_desc' has priority $prio."
        read -r -p "Make '$desc' more important? (y/n): " choice
        echo ""
        if [[ "$choice" =~ ^[Yy]$ ]]; then insert_mode="true"; else insert_mode="false"; fi
    else
        insert_mode="true"
    fi

    # Call shared function
    json_add_task "$prio" "$desc" "$insert_mode"
}

toggle_status_logic() {
    clear
    echo "TOGGLE STATUS"
    echo "-------------"
    show_colored_list "true" # Show IDs
    echo ""
    read -r -p "Enter ID to toggle (or enter to cancel): " num
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -eq 0 ]]; then return; fi

    local idx=$((num - 1))
    local len=$(jq '.tasks | length' "$json_file")
    if [[ "$idx" -ge "$len" ]]; then return; fi

    local task_obj
    task_obj=$(jq --argjson i "$idx" '.tasks | sort_by(.status, .priority) | .[$i]' "$json_file")

    jq --argjson i "$idx" '
        .tasks |= sort_by(.status, .priority) |
        .tasks[$i].status = (if .tasks[$i].status == 0 then 1 else 0 end)
    ' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
}

delete_task_logic() {
    clear
    echo "DELETE TASK"
    echo "-----------"
    show_colored_list "true" # Show IDs
    echo ""
    read -r -p "Enter ID to delete (or enter to cancel): " num
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -eq 0 ]]; then return; fi

    local idx=$((num - 1))
    local len=$(jq '.tasks | length' "$json_file")
    if [[ "$idx" -ge "$len" ]]; then return; fi

    jq --argjson i "$idx" '.tasks |= sort_by(.status, .priority) | del(.tasks[$i])' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
}

# --- Settings TUI ---

settings_menu_tui() {
    while true; do
        clear
        local s_action=$(get_config "scheduled_action")
        local s_time=$(get_config "scheduled_time")
        local m_action=$(get_config "middle_click_action")

        echo "SETTINGS"
        echo "--------"
        echo " Auto-Delete:  ${s_action} at ${s_time}"
        echo " Middle-Click: Deletes ${m_action} tasks"
        echo ""
        echo "(1) Delete ALL tasks now"
        echo "(2) Delete COMPLETED tasks now"
        echo "(3) Set daily auto-delete time"
        echo "(4) Configure middle-click action"
        echo "(b)ack"

        read -r -p "> " choice
        echo ""
        case "${choice,,}" in
        1)
            read -r -p "Confirm delete ALL? (y/n): " c
            if [[ "$c" =~ ^[Yy]$ ]]; then
                jq '.tasks = []' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
            fi
            ;;
        2)
            jq '.tasks |= map(select(.status == 0))' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
            ;;
        3)
            read -r -p "Time (e.g. 14:30) or 'disable': " t_in
            if [[ "$t_in" == "disable" ]]; then
                update_config "scheduled_time" "none"
                update_config "scheduled_action" "none"
            else
                if valid_time=$(date -d "$t_in" +%H:%M 2>/dev/null); then
                    read -r -p "Delete (1) Completed or (2) All?: " act
                    if [[ "$act" == "1" ]]; then
                        update_config "scheduled_time" "$valid_time"
                        update_config "scheduled_action" "completed"
                    elif [[ "$act" == "2" ]]; then
                        update_config "scheduled_time" "$valid_time"
                        update_config "scheduled_action" "all"
                    fi
                fi
            fi
            ;;
        4)
            read -r -p "Middle-click deletes (1) Completed or (2) All?: " act
            if [[ "$act" == "1" ]]; then
                update_config "middle_click_action" "completed"
            elif [[ "$act" == "2" ]]; then update_config "middle_click_action" "all"; fi
            ;;
        b) break ;;
        esac
    done
}

# Main TUI Loop

run_tui_main() {
    ensure_json_exists
    while true; do
        clear
        echo "TODO LIST"
        echo "---------"
        echo ""
        show_colored_list "false" # Hide IDs
        echo ""
        echo "(a)dd  (t)oggle  (d)elete  (s)ettings  (q)uit"
        read -r -p "> " choice

        case "${choice,,}" in
        a)
            clear
            echo "ADD NEW TASK"
            echo "------------"
            add_task_logic
            ;;
        t) toggle_status_logic ;;
        d) delete_task_logic ;;
        s) settings_menu_tui ;;
        q)
            clear
            break
            ;;
        esac
    done
}
