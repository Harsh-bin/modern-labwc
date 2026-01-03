#!/usr/bin/env bash
#  _   _           _       _             
# | | | |_ __   __| | __ _| |_ ___  ___  
# | | | | '_ \ / _` |/ _` | __/ _ \/ __| 
# | |_| | |_) | (_| | (_| | ||  __/\__ \ 
#  \___/| .__/ \__,_|\__,_|\__\___||___/ 
#       |_|                              
#  

# Check if command exists
_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

script_name=$(basename "$0")

# Count the instances
instance_count=$(ps aux | grep -F "$script_name" | grep -v grep | grep -v $$ | wc -l)

if [ $instance_count -gt 1 ]; then
    sleep $instance_count
fi

# ----------------------------------------------------- 
# Define thresholds for color indicators
# ----------------------------------------------------- 
threshhold_green=0
threshhold_yellow=25
threshhold_red=100

# ----------------------------------------------------- 
# Check for updates (Arch Linux only)
# ----------------------------------------------------- 
if [[ $(_checkCommandExists "pacman") == 0 ]]; then

    check_lock_files() {
        local pacman_lock="/var/lib/pacman/db.lck"
        local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"

        while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
            sleep 1
        done
    }

    check_lock_files

    if [[ $(_checkCommandExists "yay") == 0 ]]; then
        aur_helper="yay"
    elif [[ $(_checkCommandExists "paru") == 0 ]]; then
        aur_helper="paru"
    else
        aur_helper=""
    fi

    updates_pacman=$(checkupdates 2>/dev/null | wc -l)
    updates_aur=0
    if [[ -n "$aur_helper" ]]; then
        updates_aur=$($aur_helper -Qum 2>/dev/null | wc -l)
    fi

    updates=$((updates_aur + updates_pacman))
else
    updates=0
fi

# ----------------------------------------------------- 
# Output in JSON format for Waybar Module custom-updates
# ----------------------------------------------------- 
css_class="green"

if [ "$updates" -gt $threshhold_yellow ]; then
    css_class="yellow"
fi

if [ "$updates" -gt $threshhold_red ]; then
    css_class="red"
fi

if [ "$updates" != 0 ]; then
    if [ "$updates" -gt $threshhold_green ]; then
        printf '{"text": "%s", "alt": "%s", "tooltip": "Click to update your system", "class": "%s"}' "$updates" "$updates" "$css_class"
    else
        printf '{"text": "0", "alt": "0", "tooltip": "No updates available", "class": "green"}'
    fi
fi

