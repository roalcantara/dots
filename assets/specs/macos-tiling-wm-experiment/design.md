<!-- markdownlint-disable -->
# macOS tiling WM experiment — design

Requirements: [requirements.md](./requirements.md).

## 1. Context

| Fact (2026-10-27) | Value |
| --- | --- |
| WM | yabai v7.1.25, scripting addition loaded via `sudo yabai --load-sa` |
| SIP | Custom configuration (Filesystem / Debugging / NVRAM protections disabled) |
| Hotkeys | **None** — skhd not installed (Brewfile L93 commented), `config/skhd/skhdrc` empty |
| Hyper | Raycast, Right ⌘ (keyCode 231) → ⌃⌥⌘, `includeShiftKey = 0` |
| Observed bug | Space 7: yabai tree had Ghostty at half width, real frame was full width; `yabai -m space 7 --balance` restored it. Suspects: Ghostty `macos-non-native-fullscreen = true` + `ctrl+alt+enter=toggle_fullscreen`, or window-state restore after tiling |
| Prior trials | `config/rift/config.toml`, `config/glide/glide.toml` (not part of this experiment) |

Why no SIP-on tool can match yabai with the scripting addition: macOS has no public API to
move a window to another Space or to create/destroy/move Spaces. Every SIP-on WM either
fakes Spaces (AeroSpace, OmniWM, Rift) or works around it (Amethyst, yabai without SA).
That gap is exactly what Phase 2 measures.

## 2. Architecture (Phase 1 — C0)

```text
Right ⌘ ──Raycast Hyper (⌃⌥⌘)──▶ skhd ──yabai -m …──▶ yabai ──SA──▶ Dock (Spaces)
                                    │                    │
                                    └─ open -na … (apps)  └─ signals ──▶ borders (focus highlight)
```

| Unit | File | Purpose | Depends on |
| --- | --- | --- | --- |
| yabai | `config/yabai/yabairc` | Dwindle tiling, rules, signals, starts borders | SA, sudoers rule |
| skhd | `config/skhd/skhdrc` | Every binding in §3; no logic beyond one-liners | yabai, Raycast Hyper |
| helpers | `config/yabai/bin/*` (small sh scripts) | Logic too long for one skhd line: per-display Space N, layout cycle, group toggle | yabai, jq |
| borders | `config/borders/bordersrc` | Focused-window border | none (WM-agnostic) |
| Brewfile | `config/homebrew/Brewfile` | Uncomment `asmvik/formulae/skhd`; add `FelixKratz/formulae/borders` | — |

### 2.1 `yabairc` changes

- Keep: `layout bsp`, `split_type auto`, `window_insertion_point focused`,
  `window_placement second_child`, padding/gap, `mouse_modifier fn`, `mouse_drop_action swap`.
- Change: `auto_balance on` → `off` (dwindle keeps ratios).
- Add: `borders` launch; rules for System Settings / Calculator / dialogs → `manage=off`.
- Add: fix for the drift bug — **only after** the root cause is confirmed (task 1). Candidates:
  Ghostty setting change, a `window_resized` signal that re-applies the tile, or an app rule.
- Remove: ~60 lines of commented settings and the Aegis block.

### 2.2 Spaces

4 native Spaces per display (yabai indices 1–4 on display 1, 5–8 on display 2). Per-monitor
addressing in a helper: `index = first space of focused display + N − 1`. Extra Spaces
beyond 4 are destroyed on setup (SA) so numbering stays stable.

## 3. Cheat sheet (final)

**H** = Hyper (Right ⌘). Rule: `Super` → `H`, `Super+Shift` → `H+⇧`,
`Super+Alt`/`Super+Ctrl` → `H+fn`. ✱ = needs the scripting addition (tested in Phase 2).

### 3.1 Windows

