#!/usr/bin/env python3

import os
import time
import json
import signal
import sys
import re
import subprocess
import calendar
from datetime import datetime

# Configuration Paths
config_dir = os.path.expanduser("~/.config/waybar/scripts/data_monitor")
waybar_dir = os.path.dirname(os.path.dirname(config_dir))
style_file = os.path.join(waybar_dir, "style.css")
usage_file = os.path.join(config_dir, "usage.json")
config_file = os.path.join(config_dir, "config.json")
pid_file = os.path.join(config_dir, "monitor.pid")

# Icons
icon_down = "󰇚"
icon_up = "󰕒"
# Default Colors (will be overwritten by style.css if found)
primary_color = "#a6e3a1"
secondary_color = "#ff7a93"  # Used for alerts


def update_colors():
    global primary_color, secondary_color
    try:
        if not os.path.exists(style_file):
            return
        with open(style_file, "r") as f:
            style_content = f.read()
        match = re.search(r'@import "colors/(.*?)";', style_content)
        if match:
            color_path = os.path.join(waybar_dir, "colors", match.group(1))
            if os.path.exists(color_path):
                with open(color_path, "r") as f:
                    color_content = f.read()
                p_match = re.search(
                    r"@define-color\s+primary\s+([^;]+);", color_content
                )
                if p_match:
                    primary_color = p_match.group(1).strip()
                s_match = re.search(r"@define-color\s+power\s+([^;]+);", color_content)
                if s_match:
                    secondary_color = s_match.group(1).strip()
    except Exception:
        pass


##################################
##################################

state = {}
config = {}

default_config = {
    "reset_day": 30,
    "limit_monthly_gb": 800,
    "limit_daily_gb": 10,
}

default_state = {
    "monthly_wifi": 0,
    "monthly_eth": 0,
    "life_wifi": 0,
    "life_eth": 0,
    "daily_wifi": 0,
    "daily_eth": 0,
    "last_proc_wifi": 0,
    "last_proc_eth": 0,
    "last_reset_date": datetime.now().strftime("%Y-%m-%d"),
    "next_monthly_reset_date": "1970-01-01",
    "notified_daily_90": False,
    "notified_daily_95": False,
    "notified_daily_100": False,
    "notified_monthly_90": False,
    "notified_monthly_95": False,
    "notified_monthly_100": False,
}


def ensure_dirs():
    os.makedirs(config_dir, exist_ok=True)


def send_notification(title, message, urgency="normal"):
    try:
        subprocess.run(
            ["notify-send", "-u", urgency, "-a", "Waybar Data Monitor", title, message]
        )
    except Exception:
        pass


def load_config():
    global config
    ensure_dirs()
    loaded_conf = {}
    if os.path.exists(config_file):
        try:
            with open(config_file, "r") as f:
                loaded_conf = json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    config = {**default_config, **loaded_conf}
    if not os.path.exists(config_file):
        try:
            with open(config_file, "w") as f:
                json.dump(default_config, f, indent=4)
        except Exception:
            pass


def load_state():
    global state
    if not os.path.exists(usage_file):
        state = default_state.copy()
        return
    try:
        with open(usage_file, "r") as f:
            data = json.load(f)
            state = {**default_state, **data}
    except (json.JSONDecodeError, IOError):
        state = default_state.copy()


def save_state():
    temp_file = usage_file + ".tmp"
    try:
        with open(temp_file, "w") as f:
            json.dump(state, f, indent=4)
        os.replace(temp_file, usage_file)
    except Exception:
        pass


# Calculates the date of the next monthly reset based on the current date.
def calculate_next_reset_date(reset_day):
    now = datetime.now()
    if now.day < reset_day:
        year, month = now.year, now.month
    else:
        year = now.year
        month = now.month + 1
        if month > 12:
            month = 1
            year += 1
    _, last_day_of_month = calendar.monthrange(year, month)
    actual_reset_day = min(reset_day, last_day_of_month)
    return datetime(year, month, actual_reset_day).date()


# Signal Handling & Reconfiguration
def trigger_reconfig():
    if not os.path.exists(pid_file):
        print("No running instance found (PID file missing).")
        sys.exit(1)
    try:
        with open(pid_file, "r") as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGUSR1)
        print(f"Signal sent to process {pid} to reload configuration.")
    except ProcessLookupError:
        print("Process not running. Cleaning up PID file.")
        os.remove(pid_file)
    except Exception as e:
        print(f"Error sending signal: {e}")
    sys.exit(0)


