---
title: The space strip in the menu bar, drawn by SwiftBar
status: proposal
date: 2026-11-07
---

# The space strip in the menu bar, drawn by SwiftBar

Follows [the tiling design](2026-11-07-yabai-omarchy-design.md); replaces its "Menu bar strip (kb-raycast)" part.

## Intent

See every space at a glance, which ones the screens show, and where the keyboard is, without spending much
of the menu bar. Validated with a throwaway trial on 2026-11-07 (the owner: "way better than Spaceman").

## What it shows

One menu bar item: a numbered square per **existing** space, built-in screen first, a dot, then the
external screen. Numbers are the yabai labels (`s1`…`s10`), so they match fn + 1…0.

| Square | Meaning |
| --- | --- |
| Filled white | On screen and focused (where the keyboard is) |
| Outline | On screen, not focused (what the other screen shows) |
| Filled dimmed | Not on any screen |

Clicking it lists the spaces by number with their apps; choosing one runs `yb space <n>`.

## Approaches considered

1. **SwiftBar plugin (chosen).** SwiftBar shows a script's output as one menu bar item; SF Symbols numbered
   squares (`n.square`, `n.square.fill`) take one colour each. Native, crisp, scriptable from this repo.
2. **kb Raycast menu bar command (dropped).** Raycast fits the menu bar icon into a square and draws SVG
   icons as a one-colour template; the text title cannot style one character. The trial showed a strip
   shrunk to dots and a blank square.
3. **Spaceman (dropped).** Draws numbered boxes, but cannot tell the focused screen from the other one,
   and numbers spaces in Mission Control order.

## Design

- **`yb bar`** (config/bin/yb) prints the SwiftBar output from `yabai -m query --spaces/--windows/--displays`:
  - title: one `:<n>.square.fill:` or `:<n>.square:` per space, `·` between screens;
    `symbolize=true sfsize=17`, `sfconfig` = Palette rendering, large scale, bold weight;
    `sfcolor<i>` per symbol: `#000000,#FFFFFF` for on-screen squares, `#8A8A8E,#A9B0C2` for dimmed ones
    (SwiftBar reads `light,dark`; it does not accept alpha in hex);
  - dropdown: `Space <n> — <apps>` per space, `bash=$HOME/.local/bin/yb param1=space param2=<n>`.
  - yabai not answering: a single `·` title and one line saying so.
- **`config/swiftbar/plugins/spaces.sh`**: `exec yb bar`, with SwiftBar metadata that hides its own menu
  entries. `~/.config/swiftbar` links to `config/swiftbar`.
- **yabairc:** the refresh signals call `open -g "swiftbar://refreshplugin?name=spaces"` on
  `space_changed`, `display_changed`, `window_created`, `window_destroyed`, `application_front_switched`
  (focus moving between screens), replacing the kb refresh.
- **Bootstrap:** `cask "swiftbar" if OS.mac?`; SwiftBar in the login items; a post-defaults hook writes
  `com.ameba.SwiftBar PluginDirectory = $HOME/.config/swiftbar/plugins` (mise cannot expand `$HOME` in a
  default) and `SUHasLaunchedBefore = true`.
- **kb-raycast:** drop the `yabai.screen` menu bar command, `toStrip` and `spaceGroups`; keep the Hotkeys
  and System commands. Spaceman (installed by hand for the trial) is uninstalled.
- **Tests:** `yb bar` against stubbed yabai output: symbols and colours per state, the dot only between
  screens, only existing spaces, labels with index fallback, the dropdown lines, the yabai-down case.
  Bootstrap specs for the cask, login item, link, hook and signals.
- **Docs:** `docs/TILING.md` (what the squares mean, the validation checklist).

## Not in this change

- Marking spaces that hold windows in the strip (the dropdown lists their apps).
- Space switching on macOS 27 (`yb space` needs a yabai that supports it; tracked separately).
