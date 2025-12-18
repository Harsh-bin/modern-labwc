#!/bin/bash

# Directory and file paths
TODO_DIR="$HOME/.config/waybar/scripts/todo"
TASK_FILE="$TODO_DIR/tasks.txt"
CONF_FILE="$TODO_DIR/todo.conf"
TUI_SCRIPT="$TODO_DIR/todo_tui.sh"
touch "$TASK_FILE"
touch "$CONF_FILE"

# Source the configuration file
[ -s "$CONF_FILE" ] && source "$CONF_FILE"

# --- Function to update a key-value pair in the config file ---
update_config() {
    local key="$1"
    local value="$2"
    sed -i "s/^\($key\s*=\s*\).*/\1\"$value\"/" "$CONF_FILE"
}

# --- Daily Auto-Delete Logic ---
if [[ -n "$SCHEDULED_ACTION" && "$SCHEDULED_ACTION" != "none" ]]; then
    current_ts=$(date +%s)
    scheduled_ts_today=$(date -d "$SCHEDULED_TIME" +%s 2>/dev/null)
    if [[ -n "$scheduled_ts_today" ]]; then
        if (( current_ts > scheduled_ts_today )) && (( LAST_CHECKED_TIMESTAMP < scheduled_ts_today )); then
            if [[ "$SCHEDULED_ACTION" == "all" ]]; then
                > "$TASK_FILE"
            elif [[ "$SCHEDULED_ACTION" == "completed" ]]; then
                sed -i '/|1|/d' "$TASK_FILE"
            fi
            update_config "LAST_CHECKED_TIMESTAMP" "$current_ts"
        fi
    fi
fi

# --- Handle Click Actions ---
case "$1" in
    mark_done)
        current_task_line=$(grep '^[^|]*|0|' "$TASK_FILE" | sort -n -t'|' -k1 | head -n 1)
        if [[ -n "$current_task_line" ]]; then
            escaped_line=$(sed 's/[&/\]/\\&/g' <<< "$current_task_line")
            sed -i "s/^${escaped_line}$/$(echo "$current_task_line" | sed 's/|0|/|1|/')/" "$TASK_FILE"
        fi
        exit 0
        ;;
    open_tui)
        foot -e "$TUI_SCRIPT"
        exit 0
        ;;
    middle_click)
        if [[ "$MIDDLE_CLICK_ACTION" == "all" ]]; then
            > "$TASK_FILE"
        elif [[ "$MIDDLE_CLICK_ACTION" == "completed" ]]; then
            sed -i '/|1|/d' "$TASK_FILE"
        fi
        exit 0
        ;;
esac

# --- Generate Waybar JSON Output ---
current_task_line=$(grep '^[^|]*|0|' "$TASK_FILE" | sort -n -t'|' -k1 | head -n 1)
tooltip=""
full_bar_text="" # Variable to hold the full task description

if [[ ! -s "$TASK_FILE" ]]; then
    bar_text="Add a task!"
    tooltip="Right-click to add a new task"
else
    if [[ -n "$current_task_line" ]]; then 
        full_bar_text=$(echo "$current_task_line" | cut -d'|' -f3)

        # Truncation Logic
        if (( ${#full_bar_text} > 20 )); then
            # Truncate to 17 chars and add "..."
            bar_text="$(echo "$full_bar_text" | cut -c1-17)..."
        else
            # Use full text if it's 20 chars or less
            bar_text="$full_bar_text"
        fi
    else
        bar_text="✔ All Done!"
    fi

    tooltip="<b><u>Todo List\n</u></b>\n"
    pending_tasks=""
    completed_tasks=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$line" ]]; then continue; fi
        status=$(echo "$line" | cut -d'|' -f2)
        desc=$(echo "$line" | cut -d'|' -f3)
        if [[ "$status" -eq 1 ]]; then
            completed_tasks+="<s>$desc</s>\n"
        else
            pending_tasks+="$desc\n"
        fi
    done < <(sort -n -t'|' -k1 "$TASK_FILE")

    tooltip+="$pending_tasks"
    tooltip+="$completed_tasks"

    if [[ -n "$current_task_line" ]]; then
        # Always use the full, untruncated text in the tooltip
        tooltip+="\n<b>Current task:</b> $full_bar_text"
    else
        tooltip+="\n<b>All tasks cleared. Great job!</b>"
    fi
fi

# --- Final JSON Output ---
bar_text_json=$(echo "\u00a0\u00a0$bar_text" | sed 's/"/\\"/g')
tooltip_json=$(echo -e "$tooltip" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text": "%s", "tooltip": "%s"}\n' "$bar_text_json" "$tooltip_json"