# Reloads config and updates the next reset date.
def handle_reconfig_signal(sig, frame):
    global state
    load_config()
    reset_day_cfg = config.get("reset_day", 11)
    new_next_date = calculate_next_reset_date(reset_day_cfg)
    state["next_monthly_reset_date"] = new_next_date.strftime("%Y-%m-%d")
    save_state()  # Immediately save the new reset date to usage.json
    send_notification(
        "Data Monitor",
        f"Configuration reloaded. Next reset is now {state['next_monthly_reset_date']}.",
        "low",
    )


def handle_exit(sig, frame):
    save_state()
    if os.path.exists(pid_file):
        try:
            os.remove(pid_file)
        except:
            pass
    sys.exit(0)


def write_pid():
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))


signal.signal(signal.SIGINT, handle_exit)
signal.signal(signal.SIGTERM, handle_exit)
signal.signal(signal.SIGUSR1, handle_reconfig_signal)


# Formatting for bytes
def format_bytes(num):
    for unit in ["B", "KiB", "MiB", "GiB", "TiB"]:
        if num < 1024:
            return f"{num:.1f}{unit}"
        num /= 1024
    return f"{num:.1f}PiB"


def format_speed(bps):
    for unit in ["B/s", "K/s", "M/s", "G/s"]:
        if bps < 1024:
            return f"{bps:.1f}{unit}"
        bps /= 1024
    return f"{bps:.1f}T/s"


def read_proc_net():
    wifi_rx = wifi_tx = eth_rx = eth_tx = 0
    try:
        with open("/proc/net/dev") as f:
            for line in f.readlines()[2:]:
                if ":" not in line:
                    continue
                iface, data = line.split(":", 1)
                data = data.split()
                rx, tx = int(data[0]), int(data[8])
                iface = iface.strip()
                if iface.startswith(("wlan", "wlp", "wls")):
                    wifi_rx += rx
                    wifi_tx += tx
                elif iface.startswith(("eth", "enp", "eno", "ens")):
                    eth_rx += rx
                    eth_tx += tx
    except Exception:
        pass
    return wifi_rx, wifi_tx, eth_rx, eth_tx


# Alert & Reset Logic
def check_alerts(current_bytes, limit_gb, period_name):
    if limit_gb <= 0:
        return
    limit_bytes = limit_gb * (1024**3)
    percentage = (current_bytes / limit_bytes) * 100
    for t in [90, 95, 100]:
        key = f"notified_{period_name}_{t}"
        if percentage >= t and not state.get(key, False):
            urgency = "critical" if t == 100 else "normal"
            msg = f"You have used {t}% of your {period_name} data limit ({format_bytes(current_bytes)} / {limit_gb}GB)."
            send_notification(f"{period_name.capitalize()} Data Alert", msg, urgency)
            state[key] = True


def reset_notification_flags(period_name):
    for t in [90, 95, 100]:
        state[f"notified_{period_name}_{t}"] = False


def check_daily_reset():
    now_date = datetime.now().strftime("%Y-%m-%d")
    if state["last_reset_date"] != now_date:
        state["daily_wifi"] = 0
        state["daily_eth"] = 0
        state["last_reset_date"] = now_date
        reset_notification_flags("daily")


