#!/bin/bash

# --- Configuration ---
DATA_FILE="$HOME/.config/waybar/scripts/countdown/countdowns.txt"
STATE_FILE="$HOME/.config/waybar/scripts/countdown/countdown.state"

# --- Helper function to get the number of countdowns ---
function get_countdown_count() {
    if [ ! -f "$DATA_FILE" ]; then
        echo 0
    else
        # Count non-empty lines
        grep -cvE '^\s*$' "$DATA_FILE"
    fi
}

# --- Function to handle scrolling ---
function handle_scroll() {
    local direction=$1
    local count=$(get_countdown_count)

    if [ "$count" -le 1 ]; then
        return
    fi

    local current_index=1
    if [ -f "$STATE_FILE" ]; then
        current_index=$(cat "$STATE_FILE")
    fi

    if [[ "$direction" == "up" ]]; then
        current_index=$((current_index - 1))
        if [ "$current_index" -lt 1 ]; then
            current_index=$count 
        fi
    elif [[ "$direction" == "down" ]]; then
        current_index=$((current_index + 1))
        if [ "$current_index" -gt "$count" ]; then
            current_index=1 
        fi
    fi

    echo "$current_index" > "$STATE_FILE"
}

# --- Interactive Menu Functions ---

function add_countdown() {
    clear
    echo "--- Adding New Countdown ---"
    echo

    read -p "Enter Label: " new_label
    # Default start date to today
    read -e -p "Enter Start Date (YYYY-MM-DD): " -i "$(date +%Y-%m-%d)" new_start_date
    read -p "Enter End Date (YYYY-MM-DD): " new_end_date
    read -e -p "Enter Format (days or %): " -i "days" new_format

    if [ -z "$new_label" ] || [ -z "$new_start_date" ] || [ -z "$new_end_date" ]; then
        echo
        echo "Error: Label and dates cannot be empty. No changes were made."
        sleep 2
        return
    fi

    # Convert '%' to 'percentage' for internal storage
    [[ "$new_format" == "%" ]] && new_format="percentage"

    mkdir -p "$(dirname "$DATA_FILE")"
    echo "$new_label;$new_start_date;$new_end_date;$new_format" >> "$DATA_FILE"

    echo
    echo "Countdown '$new_label' saved successfully!"
    sleep 1
}

function edit_countdown() {
    read -p "Enter the number of the countdown to edit: " choice
    local count=$(get_countdown_count)

    # Validate input is a number and within range
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        echo "Invalid selection."
        sleep 1
        return
    fi

    local line_to_edit=$(sed -n "${choice}p" "$DATA_FILE")
    local current_label=$(echo "$line_to_edit" | cut -d';' -f1)
    local current_start_date=$(echo "$line_to_edit" | cut -d';' -f2)
    local current_end_date=$(echo "$line_to_edit" | cut -d';' -f3)
    local current_format=$(echo "$line_to_edit" | cut -d';' -f4)
    [[ "$current_format" == "percentage" ]] && current_format="%"

    clear
    echo "--- Editing Countdown #$choice ---"
    echo "Press Enter to keep the current value."
    echo "----------------------------------"

    read -e -p "Enter Label: " -i "$current_label" new_label
    read -e -p "Enter Start Date (YYYY-MM-DD): " -i "$current_start_date" new_start_date
    read -e -p "Enter End Date (YYYY-MM-DD): " -i "$current_end_date" new_end_date
    read -e -p "Enter Format (days or %): " -i "$current_format" new_format

    if [ -z "$new_label" ] || [ -z "$new_start_date" ] || [ -z "$new_end_date" ]; then
        echo
        echo "Error: Label and dates cannot be empty. No changes were made."
        sleep 2
        return
    fi

    [[ "$new_format" == "%" ]] && new_format="percentage"

    # Construct the new line and replace the old one in the file
    local new_line="$new_label;$new_start_date;$new_end_date;$new_format"
    sed -i "${choice}s|.*|$new_line|" "$DATA_FILE"

    echo
    echo "Countdown #$choice edited successfully!"
    sleep 1
}

