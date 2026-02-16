#!/bin/bash

dir="$HOME/.config/waybar/scripts/data_monitor"
data_monitor_script="$dir/data_monitor.py"
dns_script="$dir/dns_encrypt_rofi.sh"
config_file="$dir/config.json"
theme_menu="$dir/horizontal_menu.rasi"
theme_input="$dir/placeholder.rasi"

update_config() {
    local key="$1"
    local val="$2"
    jq ".$key = $val" "$config_file" >"${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    # Reload Python Script
    python3 "$data_monitor_script" --reconfig
}

set_limit() {
    local type="$1" # monthly or daily
    local key="limit_${type}_gb"
    local val=$(rofi -dmenu -theme "$theme_input" -mesg "<b>Enter ${type} limit in GB (e.g. 10 or 800.5)</b>")
    if [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        update_config "$key" "$val"
        notify-send "Data Monitor" "${type^} limit set to ${val} GB"
    elif [ -n "$val" ]; then
        notify-send "Invalid input. Please enter a number."
    fi
}

set_reset_day() {
    local val=$(rofi -dmenu -theme "$theme_input" -mesg "<b>Enter Monthly Reset Day (1-31)</b>")

    # Validate (Integer 1-31)
    if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 1 ] && [ "$val" -le 31 ]; then
        update_config "reset_day" "$val"
        notify-send "Data Monitor" "Reset day set to day $val"
    elif [ -n "$val" ]; then
        notify-send "Invalid input. Please enter a day between 1-31."
    fi
}

menu_settings() {
    local choice=$(echo -e "Monthly reset day\nSet limit" | rofi -dmenu -theme "$theme_menu" -mesg "<b>Settings</b>")

    case "$choice" in
    "Monthly reset day")
        set_reset_day
        ;;
    "Set limit")
        local limit_type=$(echo -e "Monthly\nDaily" | rofi -dmenu -theme "$theme_menu" -mesg "<b>Select Limit Type</b>")
        case "$limit_type" in
        "Monthly") set_limit "monthly" ;;
        "Daily") set_limit "daily" ;;
        esac
        ;;
    esac
}

main() {
    local choice=$(echo -e "󰇖  Change DNS\n  Settings" | rofi -dmenu -theme "$theme_menu" -mesg "<b>Data Monitor Control</b>")

    case "$choice" in
    *"Change DNS")
        if [ -x "$dns_script" ]; then
            "$dns_script"
        else
            notify-send "DNS script not executable or missing."
        fi
        ;;
    *"Settings")
        menu_settings
        ;;
    esac
}

# Run
main
