# TUI launcher — design

## Intent

Open any terminal tool (TUI) from Raycast the way Omarchy does: a small floating Ghostty window, centred on
the screen you are working on, that goes away when the tool quits. Adding a tool should be one entry in a
list. `psc` (gopass) is the pilot; `brew`-style one-shot commands come later.

How Omarchy does it, for reference: `omarchy-tui-install` writes a `.desktop` launcher running
`xdg-terminal-exec --app-id=TUI.float -e <command>`, a Hyprland rule floats, centres and sizes (875×600)
that app id, the app launcher lists the `.desktop` files, and `omarchy-launch-or-focus-tui` focuses an open
window instead of opening a second one. Windows close when the tool exits; there is no Esc binding.

## Goals

- `config/tuis.toml` lists the tools; one entry is enough to add one.
- Each tool is its own Raycast command (searchable by name, can take a Raycast hotkey or alias).
- The window opens on the focused screen and space, floating, centred, at the entry's size.
- The window closes when the tool exits (`q`, or Esc in tools that quit on Esc, such as gum's psc).
- Triggering a tool whose window is already open focuses that window.

## Non-goals

- No Esc-to-close binding: Esc stays with the tool (Neovim, btop menus, lazygit).
- No fn-layer key per tool (Raycast hotkeys cover that); no kb-extension "TUIs" list (possible later).
- No "press any key" pause in the pilot; the `pause` field is designed for but `brew` is not added yet.

## Anti-goals

- A TUI window that tiles and shoves the other windows around, or opens on another screen.
- Generated Raycast files that drift from `config/tuis.toml` without a failing check.

## Approaches

- **A. List file + one generated Raycast Script Command per tool** — chosen. Mirrors the Karabiner layer
  (source → generated → `--check` in the specs); each tool is first-class in Raycast search.
- B. The same list shown by a "TUIs" command in the kb extension — two steps to open a tool, and the code
  lives in the kb-raycast repo, which this branch cannot test.
- C. Hand-written Script Commands, no list — smallest start, but settings scatter and nothing checks them.

## Design

**`config/tuis.toml`** — one table per tool:

```toml
[psc]
title = "Copy a secret"   # Raycast title; defaults to the name
command = "psc"           # run through the login shell, so it gets the user's PATH
icon = "🔑"               # optional: emoji or a file under config/raycast/scripts/images
size = [875, 600]         # optional, points; default 875×600 like Omarchy
pause = false             # optional: wait for a key before closing (for one-shot commands)
```

**`yb tui <name>`** (config/bin/yb) reads the entry and:

1. Looks for an open Ghostty window titled `tui:<name>`; if found, focuses it and stops.
2. Otherwise opens a Ghostty window through AppleScript with a `surface configuration` whose `command`
   runs the entry's command in the login shell, `wait after command` false (the window closes when the
   tool exits), and sets the terminal's `name override` to `tui:<name>` so step 1 can find it.
3. Waits for the new window (`follow_new_window`), brings it to the focused screen, makes it float,
   resizes it to `size` and centres it on that screen.

Without yabai (or its scripting addition) the window still opens; it just isn't moved or floated.

**Generator** — `mise run tuis:build` writes `config/raycast/scripts/tuis/<name>.sh` per entry: a Raycast
Script Command (`mode silent`, `packageName TUIs`, title, icon) that runs `~/.local/bin/yb tui <name>`.
It removes scripts whose entry is gone. `--check` exits 1 when a committed script differs.

**Tests** — fake-yabai/osascript specs for `yb tui` (opens with the right AppleScript, floats, resizes,
centres, focuses an existing window, unknown name fails); a spec that `tuis:build --check` passes.

**Docs** — a "TUIs" section in docs/TILING.md: how to add one, and a QUICK REFERENCE note that TUIs are
triggered from Raycast.

## Left to the builder

- Where the generator lives (a small Bun script next to the Karabiner one is the natural fit) and how
  `yb` reads TOML (taplo/tombi/yq, whatever the repo already ships).
- Exact centring maths (yabai `--move abs` / `--resize abs` from the display frame).
- Confirm Raycast's script directory picks up the new `tuis/` subfolder; if not, document adding it.
