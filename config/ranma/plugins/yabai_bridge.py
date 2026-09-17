#!/usr/bin/env python3

"""Multi-monitor event bridge between yabai and ranma.

Tracks per-display space state via `yabai -m query` and updates ranma
workspace indicators via `ranma set` commands.

yabai has no event stream, so the bridge registers `yabai -m signal`
handlers that touch a stamp file; the main loop watches that file's
mtime and re-queries whenever it changes (plus a periodic safety
refresh in case a signal is missed).

Each space is rendered as a Box containing layered Rows:
  - bg:  pill background (visible when the space is visible)
  - c:   centered label (the yabai space index)
  - ul:  underline/dot indicator (bottom-aligned)

Runs as a long-lived background process, started from the init script.
"""

import atexit
import json
import os
import signal
import subprocess
import sys
import time

MAX_DISPLAYS = 3
MAX_SPACES = 10
INTERNAL_DISPLAY_ID = "1"

POLL_INTERVAL = 0.1
REFRESH_INTERVAL = 5.0

STAMP_PATH = os.path.expanduser("~/.cache/ranma/yabai_bridge.stamp")
SIGNAL_LABEL_PREFIX = "ranma_ws_"

# yabai events that can change what the workspace indicator shows
SIGNAL_EVENTS = [
    "display_added",
    "display_removed",
    "display_moved",
    "display_changed",
    "space_created",
    "space_destroyed",
    "space_changed",
    "window_created",
    "window_destroyed",
    "window_moved",
    "window_minimized",
    "window_deminimized",
    "window_focused",
    "application_launched",
    "application_terminated",
]

# SF Symbol per yabai space layout
MODE_ICONS = {
    "bsp": "rectangle.split.3x1",
    "stack": "rectangle.stack",
    "float": "macwindow",
}

_BASE = {
    "box_w": "22", "box_h": "18",
    "font_size": "10",
    "corner_radius": "8",
    "padding_h": "4", "padding_v": "2",
    "gap": "2",
    "pill_radius": "5",
    "ul_bar_w": "8", "ul_bar_h": "2",
    "dot_w": "3", "dot_h": "3",
    "margin_h": "12",
    "show_mode": True,
    "mode_h": "14", "mode_pad_h": "4", "mode_icon_size": "8",
    "sep_font_size": "11",
}

SIZES = {
    "default": {**_BASE},
    "compact": {**_BASE, "padding_h": "2", "gap": "1", "margin_h": "4", "show_mode": False},
}


def parse_hex(color):
    """Parse #RRGGBB or #RRGGBBAA to (r, g, b) tuple (0-255)."""
    c = color.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16))


def hex_rgb(r, g, b):
    """Format (r, g, b) as #RRGGBB."""
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}"


def hex_rgba(r, g, b, a):
    """Format (r, g, b, a) as #RRGGBBAA. a is 0-255."""
    return f"#{int(r):02x}{int(g):02x}{int(b):02x}{int(a):02x}"


def lerp(a, b, t):
    """Linear interpolation."""
    return a + (b - a) * t


