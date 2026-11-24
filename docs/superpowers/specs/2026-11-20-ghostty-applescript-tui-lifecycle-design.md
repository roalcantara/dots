# Ghostty AppleScript TUI lifecycle — design

## Intent

Simplify the TUI launch lifecycle by letting Ghostty own the operations expressed directly by its
AppleScript API—creating and naming a terminal, focussing existing terminals, and closing terminal
surfaces—while retaining yabai only for macOS window geometry and display placement.

This is a refinement of the existing TUI launcher, not a replacement for its Raycast command
generation or one-TUI-at-a-time behavior. The current implementation already uses Ghostty's native
AppleScript API. The change is to make object ownership explicit, reduce fragile rediscovery, and
define compatible fallbacks when AppleScript identity cannot be correlated with yabai.

## Goals

- Use the object returned by `new window with configuration cfg` within the creation AppleScript.
- Keep Ghostty object identity as the primary identity for native focus and close operations.
- Preserve exact floating size, centring, focused-display placement, and re-focus behavior through
  yabai.
- Correlate the created Ghostty surface to a yabai window reliably enough to tolerate immediate
  Raycast focus changes and concurrent window activity.
- Preserve current behavior when yabai is unavailable.
- Detect incompatible or permission-blocked AppleScript explicitly and avoid leaving a stale
  one-shot yabai rule.
- Add focused automated tests and a real manual verification matrix.

## Non-goals

- Replacing yabai with AppleScript for window geometry or display placement.
- Treating a Ghostty terminal UUID as a yabai window ID.
- Changing the Raycast generator, `config/tuis.toml`, or the TUI entry schema.
- Changing Neovim, browser, or generic Ghostty window launchers.
- Changing yabai space synchronization.
- Removing the title-based compatibility path in the first rollout.

## Anti-goals

- A refactor that opens duplicate windows while an existing named TUI is open.
- Geometry rediscovery correcting an unrelated Ghostty window.
- Closing the entire Ghostty window when the intended TUI shares a window with another surface.
- A silent partial success where the TUI opens but a stale rule remains.
- Depending on an exact Ghostty version when an operation-level capability check is possible.

The selected concurrency policy prioritizes no initial tiled flash. The one-shot yabai rule still
matches by Ghostty app identity. If an unrelated Ghostty window is created in the same instant, it
can consume the rule; correlation must never issue geometry correction against that wrong window
afterward. This rare rule-consumption race is accepted to preserve the uninterrupted floating
appearance of the TUI.

## Constraints

- The implementation remains in `config/bin/yb`; the existing Bun integration suite continues to
  exercise it through fake `osascript` and yabai commands.
- Ghostty 1.4.0 exposes its created window as a Ghostty object, with a `tab-group-*` window ID and a
  UUID terminal ID. A running-machine probe showed that yabai exposes a separate numeric window ID,
  so object identity cannot be passed directly across the APIs.
- AppleScript access may be blocked by macOS Automation/TCC permission. The launcher must surface a
  useful failure rather than interpret permission denial as "no existing TUI."
- Ghostty scripting support is a macOS-only feature and is introduced in Ghostty 1.3.0, but behavior
  should be detected by capability rather than by parsing a version string.
- A yabai one-shot rule must be installed only after Ghostty is running and must be removed when
  creation fails.
- Existing command quoting, `/bin/zsh -lc` execution, PATH construction, pause behavior,
  `875x600` defaults, custom sizes, and shell-owned exit closure remain unchanged.
- This work runs through `yb tui` without changing user-facing command generation.

## Approaches

### 1. Hybrid native identity + compatibility fallback — chosen

AppleScript retains the object returned from `new window with configuration cfg`, uses that object
to set `name override`, and activates it. The process also records the new terminal name for
shell-owned closure. For yabai, the launcher first uses a focused before/after window snapshot and
the expected `tui:<name>` title to correlate the corresponding numeric window ID. If that
correlation is inconclusive, it uses the existing title polling path and records a bounded
degraded result.

