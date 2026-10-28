<!-- markdownlint-disable -->
# REQUIREMENTS: macOS tiling WM experiment (Omarchy-style)

## OVERVIEW

Make macOS window management behave as close as possible to
[Omarchy](https://omarchy.org/manual/hotkeys/) (Hyprland, dwindle layout) on **real macOS
Spaces**, two monitors and trackpad gestures — then measure whether the SIP-off setup
yabai needs is worth it against SIP-on alternatives.

Normative design: [design.md](./design.md). Results: `results.md` (created in Phase 1).

**Hardware baseline:** MacBook M3 built-in display (1710×1112 pt) + Samsung LU28R55
(3008×1692 pt), macOS 27.2, "Displays have separate Spaces" on.

**Phases:**

1. **Phase 1 — C0:** yabai + scripting addition (SIP partially disabled, current state) +
   skhd hotkey layer + JankyBorders. Becomes the daily driver and the scoring baseline.
2. **Phase 2 — SIP-on comparison:** C2 (yabai, no scripting addition), C3 (Amethyst),
   C1 (OmniWM, reference only).

---

## User Roles

- **User:** drives windows, Spaces and monitors from the keyboard and trackpad.
- **Maintainer:** keeps configs under `config/<wm>/` and re-runs the scenario script after
  macOS or WM updates.

---

### REQUIREMENT 1: Dwindle tiling

**User Story:** As a user, I want new windows to split the focused tile like Hyprland
dwindle, so layouts are predictable without manual arrangement.

**Acceptance Criteria:**

1. WHEN a window opens on a managed Space THEN it SHALL split the **focused** window along
   that window's longer axis, with the new window placed right/below.
2. WHEN a window opens or closes THEN sibling split ratios SHALL NOT be rebalanced
   automatically (`auto_balance off`).
3. WHEN the user presses `H + J` THEN the focused tile's split direction SHALL toggle.
4. WHEN an app resizes its own window after being tiled (e.g. Ghostty restoring state or
   toggling non-native fullscreen) THEN the tile SHALL return to its layout frame without
   manual intervention.

---

### REQUIREMENT 2: Omarchy-shaped hotkey layer

**User Story:** As a user, I want Omarchy's chords on the Mac, so my muscle memory carries
over between machines.

**Acceptance Criteria:**

1. `Super` SHALL be the Raycast Hyper key on Right ⌘ (⌃⌥⌘, `includeShiftKey = 0`), written
   **H** below.
2. Mapping rule: Omarchy `Super` → `H`; `Super+Shift` → `H+⇧`; `Super+Alt` and
   `Super+Ctrl` → `H+fn`.
3. Every binding in the design's cheat sheet (§3) SHALL work as listed.
4. Bindings SHALL be defined in one file, `config/skhd/skhdrc`, for yabai candidates.
5. Bindings SHALL NOT collide with existing Raycast Hyper hotkeys or with macOS defaults
   kept in the cheat sheet (§3.6).
6. A keybindings overlay (`Super+K`) is **out of scope**.

---

### REQUIREMENT 3: Native Spaces and gestures

**User Story:** As a user, I want real macOS Spaces, so Mission Control, native swipes and
per-display Spaces keep working.

**Acceptance Criteria:**

1. Each display SHALL have 4 native Spaces, addressed per monitor as 1–4.
2. WHEN `H + N` is pressed THEN the Nth Space **of the focused display** SHALL be shown.
3. Native 3/4-finger swipes and `⌃ + ←/→` SHALL keep working and the tiled layout SHALL
   survive the transition.
4. "Automatically rearrange Spaces based on most recent use" SHALL be off.
5. Mission Control SHALL show tiled windows on their Spaces.

---

### REQUIREMENT 4: Two monitors

**User Story:** As a user, I want focus and moves to flow across both displays.

**Acceptance Criteria:**

1. Each display SHALL tile independently.
2. WHEN `H + Arrow` has no window in that direction THEN focus SHALL move to the adjacent
   display.
3. WHEN `H+⇧ + Arrow` has no window in that direction THEN the window SHALL move to the
   adjacent display and keep focus.
4. WHEN the external display is unplugged and replugged THEN windows SHALL re-tile without
   restarting the WM.

---

### REQUIREMENT 5: Focused-window highlight

**User Story:** As a user, I want the focused window visibly outlined, like Hyprland's
active border.

**Acceptance Criteria:**

1. The focused window SHALL always show a coloured border; unfocused windows SHALL show none.
2. The highlight SHALL follow focus across displays, Space switches and window close.
3. The highlight SHALL NOT require SIP changes (works for every candidate).

---

### REQUIREMENT 6: Evaluation and decision

**User Story:** As a maintainer, I want a scored, repeatable comparison, so the SIP
decision rests on evidence.

**Acceptance Criteria:**

1. Every candidate SHALL run the same scenario script (design §5) and be recorded in
   `results.md`.
2. Hard gates G1–G6 (design §4.1) SHALL be pass/fail; scores S1–S5 (design §4.2) 0–3.
3. Decision rule (design §4.3) SHALL be applied as written.
4. Phase 2 SHALL NOT start until Phase 1 is scored.

---

## Out of scope

Status bar (SketchyBar), theming beyond the border colour, scratchpad/quake terminal,
`Super+K` overlay, tmux/btop launchers, Omarchy utilities (screenshots, clipboard manager,
dictation, theme pickers) beyond the macOS defaults listed in design §3.6.