| Keys | Action | Omarchy |
| --- | --- | --- |
| `H + ←↓↑→` | Focus in direction; crosses display at edge | `Super+Arrow` |
| `H+⇧ + ←↓↑→` | Swap in direction; moves to adjacent display at edge | `Super+Shift+Arrow`, `Super+Shift+Ctrl+Arrow` |
| `⌃⌥ + Tab` | Focus other display | `Ctrl+Alt+Tab` |
| `H + W` | Close window | `Super+W` |
| `H + T` | Toggle float/tile (float is centred) | `Super+T` |
| `H + O` | Sticky float ✱ | `Super+O` |
| `H + F` | Zoom fullscreen (stays in tiling) | `Super+F` |
| `H+fn + F` | Full width (zoom parent) | `Super+Alt+F` |
| `H + J` | Toggle split direction | `Super+J` |
| `H + L` | Cycle layout bsp → stack → float | `Super+L` |
| `H + -` / `H + =` | Shrink / grow width | `Super+Minus/Equal` |
| `H+⇧ + -` / `H+⇧ + =` | Shrink / grow height | `Super+Shift+Minus/Equal` |
| `fn + drag` / `fn + right-drag` | Move / resize; drop swaps | `Super+Mouse` |

### 3.2 Groups (yabai stacks)

| Keys | Action | Omarchy |
| --- | --- | --- |
| `H + G` | Toggle group (stack with recent / unstack) | `Super+G` |
| `H+fn + G` | Move window out of group | `Super+Alt+G` |
| `H+fn + ←↓↑→` | Move window into group in direction | `Super+Alt+Arrow` |
| `H+fn + Tab` / `H+fn+⇧ + Tab` | Next / previous in group | `Super+Alt+Tab` |
| `H+fn + 1–5` | Nth window in group (verify yabai supports stack index; else drop) | `Super+Alt+1–5` |

### 3.3 Spaces

