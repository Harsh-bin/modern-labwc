#!/usr/bin/env python3
import os
import re
import sys
import json
import time
import signal
import socket
import shutil
import random
import requests
import subprocess
import urllib.parse
import threading
import queue
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

# Configurations
search_count = 30  # Number of search results to fetch
config_dir = Path.home() / ".config/rofi/rofi-tube"
thumb_dir = config_dir / "thumbnails"
history_file = config_dir / "search-history.json"
config_file = config_dir / "rofi-tube.conf"
pid_file = config_dir / "rofi-tube.pid"
cookie_file = config_dir / "youtube-cookies.txt"

# Rofi themes and icons
rofi_search_theme = config_dir / "search-window.rasi"
rofi_tube_theme = config_dir / "rofi-tube.rasi"
rofi_menu_theme = config_dir / "horizontal_menu.rasi"
yt_icon = config_dir / "youtube.png"
music_icon = config_dir / "yt-music.png"

# Mpv Socket
mpv_socket_path = Path("/tmp/rofi_tube_mpv.sock")
# Vlc rc config
vlc_rc_host = "127.0.0.1"
vlc_rc_port = 12345

# Notification id
notify_id = "string:x-canonical-private-synchronous:rofitube"
thumb_dir.mkdir(parents=True, exist_ok=True)

# Fallback player selection
config = {
    "player": "mpv" if shutil.which("mpv") else "vlc",
    "resolution": "1080",
    "codec": "h264",
    "playlist": "false",
    "playlist_limit": "50",
}


def manage_cache():
    max_cache_mb = 40  # More than enough space for thumbnails
    target_cache_mb = 35
    limit_bytes = max_cache_mb * 1024 * 1024
    target_bytes = target_cache_mb * 1024 * 1024
    if not thumb_dir.exists():
        return
    files = []
    total_size = 0
    for item in thumb_dir.glob("*"):
        if item.is_file():
            try:
                stat = item.stat()
                total_size += stat.st_size
                files.append((item, stat.st_mtime, stat.st_size))
            except:
                pass
    if total_size <= limit_bytes:
        return

    print(
        f"[!] Cache limit exceeded ({total_size / (1024*1024):.2f} MB). Clearing old files..."
    )
    files.sort(key=lambda x: x[1])
    for path, mtime, size in files:
        try:
            path.unlink()
            total_size -= size
            if total_size <= target_bytes:
                break
        except Exception:
            pass


if not config_file.exists():
    default_conf = (
        '# Player: mpv, vlc\nplayer="mpv"\n\n'
        '# Resolution: 2160, 1440, 1080, 720, 480, 360, 240, 144 or best\nresolution="1080"\n\n'
        '# Codec: h264, av1, vp9\ncodec="h264"\n\n'
        '# Playlist Mode: true/false\nplaylist="false"\n\n'
        '# Max Playlist Items\nplaylist_limit="50"\n'
    )
    with open(config_file, "w") as f:
        f.write(default_conf)
else:
    with open(config_file, "r") as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                config[k.strip()] = v.strip().replace('"', "")

player_bin = config.get("player", "mpv")

# Cookie file check
def ensure_cookie_file_exists():
    if not cookie_file.exists():
        print(f"[*] Cookie file not found. Creating at: {cookie_file}")
        try:
            with open(cookie_file, "w") as f:
                # Write the necessary header for a valid Netscape cookie file
                f.write("# Netscape HTTP Cookie File\n")
        except Exception as e:
            print(f"[!] Error creating cookie file: {e}")

# Notification helper  


def notify(title, msg):
    if shutil.which("notify-send"):
        subprocess.Popen(
            ["notify-send", "-h", notify_id, title, msg], stderr=subprocess.DEVNULL
        )


def take_control_of_session():
    current_pid = os.getpid()
    if pid_file.exists():
        try:
            old_pid = int(pid_file.read_text().strip())
            if old_pid != current_pid:
                try:
                    print(
                        f"[*] Session Handover: Killed previous loop (PID: {old_pid})"
                    )
                    os.kill(old_pid, signal.SIGTERM)
                except Exception:
                    pass
        except Exception:
            pass
    try:
        pid_file.write_text(str(current_pid))
        print(f"[*] New Session ID registered: {current_pid}")
    except Exception as e:
        print(f"[!] Error writing session file: {e}")


def get_history_input():
    if not history_file.exists():
        return ""
    try:
        with open(history_file, "r") as f:
            history = json.load(f)
            lines = []
            for entry in reversed(history):
                icon_path = thumb_dir / f"{entry['id']}.jpg"
                lines.append(f"{entry['query']}\0icon\x1f{icon_path}")
            return "\n".join(lines)
    except:
        return ""


