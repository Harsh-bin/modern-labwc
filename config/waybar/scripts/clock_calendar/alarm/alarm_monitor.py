#!/usr/bin/env python3
import json
import time
import os
import subprocess
import threading
from datetime import datetime

# configuration
config_dir = os.path.expanduser("~/.config/waybar/scripts/clock_calendar/alarm")
db_file = os.path.join(config_dir, "alarms.json")
alarm_script = os.path.join(config_dir, "alarm.sh")

# try import watchdog
try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler

    has_watchdog = True
except ImportError:
    has_watchdog = False
    print("WARNING: 'watchdog' library not found. Falling back to polling.")

    class FileSystemEventHandler:
        pass


# shared functions


def get_alarms():
    try:
        with open(db_file, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def fire_alarm(alarm, current_time_str):
    # executes the bash script
    try:
        al_id = str(alarm.get("id"))
        label = str(alarm.get("label"))
        days = str(alarm.get("days", "once"))

        print(f"[{current_time_str}] TRIGGER: {label} (ID: {al_id})")

        # use non-blocking popen so we don't delay the main thread
        subprocess.Popen(
            [alarm_script, "trigger_action", al_id, label, days, current_time_str]
        )
    except Exception as e:
        print(f"Error firing alarm: {e}")


def get_seconds_to_sleep_until_next_minute():
    # calculates exact seconds remaining until the next hh:mm:00
    now = datetime.now()
    return 60.0 - (now.second + (now.microsecond / 1_000_000.0))


############################################
# mode 1: smart scheduler (fixed) ##########
############################################


class AlarmFileHandler(FileSystemEventHandler):
    def __init__(self, callback):
        self.callback = callback
        self.db_path = os.path.abspath(db_file)

    def _maybe_callback(self, path):
        if path and os.path.abspath(path) == self.db_path:
            self.callback()

    def on_modified(self, event):
        if not event.is_directory:
            self._maybe_callback(event.src_path)

    def on_moved(self, event):
        if not event.is_directory:
            self._maybe_callback(event.dest_path)

    def on_created(self, event):
        if not event.is_directory:
            self._maybe_callback(event.src_path)


def worker_fire_alarm(alarm, target_second, stop_event, worker_id):
    # worker thread, sleeps until target second
    try:
        # sync close to the second to avoid busy waiting
        now = datetime.now()
        current_s = now.second + (now.microsecond / 1e6)
        wait_time = target_second - current_s
        # FIX: added 1sec grace period, so that alarms run even after while sorting
        if wait_time < -0.9:
            return

        # If we are slightly late (negative wait_time) don't sleep, just fire.
        if wait_time > 0:
            # Sleep until target time OR until file changes
            if stop_event.wait(wait_time):
                return

        # double check time and fire
        now = datetime.now()
        # Allow 1.5s window to ensure we catch the trigger
        if abs(now.second - target_second) < 2 or (
            target_second == 0 and now.second >= 59
        ):
            fire_alarm(alarm, now.strftime("%H:%M:%S"))

    except Exception as e:
        print(f"Error in worker {worker_id}: {e}")


def smart_monitor():
    print("--- Starting SMART Monitor (Watchdog Enabled) ---")

    main_loop_interrupt = threading.Event()

    def on_file_change():
        main_loop_interrupt.set()

    observer = Observer()
    event_handler = AlarmFileHandler(on_file_change)
    observer.schedule(event_handler, path=config_dir, recursive=False)
    observer.start()

    cached_alarms = get_alarms()
    current_worker_stop_event = threading.Event()

    try:
        while True:
            main_loop_interrupt.clear()

            now = datetime.now()
            current_hour_min = now.strftime("%H:%M")
            current_day_short = now.strftime("%a").lower()
            current_second = now.second

            scheduled_alarms = []

            for alarm in cached_alarms:
                if alarm.get("status") != "on":
                    continue

                days_str = alarm.get("days", "once").lower()
                days_list = [d.strip() for d in days_str.split(",")]

                is_today = (
                    "daily" in days_list
                    or "once" in days_list
                    or current_day_short in days_list
                )

                if not is_today:
                    continue

                alarm_time = alarm.get("time", "")
                if not alarm_time.startswith(current_hour_min):
                    continue

                try:
                    parts = alarm_time.split(":")
                    target_sec = int(parts[2])

                    # FIX 2: used >= to catch alarms at the 0th second
                    if target_sec >= current_second:
                        scheduled_alarms.append((target_sec, alarm))
                except (ValueError, IndexError):
                    continue

            scheduled_alarms.sort(key=lambda x: x[0])

            # Spawn Workers
            # create a new event object for this specific batch of workers
            current_worker_stop_event = threading.Event()

            for i, (target_sec, alarm) in enumerate(scheduled_alarms):
                t = threading.Thread(
                    target=worker_fire_alarm,
                    args=(alarm, target_sec, current_worker_stop_event, i),
                    daemon=True,
                )
                t.start()
            # calculate sleep
            if not scheduled_alarms:
                sleep_duration = get_seconds_to_sleep_until_next_minute()
            else:
                last_alarm_sec = scheduled_alarms[-1][0]
                wake_offset = last_alarm_sec + 1 - (now.second + now.microsecond / 1e6)
                sleep_duration = (
                    wake_offset
                    if wake_offset > 0
                    else get_seconds_to_sleep_until_next_minute()
                )
            # sleep and wait for interrupt
            file_changed = main_loop_interrupt.wait(sleep_duration)

            if file_changed:
                print("DEBUG: File changed. Reloading DB and rescheduling...")
                # signal all current workers to stop immediately
                current_worker_stop_event.set()
                # reload db for next iteration
                time.sleep(0.1)
                cached_alarms = get_alarms()

    except KeyboardInterrupt:
        observer.stop()
        current_worker_stop_event.set()
    finally:
        observer.join()


#########################################################
# mode 2: fallback (simple poll) [old method] ###########
#########################################################


def simple_monitor():
    print("--- Starting FALLBACK Monitor (1-sec poll) ---")

    last_mtime = 0
    cached_alarms = []
    triggered_cache = {}

    while True:
        # Sync to the exact start of the next second
        now = datetime.now()
        sleep_needed = 1.0 - (now.microsecond / 1_000_000.0)
        time.sleep(sleep_needed)

        try:
            if os.path.exists(db_file):
                current_mtime = os.path.getmtime(db_file)

                # If file changed OR script just started:
                if current_mtime != last_mtime:
                    print("DEBUG: File changed or started. Loading JSON into RAM.")
                    cached_alarms = get_alarms()
                    last_mtime = current_mtime

            now = datetime.now()
            curr_time_str = now.strftime("%H:%M:%S")
            curr_day = now.strftime("%a").lower()

            # clean up old cache entries
            prefix = now.strftime("%H:%M")
            triggered_cache = {
                k: v for k, v in triggered_cache.items() if v.startswith(prefix)
            }
            # use ram cache
            for alarm in cached_alarms:
                if alarm.get("status") != "on":
                    continue

                al_id = str(alarm.get("id"))

                # Prevent double firing in the same second
                if triggered_cache.get(al_id) == curr_time_str:
                    continue

                if alarm.get("time") == curr_time_str:
                    # String Split Logic (The Day Check)
                    days_str = alarm.get("days", "once").lower()
                    days_list = [d.strip() for d in days_str.split(",")]

                    if (
                        "daily" in days_list
                        or "once" in days_list
                        or curr_day in days_list
                    ):
                        triggered_cache[al_id] = curr_time_str
                        fire_alarm(alarm, curr_time_str)

        except Exception as e:
            print(f"Error in main loop: {e}")
            time.sleep(1)


if __name__ == "__main__":
    if has_watchdog:
        smart_monitor()
    else:
        simple_monitor()
