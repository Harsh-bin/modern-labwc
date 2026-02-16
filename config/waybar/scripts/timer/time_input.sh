#!/bin/bash

# configuration
base_dir="$HOME/.config/waybar/scripts/timer"
script_name="waybar_timer"
python_script="$base_dir/$script_name.py"
state_file="$base_dir/state.json"
input_menu="$base_dir/placeholder.rasi"

# Function to format seconds (e.g., 1500 -> 25m)
format_time() {
    local T=$1
    if ((T < 60)); then
        echo "${T}s"
    elif ((T % 60 == 0)); then
        echo "$((T / 60))m"
    else printf "%dm %ds" $((T / 60)) $((T % 60)); fi
}

if [ -f "$state_file" ]; then
    read -r raw_work raw_break <<<$(jq -r '
        .pomodoro | "\(.work_duration // 1500) \(.break_duration // 300)"
    ' "$state_file")
else
    raw_work=1500
    raw_break=300
fi

# Format the strings for the button
fmt_work=$(format_time "$raw_work")
fmt_break=$(format_time "$raw_break")

pomo_btn="Run Pomodoro (Work: $fmt_work, Break: $fmt_break)"

# Run rofi
msg=$'<b><big>Waybar Timer</big></b>\n<b>Usage:</b>\n[Time]: 10m, 90s, 1:30\n\n<b>● Countdown:</b> [Time]\n<b>● Add Time:</b> add [Time]\n<b>● Pomodoro:</b> pomo [Work] [Break]'

user_input=$(echo -e "$pomo_btn" | rofi -dmenu \
    -mesg "$msg" \
    -theme "$input_menu" \
    -p "Timer")

[ -z "$user_input" ] && exit 0

# Run pomodoro with stored value when button is clicked
if [[ "$user_input" == "$pomo_btn" ]]; then
    python3 "$python_script" pomodoro "$raw_work" "$raw_break"
    exit 0
fi

# Imports waybar_timer.py to use it's function for time input validation
final_cmd=$(python3 -c "
import sys 
sys.path.append('$base_dir')
import $script_name as timer

inp = sys.argv[1]
parts = inp.split()
cmd = parts[0].lower()

try:
    if cmd == 'add' and len(parts) >= 2:
        t = timer.parse_time(parts[1])
        print(f'countdown add {t}') if t > 0 else print('error')

    elif cmd == 'pomo':
        args = [x for x in parts[1:] if x.lower() != 'break']
        if len(args) >= 2:
            w = timer.parse_time(args[0])
            b = timer.parse_time(args[1])
            print(f'pomodoro {w} {b}') if w > 0 and b > 0 else print('error')
        else:
            print('error')

    else:
        t = timer.parse_time(inp)
        print(f'countdown {t}') if t > 0 else print('error')
except:
    print('error')
" "$user_input")

if [[ "$final_cmd" == "error" ]]; then
    notify-send -u critical "Timer Error" "Invalid format.\nTry: 10m, 1:30, or 'pomo 25m 5m'"
    exit 1
else
    # Runs python script
    python3 "$python_script" $final_cmd
fi