def build_palette(accent_hex):
    """Derive full color palette from accent color.

    Blends accent hue into greys so the palette feels cohesive.
    accent="#ffffff" → pure greys, accent="#fac800" → warm greys, etc.
    """
    ar, ag, ab = parse_hex(accent_hex)

    # Normalize accent to unit brightness for tinting
    max_c = max(ar, ag, ab, 1)
    tr, tg, tb = ar / max_c, ag / max_c, ab / max_c

    def tinted_grey(brightness, tint_strength=0.15):
        """Mix a grey value with the accent tint."""
        r = lerp(brightness, brightness * tr, tint_strength)
        g = lerp(brightness, brightness * tg, tint_strength)
        b = lerp(brightness, brightness * tb, tint_strength)
        return (r, g, b)

    occ_r, occ_g, occ_b = tinted_grey(180)
    vac_r, vac_g, vac_b = tinted_grey(100)
    dot_r, dot_g, dot_b = tinted_grey(180)

    return {
        # Focused display
        "label_active": "#ffffff",
        "label_occupied": hex_rgb(occ_r, occ_g, occ_b),
        "label_vacant": hex_rgb(vac_r, vac_g, vac_b),
        "bg_active_pill": "#ffffff18",
        "dot_color": hex_rgba(dot_r, dot_g, dot_b, 128),
        # Unfocused display (half alpha)
        "label_active_unfocused": "#ffffff80",
        "label_occupied_unfocused": hex_rgba(occ_r, occ_g, occ_b, 128),
        "label_vacant_unfocused": hex_rgba(vac_r, vac_g, vac_b, 128),
        "bg_active_pill_unfocused": "#ffffff10",
        "dot_color_unfocused": hex_rgba(dot_r, dot_g, dot_b, 64),
    }


def load_config():
    """Load config from config.json next to the init script."""
    config_path = os.path.join(os.path.dirname(__file__), "..", "config.json")
    defaults = {"accent_color": "#ffffffcc", "font_family": "Hack Nerd Font"}
    try:
        with open(config_path) as f:
            user = json.load(f)
            defaults.update(user)
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    return defaults


