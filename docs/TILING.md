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

| Part                 | What it does                                                    | Where                                                                             |
| -------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| yabai                | Tiles windows (bsp), keeps ten labelled spaces                  | [`config/yabai/yabairc`](../config/yabai/yabairc)                                 |
| `yb`                 | The yabai actions every fn key calls (`yb --help`)              | [`config/bin/yb`](../config/bin/yb)                                               |
| Karabiner-Elements   | Turns fn combinations into `yb` calls, before macOS sees them   | [`config/karabiner/src/bindings.ts`](../config/karabiner/src/bindings.ts)         |
| JankyBorders         | Outlines the focused window (qeesung's fork, built from source) | [`config/borders/bordersrc`](../config/borders/bordersrc)                         |
| SwiftBar             | The space strip in the menu bar (`yb bar`)                      | [`config/swiftbar/plugins/spaces.sh`](../config/swiftbar/plugins/spaces.sh)       |
| kb Raycast extension | Hotkeys and System commands                                     | `~/Work/kb` ([roalcantara/kb-raycast](https://github.com/roalcantara/kb-raycast)) |
| mise bootstrap       | Installs, links and starts all of it                            | [`config/mise/conf.d/yabai.toml`](../config/mise/conf.d/yabai.toml)               |

## Spaces and screens

There are ten spaces, labelled `s1`…`s10`; fn + 1…9 go to `s1`…`s9` and fn + 0 to `s10`.

- **Two screens:** `s1`–`s5` on the built-in screen, `s6`–`s10` on the external one.
- **Built-in screen alone:** all ten on it, so every key still works. Plug the external screen back in and
  `s6`–`s10` move back, windows and all.

`yb spaces` enforces this. yabai runs it at start and whenever a screen is added, removed or moved. It
creates and removes spaces as needed, and never removes one that holds windows: it moves them first.

## The menu bar strip

One numbered square per space that exists, built-in screen first, a dot, then the external screen:

| Square        | Meaning                                              |
| ------------- | ---------------------------------------------------- |
| Filled white  | On screen and focused (where the keyboard is)        |
| Outline       | On screen, not focused (what the other screen shows) |
| Filled dimmed | Not on any screen                                    |

Click it for the spaces with their apps; choose one to go there. SwiftBar runs `yb bar`, and yabai refreshes it
on every space, screen, window and focus change. The strip is a small colour image (drawn with `resvg`), so it
looks the same on both screens; without `resvg` it falls back to SF Symbols, which turn all white on the unfocused
screen.

## Keys

Every shortcut is in the [QUICK REFERENCE](#quick-reference) below; press **fn + k** for the same list on
screen (the kb Hotkeys command, read from `config/karabiner/hotkeys.json`).

Karabiner acts on a fn combination only when the layer binds it, so fn + F is yabai's fullscreen, not
macOS's. fn alone does nothing (Keyboard → Press 🌐 key to: Do Nothing); macOS's other fn shortcuts
(fn + E emoji, fn + A, C, N, Q) are not bound, and the reference marks them `?` until checked.

### Change a key

1. Edit [`config/karabiner/src/bindings.ts`](../config/karabiner/src/bindings.ts).
2. Run `mise run karabiner:build`. It rewrites the `dots` profile in `config/karabiner/karabiner.json` and
   `hotkeys.json`; Karabiner reloads at once.
3. Commit both. An `hk` step and `test/integration/bootstrap/karabiner.spec.ts` fail while they are stale.

## Setup

### Done by `mise bootstrap`

- Installs yabai, Karabiner-Elements and SwiftBar; links `~/.config/yabai`, `~/.config/karabiner`,
  `~/.config/borders` and `~/.config/swiftbar`, moving a real `~/.config/karabiner` aside first.
- Starts SwiftBar at login, pointed at `~/.config/swiftbar/plugins`.
- Sets "Press 🌐 key to" to Do Nothing (`AppleFnUsageType = 0`; takes effect after a logout).
- Builds JankyBorders from [qeesung's fork](https://github.com/qeesung/JankyBorders) at a pinned commit into
  `~/.local/share/janky-borders` (upstream leaves outlines behind in Mission Control on macOS 27).
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

### Another yabai build (macOS 27)

yabai 7.1.25 rejects macOS 27, so its scripting addition loads and does nothing. Until a release supports
it, a fork can stand in ([asmvik/yabai#2802](https://github.com/asmvik/yabai/issues/2802) lists the offsets;
read the fork's diff before building it). The agent runs `yb run` and yabairc `yb load-sa`, and both use the
binary `yb use` chose on this machine (`~/.local/state/dots/yabai-bin`), so switching is:

1. Build the fork outside the repo and copy `bin/yabai` somewhere that lasts, e.g. `~/.local/share/yabai-fork/`.
2. Stop yabai first: `launchctl bootout gui/$(id -u)/dev.mise.yabai`. Changing Accessibility while yabai runs
   freezes the screen until it exits.
3. Grant the new binary Accessibility (System Settings → Privacy & Security → Accessibility, **+**).
4. `yb use ~/.local/share/yabai-fork/yabai` (asks for your password once, for the sudoers rule), then
   `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.mise.yabai.plist` and `killall Dock`.
5. Check `/usr/bin/log show --last 5m --style compact --predicate 'process == "Dock" AND eventMessage CONTAINS "[yabai-sa]"'`
   shows "Detected Golden Gate" and every target found.

**To go back to Homebrew's yabai**

`yb use brew` goes back to Homebrew's yabai, the same way.

```sh
yb use brew
launchctl kickstart -k gui/$(id -u)/dev.mise.yabai
killall Dock.
```

After a macOS update, check the fork still matches
the new Dock before trusting it.

## Validation checklist

Walk this after a fresh setup or a change. Items marked A need yabai's scripting addition and those
marked S need space switching; both fail silently on macOS 27 with yabai 7.1.25 (it rejects the
OS), so expect them to fail there unless `yb use` runs a build that supports it (below).

### Setup

- [ ] `csrutil status` shows "Custom Configuration" with Filesystem, Debugging and NVRAM protections disabled.
- [ ] `nvram boot-args` includes `-arm64e_preview_abi`.
- [ ] `yb load-sa` exits 0 without asking for a password.
- [ ] `launchctl list | grep dev.mise` shows `dev.mise.yabai` and `dev.mise.borders` running.
- [ ] Karabiner-Elements → Profiles: `dots` is selected; pressing 🌐/fn alone does nothing.

### Look

- [x] Two tiled windows have a 10-point gap between them and at the screen edges.
- [o] Only the focused window has an outline: cyan to green, 5 wide; amber while it is zoomed (fn + f / ⌥f).
- [o] A new window splits the focused one instead of covering it.
- [x] System Settings, Calculator, Raycast and dialogs float above the tiles.
- [x] A Window shadows are gone

### Menu bar strip (SwiftBar)

- [x] One square per existing space: built-in screen first, a dot, then the external screen.
- [x] Filled white = on screen and focused; outline = on screen, not focused; dimmed = not on screen.
- [x] Clicking into the other screen swaps the filled and outlined squares at once.
- [x] The strip redraws when a window opens or closes and when the space changes.
- [?] S The dropdown lists each space with its apps; choosing one goes there
- [-] White on a dark menu bar, black on a light one.

### Spaces

- [x] `yabai -m query --spaces | jq '.[] | {index, label, display}'`: every space is labelled; `s1`… on the
      built-in screen, `s6`… on the external one.
- [ ] A Five spaces on each screen; with SIP-only yabai, add them in Mission Control and run `yb spaces`.
- [ ] S fn + 1…0 go to that space.
- [ ] S fn + ⇧ + 1…0 move the window and follow; fn + ⇧⌥ + 1…0 move it and stay.
- [ ] S fn + Tab / ⇧Tab / ⌃Tab: next / previous / last space.
- [ ] A Unplug the external screen: all spaces land on the built-in one, labels intact (`s1`–`s10` with ).
- [ ] A Plug it back in: `s6`… return to it with their windows

### Windows

- [x] fn + ←↓↑→ move focus; at the edge, focus crosses to the other screen.
- [ ] fn + ⇧ + ←↓↑→ swap with the neighbour.
- [ ] fn + ⇧ + [ / ] send the window to the screen west / east and follow it.
- [ ] fn + [ / ] focus the screen west / east.
- [ ] fn + w closes;
- [ ] fn + t toggles floating;
- [ ] fn + f fills the space;
- [ ] fn + ⌥f fills the parent split.
- [x] fn + − / = narrower / wider; with ⇧, shorter / taller.
- [ ] fn + drag moves a window; fn + right-drag resizes it.
- [ ] A fn + o pins a window on top of every space; again to unpin.
- [ ] A fn + s toggles the scratchpad; fn + ⌥s sends a window to it.

### Layout

- [ ] fn + ⇧ + \\ (|) puts the focused window and its neighbour side by side; fn + \\ one above the other.
- [ ] fn + l toggles tiled ↔ floating; a space left in the stack layout goes back to tiled.
- [ ] fn + b balances the splits.
- [ ] fn + ⌥⇧ + → rotates the layout clockwise, fn + ⌥⇧ + ← counter-clockwise; focus stays on the same window.
- [ ] fn + ⌃ + ← / →: the focused window and its neighbour side by side, focused on the left / right;
      fn + ⌃ + ↑ / ↓: one above the other, focused on top / at the bottom.

### Apps

- [ ] fn + Return opens a new Ghostty window, also while Ghostty is in front.
- [ ] fn + ⇧n opens Neovim in a new Ghostty window.
- [ ] fn + ⇧Return opens a new tab in the default browser's front window; fn + ⌥⇧Return opens a new browser window on the focused screen.
- [ ] fn + ⇧f Finder, ⇧c Claude, ⇧v VS Code, ⇧g Gemini.

### System and keyboard

- [ ] fn + k opens the kb Hotkeys list; fn + Esc opens the kb System list.
- [ ] fn + ⌥↑ / ⌥↓ page up / down.
- [ ] fn + E, F, A, C, N, Q do not open macOS's emoji picker, fullscreen, Dock, Control Center,
      Notification Center or Quick Note.
- [ ] Every fn key still works with Caps Lock on.
- [ ] ⌘C / ⌘V / ⌘Tab / ⌘Space (Raycast) behave as before.

### Recovery

- [ ] `pkill yabai`: it is back within seconds (LaunchAgent).
- [ ] A failing key leaves a line in `~/.local/state/dots/yb.log`.

## QUICK REFERENCE

Every shortcut, one per row: the fn layer in the order fn + k shows it (`config/karabiner/hotkeys.json`, which
`karabiner.spec.ts` checks against this table), then, at the end of their scope, the strip, the mouse and the
macOS shortcuts the layer leaves alone.
CHECK: `✓` works today; `S` needs space switching; `A` needs the scripting addition; `D` disabled now;
`?` not verified yet.

| CHECK |  SCOPE  | SHORTCUT            | ACTION                                                               |
| :---: | :-----: | ------------------- | -------------------------------------------------------------------- |
|   S   |  Spaces | fn + 1              | Go to space 1                                                        |
|   S   |  Spaces | fn + 2              | Go to space 2                                                        |
|   S   |  Spaces | fn + 3              | Go to space 3                                                        |
|   S   |  Spaces | fn + 4              | Go to space 4                                                        |
|   S   |  Spaces | fn + 5              | Go to space 5                                                        |
|   S   |  Spaces | fn + 6              | Go to space 6                                                        |
|   S   |  Spaces | fn + 7              | Go to space 7                                                        |
|   S   |  Spaces | fn + 8              | Go to space 8                                                        |
|   S   |  Spaces | fn + 9              | Go to space 9                                                        |
|   S   |  Spaces | fn + 0              | Go to space 10                                                       |
|   A   |  Spaces | fn + ⇧ + 1          | Move window to space 1                                               |
|   A   |  Spaces | fn + ⇧ + 2          | Move window to space 2                                               |
|   A   |  Spaces | fn + ⇧ + 3          | Move window to space 3                                               |
|   A   |  Spaces | fn + ⇧ + 4          | Move window to space 4                                               |
|   A   |  Spaces | fn + ⇧ + 5          | Move window to space 5                                               |
|   A   |  Spaces | fn + ⇧ + 6          | Move window to space 6                                               |
|   A   |  Spaces | fn + ⇧ + 7          | Move window to space 7                                               |
|   A   |  Spaces | fn + ⇧ + 8          | Move window to space 8                                               |
|   A   |  Spaces | fn + ⇧ + 9          | Move window to space 9                                               |
|   A   |  Spaces | fn + ⇧ + 0          | Move window to space 10                                              |
|   A   |  Spaces | fn + ⌥ + ⇧ + 1      | Move window to space 1, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 2      | Move window to space 2, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 3      | Move window to space 3, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 4      | Move window to space 4, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 5      | Move window to space 5, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 6      | Move window to space 6, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 7      | Move window to space 7, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 8      | Move window to space 8, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 9      | Move window to space 9, stay here                                    |
|   A   |  Spaces | fn + ⌥ + ⇧ + 0      | Move window to space 10, stay here                                   |
|   S   |  Spaces | fn + Tab            | Next space on this screen                                            |
|   S   |  Spaces | fn + ⇧ + Tab        | Previous space on this screen                                        |
|   S   |  Spaces | fn + ⌃ + Tab        | Last space you were on                                               |
|   S   |  Spaces | click the strip     | Menu bar: the spaces with their apps; choose one to go there         |
|   ✓   | Windows | fn + ←              | Focus window west                                                    |
|   ✓   | Windows | fn + →              | Focus window east                                                    |
|   ✓   | Windows | fn + ↑              | Focus window north                                                   |
|   ✓   | Windows | fn + ↓              | Focus window south                                                   |
|   ✓   | Windows | fn + ⇧ + ←          | Swap window west                                                     |
|   ✓   | Windows | fn + ⇧ + →          | Swap window east                                                     |
|   ✓   | Windows | fn + ⇧ + ↑          | Swap window north                                                    |
|   ✓   | Windows | fn + ⇧ + ↓          | Swap window south                                                    |
|   ✓   | Windows | fn + [              | Focus the screen west                                                |
|   ✓   | Windows | fn + ]              | Focus the screen east                                                |
|   ✓   | Windows | fn + ⇧ + [          | Send window to the screen west                                       |
|   ✓   | Windows | fn + ⇧ + ]          | Send window to the screen east                                       |
|   ✓   | Windows | fn + w              | Close window                                                         |
|   ✓   | Windows | fn + t              | Toggle tiled / floating                                              |
|   ✓   | Windows | fn + f              | Fullscreen inside the space                                          |
|   ✓   | Windows | fn + ⌥ + f          | Full width (fill the parent split)                                   |
|   A   | Windows | fn + o              | Pin: floating, on top, on every space                                |
|   A   | Windows | fn + s              | Toggle the scratchpad                                                |
|   A   | Windows | fn + ⌥ + s          | Send window to the scratchpad                                        |
|   ✓   | Windows | fn + −              | Narrower                                                             |
|   ✓   | Windows | fn + =              | Wider                                                                |
|   ✓   | Windows | fn + ⇧ + −          | Shorter                                                              |
|   ✓   | Windows | fn + ⇧ + =          | Taller                                                               |
|   D   | Windows | fn + drag           | Move a window with the mouse (yabairc)                               |
|   D   | Windows | fn + right-drag     | Resize a window with the mouse (yabairc)                             |
|   ✓   |  Layout | fn + ⇧ + \\         | Focused window and its neighbour side by side (\|)                   |
|   ✓   |  Layout | fn + \\             | Focused window and its neighbour one above the other (\)             |
|   ✓   |  Layout | fn + ⌃ + ←          | Focused and its neighbour side by side, focused on the left          |
|   ✓   |  Layout | fn + ⌃ + →          | Focused and its neighbour side by side, focused on the right         |
|   ✓   |  Layout | fn + ⌃ + ↑          | Focused and its neighbour one above the other, focused on top        |
|   ✓   |  Layout | fn + ⌃ + ↓          | Focused and its neighbour one above the other, focused at the bottom |
|   ✓   |  Layout | fn + l              | Toggle tiled / floating layout                                       |
|   ✓   |  Layout | fn + b              | Balance the splits                                                   |
|   ✓   |  Layout | fn + ⌥ + ⇧ + →      | Rotate the layout clockwise                                          |
|   ✓   |  Layout | fn + ⌥ + ⇧ + ←      | Rotate the layout counter-clockwise                                  |
|   ✓   |   Apps  | fn + Return         | New Ghostty window, also while Ghostty is in front                   |
|   ✓   |   Apps  | fn + ⇧ + Return     | New tab in the default browser's front window                        |
|   ✓   |   Apps  | fn + ⌥ + ⇧ + Return | New default browser window, on the focused screen                    |
|   ✓   |   Apps  | fn + ⇧ + f          | Finder                                                               |
|   ✓   |   Apps  | fn + ⇧ + c          | Claude                                                               |
|   ✓   |   Apps  | fn + ⇧ + v          | Visual Studio Code                                                   |
|   ✓   |   Apps  | fn + ⇧ + g          | Gemini                                                               |
|   ✓   |   Apps  | fn + ⇧ + n          | Neovim                                                               |
|   ✓   |  System | fn + k              | Show these hotkeys                                                   |
|   ✓   |  System | fn + Esc            | System: lock, sleep, restart                                         |
|   ✓   |  System | fn + ⌥ + ↑          | Page Up                                                              |
|   ✓   |  System | fn + ⌥ + ↓          | Page Down                                                            |
|   ?   |  System | fn                  | Alone: nothing (Keyboard → Press Globe key to: Do Nothing)           |
|   ?   |  System | fn + e              | Unbound: should not open macOS's emoji picker                        |
|   ?   |  System | fn + a              | Unbound: should not show the Dock                                    |
|   ?   |  System | fn + c              | Unbound: should not open Control Center                              |
|   ?   |  System | fn + n              | Unbound: should not open Notification Center                         |
|   ?   |  System | fn + q              | Unbound: should not open Quick Note                                  |
|   ?   |  System | ⌘ + Space           | Raycast (Spotlight's shortcut is off)                                |
|   ?   |  System | ⌘ + Tab             | macOS app switcher, unchanged                                        |
|   ?   |  System | ⌘ + c               | Copy, unchanged                                                      |
|   ?   |  System | ⌘ + v               | Paste, unchanged                                                     |

## Troubleshooting

| Symptom                                              | Check                                                                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Which key did what                                   | `yb log -f`: each fn key, its yb call and result, and yabai's window events                                         |
| A fn key does nothing                                | `~/.local/state/dots/yb.log` has the failed yabai call; `yb space 1` in a terminal shows the error                  |
| fn + E opens emoji, or fn + F goes native fullscreen | Karabiner is not running or the `dots` profile is not selected (Karabiner-Elements → Profiles)                      |
| Spaces still slide, or the scratchpad does nothing   | The scripting addition is not loaded: `yb load-sa`; if it fails, run `yb sa` (or see the macOS 27 section)          |
| Spaces out of order on a screen                      | `yb spaces` moves them back into label order (needs the scripting addition)                                         |
| The menu bar shows "SwiftBar" instead of the strip   | SwiftBar lost its plugin folder (e.g. a branch switch): `osascript -e 'quit app "SwiftBar"' && open -g -a SwiftBar` |
| The screen froze after changing Accessibility        | yabai was running: kill it, then stop the agent before changing Accessibility (macOS 27 section)                    |
| Wrong number of spaces, or labels missing            | `yb spaces`, then `yabai -m query --spaces \| jq '.[] \| {index, label, display}'`                                  |
| The menu bar strip is stale or missing               | `open -g 'swiftbar://refreshplugin?name=spaces'`; `yb bar` in a terminal shows what SwiftBar gets                   |
| yabai stopped                                        | `launchctl kickstart -k gui/$(id -u)/dev.mise.yabai`                                                                |
