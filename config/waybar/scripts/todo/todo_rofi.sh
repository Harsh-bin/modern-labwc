# this script is sourced by the main todo.sh

theme_main="$todo_dir/todo.rasi"
theme_input="$todo_dir/placeholder.rasi"
theme_input2="$todo_dir/placeholder2.rasi"
theme_choice="$todo_dir/horizontal_menu.rasi"

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

rofi_choice() {
    local msg="$1"
    local opt1="$2"
    local opt2="$3"
    echo -e "$opt1\n$opt2" | rofi -dmenu -theme "$theme_choice" -mesg "$msg"
}

# Generates a visually aligned list of tasks for Rofi using column + awk
generate_task_list_rofi() {
    local show_id="${1:-false}"
    local task_count
    task_count=$(jq '.tasks | length' "$json_file")
    if [[ "$task_count" -eq 0 ]]; then
        echo '<tt>No tasks yet!</tt>'
        return
    fi

    local rows_pending=""
    local rows_completed=""
    local i=1

    while IFS=$'\t' read -r status desc; do
        local id_str="$i."
        local stat_icon="[ ]"

        if [[ "$status" -eq 1 ]]; then
            stat_icon="[X]"
            rows_completed+=$'\n'"C|$id_str|$stat_icon|$desc"
        else
            rows_pending+=$'\n'"P|$id_str|$stat_icon|$desc"
        fi
        ((i++))
    done < <(jq -r '.tasks | sort_by(.priority)[] | "\(.status)\t\(.description)"' "$json_file")

    # Construct Raw Table
    local raw_data=""
    if [[ "$show_id" == "true" ]]; then
        raw_data="H|ID|STAT|TASK"
    else
        raw_data="H|STAT|TASK"
    fi

    if [[ "$show_id" == "false" ]]; then
        # remove ID column from rows
        rows_pending=$(echo "$rows_pending" | sed 's/|[^|]*|/|/')
        rows_completed=$(echo "$rows_completed" | sed 's/|[^|]*|/|/')
    fi

    if [ -n "$rows_pending" ]; then raw_data+="$rows_pending"; fi
    if [ -n "$rows_completed" ]; then raw_data+="$rows_completed"; fi

    echo "$raw_data" | column -t -s '|' | awk -v pc="$pending_color" -v dc="$done_color" '
    BEGIN { 

    }
    /^H/ { 
        sub(/^H  /, ""); 
        print "<tt><b>" $0 "</b></tt>"
        next 
    }
    /^P/ { 
        sub(/^P  /, ""); 
        print "<span foreground=\"" pc "\"><tt>" $0 "</tt></span>" 
    }
    /^C/ { 
        sub(/^C  /, ""); 
        print "<span foreground=\"" dc "\"><tt>" $0 "</tt></span>" 
    }
    END {
        # Added padding at the bottom to prevent text cutoff
        print "<tt> </tt>"
    }
    '
}

# Task selection for toggle/delete actions

select_task_id() {
    local action_verb="$1"
    local task_count
    task_count=$(jq '.tasks | length' "$json_file")

    if [[ "$task_count" -eq 0 ]]; then
        rofi_choice "No tasks to $action_verb" "Ok" "Back" >/dev/null
        echo "0"
        return
    fi

    local header="Enter Task ID to $action_verb"
    local task_view
    task_view=$(generate_task_list_rofi "true")
    local full_msg="${header}"$'\n\n'"${task_view}"

    local selection
    selection=$(echo -e " Back" | rofi -dmenu -theme "$theme_input2" -mesg "$full_msg")

    if [[ "$selection" == " Back" || -z "$selection" ]]; then
        echo "0"
    elif [[ "$selection" =~ ^[0-9]+$ ]]; then
        if [[ "$selection" -ge 1 && "$selection" -le "$task_count" ]]; then
            echo "$selection"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

add_task_rofi() {
    local desc
    desc=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "Enter new task description:")
    if [[ "$desc" == " Back" || -z "$desc" ]]; then return; fi

    local prio
    prio=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "Enter priority (number):")
    if [[ "$prio" == " Back" ]]; then return; fi
    if ! [[ "$prio" =~ ^[0-9]+$ ]]; then return; fi

    read -r conflict_desc < <(jq -r --argjson p "$prio" '.tasks[] | select(.priority == $p) | .description' "$json_file")
    local insert_mode="false"

    if [[ -n "$conflict_desc" ]]; then
        local choice_str
        choice_str=$(rofi_choice "Priority $prio exists ('$conflict_desc'). Make '$desc' more prior?" "Yes" "No")
        if [[ "$choice_str" == "Yes" ]]; then insert_mode="true"; else insert_mode="false"; fi
    else
        insert_mode="true"
    fi

    # Call shared function
    json_add_task "$prio" "$desc" "$insert_mode"
}