This is the chosen approach because each application owns the identity and operations it can
actually perform. It avoids an invalid AppleScript-to-yabai ID conversion while still removing
unnecessary rediscovery from Ghostty-controlled operations. The compatibility path can later be
removed only after real use demonstrates that snapshot-plus-title correlation is sufficient.

### 2. Native AppleScript only

Use the AppleScript window object for focus and placement, without yabai rediscovery.

Rejected because Ghostty's scripting dictionary does not provide the exact yabai placement controls
already required: focused-display selection, one-shot floating, point-sized resize and centring, and
the race with Raycast restoring focus.

### 3. Snapshot-diff yabai ownership

Snapshot yabai IDs before creation and identify the new Ghostty window solely by its absence from
the first snapshot.

Rejected as the sole strategy because another Ghostty window can open concurrently, producing a
valid but wrong match. A before/after set is useful as supporting evidence, but must be combined
with the named title.

## Design

### 1. Capability and preflight

Keep the AppleScript operations in the TUI-specific path. Before altering TUI state, distinguish:

- Ghostty is not running.
- Ghostty is running and scriptable.
- Scripting is denied or the installed Ghostty does not support the required dictionary.

Feature detection probes a small, read-only operation through the same scripting API. It must not
use the result of a failed lookup to decide that no TUI exists. On a scripting error, the launcher
prints a concise error naming AppleScript access and exits non-zero before adding a yabai rule or
altering any TUI state.

The design does not require a separate `macos-applescript` setting if the installed Ghostty
dictionary is available. Existing permission and configuration documentation should explain that
macOS Automation approval may be required for the process invoking `osascript`.

Determine whether Ghostty is running with a non-`tell application` query so the check itself cannot
launch Ghostty as a side effect. Launch it explicitly only after a successful running-state check.

### 2. Existing TUI behavior

Continue to enforce one named TUI at a time in one AppleScript transaction:

1. Find an existing terminal whose name is exactly `tui:<name>`.
2. Close other terminals whose names start with `tui:`.
3. If more than one requested terminal exists, retain the first and close the duplicates.
4. If the requested terminal exists, obtain its owning window, focus the terminal, and activate that
   window.
5. Return without taking a yabai rule.

The operation is terminal-scoped. A terminal close removes a TUI surface without assuming that its
window cannot contain another tab or split.

### 3. New window creation

After Ghostty is running and the focused display has been read, add the existing one-shot yabai rule.
Create the new window through one AppleScript transaction:

```applescript
set cfg to new surface configuration
set command of cfg to ...
set environment variables of cfg to ...
set w to new window with configuration cfg
set t to focused terminal of selected tab of w
set name override of t to ...
activate window w
```

The AppleScript object is used for the native operations and is not serialized as a yabai ID. The
terminal name `tui:<name>` remains the cross-process closure handle because the terminal process
cannot retain an in-memory AppleScript object.

If creation fails, remove the labelled one-shot rule, report the error, and exit non-zero. Normal
creation emits no user-facing success output.

### 4. Yabai correlation

Capture the set of existing Ghostty yabai window IDs immediately before creation. After creation,
the placement phase obtains the numeric yabai window using these signals, in order:

1. A Ghostty window whose ID is new and whose title is `tui:<name>`.
2. The existing bounded title poll for `tui:<name>` while maintaining the snapshot.

Do not correlate on first/new window order alone, and do not accept a title-less unique new window.
Ambiguous results continue polling until the bound is exhausted, then leave the window open without
issuing geometry commands against an uncertain target. Attempt to remove the one-shot rule at the
end of every timeout path; removal is expected to be a no-op if another window already consumed it.
A later change may remove fallback 2 only after both integration and manual results show it is
unnecessary.

The existing one-shot rule remains the fast placement path. Yabai correction after discovery remains
limited to a wrong display or a size outside the current tolerance.

### 5. Focus and settlement

Keep Ghostty's `activate window w` as the primary activation action. Use yabai to re-focus the
correlated numeric window after Raycast settles, then perform the existing bounded second focus
check when another app reclaimed focus.

Yabai focus is a corrective step, not the source of the Ghostty window identity.

### 6. Exit closure

Keep shell-owned exit closure. The command passed to Ghostty closes every terminal whose name exactly
matches `$YB_TUI`.

