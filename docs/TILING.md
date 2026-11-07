---
title: Tiling and the fn layer
description: Omarchy-style tiling on macOS with yabai, ten labelled spaces, and fn hotkeys from Karabiner-Elements
---

# Tiling and the fn layer

> Last reviewed: 2026-11-07

The Mac tiles windows the way [Omarchy](https://omarchy.org/manual/hotkeys/) does on Linux, with **fn** in the
role of Super: ⌘ keeps copy, paste and app shortcuts, and every window, space and layout action is fn plus a key.
The design and its trade-offs are in the
[spec](superpowers/specs/2026-11-07-yabai-omarchy-design.md).

| Part | What it does | Where |
| --- | --- | --- |
| yabai | Tiles windows (bsp), keeps ten labelled spaces | [`config/yabai/yabairc`](../config/yabai/yabairc) |
| `yb` | The yabai actions every fn key calls (`yb --help`) | [`config/bin/yb`](../config/bin/yb) |
| Karabiner-Elements | Turns fn combinations into `yb` calls, before macOS sees them | [`config/karabiner/src/bindings.ts`](../config/karabiner/src/bindings.ts) |
| JankyBorders | Outlines the focused window | [`config/borders/bordersrc`](../config/borders/bordersrc) |
| kb Raycast extension | Space strip in the menu bar, Hotkeys and System commands | `~/Work/kb` ([roalcantara/kb-raycast](https://github.com/roalcantara/kb-raycast)) |
| mise bootstrap | Installs, links and starts all of it | [`config/mise/conf.d/yabai.toml`](../config/mise/conf.d/yabai.toml) |

## Spaces and screens

There are ten spaces, labelled `s1`…`s10`; fn + 1…9 go to `s1`…`s9` and fn + 0 to `s10`.

- **Two screens:** `s1`–`s5` on the built-in screen, `s6`–`s10` on the external one.
- **Built-in screen alone:** all ten on it, so every key still works. Plug the external screen back in and
  `s6`–`s10` move back, windows and all.

`yb spaces` enforces this. yabai runs it at start and whenever a screen is added, removed or moved. It
creates and removes spaces as needed, and never removes one that holds windows: it moves them first.

## Keys

Press **fn + k** for the full list (the kb Hotkeys command, read from `config/karabiner/hotkeys.json`). The
everyday ones:

| Keys | Action |
| --- | --- |
| fn + 1…0 | Go to space 1…10 |
| fn + ⇧ + 1…0 / fn + ⇧⌥ + 1…0 | Move the window there and follow / and stay |
| fn + Tab / ⇧Tab / ⌃Tab | Next / previous / last space |
| fn + ←↓↑→ | Focus the window that way; at the edge, the other screen |
| fn + ⇧ + ←↓↑→ | Swap with the window that way |
| fn + ⇧⌃ + ← / → | Send the window to the other screen |
| fn + \` | Focus the other screen |
| fn + w / t / f / ⌥f | Close / tiled↔floating / fullscreen in place / full width |
| fn + o / s / ⌥s | Pin on top of every space / scratchpad / send to scratchpad |
| fn + − / = (⇧ for height) | Narrower / wider (shorter / taller) |
| fn + g / ⌥ + ← → / ⌥Tab | Stack with the neighbour / stack that way / next in the stack |
| fn + j / l / b / r | Split orientation / next layout / balance / rotate |
| fn + ⌥ + ↑ / ↓ | Page Up / Page Down (fn + ↑/↓ now move focus) |
| fn + Return / ⇧Return | Ghostty / Chrome; fn + ⇧ + f, a, c, v, g, d, n for Finder, ChatGPT, Claude, VS Code, WhatsApp, Discord, Neovim |
| fn + Esc | Lock, sleep, restart (kb System command) |
| fn + drag / right-drag | Move / resize a window with the mouse |

macOS's own fn shortcuts (fn + E emoji, fn + F fullscreen, fn + A, C, N, Q) are replaced: Karabiner acts first.

### Change a key

1. Edit [`config/karabiner/src/bindings.ts`](../config/karabiner/src/bindings.ts).
2. Run `mise run karabiner:build`. It rewrites the `dots` profile in `config/karabiner/karabiner.json` and
   `hotkeys.json`; Karabiner reloads at once.
3. Commit both. An `hk` step and `test/integration/bootstrap/karabiner.spec.ts` fail while they are stale.

## Setup

### Done by `mise bootstrap`

- Installs yabai, JankyBorders and Karabiner-Elements; links `~/.config/yabai`, `~/.config/karabiner` and
  `~/.config/borders`, moving a real `~/.config/karabiner` aside first.
- Sets "Press 🌐 key to" to Do Nothing (`AppleFnUsageType = 0`; takes effect after a logout).
- Runs yabai and borders as LaunchAgents (`dev.mise.yabai`, `dev.mise.borders`) that restart if they exit.
- `yb sa` writes `/etc/sudoers.d/yabai` (pinned to yabai's hash, rewritten after `brew upgrade yabai`) and adds
  the `-arm64e_preview_abi` boot argument once SIP is partly off.
- Clones `roalcantara/kb-raycast` to `~/Work/kb`, and warns when SIP or yabai's Accessibility still need you.

### Once per machine, by hand

1. **Partly disable SIP** for the scripting addition (instant space switching, scratchpad, pinning, creating
   spaces): start in Recovery (hold the power button), open Terminal, run
   `csrutil enable --without fs --without debug --without nvram`, reboot. Then run `mise bootstrap` again so
   `yb sa` adds the boot argument, and reboot once more.
2. **Approve Karabiner-Elements** when it asks: its driver extension (System Settings → General → Login Items
   & Extensions) and Input Monitoring. Choose ANSI if it asks for a keyboard type.
3. **Grant Accessibility to yabai** (System Settings → Privacy & Security → Accessibility).
4. **Register the kb extension** with Raycast once: `bun install && bun run dev` in `~/Work/kb`.
5. **Log out once** so the fn setting applies.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| A fn key does nothing | `~/.local/state/dots/yb.log` has the failed yabai call; `yb space 1` in a terminal shows the error |
| fn + E opens emoji, or fn + F goes native fullscreen | Karabiner is not running or the `dots` profile is not selected (Karabiner-Elements → Profiles) |
| Spaces still slide, or the scratchpad does nothing | The scripting addition is not loaded: `sudo -n yabai --load-sa`; if it asks for a password, run `yb sa` |
| Wrong number of spaces, or labels missing | `yb spaces`, then `yabai -m query --spaces \| jq '.[] \| {index, label, display}'` |
| The menu bar strip is stale | Run the kb "Yabai" command once; `yabairc` refreshes it on every space and window change |
| yabai stopped | `launchctl kickstart -k gui/$(id -u)/dev.mise.yabai` |