function delete_countdown() {
    read -p "Enter the number of the countdown to delete: " choice
    local count=$(get_countdown_count)

    # Validate input
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
        echo "Invalid selection."
        sleep 1
        return
    fi

    local label_to_delete=$(sed -n "${choice}p" "$DATA_FILE" | cut -d';' -f1)

    read -p "Are you sure you want to delete '$label_to_delete'? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sed -i "${choice}d" "$DATA_FILE"
        echo "Countdown deleted."
        
        local current_index=1
        if [ -f "$STATE_FILE" ]; then
            current_index=$(cat "$STATE_FILE")
        fi
        local new_count=$(get_countdown_count)
        if [ "$current_index" -gt "$new_count" ] && [ "$new_count" -gt 0 ]; then
             echo "$new_count" > "$STATE_FILE"
        fi
        
        sleep 1
    else
        echo "Deletion cancelled."
        sleep 1
    fi
}

function show_menu_loop() {
    while true; do
        clear
        echo "--- Waybar Countdown Manager ---"
        echo

        local count=$(get_countdown_count)
        if [ "$count" -gt 0 ]; then
            echo "Current Countdowns:"
            awk -F';' '{printf "  %2d) %-25s -> %s\n", NR, $1, $3}' "$DATA_FILE"
            echo
            echo "Choose an option:"
            echo "  a) Add New Countdown"
            echo "  e) Edit a Countdown"
            echo "  d) Delete a Countdown"
            echo "  q) Quit"
            read -p "Choice: " choice
        else
            echo "No countdowns are currently set."
            echo
            echo "Choose an option:"
            echo "  a) Add New Countdown"
            echo "  q) Quit"
            read -p "Choice: " choice
        fi

        case "$choice" in
            a|A) add_countdown ;;
            e|E) [ "$count" -gt 0 ] && edit_countdown || { echo "Invalid choice."; sleep 1; } ;;
            d|D) [ "$count" -gt 0 ] && delete_countdown || { echo "Invalid choice."; sleep 1; } ;;
            q|Q|*) break ;;
        esac
    done
    clear
}

case "$1" in
    interactive)
        show_menu_loop
        exit 0
        ;;
    scroll-up)
        handle_scroll "up"
        exit 0
        ;;
    scroll-down)
        handle_scroll "down"
        exit 0
        ;;
esac

COUNTDOWN_COUNT=$(get_countdown_count)
if [ "$COUNTDOWN_COUNT" -eq 0 ]; then
    echo '{"text": "No Countdowns", "tooltip": "Right-click to add a new countdown", "percentage": 0}'
    exit 0
fi

CURRENT_INDEX=1
if [ -f "$STATE_FILE" ]; then
    CURRENT_INDEX=$(cat "$STATE_FILE")
fi
if [ "$CURRENT_INDEX" -gt "$COUNTDOWN_COUNT" ]; then
    CURRENT_INDEX=1
    echo "$CURRENT_INDEX" > "$STATE_FILE"
fi

