---
title: Omarchy-style tiling on macOS with yabai and an fn layer
status: proposal (phase 1 of 2)
date: 2026-11-07
---

# Omarchy-style tiling on macOS with yabai and an fn layer

## Intent

Bring Omarchy's keyboard-driven window workflow to this Mac: one modifier for workspaces, focus,
moving and resizing windows, and launching the everyday apps. On Omarchy that modifier is Super, which
sits where ⌘ sits on a Mac. Here ⌘ keeps its macOS jobs (copy, paste, editing, app shortcuts), so the
window layer moves to **fn**. The result does not have to match Omarchy key for key; where macOS forces
a change, the layout adapts.

As much as possible is installed and configured by `mise bootstrap`, so a fresh install comes back the
same way.

## Phases

1. **This document.** Ten spaces, five per screen, with numbers but no roles: the key layout, yabai,
   Karabiner (the `fn` layer), the focused-window border, the Raycast menu bar strip, SIP and the scripting addition,
   bootstrap automation, tests and docs.
2. **Later.** A separate brainstorm assigns a role to each space and the app rules that follow from it.

## Goals

- `fn`+1…0 reaches ten spaces: **1–5 on the built-in screen**, **6–0 on the external screen**.
- Tiling (bsp) by default, with Omarchy's toggles: float, fullscreen in place, split orientation,
  scratchpad, pinned floating window, stacking as the counterpart of groups.