| Keys | Action | Omarchy |
| --- | --- | --- |
| `H + 1–4` | Space N of focused display ✱ | `Super+1–4` |
| `H+⇧ + 1–4` | Move window to Space N, follow ✱ | `Super+Shift+1–4` |
| `H+fn+⇧ + 1–4` | Move window to Space N, stay ✱ | `Super+Shift+Alt+1–4` |
| `H + Tab` / `H+⇧ + Tab` | Next / previous Space on display ✱ | `Super+Tab`, `Super+Shift+Tab` |
| ``H + ` `` | Previous (recent) Space ✱ | `Super+Ctrl+Tab` |
| `H+fn+⇧ + ←→` | Move Space to display in direction ✱ | `Super+Shift+Alt+Arrow` |
| 3/4-finger swipe, `⌃ + ←→` | Native Space switch (unchanged) | `Super+Scroll` |

### 3.4 Launchers

| Keys | Action | Omarchy |
| --- | --- | --- |
| `H + Return` | New Ghostty window | `Super+Return` |
| `H+⇧ + Return` | New Brave window | `Super+Shift+Return` |
| `H+fn+⇧ + B` | New Brave private window | `Super+Shift+Alt+B` |
| `H+⇧ + F` | New Finder window | `Super+Shift+F` |
| `H+⇧ + N` | Neovim in new Ghostty window | `Super+Shift+N` |
| `H+⇧ + /` | Bitwarden | `Super+Shift+/` |
| `H+fn+⇧ + G` | WhatsApp | `Super+Shift+Alt+G` |
| `H + Space` | Raycast (alias of ⌘Space) | `Super+Space` |

### 3.5 Focus highlight

No key. JankyBorders: active border ≈4 px in the Ghostty theme accent colour, inactive
transparent, rounded corners. No inactive-window dimming (would need SA).

### 3.6 Kept as macOS defaults

`⌘C/⌘X/⌘V` copy/cut/paste · `⌘⇧5` capture · `⌃⌘Space` emoji · `⌃⌘Q` lock.

### 3.7 Deviations from Omarchy

Previous Space is ``H+` `` (not `Super+Ctrl+Tab`); `Super+Ctrl+←→` dropped (use
`H+fn+Tab`); fine/coarse resize steps dropped; mouse modifier is `fn`; no pseudo-tile, no
group tab bar; preselect unbound (Omarchy doesn't bind it); browser is Brave although the
macOS default is Safari.

## 4. Evaluation

### 4.1 Hard gates (pass/fail)

| Gate | Pass when |
| --- | --- |
| G1 SIP | Runs with `csrutil status` = enabled (C0 exempt — it is the thing being judged) |
| G2 Real Spaces | Tiled windows on native Spaces, visible in Mission Control; swipe and `⌃←→` keep the layout |
| G3 Dwindle | New window splits focused tile on its longer axis; `H+J` toggles |
| G4 Two monitors | Independent tiling; focus/move cross displays via `H(+⇧)+Arrow` |
| G5 Stable | No crash or layout corruption through the scenario script, incl. replug and sleep/wake |
| G6 Highlight | Focused window always outlined, both displays, after Space switch and window close |

### 4.2 Scores (0–3 each)

| Score | Measures |
| --- | --- |
| S1 Hotkey parity | Share of §3.1–3.4 rows working as listed (0 <50%, 1 ≥50%, 2 ≥75%, 3 ≥95%) |
| S2 Send to Space N | Successes out of 20 `H+⇧+N` across both displays (0 <10, 1 ≥10, 2 ≥17, 3 = 20) |
| S3 Setup cost | Steps, permissions, sudoers/SIP steps, config LOC (3 = brew + one file) |
| S4 Upkeep risk | Breakage after macOS point updates, from issue tracker + one re-check |
| S5 Feel | Switch/tile latency and annoyances logged in a 2–3 day daily-driver run |

### 4.3 Decision rule

If a SIP-on candidate (C2 or C3) passes G1–G6, scores ≥ 80% of C0's total and has S2 ≥ 2,
switch to it and remove the scripting addition, sudoers rule and SIP customisation.
Otherwise keep C0. C1 (OmniWM) fails G2 by design and is recorded for reference only.

## 5. Scenario script (run per candidate)

1. Open 4 windows (Ghostty ×2, VS Code, Brave) on display 1, Space 1 → check dwindle (G3).
2. `H+J`, resize ×4, `H+T`, `H+F`, `H+fn+F`, `H+L` cycle → record per-row results (S1).
3. `H+⇧+N` ×10 per display, alternating Spaces → count successes (S2).
4. Focus and swap across displays with `H(+⇧)+Arrow` (G4).
5. Swipe and `⌃←→` between Spaces; open Mission Control (G2).
6. Ghostty fullscreen toggle + relaunch → tile restores (Req 1.4).
7. Close the focused window, switch Space, switch display → border follows (G6).
8. Unplug/replug external display; sleep/wake (G5).
9. Record everything in `results.md` (one table per candidate).

## 6. Phase 2 — SIP-on candidates

Precondition: Phase 1 scored. One Recovery reboot: `csrutil enable`. Each candidate runs
alone (`yabai --stop-service`, other WMs quit).

| Candidate | Setup | ✱ bindings |
| --- | --- | --- |
| C2 yabai, no SA | Same `skhdrc`; Space focus via macOS "Switch to Desktop N" shortcuts (`⌃1–8`) | Others marked as failing |
| C3 Amethyst | `brew install --cask amethyst`; `config/amethyst/amethyst.yml` mapping the same chords; BSP layout | Throw-to-Space via its own workaround |
| C1 OmniWM | `brew install --cask omniwm`; `config/omniwm/settings.toml`; dwindle layout | Uses virtual workspaces — G2 fails |

After Phase 2: restore SIP customisation if C0 wins (Recovery, `csrutil enable --without fs
--without debug --without nvram`, matching the configuration recorded in §1) or clean up per §4.3.

## 7. Risks and checks before building

| Risk | Check |
| --- | --- |
| skhd may not see Raycast's synthesized Hyper modifiers | Bind `cmd + alt + ctrl - x` to `osascript -e 'beep'` first |
| Raycast Hyper hotkeys collide with §3 | Inventory Raycast hotkeys before writing `skhdrc` |
| `fn` layer conflicts (globe key opens emoji/dictation) | Set "Press 🌐 key to" → "Do Nothing" |
| `H+⇧+N` with Hyper may be eaten by apps | Verify in Ghostty, VS Code, Brave |
| yabai stack index selection may not exist | Drop `H+fn+1–5` if unsupported |
| Ghostty new-window command opens a new app instance | Verify `open -na` vs Ghostty's own new-window action |

## 8. Branch and files

Branch `experiment/macos-tiling-wm`. Files: `config/yabai/yabairc`, `config/yabai/bin/*`,
`config/skhd/skhdrc`, `config/borders/bordersrc`, `config/homebrew/Brewfile`, plus Phase 2
`config/amethyst/`, `config/omniwm/`. Results: `assets/specs/macos-tiling-wm-experiment/results.md`.