delete_task() {
    local num
    num=$(select_task_id "delete")
    if [[ "$num" -eq 0 ]]; then return; fi
    local idx=$((num - 1))

    json_delete_task "$idx"
}

toggle_status() {
    local num
    num=$(select_task_id "toggle")
    if [[ "$num" -eq 0 ]]; then return; fi
    local idx=$((num - 1))

    json_toggle_task "$idx"
}

# --- settings functions ---

delete_all_tasks() {
    local choice_str
    choice_str=$(rofi_choice "Delete ALL tasks? Cannot be undone." "Yes" "No")
    if [[ "$choice_str" == "Yes" ]]; then
        jq '.tasks = []' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
    fi
}

delete_completed_tasks() {
    local choice_str
    choice_str=$(rofi_choice "Delete all COMPLETED tasks?" "Yes" "No")
    if [[ "$choice_str" == "Yes" ]]; then
        jq '.tasks |= map(select(.status == 0))' "$json_file" >"$temp_file" && mv "$temp_file" "$json_file"
    fi
}

set_auto_delete() {
    local time_input
    time_input=$(echo -e " Back" | rofi -dmenu -theme "$theme_input" -mesg "Enter daily deletion time (e.g., 14:10 or 2:10pm)\nType 'disable' to disable auto-delete")
    if [[ "$time_input" == " Back" || -z "$time_input" ]]; then return; fi

    if [[ "$time_input" == "disable" ]]; then
        update_config "scheduled_time" "none"
        update_config "scheduled_action" "none"
        return
    fi

    local valid_time
    valid_time=$(date -d "$time_input" +%H:%M 2>/dev/null)
    if [[ -z "$valid_time" ]]; then
        rofi -e "Invalid time format."
        return
    fi

    local choice_str
    choice_str=$(rofi_choice "What to delete daily at $valid_time?" "Completed" "All")
    if [[ "$choice_str" == "Completed" ]]; then
        update_config "scheduled_time" "$valid_time"
        update_config "scheduled_action" "completed"
    elif [[ "$choice_str" == "All" ]]; then
        update_config "scheduled_time" "$valid_time"
        update_config "scheduled_action" "all"
    fi
}

set_middle_click() {
    local choice_str
    choice_str=$(rofi_choice "Middle-click Action" "Delete Completed" "Delete All")
    if [[ "$choice_str" == "Delete Completed" ]]; then update_config "middle_click_action" "completed"; fi
    if [[ "$choice_str" == "Delete All" ]]; then update_config "middle_click_action" "all"; fi
}

settings_menu_rofi() {
    while true; do
        local s_action
        s_action=$(get_config "scheduled_action")
        local s_time
        s_time=$(get_config "scheduled_time")
        local m_action
        m_action=$(get_config "middle_click_action")

        local msg="Settings"
        msg+=$'\n\n'
        msg+="Auto-Delete: ${s_action} at ${s_time}"
        msg+=$'\n'
        msg+="Middle-Click: Deletes ${m_action} tasks"
        msg+=$'\n\n'
        msg+='(1) Delete ALL tasks now'
        msg+=$'\n'
        msg+='(2) Delete COMPLETED tasks now'
        msg+=$'\n'
        msg+='(3) Set daily auto-delete time'
        msg+=$'\n'
        msg+='(4) Configure middle-click action'

        local choice
        choice=$(echo " Back" | rofi -dmenu -theme "$theme_input2" -mesg "$msg")

        case "$choice" in
        1) delete_all_tasks ;;
        2) delete_completed_tasks ;;
        3) set_auto_delete ;;
        4) set_middle_click ;;
        " Back" | "") break ;;
        *) ;;
        esac
    done
}

# Main app loop

run_rofi_main() {
    ensure_json_exists
    while true; do
        local view_header="Waybar Todo Manager"
        local view_tasks
        view_tasks=$(generate_task_list_rofi "false")
        local full_message="${view_header}"$'\n\n'"${view_tasks}"
        local options="  Add Task\n  Toggle Status\n  Delete Task\n  Settings\n󰗼  Quit"

        local selection
        selection=$(echo -e "$options" | rofi -dmenu -i -theme "$theme_main" -mesg "$full_message" -markup-rows)

        if [[ -z "$selection" ]]; then break; fi

        case "$selection" in
        *"Add Task") add_task_rofi ;;
        *"Toggle Status") toggle_status ;;
        *"Delete Task") delete_task ;;
        *"Settings") settings_menu_rofi ;;
        *"Quit") break ;;
        esac
    done
}
