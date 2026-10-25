#!/usr/bin/env python3
"""
Native GNOME / Freedesktop StatusNotifierItem + DBusMenu Top-Bar Indicator.

Runs under system `/usr/bin/python3` (providing `dbus` and `gi.repository.GLib`)
so GNOME Shell / Zorin OS AppIndicator (`org.kde.StatusNotifierWatcher`) renders crisp
16x16 vector `.svg` icons with 100% true panel transparency and zero X11 artifacts.

Communicates with `agent/agent.py` via JSON lines over stdin / stdout.
"""

import json
import os
import sys
import threading
from pathlib import Path

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib


SNI_INTERFACE = "org.kde.StatusNotifierItem"
SNI_PATH = "/org/ayatana/NotificationItem/world_of_iot"
MENU_INTERFACE = "com.canonical.dbusmenu"
MENU_PATH = "/org/ayatana/NotificationItem/world_of_iot/Menu"
WATCHER_BUS = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"


def _build_svg(dot_hex: str, clip_stroke: str = "#534E18", has_unread: bool = False) -> str:
    """
    Builds a crisp Adwaita/SF-Symbols style 16x16 minimal hollow clipboard SVG
    with clean stroke cutouts around the top clip and bottom-right pastel status dot.
    """
    inner = (
        f'<circle cx="7.8" cy="8.8" r="1.25" fill="{dot_hex}"/>'
        if has_unread
        else ""
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none">
  <path d="M5.6 3.0H4.5C3.67 3.0 3.0 3.67 3.0 4.5V12.8C3.0 13.63 3.67 14.3 4.5 14.3H9.2"
        stroke="{clip_stroke}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10.0 3.0H11.1C11.93 3.0 12.6 3.67 12.6 4.5V8.9"
        stroke="{clip_stroke}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="5.6" y="1.6" width="4.4" height="2.5" rx="1.0"
        stroke="{clip_stroke}" stroke-width="1.4" fill="none"/>
  {inner}
  <circle cx="12.5" cy="12.5" r="2.4" fill="{dot_hex}"/>
</svg>
"""


def write_svg_icons(icon_dir: Path) -> None:
    """Writes crisp vector SVG icons into an icon theme directory structure."""
    scalable_apps = icon_dir / "hicolor" / "scalable" / "apps"
    scalable_status = icon_dir / "hicolor" / "scalable" / "status"
    scalable_apps.mkdir(parents=True, exist_ok=True)
    scalable_status.mkdir(parents=True, exist_ok=True)

    index_theme = """[Icon Theme]
Name=WorldOfIoTTray
Directories=hicolor/scalable/apps,hicolor/scalable/status

[hicolor/scalable/apps]
Size=16
Type=Scalable
MinSize=8
MaxSize=256

[hicolor/scalable/status]
Size=16
Type=Scalable
MinSize=8
MaxSize=256
"""
    (icon_dir / "index.theme").write_text(index_theme, encoding="utf-8")
    (icon_dir / "hicolor" / "index.theme").write_text(index_theme, encoding="utf-8")

    variants = {
        # Soft Pastel Mint-Green (Synced: 2+ devices online)
        "woi-clip-green": _build_svg("#34C77B", has_unread=False),
        # Soft Pastel Amber (Waiting for second device)
        "woi-clip-yellow": _build_svg("#E5A922", has_unread=False),
        # Soft Pastel Amber + inner dot (New unread clipboard item)
        "woi-clip-unread": _build_svg("#E5A922", has_unread=True),
        # Soft Pastel Rose-Coral (Offline or Auto-Sync paused)
        "woi-clip-red": _build_svg("#E56B6F", has_unread=False),
    }

    for name, svg in variants.items():
        (icon_dir / f"{name}.svg").write_text(svg, encoding="utf-8")
        (scalable_apps / f"{name}.svg").write_text(svg, encoding="utf-8")
        (scalable_status / f"{name}.svg").write_text(svg, encoding="utf-8")


class DBusMenuService(dbus.service.Object):
    """Minimal com.canonical.dbusmenu implementation for native GNOME Shell popup menus."""

    def __init__(self, bus: dbus.Bus, state_ref: dict, emit_action):
        super().__init__(bus, MENU_PATH)
        self.state = state_ref
        self.emit_action = emit_action
        self.revision = dbus.UInt32(1)

    def _menu_items(self):
        is_connected = self.state.get("is_connected", True)
        both_synced = self.state.get("both_synced", False)
        online_count = self.state.get("online_count", 1)
        has_unread = self.state.get("has_unread_clip", False)
        latest = self.state.get("latest_clip_preview", "None yet")
        auto_sync = self.state.get("auto_sync", True)

        if not is_connected:
            status_txt = "Offline · Waiting for Wi-Fi"
        elif both_synced:
            status_txt = f"Synced · {online_count} Devices Online"
        else:
            status_txt = f"Ready · {online_count} Device Online"

        latest_txt = f"{'● New: ' if has_unread else 'Latest: '}{latest}"
        auto_txt = f"Auto-Sync Clipboard: {'On' if auto_sync else 'Off'}"

        def item(item_id: int, label: str = "", enabled: bool = True, sep: bool = False):
            if sep:
                props = dbus.Dictionary(
                    {
                        "type": dbus.String("separator"),
                        "visible": dbus.Boolean(True),
                    },
                    signature="sv",
                )
            else:
                props = dbus.Dictionary(
                    {
                        "label": dbus.String(label),
                        "enabled": dbus.Boolean(enabled),
                        "visible": dbus.Boolean(True),
                    },
                    signature="sv",
                )
            return dbus.Struct(
                (
                    dbus.Int32(item_id),
                    props,
                    dbus.Array([], signature="v"),
                ),
                signature=None,
            )

        children = dbus.Array(
            [
                item(1, status_txt, enabled=False),
                item(2, latest_txt, enabled=True),
                item(3, sep=True),
                item(4, "Send Clipboard Now", enabled=True),
                item(5, auto_txt, enabled=True),
                item(6, sep=True),
                item(7, "Open World of IT", enabled=True),
            ],
            signature="v",
        )
        root_props = dbus.Dictionary(
            {"children-display": dbus.String("submenu")}, signature="sv"
        )
        return (self.revision, (dbus.Int32(0), root_props, children))

    def notify_updated(self):
        self.revision = dbus.UInt32(int(self.revision) + 1)
        self.LayoutUpdated(self.revision, dbus.Int32(0))

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface_name, property_name):
        return self.GetAll(interface_name).get(property_name, dbus.String(""))

    @dbus.service.method(
        dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface_name):
        if interface_name == MENU_INTERFACE:
            return dbus.Dictionary(
                {
                    "Version": dbus.UInt32(3),
                    "TextDirection": dbus.String("ltr"),
                    "Status": dbus.String("normal"),
                    "IconThemePath": dbus.Array([], signature="s"),
                },
                signature="sv",
            )
        return dbus.Dictionary({}, signature="sv")

    @dbus.service.method(
        MENU_INTERFACE, in_signature="iias", out_signature="u(ia{sv}av)"
    )
    def GetLayout(self, parent_id, recursion_depth, property_names):
        return self._menu_items()

    @dbus.service.method(
        MENU_INTERFACE, in_signature="aias", out_signature="a(ia{sv})"
    )
    def GetGroupProperties(self, ids, property_names):
        _, (_, _, children) = self._menu_items()
        result = dbus.Array([], signature="(ia{sv})")
        id_set = set(int(x) for x in ids)
        for child in children:
            cid = int(child[0])
            if not id_set or cid in id_set:
                result.append((dbus.Int32(cid), child[1]))
        return result

    @dbus.service.method(MENU_INTERFACE, in_signature="is", out_signature="v")
    def GetProperty(self, item_id, name):
        _, (_, _, children) = self._menu_items()
        for child in children:
            if int(child[0]) == int(item_id):
                return child[1].get(name, dbus.String(""))
        return dbus.String("")

    @dbus.service.method(MENU_INTERFACE, in_signature="isvu", out_signature="")
    def Event(self, item_id, event_id, data, timestamp):
        if str(event_id) != "clicked":
            return
        iid = int(item_id)
        if iid == 2:
            self.emit_action("mark_read")
        elif iid == 4:
            self.emit_action("manual_push")
        elif iid == 5:
            self.emit_action("toggle_auto")
        elif iid == 7:
            self.emit_action("open_app")

    @dbus.service.method(
        MENU_INTERFACE, in_signature="a(isvu)", out_signature="ai"
    )
    def EventGroup(self, events):
        for ev in events:
            self.Event(ev[0], ev[1], ev[2], ev[3])
        return dbus.Array([], signature="i")

    @dbus.service.method(MENU_INTERFACE, in_signature="i", out_signature="b")
    def AboutToShow(self, item_id):
        return dbus.Boolean(False)

    @dbus.service.method(MENU_INTERFACE, in_signature="ai", out_signature="aiai")
    def AboutToShowGroup(self, ids):
        return (dbus.Array([], signature="i"), dbus.Array([], signature="i"))

    @dbus.service.signal(MENU_INTERFACE, signature="ui")
    def LayoutUpdated(self, revision, parent):
        pass


class StatusNotifierItemService(dbus.service.Object):
    """Freedesktop / KDE / Ayatana StatusNotifierItem service for GNOME Shell."""

    def __init__(self, bus: dbus.Bus, icon_dir: Path, state_ref: dict, emit_action):
        super().__init__(bus, SNI_PATH)
        self.bus = bus
        self.icon_dir = str(icon_dir)
        self.state = state_ref
        self.emit_action = emit_action

    def _icon_name(self) -> str:
        if not self.state.get("is_connected", True) or not self.state.get(
            "auto_sync", True
        ):
            return "woi-clip-red"
        if self.state.get("has_unread_clip", False):
            return "woi-clip-unread"
        if not self.state.get("both_synced", False):
            return "woi-clip-yellow"
        return "woi-clip-green"

    def _title(self) -> str:
        if not self.state.get("is_connected", True):
            return "World of IT · Offline"
        if not self.state.get("auto_sync", True):
            return "World of IT · Auto-Sync Off"
        if self.state.get("both_synced", False):
            return f"World of IT · Synced ({self.state.get('online_count', 2)} Online)"
        return "World of IT · Ready"

    def refresh(self):
        self.NewIcon()
        self.NewTitle()

    @dbus.service.method(dbus.PROPERTIES_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface_name, property_name):
        props = self.GetAll(interface_name)
        if property_name in props:
            return props[property_name]
        return dbus.String("")

    @dbus.service.method(
        dbus.PROPERTIES_IFACE, in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface_name):
        if interface_name == SNI_INTERFACE:
            return dbus.Dictionary(
                {
                    "Category": dbus.String("ApplicationStatus"),
                    "Id": dbus.String("world-of-iot-sync"),
                    "Title": dbus.String(self._title()),
                    "Status": dbus.String("Active"),
                    "IconName": dbus.String(self._icon_name()),
                    "IconThemePath": dbus.String(self.icon_dir),
                    "IconAccessibleDesc": dbus.String("World of IT Clipboard Sync"),
                    "AttentionIconName": dbus.String("woi-clip-unread"),
                    "AttentionAccessibleDesc": dbus.String("New synced clipboard"),
                    "ItemIsMenu": dbus.Boolean(True),
                    "Menu": dbus.ObjectPath(MENU_PATH),
                },
                signature="sv",
            )
        return dbus.Dictionary({}, signature="sv")

    @dbus.service.method(SNI_INTERFACE, in_signature="ii", out_signature="")
    def Activate(self, x, y):
        self.emit_action("open_app")

    @dbus.service.method(SNI_INTERFACE, in_signature="ii", out_signature="")
    def ContextMenu(self, x, y):
        pass

    @dbus.service.method(SNI_INTERFACE, in_signature="ii", out_signature="")
    def SecondaryActivate(self, x, y):
        self.emit_action("manual_push")

    @dbus.service.method(SNI_INTERFACE, in_signature="is", out_signature="")
    def Scroll(self, delta, orientation):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewIcon(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="")
    def NewTitle(self):
        pass

    @dbus.service.signal(SNI_INTERFACE, signature="s")
    def NewStatus(self, status):
        pass


def main() -> int:
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    icon_dir = Path(f"/tmp/world_of_iot_sni_{os.getuid()}")
    write_svg_icons(icon_dir)

    bus_name_str = f"org.kde.StatusNotifierItem-{os.getpid()}-1"
    bus_name = dbus.service.BusName(bus_name_str, bus)  # noqa: F841

    state = {
        "is_connected": True,
        "online_count": 1,
        "both_synced": False,
        "has_unread_clip": False,
        "latest_clip_preview": "None yet",
        "auto_sync": True,
    }

    def emit_action(action: str):
        sys.stdout.write(json.dumps({"action": action}) + "\n")
        sys.stdout.flush()

    menu_service = DBusMenuService(bus, state, emit_action)
    sni_service = StatusNotifierItemService(bus, icon_dir, state, emit_action)

    def register_with_watcher():
        try:
            watcher = bus.get_object(WATCHER_BUS, WATCHER_PATH)
            iface = dbus.Interface(watcher, WATCHER_BUS)
            iface.RegisterStatusNotifierItem(SNI_PATH)
            sys.stdout.write(json.dumps({"status": "registered"}) + "\n")
            sys.stdout.flush()
        except Exception as exc:
            sys.stderr.write(f"SNI registration failed: {exc}\n")
            sys.stderr.flush()

    register_with_watcher()

    def on_name_owner_changed(name, old_owner, new_owner):
        if name == WATCHER_BUS and new_owner:
            register_with_watcher()

    bus.add_signal_receiver(
        on_name_owner_changed,
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus",
    )

    loop = GLib.MainLoop()

    def stdin_reader():
        for raw in sys.stdin:
            raw = raw.strip()
            if not raw:
                continue
            try:
                msg = json.loads(raw)
                if msg.get("cmd") == "quit":
                    GLib.idle_add(loop.quit)
                    return
                state.update(msg)
                GLib.idle_add(sni_service.refresh)
                GLib.idle_add(menu_service.notify_updated)
            except Exception:
                pass
        GLib.idle_add(loop.quit)

    t = threading.Thread(target=stdin_reader, daemon=True)
    t.start()

    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
