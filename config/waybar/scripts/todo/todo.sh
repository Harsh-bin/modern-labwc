#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# --- directory and file paths ---
todo_dir="$HOME/.config/waybar/scripts/todo"
json_file="$todo_dir/todo.json"

# script paths
tui_script="$todo_dir/todo_tui.sh"
rofi_script="$todo_dir/todo_rofi.sh"

# source color extraction script
source "$HOME/.config/waybar/scripts/css_color_extraction.sh"
# define colors for rofi ui and tooltip
done_color="$primary_color"
pending_color="$secondary_color"

# --- Core Functions ---

ensure_json_exists() {
    if [[ ! -f "$json_file" ]]; then
        echo '{
  "config": {
    "scheduled_time": "none",
    "scheduled_action": "none",
    "last_checked_timestamp": 0,
    "middle_click_action": "none"
  },
  "tasks": []
}' >"$json_file"
    fi
}

get_config() {
    local key="$1"
    jq -r ".config.$key" "$json_file"
}

update_config() {
    local key="$1"
    local value="$2"
    local tmp_file=$(mktemp)
    jq --arg k "$key" --arg v "$value" '.config[$k] = $v' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
}

# Shared JSON Manipulation Functions

# $1=priority, $2=description, $3=insert_mode (true/false)
json_add_task() {
    local prio="$1"
    local desc="$2"
    local insert_mode="$3"
    local tmp_file=$(mktemp)

    jq --argjson p "$prio" --arg d "$desc" --argjson insert "$insert_mode" '
        (if $insert then $p else $p + 1 end) as $target_p |
        .tasks |= map(
            if $insert then
                if .priority >= $p then .priority += 1 else . end
            else
                if .priority > $p then .priority += 1 else . end
            end
        ) |
        .tasks += [{"priority": $target_p, "status": 0, "description": $d}] |
        .tasks |= sort_by(.priority)
    ' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
}

# $1=0-based index
json_delete_task() {
    local idx="$1"
    local tmp_file=$(mktemp)
    jq --argjson i "$idx" '.tasks |= sort_by(.priority) | del(.tasks[$i])' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
}

# $1=0-based index
json_toggle_task() {
    local idx="$1"
    local tmp_file=$(mktemp)
    jq --argjson i "$idx" '
        .tasks |= sort_by(.priority) |
        .tasks[$i].status = (if .tasks[$i].status == 0 then 1 else 0 end)
    ' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
}

# --- Automation Logic ---

check_scheduled_actions() {
    local scheduled_action=$(get_config "scheduled_action")
    local scheduled_time=$(get_config "scheduled_time")
    local last_checked=$(get_config "last_checked_timestamp")

    if [[ "$scheduled_action" != "none" && "$scheduled_time" != "none" ]]; then
        local current_ts=$(date +%s)
        local scheduled_ts_today=$(date -d "$scheduled_time" +%s 2>/dev/null)

        if [[ -n "$scheduled_ts_today" ]]; then
            # Check if we passed the time AND haven't checked since then
            if ((current_ts > scheduled_ts_today)) && ((last_checked < scheduled_ts_today)); then
                local tmp_file=$(mktemp)
                if [[ "$scheduled_action" == "all" ]]; then
                    jq '.tasks = []' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
                elif [[ "$scheduled_action" == "completed" ]]; then
                    jq '.tasks |= map(select(.status == 0))' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
                fi
                update_config "last_checked_timestamp" "$current_ts"
            fi
        fi
    fi
}

# --- Waybar Output Logic ---

generate_waybar_output() {
    # Extract current task and all tasks sorted by priority
    {
        read -r current_task_desc
        read -r all_tasks_json
    } < <(jq -r '
        .tasks |= sort_by(.priority) |
        ( [.tasks[] | select(.status == 0)] | first | .description // "" ) as $curr |
        $curr, (.tasks | tojson)
    ' "$json_file")

    local tooltip=""
    local bar_text=""
    local json_class=""

    local task_count=$(echo "$all_tasks_json" | jq 'length')

    if [[ "$task_count" -eq 0 ]]; then
        bar_text="\u2009\u2009Add a task!"
        tooltip="Right-click to add a new task"
    else
        if [[ -n "$current_task_desc" ]]; then
            local full_bar_text="\u2009$current_task_desc"
            json_class="pending"

            if ((${#full_bar_text} > 20)); then
                bar_text="$(echo "\u2009$full_bar_text" | cut -c1-17)..."
            else
                bar_text="\u2009$full_bar_text"
            fi
        else
            bar_text="✔All Done!"
        fi

        tooltip="<b><u>Todo List\n</u></b>\n"
        local pending_tasks=""
        local completed_tasks=""

        while IFS=$'\t' read -r status desc; do
            if [[ "$status" -eq 1 ]]; then
                completed_tasks+="<span color='$done_color'> - <s>$desc</s></span>\n"
            else
                pending_tasks+="<span color='$pending_color'> - $desc</span>\n"
            fi
        done < <(echo "$all_tasks_json" | jq -r '.[] | "\(.status)\t\(.description)"')

        tooltip+="<span color='$pending_color'>●</span> pending tasks\n"
        tooltip+="$pending_tasks\n"
        tooltip+="<span color='$done_color'>●</span> completed tasks\n"
        tooltip+="$completed_tasks"

        if [[ -n "$current_task_desc" ]]; then
            tooltip+="\n<b>Current task:</b> <span color='$pending_color'>$full_bar_text</span>"
        else
            tooltip+="\n<b>All tasks cleared. Great job!</b>"
        fi
    fi

    local bar_text_json=$(echo "$bar_text" | sed 's/"/\\"/g')
    local tooltip_json=$(echo -e "$tooltip" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$bar_text_json" "$tooltip_json" "$json_class"
}

ensure_json_exists
check_scheduled_actions

# --- Argument Handling ---
case "$1" in
--show-rofi)
    if [[ -f "$rofi_script" ]]; then
        source "$rofi_script"
        run_rofi_main
    else
        echo "Error: Rofi script not found at $rofi_script"
    fi
    exit 0
    ;;
--show-tui)
    if [[ -f "$tui_script" ]]; then
        source "$tui_script"
        run_tui_main
    else
        echo "Error: TUI script not found at $tui_script"
    fi
    exit 0
    ;;
--mark-done)
    tmp_file=$(mktemp)
    jq '
          .tasks |= sort_by(.priority) |
          (.tasks | map(.status == 0) | index(true)) as $idx |
          if $idx != null then .tasks[$idx].status = 1 else . end
        ' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
    exit 0
    ;;
--middle-click)
    middle_click_action=$(get_config "middle_click_action")
    tmp_file=$(mktemp)
    if [[ "$middle_click_action" == "all" ]]; then
        jq '.tasks = []' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
    elif [[ "$middle_click_action" == "completed" ]]; then
        jq '.tasks |= map(select(.status == 0))' "$json_file" >"$tmp_file" && mv "$tmp_file" "$json_file"
    fi
    exit 0
    ;;
esac

generate_waybar_output