# --- Calculate dynamic column width for tooltip ---
max_label_len=6 # Minimum width for the word "Labels"
while IFS=';' read -r label _ _ _; do
    [[ -z "$label" ]] && continue
    if (( ${#label} > max_label_len )); then
        max_label_len=${#label}
    fi
done < "$DATA_FILE"

# Add padding for a clean look
label_col_width=$((max_label_len + 2))
# Define the format string using the calculated width for the first column
printf_format="%-*s  %-12s  %-s"


# --- Generate Tooltip with dynamic formatting ---
TOOLTIP="<b><u>Countdowns</u></b>\n\n<tt>"
TOOLTIP+=$(printf "$printf_format" "$label_col_width" "Labels" "Date" "Left")
TOOLTIP+='\n' 
TOOLTIP+='\n'

while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    LABEL=$(echo "$line" | cut -d';' -f1)
    START_DATE=$(echo "$line" | cut -d';' -f2)
    END_DATE=$(echo "$line" | cut -d';' -f3)

    START_SECS=$(date -d "$START_DATE" +%s 2>/dev/null)
    END_SECS=$(date -d "$END_DATE" +%s 2>/dev/null)
    NOW_SECS=$(date +%s)

    if [[ -z "$START_SECS" || -z "$END_SECS" ]]; then
        LEFT_INFO="Invalid Date"
    elif [ "$NOW_SECS" -ge "$END_SECS" ]; then
        LEFT_INFO="Done!"
    else
        TOTAL_SECS=$(( END_SECS - START_SECS ))
        REMAINING_SECS=$(( END_SECS - NOW_SECS ))
        REMAINING_DAYS=$(( REMAINING_SECS / 86400 ))

        if [ "$TOTAL_SECS" -le 0 ]; then
            PERCENTAGE_LEFT="0"
        else
            PERCENTAGE_LEFT=$(echo "scale=0; ($REMAINING_SECS * 100) / $TOTAL_SECS" | bc)
        fi
        [ "$PERCENTAGE_LEFT" -gt 100 ] && PERCENTAGE_LEFT=100
        [ "$PERCENTAGE_LEFT" -lt 0 ] && PERCENTAGE_LEFT=0
        
        LEFT_INFO="$REMAINING_DAYS days ($PERCENTAGE_LEFT%)"
    fi
    # Format the countdown line using the dynamic format
    line_content=$(printf "$printf_format" "$label_col_width" "$LABEL" "$END_DATE" "$LEFT_INFO")
    TOOLTIP+="$line_content" 
    TOOLTIP+='\n' 
done < "$DATA_FILE"

TOOLTIP+="</tt>"

# --- Generate Main Text for the currently selected countdown ---
CURRENT_LINE=$(sed -n "${CURRENT_INDEX}p" "$DATA_FILE")

LABEL=$(echo "$CURRENT_LINE" | cut -d';' -f1)
START_DATE=$(echo "$CURRENT_LINE" | cut -d';' -f2)
END_DATE=$(echo "$CURRENT_LINE" | cut -d';' -f3)
FORMAT=$(echo "$CURRENT_LINE" | cut -d';' -f4)

START_SECS=$(date -d "$START_DATE" +%s 2>/dev/null)
END_SECS=$(date -d "$END_DATE" +%s 2>/dev/null)
NOW_SECS=$(date +%s)

if [[ -z "$START_SECS" || -z "$END_SECS" ]]; then
    echo "{\"text\": \"Invalid Date\", \"tooltip\": \"Click to fix.\", \"percentage\": 0}"
    exit 0
fi

# Escape the completed tooltip string for JSON
TOOLTIP_JSON=$(echo -e "$TOOLTIP" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

if [ "$NOW_SECS" -ge "$END_SECS" ]; then
    echo "{\"text\": \"$LABEL - Done!\", \"tooltip\": \"$TOOLTIP_JSON\", \"percentage\": 100}"
    exit 0
fi

TOTAL_SECS=$(( END_SECS - START_SECS ))
REMAINING_SECS=$(( END_SECS - NOW_SECS ))
REMAINING_DAYS=$(( REMAINING_SECS / 86400 ))

if [ "$TOTAL_SECS" -le 0 ]; then
    JSON_PERCENTAGE=0
    DISPLAY_PERCENTAGE=100
else
    COMPLETED_SECS=$(( NOW_SECS - START_SECS ))
    JSON_PERCENTAGE=$(echo "scale=0; ($COMPLETED_SECS * 100) / $TOTAL_SECS" | bc)
    DISPLAY_PERCENTAGE=$(echo "scale=2; ($REMAINING_SECS * 100) / $TOTAL_SECS" | bc)
fi

if (( $(echo "$JSON_PERCENTAGE > 100" | bc -l) )); then
    JSON_PERCENTAGE="100"
elif (( $(echo "$JSON_PERCENTAGE < 0" | bc -l) )); then
    JSON_PERCENTAGE="0"
fi

if [ "$FORMAT" == "percentage" ]; then
    TEXT_PERCENTAGE=$(echo "$DISPLAY_PERCENTAGE" | sed 's/\.00$//')
    TEXT="$LABEL - $TEXT_PERCENTAGE% left"
else
    TEXT="$LABEL - $REMAINING_DAYS days left"
fi

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP_JSON\", \"percentage\": $JSON_PERCENTAGE}"