- Switching spaces is instant (no slide animation).
- The focused window is outlined.
- A menu bar strip shows every space, which one each screen shows, and which hold windows.
- One key shows the hotkeys (Omarchy's `Super + K`).
- `mise bootstrap` installs and configures everything it can, and prints the few manual steps.

## Non-goals

- Space roles and per-app space rules (phase 2).
- SketchyBar or any replacement for the macOS menu bar.
- Omarchy's themes, system panels, notifications, capture, reminders and media keys.
- Moving a whole space to the other screen: the five-and-five split is fixed.

## Anti-goals

- Taking over a ⌘ shortcut that macOS or an app relies on.
- A binding that silently does nothing, or does something different, depending on which screen is
  plugged in.
- A setup that only works after hand edits outside this repo, other than the manual steps listed below.

## Constraints found during research

| Constraint | Consequence |
| --- | --- |
| macOS turns `fn` + arrows into Home, End, Page Up and Page Down before skhd, Hammerspoon or Raycast see them. Karabiner-Elements works at the keyboard driver and sees the raw `fn` + arrow (it stopped converting them itself in 15.1) | The `fn` layer is built in Karabiner, so Omarchy's arrow bindings stay on the arrows |
| Using `fn` + arrows for windows takes them away from paging | Line and document jumps stay on ⌘←/→/↑/↓; Page Up and Page Down move to `fn` + ⌥↑/↓ (see Key layout) |
| macOS keeps a few `fn` shortcuts: fn+E emoji, fn+F native fullscreen, fn+A Dock, fn+C Control Center, fn+N Notification Center, fn+Q Quick Note (confirmed on this Mac with nothing intercepting) | With Karabiner rules on those keys, the rules win and macOS does nothing (tested 2026-11-07, see Validation) |
| "Press 🌐 key to" is `com.apple.HIToolbox` `AppleFnUsageType` (0 Do Nothing, 1 input source, 2 emoji, 3 dictation); needs a logout | Bootstrap writes `0` (already set by hand on this Mac); it changes the single press only, not the fn+letter shortcuts |
| Raycast keeps hotkeys in its own encrypted database; the only export is a password-protected file | Window hotkeys live in Karabiner's config (generated from source in this repo), not Raycast |
| Karabiner rewrites `karabiner.json` when its settings window changes something, replacing the file | Link the whole `~/.config/karabiner` folder, never the file alone; keep generated output and source side by side |
| A Raycast menu bar command is one item, mirrored on every screen's menu bar | The strip shows both screens' spaces in one item |
| Creating, destroying and moving spaces, removing the slide, scratchpad, sticky and topmost windows need yabai's scripting addition, so SIP partly off | The owner accepts partial SIP; disabling it is a manual Recovery step |
| macOS numbers spaces by display order, and the built-in screen is currently first | Keys address spaces by yabai labels, not by index |
| yabai 7.1.19+ focuses spaces with SIP on | Space switching still works if SIP is ever re-enabled, just with the slide |

## Approaches considered

**Bar.** (1) SketchyBar with the macOS menu bar auto-hidden: closest to Omarchy, most work.
(2) Keep the macOS menu bar and show the spaces in a Raycast menu bar item. (3) No bar.
**Chosen: 2**, extending the owner's `kb` Raycast extension (`roalcantara/kb-raycast`), whose
`yabai.screen` command already lists spaces per display and focuses them on click. The Raycast Store
"Yabai" extension shows only the current space; YabaiIndicator is unmaintained since 2023.

**Hotkeys.** (1) skhd, plain-text config with `fn` as a modifier, the usual pairing with yabai; cannot
bind `fn` + arrows and probably loses `fn` + E/F/A/C/N/Q to macOS. (2) Raycast hotkeys bound to script
commands: same event level as skhd, and cannot be set by bootstrap. (3) Karabiner-Elements as the whole
`fn` layer: sees `fn` + arrows and acts before macOS, at the cost of a driver extension approved once.
(4) Karabiner for the arrows only, skhd for the rest: two tools to keep in step. (5) Hammerspoon: same
event level as skhd.
**Chosen: 3, Karabiner-Elements**, with its rules generated from TypeScript by
[karabiner.ts](https://github.com/evan-liu/karabiner.ts). Every rule calls yabai by absolute path. Raycast
keeps the launcher (⌘Space) and Hyper on right ⌘. A single `fn` tap stays unbound (deferred).

**Highlight.** JankyBorders (`FelixKratz/formulae/borders`), the common choice in every setup reviewed.

## Design

### Spaces and screens

- yabai labels the spaces `s1`…`s10` (labels cannot be bare numbers). `fn`+1…9 focus `s1`…`s9`,
  `fn`+0 focuses `s10`.
- **Two screens:** `s1`–`s5` on the built-in screen, `s6`–`s10` on the external one.
- **Built-in only (lid open, nothing plugged in):** all ten on the built-in screen, so every binding
  still works. When the external screen returns, `s6`–`s10` move back to it.
- A script, `config/yabai/spaces`, enforces this. It runs when yabai starts and on yabai's
  `display_added`, `display_removed` and `display_moved` signals. It creates or destroys spaces so each
  screen has the right count, moves `s6`–`s10` between screens, and relabels. It never destroys a space
  that holds windows; it moves the windows first.
- The built-in screen is identified by the hardware, not by its position or size:
  `system_profiler SPDisplaysDataType -json` marks it `spdisplays_connection_type = spdisplays_internal`,
  and its `_spdisplays_displayID` equals the `id` yabai reports for that display (about 0.2 s).

### Key layout

`fn` replaces Super, and Karabiner turns each `fn` combination into a yabai command. ⌘ is untouched. `⇧` = Shift, `⌥` = Option, `⌃` = Control.

| Omarchy | Here | Action |
| --- | --- | --- |
| Super + 1…0 | fn + 1…0 | Focus space s1…s10 (its screen follows) |
| Super + Shift + 1…0 | fn + ⇧ + 1…0 | Move window to that space and follow |
| Super + Shift + Alt + 1…0 | fn + ⇧⌥ + 1…0 | Move window there without following |
| Super + Tab / Shift + Tab | fn + Tab / ⇧Tab | Next / previous space on this screen |
| Super + Ctrl + Tab | fn + ⌃Tab | Last space you were on |
| Super + Arrows | fn + ←↓↑→ | Focus window; crosses to the other screen at the edge |
| Super + Shift + Arrows | fn + ⇧ ←↓↑→ | Swap with the neighbour |
| Super + Shift + Ctrl + Arrows | fn + ⇧⌃ ← / → | Send window to the other screen |
| Ctrl + Alt + Tab | fn + \` | Focus the other screen |
| Super + J | fn + j | Toggle split orientation |
| Super + L / Alt + L | fn + l / ⌥l | Cycle layout bsp → stack → float / reverse |
| Super + K | fn + k | Show the hotkeys |
| Super + W | fn + w | Close window |
| Super + T | fn + t | Toggle tiled / floating |
| Super + F | fn + f | Fullscreen inside the space (yabai zoom) |
| Super + Alt + F | fn + ⌥f | Full width (zoom to parent) |
| Super + O | fn + o | Floating, on top, on every space of its screen |
| Super + S / Alt + S | fn + s / ⌥s | Toggle the scratchpad / send window to it |
| Super + Minus / Equal | fn + − / = | Narrower / wider |
| Super + Shift + Minus / Equal | fn + ⇧− / ⇧= | Shorter / taller |
| Super + G | fn + g | Stack the window onto its neighbour (yabai's groups) |
| Super + Alt + Arrows | fn + ⌥ ← / → | Stack onto the neighbour in that direction |
| (macOS paging) | fn + ⌥ ↑ / ↓ | Page Up / Page Down, which `fn` + ↑/↓ used to send (proposal) |
| Super + Alt + Tab / Shift + Tab | fn + ⌥Tab / ⇧⌥Tab | Next / previous window in the stack |
| (none) | fn + b | Balance the layout (proposal) |
| (none) | fn + r | Rotate the layout 90° (proposal) |
| Super + Return | fn + Return | Ghostty |
| Super + Shift + Return | fn + ⇧Return | Google Chrome |
| Super + Shift + F | fn + ⇧f | Finder |
| Super + Shift + N | fn + ⇧n | Neovim in Ghostty |
| Super + Shift + A | fn + ⇧a | ChatGPT |
| (none) | fn + ⇧c | Claude (proposal) |
| (none) | fn + ⇧v | Visual Studio Code (proposal) |
| Super + Shift + Alt + G | fn + ⇧g | WhatsApp |
| (none) | fn + ⇧d | Discord (proposal) |
| Super + Space | ⌘Space (unchanged) | Raycast (the "Omarchy menu") |
| Super + Escape | fn + Esc | Raycast's system commands (lock, sleep, restart) |
| Super + Left / Right mouse | fn + drag / right-drag | Move / resize (already in `yabairc`) |

Kept as macOS has them: ⌘Tab, ⌘C/⌘V/⌘X, ⌃⌘Q (lock), ⌘Space (Raycast), screenshots.

Changed after the owner's validation (2026-11-07): stacking is removed (fn + g, fn + ⌥ + ← / →, fn + ⌥Tab,
fn + ⌥⇧Tab and the stack layout in fn + l). yabai shows no sign of a stack, so stacked windows simply vanished;
fn + l toggles tiled ↔ floating. fn + ⌥⇧ + ← / → rotate the layout and fn + ⌃ + arrows arrange a window with
its neighbour (docs/TILING.md has the current keys).

### Look and behaviour

- bsp layout, new windows split the focused one, `auto_balance` on, gaps and padding as in the current
  `yabairc` (12 padding, 6 gap) until tuned.
- Focused window: JankyBorders outline, accent colour, width about 5, rounded; unfocused windows get no
  border.
- With the scripting addition: no slide between spaces, no window shadows.
- Floating by default: System Settings, Calculator, Archive Utility, Raycast, the Ghostty quick terminal,
  and dialogs (yabai rules).
- `mouse_follows_focus` on, `focus_follows_mouse` off. The current `yabairc` has `autofocus`; Omarchy
  does not move focus with the mouse.

### Menu bar strip (kb-raycast, separate PR)

Changes to `apps/kb/src/yabai.screen.tsx` and `packages/core/src/yabai`:

- The title becomes the strip, by label, in two groups: `1 ❷ 3 · 5 │ 6 7 ❽ 9 0`. A circled number marks
  the space each screen shows, the focused one in the primary colour; `·` marks a space that holds
  windows; a plain number is empty.
- The dropdown keeps one section per screen, named Built-in and External, items ordered by label.
- A "Hotkeys" submenu lists the key layout, read from the descriptions of the Karabiner rules. `fn` + k
  opens it.
- yabai refreshes the strip through the existing signals (`space_changed`, `display_changed`), plus
  `window_created` and `window_destroyed` so the `·` marks stay right.

### Raycast

- `fn` + Esc opens Raycast's system commands through a deeplink from the Karabiner rule, so there is
  nothing to set in Raycast for this phase.

## Automation

### Done by `mise bootstrap`

| What | Where |
| --- | --- |
| `yabai` (`asmvik/formulae`), `borders` (`FelixKratz/formulae`), `karabiner-elements` (cask) | `config/homebrew/Brewfile` |
| `AppleFnUsageType = 0` | `config/mise/conf.d/macos.toml` |
| `~/.config/yabai`, `~/.config/karabiner`, `~/.config/borders` linked into the repo (whole folders) | `config/mise/conf.d/dotfiles.toml` |
| `karabiner.json` generated from `config/karabiner/src/*.ts` (karabiner.ts) and committed | a mise task; a test fails when the committed file is stale |
| LaunchAgents for yabai and borders, restarted on exit (Karabiner runs its own) | `[bootstrap.macos.launchd.agents.*]` |
| `/etc/sudoers.d/yabai`, so `yabai --load-sa` runs without a password; rewritten when the yabai binary's hash changes | a bootstrap hook, validated with `visudo -c` |
| The arm64e boot argument the scripting addition needs (`nvram boot-args=-arm64e_preview_abi`) | a bootstrap hook, only when SIP is already partly off |
| Clone `roalcantara/kb-raycast` to `~/Work/kb` | `[bootstrap.repos]` |
| Warnings for each manual step still missing (SIP state, permissions, kb extension) | the bootstrap task |

### Manual, once per machine

1. Partly disable SIP in Recovery: `csrutil enable --without fs --without debug --without nvram`, then
   reboot. Bootstrap detects whether it is done.
2. Allow Karabiner's driver extension and Input Monitoring when macOS asks, and grant Accessibility to
   yabai.
3. Register the kb extension with Raycast once (`npm run dev` in `apps/kb`, or import).
4. Log out once so `AppleFnUsageType` takes effect.

## Validation

### Spike first (throwaway, before the plan)

Results so far (2026-11-07, Karabiner-Elements 16.3.0, macOS 27.2, built-in keyboard and Magic
Keyboard):

- Item 1 passed: `fn` + ←→↑↓, `fn` + ⇧←, `fn` + 1/0 and fn+E/F/A/C/N/Q/H all reached Karabiner rules on
  both keyboards, and macOS took no action of its own. No binding has to move.
- Identifying the built-in screen from a script works: see Spaces and screens.
- Item 2 is deferred with the single `fn` tap (⌘Space already opens Raycast).
- `osascript` notifications from a Karabiner `shell_command` do not appear; rules that need feedback
  should use a sound or a log line.

1. With `AppleFnUsageType = 0` and Karabiner running, bind `fn` + ←, `fn` + 1 and fn+E, fn+F, fn+A,
   fn+C, fn+N, fn+Q to a notification. If macOS still wins for any of them, move that binding
   (candidates: fn+x, fn+y, fn+z, fn+p, fn+u, fn+i) and record it here.
2. (Deferred) Confirm that a single `fn` tap still reaches Raycast with Karabiner running, and does not fire when
   `fn` is held as a modifier.

### Tests (Bun, `test/integration/bootstrap`)

- The committed `karabiner.json` matches what the TypeScript source generates, and has no duplicate
  `from` combinations.
- Every `fn`+1…0, `fn` + ⇧ + 1…0 and `fn` + ⇧⌥ + 1…0 binding targets `s1`…`s10`.
- `config/yabai/spaces`, run against stubbed `yabai` output, makes the right calls for one and two
  screens and never destroys a space with windows.
- The sudoers hook writes a file `visudo -c` accepts, and only when the hash changed.
- Brewfile entries, links, LaunchAgents and the `AppleFnUsageType` default are declared.

### Gates

`hk check --all`, `mise run test:specs`, and a manual run-through of every row in the key layout on
both screens and on the built-in screen alone.

## Left to the builder

- The exact JankyBorders colours, width and the gaps.
- The list of apps that float by default.
- How the hotkey list reaches the kb extension (read `karabiner.json`, or a small JSON the generator
  writes alongside it).

## References

- Omarchy: [hotkeys](https://omarchy.org/manual/hotkeys/), [navigation](https://omarchy.org/manual/navigation/), [coming from Mac or Windows](https://omarchy.org/manual/coming-from-mac-or-windows/)
- Raycast: [single-key and fn hotkeys](https://manual.raycast.com/command-aliases-and-hotkeys#single-key), [menu bar commands](https://developers.raycast.com/api-reference/menu-bar-commands)
- yabai: [command reference](https://github.com/asmvik/yabai/blob/master/doc/yabai.asciidoc), [disabling SIP](https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection)
- Karabiner-Elements: [breaking changes (fn + arrows)](https://karabiner-elements.pqrs.org/docs/help/troubleshooting/breaking-changes/), [implicit behavior](https://karabiner-elements.pqrs.org/docs/manual/misc/implicit-behavior/), [issue #2333](https://github.com/pqrs-org/Karabiner-Elements/issues/2333), [karabiner.ts](https://github.com/evan-liu/karabiner.ts)
- skhd (considered): [keywords, including the keys fn cannot combine with](https://github.com/asmvik/skhd/issues/1); [skhd.zig](https://github.com/jackielii/skhd.zig)
- `AppleFnUsageType`: [nix-darwin hitoolbox module](https://github.com/nix-darwin/nix-darwin/blob/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48/modules/system/defaults/hitoolbox.nix), [inputalk PR #10 (cached value)](https://github.com/sebi75/inputalk/pull/10), [macos-defaults.com](https://macos-defaults.com/)
- Similar setups: [RyanAHayden/hypr-mac](https://github.com/RyanAHayden/hypr-mac), [jlargs64/macarchy](https://github.com/jlargs64/macarchy), [locupleto/the-gallery](https://github.com/locupleto/the-gallery), [Carter-FS/dotfiles-macos](https://github.com/Carter-FS/dotfiles-macos), [penkin.me write-up](https://www.penkin.me/development/tools/productivity/configuration/2025/11/28/building-omarchy-inspired-setup-macos.html), [OthinusG/mac-dotfiles-yabai](https://github.com/OthinusG/mac-dotfiles-yabai), [jerechinsky/macos-window-manager-dotfiles](https://github.com/jerechinsky/macos-window-manager-dotfiles), [FelixKratz/dotfiles](https://github.com/FelixKratz/dotfiles)
- Menu bar alternatives considered: [Raycast Store Yabai](https://www.raycast.com/krzysztoff1/yabai), [YabaiIndicator](https://github.com/xiamaz/YabaiIndicator), [space-number](https://github.com/daugvinasr/space-number)
