#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# --- Configuration ---
PINS_DIR="$HOME/pins"
STATE_FILE="$HOME/.config/waybar/scripts/pin_notes/pin_state.json"
ICON=" 📌"

# Ensure directories exist
mkdir -p "$PINS_DIR"
mkdir -p "$(dirname "$STATE_FILE")"

# --- Functions ---

get_file_list() {
    # Populates the global array 'FILES' with .txt files, sorted
    FILES=()
    while IFS=  read -r -d $'\0'; do
        FILES+=("$REPLY")
    done < <(find "$PINS_DIR" -maxdepth 1 -name "*.txt" -print0 | sort -z)
}

get_state_index() {
    if [ -f "$STATE_FILE" ]; then
        jq -r '.index // 0' "$STATE_FILE"
    else
        echo 0
    fi
}

save_state_index() {
    echo "{\"index\": $1}" > "$STATE_FILE"
}

parse_markdown() {
    # 1. HTML Escape special chars (&, <, >)
    # 2. H3 (###) -> Medium Bold
    # 3. H2 (##)  -> Large Bold
    # 4. H1 (#)   -> Extra Large Bold Underline
    # 5. Bold (**text**) -> <b>text</b>
    # 6. Italic (*text*) -> <i>text</i>
    # 7. Bullets (- ) -> •
    
    sed -E '
        s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;
        s/^### (.*)/<span size="medium" weight="bold">\1<\/span>/;
        s/^## (.*)/<span size="large" weight="bold">\1<\/span>/;
        s/^# (.*)/<span size="x-large" weight="bold" underline="single">\1<\/span>/;
        s/\*\*([^*]+)\*\*/<b>\1<\/b>/g;
        s/\*([^*]+)\*/<i>\1<\/i>/g;
        s/^- /• /
    ' "$1"
}

generate_output() {
    get_file_list
    count=${#FILES[@]}

    # Handle Empty Case
    if [ "$count" -eq 0 ]; then
        jq -n -c --arg icon "$ICON" '{"text": $icon, "tooltip": "no pins found."}'
        return
    fi

    current_idx=$(get_state_index)
    if (( current_idx >= count )); then current_idx=0; save_state_index 0; fi
    if (( current_idx < 0 )); then (( current_idx = count - 1 )); save_state_index $current_idx; fi

    target_file="${FILES[$current_idx]}"
    filename=$(basename "$target_file")
    
    # Process file content
    body=$(parse_markdown "$target_file")
    
    # Construct Tooltip
    header="<b>$filename</b> <span alpha='85%'>($((current_idx + 1))/$count)</span>"
    
    # Generate JSON
    jq -n -c \
       --arg icon "$ICON" \
       --arg header "$header" \
       --arg body "$body" \
       '{ "text": $icon, "tooltip": ($header + "\n<tt>" + $body + "</tt>"), "class": "pinned-mode" }'
}


# Scrolling Logic
if [ "$1" == "--up" ]; then
    get_file_list
    idx=$(get_state_index)
    count=${#FILES[@]}
    if [ "$count" -gt 0 ]; then
        (( idx = (idx + 1) % count ))
        save_state_index $idx
    fi
    exit 0
elif [ "$1" == "--down" ]; then
    get_file_list
    idx=$(get_state_index)
    count=${#FILES[@]}
    if [ "$count" -gt 0 ]; then
        (( idx = idx - 1 ))
        if (( idx < 0 )); then (( idx = count - 1 )); fi
        save_state_index $idx
    fi
    exit 0
fi

# DAEMON MODE: Watch for changes and update output
generate_output

# Fix for multiple instances of inotifywait and script
trap "kill 0" EXIT SIGTERM SIGINT

# Start inotifywait loop and react to changes in the pins directory or state file
inotifywait -m -q -e close_write -e create -e delete -e moved_to \
    "$PINS_DIR" "$(dirname "$STATE_FILE")" | \
while read -r directory events filename; do
    # Filter: Only react if it's a .txt file or the specific json state file
    if [[ "$filename" == "pin_state.json" ]] || [[ "$filename" == *.txt ]]; then
        generate_output
    fi
done &

wait