def update_history_file(query, results, played_video_id=None):
    if not results and not played_video_id:
        return
    history = []
    if history_file.exists():
        try:
            with open(history_file, "r") as f:
                history = json.load(f)
        except:
            pass

    if played_video_id:
        history = [h for h in history if h["query"].lower() != query.lower()]
        history.append({"query": query, "id": played_video_id})
    else:
        existing = next(
            (h for h in history if h["query"].lower() == query.lower()), None
        )
        if existing:
            history = [h for h in history if h["query"].lower() != query.lower()]
            history.append(existing)
        else:
            if results:
                history.append({"query": query, "id": results[0]["id"]})

    history = history[-150:]
    with open(history_file, "w") as f:
        json.dump(history, f, indent=4)


def get_streaming_links(video_id, mode="Video"):
    print(f"[*] Resolving links for ID: {video_id} ({mode})...")
    video_url = f"https://www.youtube.com/watch?v={video_id}"
    cmd = ["yt-dlp", "-g", "--cookies", str(cookie_file)]

    if mode == "YT-Music":
        cmd.extend(["-f", "bestaudio/best"])
    else:
        res = config.get("resolution", "1080")
        codec = config.get("codec", "h264")
        codec_arg = ""
        if codec == "h264":
            codec_arg = "[vcodec^=avc1]"
        elif codec == "av1":
            codec_arg = "[vcodec^=av01]"
        elif codec == "vp9":
            codec_arg = "[vcodec^=vp9]"

        if res == "best":
            fmt = f"bestvideo{codec_arg}+bestaudio/best"
        else:
            fmt = f"bestvideo[height<={res}]{codec_arg}+bestaudio/best[height<={res}]{codec_arg}/best"
        cmd.extend(["-f", fmt])

    cmd.append(video_url)
    try:
        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
        links = [l for l in result.stdout.strip().split("\n") if l.strip()]
        if links:
            print(f"[+] Links acquired for: {video_id}")
        return links
    except:
        return []


# MPV and VLC Control


def send_mpv_command(cmd_data):
    if not mpv_socket_path.exists():
        return False
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(1)
            client.connect(str(mpv_socket_path))
            client.send(json.dumps(cmd_data).encode() + b"\n")
            client.recv(1024)
        return True
    except:
        return False


def send_vlc_command(cmd_str):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(1)
            s.connect((vlc_rc_host, vlc_rc_port))
            s.sendall(f"{cmd_str}\n".encode())
        return True
    except:
        return False


def is_player_running():
    if "mpv" in player_bin:
        if mpv_socket_path.exists():
            return send_mpv_command({"command": ["get_property", "idle-active"]})
        return False
    else:
        return send_vlc_command("status")


