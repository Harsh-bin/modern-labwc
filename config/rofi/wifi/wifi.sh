#!/bin/bash

# Remove 'set -e' so the script doesn't crash if a connection fails initially
set -u

# Notify user about the script launch
notify-send "   Checking for Wi-Fi..."

# --- Configuration ---
LIST_THEME="$HOME/.config/rofi/wifi/list.rasi"
ENABLE_THEME="$HOME/.config/rofi/wifi/enable.rasi"
SSID_THEME="$HOME/.config/rofi/wifi/ssid.rasi"
PASSWORD_THEME="$HOME/.config/rofi/wifi/password.rasi"

# --- Functions ---

enable_wifi_menu() {
    echo -e "   Enable Wi-Fi" | rofi -dmenu -theme "$ENABLE_THEME" || true    
}

prompt_ssid() {
    rofi -dmenu -p "SSID" -theme "$SSID_THEME" || true
}

prompt_password() {
    local msg="$1"
    if [[ -n "$msg" ]]; then
        rofi -dmenu -p "Password (Retry)" -mesg "<b>Error:</b> $msg" -theme "$PASSWORD_THEME" || true
    else
        rofi -dmenu -p "Password" -theme "$PASSWORD_THEME" || true
    fi
}

list_wifi_menu() {
    echo -e "󱚼   Disable Wi-Fi\n${connection_status}\n   Manual Setup\n${wifi_list}" | rofi -markup-rows -dmenu -theme "$LIST_THEME" || true
}

connect_secure_loop() {
    local target_ssid="$1"
    local error_output=""
    
    while true; do
        local pass
        pass=$(prompt_password "$error_output")
        
        # Exit if cancelled
        if [[ -z "$pass" ]]; then
            exit 0
        fi

        notify-send "   Connecting to \"$target_ssid\""

        # Delete the old connection profile to ensure a fresh start.
        nmcli connection delete id "$target_ssid" &> /dev/null

        # Try to connect with the new password
        local output
        output=$(nmcli dev wifi connect "$target_ssid" password "$pass" 2>&1)

        if [[ $? -eq 0 ]]; then
            notify-send "   Connected to \"$target_ssid\""
            break
        else
            # Capture error for the next retry prompt
            error_output=$(echo "$output" | sed 's/Error: //')
            notify-send "   Connection Failed" "Retrying..."
        fi
    done
}

# --- Main Logic ---

# Check Wi-Fi status
wifi_status=$(nmcli -t -f WIFI general | tail -n1)

if [[ "$wifi_status" == "disabled" ]]; then
    choice=$(enable_wifi_menu)
    [[ -z "$choice" ]] && exit 0
  	nmcli radio wifi on
    notify-send " 󱚽  Wi-Fi Enabled..."
    exit 0
fi

# Get currently connected SSID
connected_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2- || true)

# Get list of networks
wifi_list=$(nmcli -t -f ssid,security dev wifi | awk -F: '
{
    icon = ($2 ~ /WPA|WEP|802\.1X/) ? "" : "";
    if ($1 != "") {
        printf "%s   %s\n", icon, $1
    }
}' | sort -u)

# Compose status line
if [[ -n "$connected_ssid" ]]; then
    connection_status="   Connected to $connected_ssid"
else
    connection_status="󱛅   Wi-Fi not connected"
fi

# Show Rofi Menu
choice=$(list_wifi_menu)
[[ -z "$choice" ]] && exit 0

raw_choice="$choice"
ssid_name=$(echo "$choice" | sed 's/^[^ ]*   //')

case "$raw_choice" in

    *"Disable Wi-Fi"*)
        nmcli radio wifi off
        notify-send " 󱚼  Wi-Fi Disabled..."
        ;;

    *"Manual Setup"*)
        manual_ssid=$(prompt_ssid)
        [[ -z "$manual_ssid" ]] && exit 0
        manual_password=$(prompt_password)
        nmcli dev wifi connect "$manual_ssid" hidden yes password "$manual_password"
        ;;

    *"Connected to"*)
        # Disconnects from the wifi network
        nmcli connection down "$connected_ssid"
        notify-send " 󱛅  Disconnected from \"$connected_ssid\""
        ;;
    
    *"Wi-Fi not connected"*)
        exit 0
        ;;

    *)
        # === CONNECTION LOGIC ===

        saved_profile_exists=false
        if nmcli -t -f NAME connection show | grep -q -x "$ssid_name"; then
            saved_profile_exists=true
        fi

        # Try saved profile first (Auto-Connect)
        if [[ "$saved_profile_exists" == "true" ]]; then
            notify-send "   Connecting to saved network: \"$ssid_name\""
            
            if nmcli dev wifi connect "$ssid_name" > /dev/null 2>&1; then
                notify-send "   Connected to \"$ssid_name\""
                exit 0
            else
                notify-send "   Login failed. Retrying with password..."
                # If auto-connect fails, we assume the saved password is wrong.
            fi
        fi

        # 2. Handle Security
        if [[ "$raw_choice" == *""* ]]; then
            # Enter the password loop (handles new connections and failed saved ones)
            connect_secure_loop "$ssid_name"
        else
            # Open Network
            notify-send "   Connecting to \"$ssid_name\""
            if nmcli dev wifi connect "$ssid_name" > /dev/null 2>&1; then
                 notify-send "   Connected to \"$ssid_name\""
            else
                 notify-send "   Connection Failed..."
            fi
        fi
        ;;
esac