def kill_old_instances():
    """Kill any existing yabai_bridge.py processes (except ourselves)."""
    my_pid = os.getpid()
    try:
        result = subprocess.run(
            ["pgrep", "-f", "yabai_bridge.py"],
            capture_output=True,
            text=True,
        )
        for line in result.stdout.strip().split("\n"):
            if not line:
                continue
            pid = int(line)
            if pid != my_pid:
                try:
                    os.kill(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
    except Exception:
        pass


# ---------------------------------------------------------------------------
# yabai
# ---------------------------------------------------------------------------


def yabai_query(domain):
    """Run `yabai -m query --<domain>`. Returns parsed JSON or None."""
    try:
        result = subprocess.run(
            ["yabai", "-m", "query", f"--{domain}"],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return None


def yabai_signals(stamp_path):
    """Register yabai signals that touch the stamp file on every change."""
    remove_yabai_signals()
    action = f"/usr/bin/touch {stamp_path}"
    for event in SIGNAL_EVENTS:
        subprocess.run(
            [
                "yabai", "-m", "signal", "--add",
                f"event={event}",
                f"action={action}",
                f"label={SIGNAL_LABEL_PREFIX}{event}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def remove_yabai_signals():
    """Remove any signals previously registered by this bridge."""
    for event in SIGNAL_EVENTS:
        subprocess.run(
            ["yabai", "-m", "signal", "--remove", f"{SIGNAL_LABEL_PREFIX}{event}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def touch_stamp(path):
    """Create the stamp file (and its directory) if missing."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a"):
        pass


def stamp_mtime(path):
    """Return the stamp file mtime in ns, or 0 if unreadable."""
    try:
        return os.stat(path).st_mtime_ns
    except OSError:
        return 0


# ---------------------------------------------------------------------------
# ranma
# ---------------------------------------------------------------------------


def ranma_set(name, **kwargs):
    """Run `ranma set <name> --key value ...`."""
    args = ["ranma", "set", name]
    for key, value in kwargs.items():
        flag = "--" + key.replace("_", "-")
        args.extend([flag, str(value)])
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def ranma_add(name, **kwargs):
    """Run `ranma add <name> --key value ...`."""
    args = ["ranma", "add", name]
    for key, value in kwargs.items():
        flag = "--" + key.replace("_", "-")
        args.extend([flag, str(value)])
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def ranma_remove(name):
    """Run `ranma remove <name>`."""
    subprocess.run(
        ["ranma", "remove", name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def sizes_for_display(did):
    """Return size parameters based on display ID."""
    return SIZES["compact"] if did == INTERNAL_DISPLAY_ID else SIZES["default"]


def build_slot_items(slot, did, spaces, state):
    """Create the ranma container and items for one display slot."""
    config = state["config"]
    sz = sizes_for_display(did)
    state["slot_sizes"][slot] = sz

    ranma_add(
        f"ws.d{slot}",
        type="row",
        align_items="center",
        background_color="#0a0a0f",
        corner_radius=sz["corner_radius"],
        shadow_color="#00000080",
        shadow_radius="8",
        margin_horizontal=sz["margin_h"],
        margin_vertical="4",
        padding_horizontal=sz["padding_h"],
        padding_vertical=sz["padding_v"],
        gap=sz["gap"],
        notch_align="right",
        display=did,
    )
    for position, index in enumerate(spaces, start=1):
        base = f"ws.d{slot}.{index}"
        ranma_add(
            base,
            type="box",
            parent=f"ws.d{slot}",
            width=sz["box_w"],
            height=sz["box_h"],
            position=str(position),
            on_click=f"yabai -m space --focus {index}",
        )
        ranma_add(
            f"{base}.bg",
            type="row",
            parent=base,
            corner_radius=sz["pill_radius"],
            width=sz["box_w"],
            height=sz["box_h"],
        )
        ranma_add(
            f"{base}.c",
            type="row",
            parent=base,
            justify_content="center",
            align_items="center",
            width=sz["box_w"],
            height=sz["box_h"],
            position="2",
        )
        ranma_add(
            f"{base}.c.label",
            parent=f"{base}.c",
            label=str(index),
            label_color=state["palette"]["label_vacant"],
            font_family=config["font_family"],
            font_size=sz["font_size"],
        )
        ranma_add(
            f"{base}.ul",
            type="row",
            parent=base,
            justify_content="center",
            align_items="end",
            width=sz["box_w"],
            height=sz["box_h"],
            position="3",
        )
        ranma_add(
            f"{base}.ul.ind",
            type="row",
            parent=f"{base}.ul",
            corner_radius="1",
        )
    if sz["show_mode"]:
        ranma_add(
            f"ws.d{slot}.sep",
            parent=f"ws.d{slot}",
            label="|",
            label_color="#565f8930",
            font_size=sz["sep_font_size"],
            position=str(len(spaces) + 1),
        )
        ranma_add(
            f"ws.d{slot}.mode",
            type="row",
            parent=f"ws.d{slot}",
            background_color="#ffffff18",
            corner_radius="4",
            padding_horizontal=sz["mode_pad_h"],
            align_items="center",
            height=sz["mode_h"],
            position=str(len(spaces) + 2),
        )
        ranma_add(
            f"ws.d{slot}.mode.icon",
            parent=f"ws.d{slot}.mode",
            icon=MODE_ICONS["bsp"],
            icon_color="#ffffff",
            font_size=sz["mode_icon_size"],
        )


def ensure_display_items(state):
    """(Re)build ranma items whenever the display/space layout changes."""
    wanted = {
        slot: tuple(info["spaces"])
        for slot, info in state["slots"].items()
    }
    built = state["built_slots"]

    for slot in sorted(set(built) - set(wanted)):
        ranma_remove(f"ws.d{slot}")
        state["slot_sizes"].pop(slot, None)
        del built[slot]

    for slot in sorted(wanted):
        if built.get(slot) == wanted[slot]:
            continue
        if slot in built:
            ranma_remove(f"ws.d{slot}")
        build_slot_items(slot, state["slots"][slot]["display_id"], wanted[slot], state)
        built[slot] = wanted[slot]


def update_all(state):
    """Re-render all items based on current state."""
    accent = state["config"]["accent_color"]
    p = state["palette"]

    for slot, info in state["slots"].items():
        sz = state["slot_sizes"].get(slot, SIZES["default"])
        focused = info["focused"]

        for index in info["spaces"]:
            space = state["spaces"].get(index, {})
            base = f"ws.d{slot}.{index}"
            is_active = space.get("visible", False)
            is_occupied = space.get("occupied", False)

            if is_active:
                ranma_set(
                    f"{base}.c.label",
                    label_color=p["label_active"] if focused else p["label_active_unfocused"],
                )
                ranma_set(
                    f"{base}.bg",
                    background_color=p["bg_active_pill"] if focused else p["bg_active_pill_unfocused"],
                )
                ranma_set(
                    f"{base}.ul.ind",
                    background_color=accent,
                    width=sz["ul_bar_w"],
                    height=sz["ul_bar_h"],
                    corner_radius="1",
                )
            elif is_occupied:
                ranma_set(
                    f"{base}.c.label",
                    label_color=p["label_occupied"] if focused else p["label_occupied_unfocused"],
                )
                ranma_set(f"{base}.bg", background_color="")
                ranma_set(
                    f"{base}.ul.ind",
                    background_color=p["dot_color"] if focused else p["dot_color_unfocused"],
                    width=sz["dot_w"],
                    height=sz["dot_h"],
                    corner_radius="2",
                )
            else:
                ranma_set(
                    f"{base}.c.label",
                    label_color=p["label_vacant"] if focused else p["label_vacant_unfocused"],
                )
                ranma_set(f"{base}.bg", background_color="")
                ranma_set(f"{base}.ul.ind", background_color="")

        if sz["show_mode"]:
            layout = state["spaces"].get(info["visible_space"], {}).get("layout", "bsp")
            ranma_set(
                f"ws.d{slot}.mode.icon",
                icon=MODE_ICONS.get(layout, MODE_ICONS["bsp"]),
                icon_color="#ffffff" if focused else "#ffffff80",
            )


def read_state(state):
    """Refresh state from yabai. Returns False if yabai is unreachable."""
    displays = yabai_query("displays")
    spaces = yabai_query("spaces")
    if displays is None or spaces is None:
        return False

    state["spaces"] = {
        s["index"]: {
            # `display` is the display *arrangement index*, not its id
            "display": s["display"],
            "visible": bool(s.get("is-visible")),
            "occupied": bool(s.get("windows")),
            "layout": s.get("type", "bsp"),
        }
        for s in spaces
    }

    spaces_by_display = {}
    for index in sorted(state["spaces"]):
        display = state["spaces"][index]["display"]
        spaces_by_display.setdefault(display, []).append(index)

    # Slot = yabai display arrangement index, so items stay put across replugs
    state["slots"] = {}
    for d in sorted(displays, key=lambda d: d["index"])[:MAX_DISPLAYS]:
        did = str(d["id"])
        owned = spaces_by_display.get(d["index"], [])[:MAX_SPACES]
        visible = next((i for i in owned if state["spaces"][i]["visible"]), None)
        state["slots"][d["index"]] = {
            "display_id": did,
            "spaces": owned,
            "focused": bool(d.get("has-focus")),
            "visible_space": visible,
        }
    return True


def refresh(state):
    """Query yabai and push the resulting state to ranma."""
    if not read_state(state):
        return
    ensure_display_items(state)
    update_all(state)


def run():
    kill_old_instances()
    config = load_config()

    state = {
        "spaces": {},
        "slots": {},
        "built_slots": {},
        "slot_sizes": {},
        "config": config,
        "palette": build_palette(config["accent_color"]),
    }

    touch_stamp(STAMP_PATH)
    yabai_signals(STAMP_PATH)
    atexit.register(remove_yabai_signals)
    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(sig, lambda *_: sys.exit(0))

    last_mtime = 0
    last_refresh = 0.0

    while True:
        try:
            mtime = stamp_mtime(STAMP_PATH)
            now = time.monotonic()
            if mtime != last_mtime or now - last_refresh >= REFRESH_INTERVAL:
                last_mtime = mtime
                last_refresh = now
                refresh(state)
        except Exception as e:
            print(f"yabai_bridge: {e}", file=sys.stderr)
            time.sleep(2)

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