def ensure_player_running():
    if is_player_running():
        print(f"[#] {player_bin} is already running.")
        return True

    print(f"[#] Starting {player_bin}...")
    if "mpv" in player_bin:
        cmd = [
            player_bin,
            "--idle=yes",
            "--force-window=immediate",
            f"--input-ipc-server={mpv_socket_path}",
        ]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for i in range(20):
            if mpv_socket_path.exists():
                print(f"[#] MPV Socket ready after {i*0.2}s")
                break
            time.sleep(0.2)
    else:
        subprocess.Popen(
            [
                player_bin,
                "--one-instance",
                "--extraintf",
                "rc",
                "--rc-host",
                f"{vlc_rc_host}:{vlc_rc_port}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(3)
    return True



def fetch_worker(video_queue, result_queue, mode_choice):
    print("[Thread] Worker thread started for prefetching...")
    while True:
        try:
            item = video_queue.get()
            if item is None:
                break
            vid_id, title = item
            print(f"[*] Prefetching: {title}")
            links = get_streaming_links(vid_id, mode_choice)
            result_queue.put((vid_id, title, links))
            video_queue.task_done()
        except Exception as e:
            print(f"[!] Worker Error: {e}")


def play_video_mpv(links, title):
    print(f"[>] Sending load command for: {title}")
    send_mpv_command({"command": ["loadfile", links[0], "replace"]})
    if len(links) > 1:
        time.sleep(0.1)
        send_mpv_command({"command": ["audio-add", links[1]]})

    # Send title immediately to prevent Lua crash
    send_mpv_command({"command": ["set_property", "force-media-title", title]})
    send_mpv_command({"command": ["set_property", "pause", False]})


def play_video_vlc(links, title):
    print(f"[>] Sending VLC command for: {title}")
    safe_title = title.replace(" ", "\u00A0").replace('"', "'")
    send_vlc_command("clear")
    time.sleep(0.1)
    vlc_cmd = f"add {links[0]} :meta-title={safe_title}"
    if len(links) > 1:
        vlc_cmd += f" :input-slave={links[1]}"
    send_vlc_command(vlc_cmd)


def get_vlc_state():
    """Returns 'playing', 'stopped', 'paused', or 'unknown' via RC interface"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(0.5)
            s.connect((vlc_rc_host, vlc_rc_port))
            # clear welcome message if any
            try:
                s.recv(1024)
            except:
                pass

            s.sendall(b"status\n")
            response = s.recv(4096).decode("utf-8", errors="ignore").lower()

            if "state playing" in response:
                return "playing"
            if "state paused" in response:
                return "paused"
            if "state stop" in response:
                return "stopped"
            return "unknown"
    except:
        return "error"


def manage_playlist_loop(playlist_items, mode_choice):
    take_control_of_session()
    ensure_player_running()

    is_mpv = "mpv" in player_bin
    total = len(playlist_items)
    video_q = queue.Queue()
    result_q = queue.Queue()

    worker = threading.Thread(
        target=fetch_worker, args=(video_q, result_q, mode_choice), daemon=True
    )
    worker.start()

    # Queue only the first song initially
    video_q.put((playlist_items[0]["id"], playlist_items[0]["title"]))

    next_index_to_queue = 1

    for idx in range(total):
        print(f"[*] Waiting for link processing [{idx+1}/{total}]...")
        vid_id, raw_title, links = result_q.get()
        display_title = f"[{idx+1}/{total}] {raw_title}"

        if links:
            notify("YouTube", f"Playing: {raw_title}")
            print(f"\n[>>>] PLAYING: {raw_title} [>>>]\n")

            if is_mpv:
                play_video_mpv(links, display_title)
            else:
                play_video_vlc(links, display_title)

            # Queue next song
            if next_index_to_queue < total:
                next_item = playlist_items[next_index_to_queue]
                video_q.put((next_item["id"], next_item["title"]))
                next_index_to_queue += 1

            print("[.] Monitor: Waiting for playback to START...")

            # Wait for the player to report that it has started playing
            started_playing = False
            for _ in range(20):
                time.sleep(0.5)
                if not is_player_running():
                    return

                if is_mpv:
                    try:
                        with socket.socket(
                            socket.AF_UNIX, socket.SOCK_STREAM
                        ) as client:
                            client.connect(str(mpv_socket_path))
                            client.send(
                                json.dumps(
                                    {"command": ["get_property", "core-idle"]}
                                ).encode()
                                + b"\n"
                            )
                            resp = json.loads(client.recv(4096).decode())
                            if resp.get("data") is False:
                                started_playing = True
                                break
                    except:
                        pass
                else:
                    # vlc Check
                    if get_vlc_state() == "playing":
                        started_playing = True
                        break

            if not started_playing:
                print(
                    "[!] Warning: Player didn't report 'Playing' state. Monitoring anyway."
                )

            print(f"[.] Monitor: Watching {raw_title}...")

            # wait for the track to finish 
            while True:
                time.sleep(1.5)
                if not is_player_running():
                    print("[!] Player closed. Playlist Aborted.")
                    return

                if is_mpv:
                    try:
                        with socket.socket(
                            socket.AF_UNIX, socket.SOCK_STREAM
                        ) as client:
                            client.connect(str(mpv_socket_path))
                            client.send(
                                json.dumps(
                                    {"command": ["get_property", "idle-active"]}
                                ).encode()
                                + b"\n"
                            )
                            resp = json.loads(client.recv(4096).decode())
                            if resp.get("data") is True:
                                print(f"[-] Track Finished: {raw_title}")
                                break
                    except:
                        break
                else:
                    state = get_vlc_state()
                    if state == "stopped":
                        print(f"[-] Track Finished: {raw_title}")
                        break
        else:
            print(f"[!] FAILED to get links for: {raw_title}")

    video_q.put(None)
    print("[*] Playlist Finished.")


def run_rofi(cmd_input, theme, prompt, message=None):
    args = ["rofi", "-dmenu", "-p", prompt, "-show-icons", "-theme", str(theme)]
    if message:
        args.extend(["-mesg", message])
    process = subprocess.Popen(
        args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
    )
    stdout, _ = process.communicate(input=cmd_input)
    return stdout.strip()


# Youtube Scraping and Thumbnail Handling

def fetch_youtube_data(query):
    encoded_search = urllib.parse.quote(query)
    url = f"https://www.youtube.com/results?search_query={encoded_search}"
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        response = requests.get(url, headers=headers)
        match = re.search(r"var ytInitialData = ({.*?});", response.text, re.S)
        if not match:
            return []
        raw_data = json.loads(match.group(1))
        results = []
        try:
            contents = raw_data["contents"]["twoColumnSearchResultsRenderer"][
                "primaryContents"
            ]["sectionListRenderer"]["contents"]
            for section in contents:
                if "itemSectionRenderer" not in section:
                    continue
                for item in section["itemSectionRenderer"]["contents"]:
                    if len(results) >= search_count:
                        break
                    if "videoRenderer" in item:
                        v = item["videoRenderer"]
                        results.append(
                            {
                                "id": v.get("videoId"),
                                "title": v.get("title", {})
                                .get("runs", [{}])[0]
                                .get("text", "No Title"),
                                "duration": v.get("lengthText", {}).get(
                                    "simpleText", "N/A"
                                ),
                                "thumbnail": v.get("thumbnail", {}).get(
                                    "thumbnails", []
                                )[0]["url"]
                                if v.get("thumbnail")
                                else None,
                            }
                        )
        except:
            pass
        return results
    except:
        return []


def download_thumbnail(item):
    t_path = thumb_dir / f"{item['id']}.jpg"
    if t_path.exists():
        print(f"[~] Cached: {item['id']}")
        return
    try:
        print(f"[↓] Downloading: {item['id']}")
        r = requests.get(item["thumbnail"], timeout=5)
        with open(t_path, "wb") as f:
            f.write(r.content)
    except:
        print(f"[!] Failed thumb: {item['id']}")


def get_playlist_data(base_id, limit):
    print(f"[*] Fetching Playlist Data for ID: {base_id}...")
    mix_url = f"https://www.youtube.com/watch?v={base_id}&list=RD{base_id}"
    cmd = [
        "yt-dlp",
        "--flat-playlist",
        "--print",
        "%(id)s<SEP>%(title)s",
        "--playlist-end",
        str(limit),
        "--cookies",
        str(cookie_file),
        mix_url,
    ]
    try:
        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
        items = []
        seen = set()
        for line in result.stdout.splitlines():
            if "<SEP>" in line:
                vid_id, vid_title = line.split("<SEP>", 1)
                if vid_id not in seen:
                    items.append({"id": vid_id.strip(), "title": vid_title.strip()})
                    seen.add(vid_id.strip())
        print(f"[+] Playlist generated with {len(items)} items.")
        return items
    except:
        print("[!] Failed to fetch playlist data.")
        return [{"id": base_id, "title": "Unknown"}]


def main():
    manage_cache()
    ensure_cookie_file_exists()
    print("[+] Opening Mode Selection...")
    mode_options = [f"YouTube\0icon\x1f{yt_icon}", f"YT-Music\0icon\x1f{music_icon}"]
    mode_choice = run_rofi(
        "\n".join(mode_options),
        rofi_menu_theme,
        "Mode",
        message="<big>Select Mode</big>",
    )
    if not mode_choice:
        print("[-] Selection cancelled.")
        return

    print(f"[+] Selected Mode: {mode_choice}")

    history_data = get_history_input()
    query = run_rofi(history_data, rofi_search_theme, f"Search ({mode_choice}) ::")
    if not query:
        print("[-] Search cancelled.")
        return

    notify("YouTube", f"Searching: {query}")
    print(f"[?] Searching YouTube for: {query}")
    results = fetch_youtube_data(query)
    print(f"[+] Found {len(results)} results.")

    print("[*] Processing thumbnails...")
    with ThreadPoolExecutor(max_workers=15) as executor:
        executor.map(download_thumbnail, results)

    rofi_list = []
    for vid in results:
        t = vid["title"].replace("&", "&amp;")
        icon_path = thumb_dir / f"{vid['id']}.jpg"
        rofi_list.append(f"{t} [{vid['duration']}] | {vid['id']}\0icon\x1f{icon_path}")

    selected = run_rofi(
        "\n".join(rofi_list), rofi_tube_theme, "Select", message=f"Results for {query}"
    )
    if not selected:
        print("[-] Result selection cancelled.")
        return

    video_id = selected.split(" | ")[-1]
    video_title = selected.rsplit(" | ", 1)[0]
    print(f"[+] Selected: {video_title} ({video_id})")
    update_history_file(query, results, played_video_id=video_id)

    is_playlist = config.get("playlist", "false").lower() == "true"
    mode_clean = "YT-Music" if "Music" in mode_choice else "Video"

    if is_playlist:
        limit = config.get("playlist_limit", "50")
        notify("Playlist", f"Generating Mix: {video_title}")
        items = get_playlist_data(video_id, limit)
        manage_playlist_loop(items, mode_clean)
    else:
        take_control_of_session()
        ensure_player_running()
        notify("YouTube", f"Opening: {video_title}")
        links = get_streaming_links(video_id, mode_clean)
        if links:
            if "mpv" in player_bin:
                play_video_mpv(links, video_title)
            else:
                play_video_vlc(links, video_title)


if __name__ == "__main__":
    main()