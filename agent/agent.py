#!/usr/bin/env python3
"""
World of IT: Linux Desktop Agent (V2 Seamless Edition)
- Seamless 1s automatic clipboard watcher + manual push
- Native Linux Top Bar / System Tray indicator icon with unread badge dot
- Native desktop toast notification + subtle "dink" sound on incoming clipboard
- Automatic Wi-Fi reconnect & presence tracking for all online devices
"""

import argparse
import asyncio
import fcntl
import json
import logging
import os
import platform
import shutil
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, Any, Callable

try:
    import httpx
    import websockets
except ImportError:
    print("Error: Missing python dependencies. Run: pip install httpx websockets")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("world_of_it_agent")


def get_utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_current_epoch_ms() -> int:
    return int(time.time() * 1000)


def notify_desktop_clipboard(source_name: str, text: str):
    """Shows a compact native desktop toast and plays a subtle notification 'dink'."""
    preview = text.strip().replace("\n", " ")
    if len(preview) > 70:
        preview = preview[:67] + "..."

    # 1. Native desktop notification banner
    if shutil.which("notify-send"):
        try:
            subprocess.Popen(
                [
                    "notify-send",
                    "-a",
                    "World of IT",
                    "-i",
                    "edit-paste",
                    "-t",
                    "2500",
                    f"Synced from {source_name}",
                    preview,
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass

    # 2. Subtle native "dink" sound
    if shutil.which("canberra-gtk-play"):
        try:
            subprocess.Popen(
                ["canberra-gtk-play", "-i", "message-new-instant"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return
        except Exception:
            pass

    sound_file = "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
    if shutil.which("paplay") and os.path.exists(sound_file):
        try:
            subprocess.Popen(
                ["paplay", sound_file],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass


class LinuxTopBarTray:
    """
    Renders a crisp, minimal native GNOME StatusNotifierItem SVG Clipboard icon
    (with soft pastel mint-green / amber / coral status dot) in the Linux Top Bar.
    Falls back cleanly to pystray only on non-SNI X11 sessions.
    """

    def __init__(
        self,
        on_manual_push: Callable[[], None],
        on_toggle_auto: Callable[[], bool],
        on_open_app: Callable[[], None],
    ):
        self.on_manual_push = on_manual_push
        self.on_toggle_auto = on_toggle_auto
        self.on_open_app = on_open_app
        self.is_connected = True
        self.online_count = 1
        self.both_synced = False
        self.has_unread_clip = False
        self.auto_sync = True
        self.latest_clip_preview = "None yet"
        self._icon = None
        self._sni_proc: Optional[subprocess.Popen] = None
        self._last_icon_state = None

    def _status_color(self):
        if not self.is_connected or not self.auto_sync:
            return (229, 107, 111, 255)  # Soft Pastel Coral (#E56B6F)
        if self.has_unread_clip or not self.both_synced:
            return (229, 169, 34, 255)  # Soft Pastel Amber (#E5A922)
        return (52, 199, 123, 255)  # Soft Pastel Mint-Green (#34C77B)

    def _create_image(self):
        from PIL import Image, ImageDraw

        # Fallback XEmbed image: composite onto light sage panel tone (#D2DCD7)
        # so legacy non-SNI X11 trays never show black uninitialized corners.
        bg = (210, 220, 215, 255)
        fg = (83, 78, 24, 255)
        dot = self._status_color()

        img = Image.new("RGBA", (32, 32), bg)
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle((7, 6, 23, 28), radius=3, outline=fg, width=2)
        draw.rounded_rectangle((11, 3, 19, 8), radius=2, fill=bg, outline=fg, width=2)
        draw.ellipse((19, 19, 27, 27), fill=dot, outline=bg, width=1)
        return img

    def _push_sni_state(self):
        proc = self._sni_proc
        if proc is None or proc.poll() is not None or proc.stdin is None:
            return
        payload = {
            "is_connected": self.is_connected,
            "online_count": self.online_count,
            "both_synced": self.both_synced,
            "has_unread_clip": self.has_unread_clip,
            "latest_clip_preview": self.latest_clip_preview,
            "auto_sync": self.auto_sync,
        }
        try:
            proc.stdin.write(json.dumps(payload) + "\n")
            proc.stdin.flush()
        except Exception:
            pass

    def update_state(
        self,
        *,
        is_connected: Optional[bool] = None,
        online_count: Optional[int] = None,
        has_unread_clip: Optional[bool] = None,
        latest_clip: Optional[str] = None,
        auto_sync: Optional[bool] = None,
    ):
        if is_connected is not None:
            self.is_connected = is_connected
        if online_count is not None:
            self.online_count = online_count
            self.both_synced = online_count >= 2
        if has_unread_clip is not None:
            self.has_unread_clip = has_unread_clip
        if latest_clip is not None:
            clean = latest_clip.strip().replace("\n", " ")
            self.latest_clip_preview = clean[:34] + ("..." if len(clean) > 34 else "")
        if auto_sync is not None:
            self.auto_sync = auto_sync

        cur_state = (
            self.is_connected,
            self.both_synced,
            self.has_unread_clip,
            self.online_count,
            self.latest_clip_preview,
            self.auto_sync,
        )
        if cur_state == self._last_icon_state:
            return
        self._last_icon_state = cur_state

        if self._sni_proc is not None and self._sni_proc.poll() is None:
            self._push_sni_state()
            return

        if self._icon is not None:
            try:
                self._icon.icon = self._create_image()
                if not self.is_connected:
                    status_txt = "World of IT: Offline / Waiting for Wi-Fi"
                elif not self.auto_sync:
                    status_txt = "World of IT: Auto-Sync Paused"
                elif self.both_synced:
                    status_txt = f"World of IT: Synced ({self.online_count} Online)"
                else:
                    status_txt = "World of IT: Waiting for Phone (1 Online)"
                self._icon.title = status_txt
                self._icon.update_menu()
            except Exception:
                pass

    def _try_start_native_sni(self) -> bool:
        """Attempts to launch native D-Bus StatusNotifierItem helper via /usr/bin/python3."""
        sys_py = "/usr/bin/python3"
        helper = Path(__file__).resolve().parent / "sni_tray.py"
        if not os.path.exists(sys_py) or not helper.exists():
            return False

        try:
            proc = subprocess.Popen(
                [sys_py, str(helper)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )
            first_line = proc.stdout.readline().strip() if proc.stdout else ""
            if '"registered"' not in first_line:
                proc.terminate()
                return False

            self._sni_proc = proc
            self._push_sni_state()

            import atexit

            def _cleanup():
                if proc.poll() is None:
                    try:
                        if proc.stdin:
                            proc.stdin.write(json.dumps({"cmd": "quit"}) + "\n")
                            proc.stdin.flush()
                        proc.terminate()
                    except Exception:
                        pass

            atexit.register(_cleanup)

            def _listen_actions():
                if not proc.stdout:
                    return
                for raw in proc.stdout:
                    raw = raw.strip()
                    if not raw:
                        continue
                    try:
                        evt = json.loads(raw)
                        act = evt.get("action")
                        if act == "mark_read":
                            self.update_state(has_unread_clip=False)
                        elif act == "manual_push":
                            self.update_state(has_unread_clip=False)
                            self.on_manual_push()
                        elif act == "toggle_auto":
                            new_val = self.on_toggle_auto()
                            self.update_state(auto_sync=new_val)
                        elif act == "open_app":
                            self.update_state(has_unread_clip=False)
                            self.on_open_app()
                    except Exception:
                        pass

            threading.Thread(target=_listen_actions, daemon=True).start()
            logger.info("Native GNOME StatusNotifierItem SVG top-bar indicator initialized.")
            return True
        except Exception as exc:
            logger.debug(f"Native SNI helper unavailable: {exc}")
            return False

    def start_in_background(self):
        if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
            return

        def _run():
            if self._try_start_native_sni():
                return

            try:
                import pystray
                from pystray import MenuItem as Item

                def status_label(_):
                    if self.both_synced:
                        return f"Synced · {self.online_count} Devices Online"
                    return f"Ready · {self.online_count} Device Online"

                def latest_label(_):
                    prefix = "● New: " if self.has_unread_clip else "Latest: "
                    return f"{prefix}{self.latest_clip_preview}"

                def auto_label(_):
                    return f"Auto-Sync Clipboard: {'On' if self.auto_sync else 'Off'}"

                def on_click_latest(icon, item):
                    self.update_state(has_unread_clip=False)

                def on_click_push(icon, item):
                    self.has_unread_clip = False
                    self.on_manual_push()

                def on_click_auto(icon, item):
                    new_val = self.on_toggle_auto()
                    self.update_state(auto_sync=new_val)

                def on_click_open(icon, item):
                    self.update_state(has_unread_clip=False)
                    self.on_open_app()

                menu = pystray.Menu(
                    Item(status_label, on_click_latest, enabled=False),
                    Item(latest_label, on_click_latest, default=True),
                    pystray.Menu.SEPARATOR,
                    Item("Send Clipboard Now", on_click_push),
                    Item(auto_label, on_click_auto),
                    pystray.Menu.SEPARATOR,
                    Item("Open World of IT", on_click_open),
                )

                self._icon = pystray.Icon(
                    "world_of_iot_tray",
                    self._create_image(),
                    "World of IT Sync",
                    menu,
                )
                logger.info("Fallback pystray top bar indicator initialized.")
                self._icon.run()
            except Exception as e:
                logger.debug(f"Top bar indicator not started: {e}")

        t = threading.Thread(target=_run, daemon=True)
        t.start()


class LocalClipboard:
    """Handles clipboard interaction across Wayland, X11, and in-memory mock."""

    def __init__(self):
        self._last_content = ""
        self._backend = "in_memory"

        if shutil.which("wl-paste") and shutil.which("wl-copy") and os.environ.get("WAYLAND_DISPLAY"):
            self._backend = "wayland"
        elif shutil.which("xclip"):
            self._backend = "x11_xclip"
        elif shutil.which("xsel"):
            self._backend = "x11_xsel"

        logger.info(f"Clipboard watcher initialized using backend: {self._backend}")

    def read_text(self) -> Optional[str]:
        try:
            if self._backend == "wayland":
                res = subprocess.run(["wl-paste", "--no-newline"], capture_output=True, text=True, timeout=1)
                if res.returncode == 0:
                    return res.stdout
            elif self._backend == "x11_xclip":
                res = subprocess.run(["xclip", "-selection", "clipboard", "-o"], capture_output=True, text=True, timeout=1)
                if res.returncode == 0:
                    return res.stdout
            elif self._backend == "x11_xsel":
                res = subprocess.run(["xsel", "--clipboard", "--output"], capture_output=True, text=True, timeout=1)
                if res.returncode == 0:
                    return res.stdout
            return self._last_content
        except Exception:
            return self._last_content

    def write_text(self, text: str) -> bool:
        self._last_content = text
        try:
            if self._backend == "wayland":
                p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE, text=True)
                p.communicate(input=text, timeout=1)
                return p.returncode == 0
            elif self._backend == "x11_xclip":
                p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE, text=True)
                p.communicate(input=text, timeout=1)
                return p.returncode == 0
            elif self._backend == "x11_xsel":
                p = subprocess.Popen(["xsel", "--clipboard", "--input"], stdin=subprocess.PIPE, text=True)
                p.communicate(input=text, timeout=1)
                return p.returncode == 0
            return True
        except Exception as e:
            logger.warning(f"Failed to write to system clipboard: {e}")
            return False


class DeviceAgent:
    """Linux Device Agent for World of IT."""

    ALLOWLISTED_ACTIONS = {"shutdown", "restart", "sleep", "health_check"}

    def __init__(self, config_file: str, dry_run: bool = True):
        self.config_file = Path(config_file).resolve()
        self.repo_root = self.config_file.parent
        self.dry_run = dry_run
        self.config: Dict[str, Any] = {}
        self.clipboard = LocalClipboard()
        self.last_received_event_id: Optional[str] = None
        self.last_synced_clipboard_text: Optional[str] = None
        self.manual_push_requested = False
        self.running = True
        self.websocket: Optional[websockets.WebSocketClientProtocol] = None
        self.processed_command_ids: set[str] = set()
        self.tray = LinuxTopBarTray(
            on_manual_push=self._request_manual_push,
            on_toggle_auto=self._toggle_auto_sync,
            on_open_app=self._launch_desktop_app,
        )

    def _request_manual_push(self):
        self.manual_push_requested = True

    def _toggle_auto_sync(self) -> bool:
        cur = bool(self.config.get("clipboard_sync_enabled", True))
        new_val = not cur
        self.config["clipboard_sync_enabled"] = new_val
        self.save_config()
        return new_val

    def _launch_desktop_app(self):
        bundle_bin = self.repo_root / "build/linux/x64/debug/bundle/world_of_iot"
        if bundle_bin.exists():
            subprocess.Popen([str(bundle_bin)], cwd=str(self.repo_root))

    def load_config(self) -> bool:
        if not self.config_file.exists():
            return False
        try:
            with open(self.config_file, "r", encoding="utf-8") as f:
                self.config = json.load(f)
            return bool(self.config.get("device_id"))
        except Exception as e:
            logger.error(f"Error loading configuration: {e}")
            return False

    def save_config(self):
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_file, "w", encoding="utf-8") as f:
            json.dump(self.config, f, indent=2)

    def execute_command_action(self, action: str) -> Dict[str, Any]:
        """Safely executes an allowlisted command action."""
        if action not in self.ALLOWLISTED_ACTIONS:
            return {"status": "failed", "summary": f"Action '{action}' not allowlisted"}

        if action == "health_check":
            load1, load5, load15 = os.getloadavg() if hasattr(os, "getloadavg") else (0, 0, 0)
            return {
                "status": "succeeded",
                "summary": f"Health OK: load={load1:.2f}, {load5:.2f}, {load15:.2f}; host={platform.node()}; dry_run={self.dry_run}",
            }

        if self.dry_run:
            logger.info(f"[DRY-RUN] Simulated execution of action: {action}")
            return {
                "status": "succeeded",
                "summary": f"[DRY-RUN] Simulated '{action}' succeeded safely without modifying OS state.",
            }

        try:
            if action == "shutdown":
                logger.warning("Initiating real system shutdown...")
                subprocess.run(["systemctl", "poweroff"], check=True)
                return {"status": "succeeded", "summary": "System shutdown initiated"}
            elif action == "restart":
                logger.warning("Initiating real system restart...")
                subprocess.run(["systemctl", "reboot"], check=True)
                return {"status": "succeeded", "summary": "System reboot initiated"}
            elif action == "sleep":
                logger.warning("Initiating real system suspend...")
                subprocess.run(["systemctl", "suspend"], check=True)
                return {"status": "succeeded", "summary": "System sleep initiated"}
        except Exception as e:
            logger.error(f"Failed to execute system action '{action}': {e}")
            return {"status": "failed", "summary": f"OS execution error: {str(e)}"}

        return {"status": "failed", "summary": "Unknown action"}

    async def refresh_firebase_token_if_needed(self):
        """Refreshes Firebase ID token using refresh_token if configured."""
        api_key = self.config.get("firebase_api_key")
        refresh_token = self.config.get("firebase_refresh_token")
        if not api_key or not refresh_token:
            return
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(
                    f"https://securetoken.googleapis.com/v1/token?key={api_key}",
                    data={"grant_type": "refresh_token", "refresh_token": refresh_token},
                )
                if resp.status_code == 200:
                    data = resp.json()
                    self.config["firebase_id_token"] = data["id_token"]
                    self.config["firebase_refresh_token"] = data.get("refresh_token", refresh_token)
                    self.save_config()
                    logger.info("Refreshed Firebase ID token successfully.")
        except Exception as e:
            logger.debug(f"Token refresh note: {e}")

    # ---------------- Firebase Realtime Database Mode ----------------

    async def run_firebase_mode(self):
        """Runs the agent using Firebase Realtime Database REST listeners."""
        rtdb_url = self.config.get(
            "firebase_rtdb_url",
            "https://world-of-iot-hub-default-rtdb.firebaseio.com",
        ).rstrip("/")
        user_id = self.config["user_id"]
        device_id = self.config["device_id"]
        display_name = self.config.get("display_name", f"Linux-{platform.node()}")

        self.tray.start_in_background()

        logger.info(f"Connecting to Firebase Realtime Database at {rtdb_url} for user {user_id} (device={device_id})...")

        initial_clip = self.clipboard.read_text()
        if initial_clip:
            self.last_synced_clipboard_text = initial_clip
            self.tray.update_state(latest_clip=initial_clip)

        # Ensure device registration exists in RTDB (retries automatically until Wi-Fi is online)
        while self.running:
            try:
                auth_token = self.config.get("firebase_id_token")
                params = {"auth": auth_token} if auth_token else {}
                url = f"{rtdb_url}/users/{user_id}/devices/{device_id}.json"
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get(url, params=params)
                    if resp.status_code == 401:
                        await self.refresh_firebase_token_if_needed()
                        auth_token = self.config.get("firebase_id_token")
                        params = {"auth": auth_token} if auth_token else {}
                        resp = await client.get(url, params=params)
                    now_ms = get_current_epoch_ms()
                    existing = resp.json() if resp.status_code == 200 and resp.json() else {}
                    if not isinstance(existing, dict) or not existing.get("displayName"):
                        await client.put(
                            url,
                            json={
                                "displayName": display_name,
                                "platform": "linux",
                                "agentVersion": "2.0.0",
                                "trusted": True,
                                "revoked": False,
                                "clipboardSyncEnabled": self.config.get("clipboard_sync_enabled", True),
                                "lastSeenAt": now_ms,
                                "createdAt": now_ms,
                            },
                            params=params,
                        )
                        logger.info(f"Registered Linux device '{display_name}' ({device_id}) in Firebase RTDB.")
                    self.tray.update_state(is_connected=True)
                    break
            except Exception as e:
                self.tray.update_state(is_connected=False)
                logger.warning(f"Waiting for Wi-Fi / Firebase connection ({e})...")
                await asyncio.sleep(3)

        # Persistent keep-alive HTTP pool so every outbound write reuses the warm TLS socket (~120ms vs ~1500ms)
        http_client = httpx.AsyncClient(
            limits=httpx.Limits(max_keepalive_connections=10, keepalive_expiry=120.0),
            timeout=8.0,
        )

        async def token_refresh_loop():
            while self.running:
                await asyncio.sleep(2400)
                await self.refresh_firebase_token_if_needed()

        async def heartbeat_and_presence_loop():
            while self.running:
                try:
                    auth_token = self.config.get("firebase_id_token")
                    url = f"{rtdb_url}/users/{user_id}/devices/{device_id}.json"
                    all_devs_url = f"{rtdb_url}/users/{user_id}/devices.json"
                    params = {"auth": auth_token} if auth_token else {}
                    now_ms = get_current_epoch_ms()
                    resp = await http_client.patch(
                        url,
                        json={
                            "displayName": self.config.get("display_name", display_name),
                            "platform": "linux",
                            "agentVersion": "2.1.0",
                            "lastSeenAt": now_ms,
                        },
                        params=params,
                    )
                    if resp.status_code == 401:
                        await self.refresh_firebase_token_if_needed()
                    elif resp.status_code == 200:
                        all_resp = await http_client.get(all_devs_url, params=params)
                        if all_resp.status_code == 200 and isinstance(all_resp.json(), dict):
                            all_devs = all_resp.json()
                            online = 0
                            for d_id, d_val in all_devs.items():
                                if isinstance(d_val, dict) and not d_val.get("revoked"):
                                    last_seen = d_val.get("lastSeenAt", 0)
                                    if isinstance(last_seen, (int, float)) and (now_ms - last_seen) < 45000:
                                        online += 1
                                if d_id == device_id and isinstance(d_val, dict):
                                    self.config["clipboard_sync_enabled"] = d_val.get("clipboardSyncEnabled", True)
                                    self.config["display_name"] = d_val.get("displayName", display_name)
                            self.tray.update_state(
                                is_connected=True,
                                online_count=max(1, online),
                                auto_sync=self.config.get("clipboard_sync_enabled", True),
                            )
                    else:
                        self.tray.update_state(is_connected=False)
                except Exception as e:
                    self.tray.update_state(is_connected=False)
                    logger.debug(f"Firebase heartbeat error: {e}")
                await asyncio.sleep(10)

        def _process_incoming_clip_payload(evt_data: dict):
            if not isinstance(evt_data, dict):
                return
            if not self.config.get("clipboard_sync_enabled", True):
                return
            src_dev = evt_data.get("sourceDeviceId", "")
            created_at = str(evt_data.get("createdAt", ""))
            text = evt_data.get("text", "")
            if not text or src_dev in (device_id, "linux-thinkpad-ui"):
                return
            if created_at and created_at == self.last_received_event_id:
                return
            self.last_received_event_id = created_at
            if text != self.last_synced_clipboard_text:
                self.last_synced_clipboard_text = text
                self.clipboard.write_text(text)
                friendly_src = "Samsung Phone" if "android" in src_dev else src_dev
                logger.info(f"[INSTANT-SSE] Synced incoming clipboard from {friendly_src}")
                notify_desktop_clipboard(friendly_src, text)
                self.tray.update_state(has_unread_clip=True, latest_clip=text)

        async def remote_clipboard_sse_loop():
            """Real-time Firebase Server-Sent Events (SSE) push listener (~100ms latency, zero polling)."""
            sse_timeout = httpx.Timeout(connect=10.0, read=75.0, write=10.0, pool=10.0)
            initial_snapshot_skipped = False
            while self.running:
                try:
                    auth_token = self.config.get("firebase_id_token")
                    params = {"auth": auth_token} if auth_token else {}
                    url = f"{rtdb_url}/users/{user_id}/clipboardEvents/latest.json"
                    async with httpx.AsyncClient(timeout=sse_timeout, follow_redirects=True) as sse_client:
                        async with sse_client.stream(
                            "GET",
                            url,
                            params=params,
                            headers={"Accept": "text/event-stream"},
                        ) as stream:
                            if stream.status_code == 401:
                                await self.refresh_firebase_token_if_needed()
                                await asyncio.sleep(1)
                                continue
                            event_type = ""
                            async for line in stream.aiter_lines():
                                if not self.running:
                                    break
                                if line.startswith("event:"):
                                    event_type = line[6:].strip()
                                elif line.startswith("data:"):
                                    raw_data = line[5:].strip()
                                    if event_type in ("put", "patch") and raw_data and raw_data != "null":
                                        payload = json.loads(raw_data)
                                        data_obj = payload.get("data") if isinstance(payload, dict) else None
                                        if not initial_snapshot_skipped:
                                            initial_snapshot_skipped = True
                                            if isinstance(data_obj, dict) and data_obj.get("createdAt"):
                                                self.last_received_event_id = str(data_obj["createdAt"])
                                        elif isinstance(data_obj, dict):
                                            _process_incoming_clip_payload(data_obj)
                                    elif event_type == "auth_revoked":
                                        await self.refresh_firebase_token_if_needed()
                                        break
                except Exception as e:
                    logger.debug(f"Clipboard SSE stream reconnecting: {e}")
                    await asyncio.sleep(1.0)

        async def local_clipboard_watch_loop():
            """Watches local Linux clipboard every 200ms and pushes instantly over warm keep-alive TLS."""
            while self.running:
                try:
                    local_text = self.clipboard.read_text()
                    should_push = (
                        local_text
                        and (
                            (self.config.get("clipboard_sync_enabled", True) and local_text != self.last_synced_clipboard_text)
                            or self.manual_push_requested
                        )
                    )
                    if should_push and local_text:
                        was_manual = self.manual_push_requested
                        self.manual_push_requested = False
                        self.last_synced_clipboard_text = local_text
                        now_ms = get_current_epoch_ms()
                        self.last_received_event_id = str(now_ms)
                        auth_token = self.config.get("firebase_id_token")
                        params = {"auth": auth_token} if auth_token else {}
                        resp = await http_client.put(
                            f"{rtdb_url}/users/{user_id}/clipboardEvents/latest.json",
                            json={
                                "sourceDeviceId": device_id,
                                "text": local_text,
                                "createdAt": now_ms,
                                "expiresAt": now_ms + 60000,
                            },
                            params=params,
                        )
                        if resp.status_code == 401:
                            await self.refresh_firebase_token_if_needed()
                        else:
                            logger.info("[INSTANT-PUSH] Published local clipboard update to Firebase RTDB.")
                            self.tray.update_state(latest_clip=local_text)
                            if was_manual:
                                notify_desktop_clipboard("Linux (Sent to Phone)", local_text)
                except Exception as e:
                    logger.debug(f"Local clipboard push error: {e}")
                await asyncio.sleep(0.2)

        async def remote_command_sse_loop():
            """Real-time SSE listener for allowlisted commands (~100ms execution start)."""
            sse_timeout = httpx.Timeout(connect=10.0, read=75.0, write=10.0, pool=10.0)
            while self.running:
                try:
                    auth_token = self.config.get("firebase_id_token")
                    params = {"auth": auth_token} if auth_token else {}
                    url = f"{rtdb_url}/users/{user_id}/commands.json"
                    async with httpx.AsyncClient(timeout=sse_timeout, follow_redirects=True) as sse_client:
                        async with sse_client.stream(
                            "GET",
                            url,
                            params=params,
                            headers={"Accept": "text/event-stream"},
                        ) as stream:
                            if stream.status_code == 401:
                                await self.refresh_firebase_token_if_needed()
                                await asyncio.sleep(1)
                                continue
                            event_type = ""
                            async for line in stream.aiter_lines():
                                if not self.running:
                                    break
                                if line.startswith("event:"):
                                    event_type = line[6:].strip()
                                elif line.startswith("data:") and event_type in ("put", "patch"):
                                    raw_data = line[5:].strip()
                                    if not raw_data or raw_data == "null":
                                        continue
                                    payload = json.loads(raw_data)
                                    if not isinstance(payload, dict):
                                        continue
                                    path = payload.get("path", "/")
                                    data_obj = payload.get("data")
                                    candidates = {}
                                    if path == "/" and isinstance(data_obj, dict):
                                        candidates = data_obj
                                    elif path.startswith("/") and isinstance(data_obj, dict):
                                        cmd_key = path.strip("/").split("/")[0]
                                        candidates = {cmd_key: data_obj}
                                    for cmd_id, cmd_data in candidates.items():
                                        if (
                                            isinstance(cmd_data, dict)
                                            and cmd_data.get("targetDeviceId") == device_id
                                            and cmd_data.get("status") == "pending"
                                            and cmd_id not in self.processed_command_ids
                                        ):
                                            self.processed_command_ids.add(cmd_id)
                                            await self.handle_firebase_command(
                                                http_client, rtdb_url, user_id, cmd_id, cmd_data, params
                                            )
                except Exception as e:
                    logger.debug(f"Command SSE stream reconnecting: {e}")
                    await asyncio.sleep(1.5)

        try:
            await asyncio.gather(
                token_refresh_loop(),
                heartbeat_and_presence_loop(),
                remote_command_sse_loop(),
                remote_clipboard_sse_loop(),
                local_clipboard_watch_loop(),
            )
        finally:
            await http_client.aclose()

    async def handle_firebase_command(self, client: httpx.AsyncClient, rtdb_url: str, user_id: str, cmd_id: str, cmd: dict, params: dict):
        action = cmd.get("action")
        logger.info(f"Firebase command received: {cmd_id} action='{action}'")

        cmd_url = f"{rtdb_url}/users/{user_id}/commands/{cmd_id}.json"
        await client.patch(cmd_url, json={"status": "accepted", "acceptedAt": get_current_epoch_ms()}, params=params)

        expires_at = cmd.get("expiresAt")
        if expires_at and isinstance(expires_at, (int, float)) and expires_at < get_current_epoch_ms():
            logger.warning(f"Command {cmd_id} has expired; reporting expired.")
            await client.patch(cmd_url, json={"status": "expired", "resultCode": "EXPIRED"}, params=params)
            return

        if action not in self.ALLOWLISTED_ACTIONS:
            logger.error(f"Action '{action}' is not allowlisted.")
            await client.patch(cmd_url, json={"status": "failed", "resultCode": "ACTION_NOT_PERMITTED"}, params=params)
            return

        outcome = self.execute_command_action(action)

        await client.patch(
            cmd_url,
            json={
                "status": outcome["status"],
                "finishedAt": get_current_epoch_ms(),
                "resultSummary": outcome["summary"],
            },
            params=params,
        )
        logger.info(f"Command {cmd_id} finished with status '{outcome['status']}'")

    # ---------------- WebSocket / REST Mode ----------------

    async def run_websocket_mode(self):
        """Runs the agent using outbound WebSocket connection."""
        server_url = self.config.get("server_url", "http://localhost:8000")
        device_id = self.config["device_id"]
        secret = self.config.get("device_secret", "")

        ws_proto = "wss://" if server_url.startswith("https://") else "ws://"
        host_port = server_url.split("://", 1)[-1].rstrip("/")
        ws_url = f"{ws_proto}{host_port}/ws/agent/{device_id}?secret={secret}"

        backoff = 1
        max_backoff = 30

        while self.running:
            try:
                logger.info(f"Connecting to WebSocket backend: {ws_proto}{host_port}/ws/agent/{device_id}...")
                async with websockets.connect(ws_url) as ws:
                    self.websocket = ws
                    backoff = 1
                    logger.info("Connected to backend via WebSocket!")

                    async def ws_heartbeat():
                        while self.running and self.websocket:
                            try:
                                await self.websocket.send(json.dumps({"type": "heartbeat", "timestamp": get_utc_now()}))
                            except Exception:
                                break
                            await asyncio.sleep(15)

                    hb_task = asyncio.create_task(ws_heartbeat())

                    async for message in ws:
                        await self.handle_ws_message(message)

                    hb_task.cancel()

            except Exception as e:
                self.websocket = None
                logger.warning(f"WebSocket disconnected ({e}). Reconnecting in {backoff}s...")
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, max_backoff)

    async def handle_ws_message(self, raw_message: str):
        try:
            msg = json.loads(raw_message)
        except Exception:
            return

        msg_type = msg.get("type")
        if msg_type == "command_dispatch":
            cmd = msg.get("command", {})
            cmd_id = cmd.get("id")
            action = cmd.get("action")

            if self.websocket:
                await self.websocket.send(json.dumps({"type": "command_ack", "command_id": cmd_id}))

            outcome = self.execute_command_action(action)
            if self.websocket:
                await self.websocket.send(json.dumps({
                    "type": "command_result",
                    "command_id": cmd_id,
                    "status": outcome["status"],
                    "result_summary": outcome["summary"],
                }))

    async def run(self):
        if self.config.get("backend_type") == "websocket" or self.config.get("server_url", "").startswith("ws"):
            await self.run_websocket_mode()
        else:
            await self.run_firebase_mode()


def main():
    parser = argparse.ArgumentParser(description="World of IT Linux Desktop Agent")
    parser.add_argument("--config", default="device_config.json", help="Path to config file")
    parser.add_argument(
        "--firebase-url",
        default="https://world-of-iot-hub-default-rtdb.firebaseio.com",
        help="Firebase Realtime Database URL",
    )
    parser.add_argument("--user-id", help="Firebase user UID")
    parser.add_argument("--device-id", help="Registered device ID")
    parser.add_argument("--auth-token", help="Firebase ID token for authenticated RTDB access")
    parser.add_argument("--refresh-token", help="Firebase refresh token")
    parser.add_argument("--api-key", help="Firebase Web API key")
    parser.add_argument("--name", help="Display name for this device")
    parser.add_argument("--real", action="store_true", help="Execute real system shutdown/reboot (default: dry-run safe)")
    args = parser.parse_args()

    # Ensure single running instance so duplicate tray icons or agents never spawn
    lock_file = open("/tmp/world_of_iot_agent.lock", "w")
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        logger.info("Another instance of world_of_it_agent is already running; exiting.")
        sys.exit(0)

    agent = DeviceAgent(config_file=args.config, dry_run=not args.real)

    loaded = agent.load_config()
    if args.user_id and args.device_id:
        agent.config = {
            "backend_type": "firebase",
            "firebase_rtdb_url": args.firebase_url,
            "user_id": args.user_id,
            "device_id": args.device_id,
            "display_name": args.name or f"Linux-{platform.node()}",
            "clipboard_sync_enabled": True,
            "firebase_id_token": args.auth_token or agent.config.get("firebase_id_token"),
            "firebase_refresh_token": args.refresh_token or agent.config.get("firebase_refresh_token"),
            "firebase_api_key": args.api_key or agent.config.get("firebase_api_key"),
        }
        agent.save_config()
    elif not loaded:
        print("\n[!] No device configuration found.")
        print(f"Usage: python3 {sys.argv[0]} --user-id <UID> --device-id <DEVICE_ID> [--firebase-url <URL>]\n")
        sys.exit(1)

    try:
        asyncio.run(agent.run())
    except KeyboardInterrupt:
        logger.info("Agent stopped by user.")


if __name__ == "__main__":
    main()