##########################
# Main Loop  #############
##########################


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--reconfig":
        trigger_reconfig()

    global state
    ensure_dirs()
    write_pid()
    load_config()
    load_state()
    update_colors()

    last_wifi_raw = state["last_proc_wifi"]
    last_eth_raw = state["last_proc_eth"]
    last_rx, last_tx = 0, 0
    first_run, tick_counter = True, 0

    while True:
        wifi_rx, wifi_tx, eth_rx, eth_tx = read_proc_net()
        wifi_total, eth_total = wifi_rx + wifi_tx, eth_rx + eth_tx
        curr_rx, curr_tx = wifi_rx + eth_rx, wifi_tx + eth_tx

        if first_run:
            last_rx, last_tx, first_run = curr_rx, curr_tx, False
            time.sleep(1)
            continue

        in_speed = max(curr_rx - last_rx, 0)
        out_speed = max(curr_tx - last_tx, 0)
        delta_wifi = (
            wifi_total - last_wifi_raw if wifi_total >= last_wifi_raw else wifi_total
        )
        delta_eth = eth_total - last_eth_raw if eth_total >= last_eth_raw else eth_total

        state["monthly_wifi"] += delta_wifi
        state["monthly_eth"] += delta_eth
        state["life_wifi"] += delta_wifi
        state["life_eth"] += delta_eth
        state["daily_wifi"] += delta_wifi
        state["daily_eth"] += delta_eth
        state["last_proc_wifi"] = wifi_total
        state["last_proc_eth"] = eth_total

        monthly_total = state["monthly_wifi"] + state["monthly_eth"]
        daily_total = state["daily_wifi"] + state["daily_eth"]
        life_total = state["life_wifi"] + state["life_eth"]

        check_alerts(daily_total, config["limit_daily_gb"], "daily")
        check_alerts(monthly_total, config["limit_monthly_gb"], "monthly")

        if tick_counter % 5 == 0:
            check_daily_reset()
            update_colors()

            today = datetime.now().date()
            next_reset_str = state.get("next_monthly_reset_date", "1970-01-01")
            try:
                next_reset_date = datetime.strptime(next_reset_str, "%Y-%m-%d").date()
            except ValueError:
                next_reset_date = datetime(1970, 1, 1).date()

            if today >= next_reset_date:
                state["monthly_wifi"] = 0
                state["monthly_eth"] = 0
                reset_notification_flags("monthly")
                reset_day_cfg = config.get("reset_day", 11)
                new_next_date = calculate_next_reset_date(reset_day_cfg)
                state["next_monthly_reset_date"] = new_next_date.strftime("%Y-%m-%d")
                save_state()

        if tick_counter >= 60:
            save_state()
            tick_counter = 0
        tick_counter += 1

        dominant_icon = icon_down if in_speed >= out_speed else icon_up
        dominant_speed = max(in_speed, out_speed)
        in_fmt = f"<span color='{primary_color}'>{format_speed(in_speed)}</span>"
        out_fmt = f"<span color='{secondary_color}'>{format_speed(out_speed)}</span>"

        limit_m_gb = config["limit_monthly_gb"]
        monthly_str = f"{format_bytes(monthly_total)} / {limit_m_gb}GB"
        if limit_m_gb > 0 and monthly_total >= 0.9 * (limit_m_gb * 1024**3):
            monthly_str = f"<span color='{secondary_color}'>{monthly_str}</span>"

        limit_d_gb = config["limit_daily_gb"]
        if limit_d_gb <= 0:
            daily_str = format_bytes(daily_total)
        else:
            daily_str = f"{format_bytes(daily_total)} / {limit_d_gb}GB"
            if daily_total >= 0.9 * (limit_d_gb * 1024**3):
                daily_str = f"<span color='{secondary_color}'>{daily_str}</span>"

        # WAYBAR TOOLTIP
        tooltip = (
            "<big><b><u>Waybar Data Manager</u></b></big>\n\n"
            "<b>This Session</b> (Since Boot)\n"
            f"WiFi Usage: {format_bytes(wifi_total)}\n"
            f"Ethernet Usage: {format_bytes(eth_total)}\n\n"
            "<b>Today's Usage</b>\n"
            f"WiFi Usage: {format_bytes(state['daily_wifi'])}\n"
            f"Ethernet Usage: {format_bytes(state['daily_eth'])}\n"
            f"Total: {daily_str}\n\n"
            f"<b>This Month</b> (Resets on {state.get('next_monthly_reset_date', 'N/A')})\n"
            f"Wifi usage: {format_bytes(state['monthly_wifi'])}\n"
            f"Ethernet usage: {format_bytes(state['monthly_eth'])}\n"
            f"Total : {monthly_str}\n\n"
            "<b>Life Time</b>\n"
            f"Total data: {format_bytes(life_total)}\n\n"
            "<b>Speed</b>\n"
            f"Incoming: {in_fmt}\n"
            f"Outgoing: {out_fmt}"
        )

        print(
            json.dumps(
                {
                    "text": f"{dominant_icon} {format_speed(dominant_speed)}",
                    "tooltip": tooltip,
                }
            ),
            flush=True,
        )

        last_rx, last_tx = curr_rx, curr_tx
        last_wifi_raw, last_eth_raw = wifi_total, eth_total
        time.sleep(1)


if __name__ == "__main__":
    main()