Closing a terminal is intentional: window closure can be too broad if future Ghostty behavior permits
additional surfaces in the same window. The current exact name prevents a completed TUI from
closing a different TUI.

### 7. No-yabai and incompatible-Ghostty behavior

- Without yabai, Ghostty still opens and manages the named terminal, including native focus and
  shell-owned closure.
- If the required AppleScript capability is unavailable, do not silently fall back to an
  undocumented CLI mechanism. Fail with a short actionable message.
- If creation succeeds but yabai correlation is unavailable, leave the Ghostty window open and
  usable. Log the placement degradation through the existing `yb` trace mechanism and remove no
  broader state.
- The first rollout keeps title polling. A later cleanup can remove it only when its tests and
  manual verification show that snapshot-plus-title correlation is stable.

## Test strategy

Extend `test/integration/bin/yb.spec.ts` with stub support for distinct AppleScript results and
window snapshots. Add focused cases for:

- Ghostty not running and the first Ghostty window not consuming the TUI rule.
- Existing named TUI focus with no duplicate and no rule.
- Closing another TUI before opening the requested one.
- Capturing and naming the returned Ghostty window object, then focussing and activating through
  that same object in one AppleScript transaction.
- A new yabai ID with the expected title.
- A new yabai ID whose title arrives after the first poll.
- Multiple new Ghostty windows, rejecting ambiguous snapshot-only matches.
- A unique new Ghostty window with no matching title, which must not be corrected.
- Duplicate named terminals, retaining one and closing the duplicates.
- Correct default and custom geometry, focused display, and multi-display correction.
- Pause and command quoting preservation.
- Shell exit closing only the matching terminal.
- AppleScript denial before rule creation.
- AppleScript creation failure and stale rule removal.
- Yabai correlation timeout, stale-rule removal, and no geometry command against an uncertain
  window.
- Missing yabai with successful native creation.
- An incompatible Ghostty dictionary with no fallback to an undocumented command.

Run at least:

- `mise run test:specs`
- `hk check --all`
- `mise run zsh:verify`

## Manual verification

After implementation, verify on the real Mac:

1. Grant or confirm Automation permission, then run `yb tui` while Ghostty is stopped.
2. Run the same TUI twice and confirm the second invocation focuses without duplicating.
3. Open a different TUI and confirm only the first `tui:*` terminal closes.
4. Verify terminal exit closes the intended surface, with no effect on another Ghostty terminal or
   split.
5. Verify one display: 875x600 default, custom size, centring, floating, and correct focus.
6. Verify multiple displays: open from each focused display and confirm no cross-display landing.
7. Cover Raycast returning focus after invocation and a 0.25-second follow-up reclaim.
8. Revoke or simulate denial of Automation permission and confirm a clear failure and no stale rule.
9. Temporarily hide yabai and confirm the terminal still opens, focuses, and closes.
10. Run with no pre-existing Ghostty windows and with an unrelated Ghostty window open.

## Rollout and rollback

Roll out in three bounded phases:

1. **Probe and characterize.** Capture the installed AppleScript dictionary evidence where
   available, plus read-only identity and failure results. Make no launcher behavior change.
2. **Native-owned lifecycle.** Retain Ghostty objects for create/name/focus, add preflight failure
   handling, and introduce snapshot-plus-title yabai correlation while preserving title polling.
3. **Fallback evaluation.** After real-use evidence, decide separately whether title polling can be
   removed. Do not bundle that cleanup with the lifecycle change.

Rollback means restoring the prior `tui_open` correlation and error path while retaining tests and
documentation of the probe. No TOML, Raycast, or generic Ghostty behavior needs to move, so rollback
is isolated to `yb` and its TUI tests.

## What is left to the builder

- Choose the smallest AppleScript return format that lets the zsh caller distinguish success,
  failure type, and existing-window focus without parsing human-readable properties.
- Choose trace wording for ambiguous yabai correlation and timing degradation.
- Decide whether the capability preflight and lifecycle transaction are separate `osascript`
  calls or one call with a typed result.
- Preserve the test stubs' current readability while allowing scripted failures and delayed
  correlation.
