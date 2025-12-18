#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# rofi menu file
rofi_menu="$HOME/.config/rofi/nightlight/night-light.rasi"
config_file="$HOME/.config/rofi/nightlight/night.conf"

# Function to apply night-light
apply_gamma() {
    local temp="$1"
    # Save value to config
    echo "$temp" > "$config_file"
    # Kill existing instance. 
    pkill -x gammastep || true
    # Start new instance in background.
    nohup gammastep -O "$1" >/dev/null 2>&1 &
}

# --- Main Menu ---

# Check if gammastep is currently running
if pgrep -x "gammastep" > /dev/null; then
    # Read the current/last value
    val=$(<"$config_file")
    mesg="<b>Night Light: ON (${val}K)</b>"
    toggle_option="Disable"
else    
    mesg="<b>Night Light: OFF</b>"
    toggle_option="Enable"
fi

# Rofi options
options="$toggle_option\nWarm\nNeutral"
# Run Rofi
main_choice=$(echo -e "$options" | rofi -dmenu -mesg "$mesg" -theme "$rofi_menu")

# Exit if no choice is made
if [ -z "$main_choice" ]; then
    exit 0
fi

# --- Handle the choice ---
case "$main_choice" in
    "Disable")
        # Just kill it to return to normal
        pkill -x gammastep || true
        notify-send "Night Light Off"
        ;;
    "Enable")
        target_temp=4500
        # Load the last used value from file
        if [[ -f "$config_file" ]]; then
            last_temp=$(<"$config_file")
            if [[ "$last_temp" =~ ^[0-9]+$ ]]; then 
              target_temp="$last_temp" 
            else
              notify-send "Night Light" "Config corrupted!! Using default"
            fi
        fi
        apply_gamma "$target_temp"
        notify-send "Night Light" "Enabled ($target_temp K)"
        ;;
    "Warm")
        apply_gamma 3000
        notify-send "Night Light" "Warm (3000K) Applied"
        ;;        
    "Neutral")
        apply_gamma 4500
        notify-send "Night Light" "Neutral (4500K) Applied"
        ;;
    *)
        # Check if the input is actually a valid number
        if [[ "$main_choice" =~ ^[0-9]+$ ]]; then
            if [[ $main_choice -ge 1000 && $main_choice -le 25000 ]]; then        
                apply_gamma "$main_choice"
                notify-send "Night Light" "Custom value: ${main_choice}K"
            else
                notify-send "Night Light" "Please enter value btw (1000-25000)"
            fi
        else
            notify-send "Night Light" "Invalid input!! Please enter digits"
            exit 1            
        fi
        ;;        
esac
