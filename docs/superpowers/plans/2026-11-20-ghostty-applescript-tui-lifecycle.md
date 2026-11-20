# Ghostty AppleScript TUI Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine `yb tui` so Ghostty owns native window and terminal operations, while yabai retains
geometry and display placement behind a title-and-snapshot correlation boundary.

**Architecture:** Add a read-only Ghostty capability preflight, keep named-terminal reconciliation
and new-window creation in AppleScript object transactions, and correlate the resulting surface to
a new yabai window ID only when its `tui:<name>` title agrees. Preserve one-shot placement for
no-flash behavior, plus bounded title polling, stale-rule cleanup, and terminal-scoped exit closure.

**Tech Stack:** zsh + usage, macOS AppleScript, Ghostty 1.4.0, yabai, jq, Bun integration tests.

**Spec:** `docs/superpowers/specs/2026-11-20-ghostty-applescript-tui-lifecycle-design.md`

## Global Constraints

- The implementation remains in `config/bin/yb` and does not change the CLI, Raycast generator,
  `config/tuis.toml`, or the TUI entry schema.
- Keep `/bin/zsh -lc`, command quoting, PATH construction, `pause`, `875x600` defaults, custom
  sizes, one-TUI-at-a-time behavior, and shell-owned exit closure unchanged.
- Keep the Ghostty one-shot yabai rule. A concurrent unrelated Ghostty window may consume it, but no
  later correction may target a window without the expected `tui:<name>` title.
- A Ghostty AppleScript ID (`tab-group-*` or terminal UUID) must never be used as a yabai numeric
  window ID.
- Detect capability by a read-only AppleScript operation, not by parsing a Ghostty version string.
- Do not silently fall back to an undocumented Ghostty CLI on AppleScript failure.
- Permission/capability failure must happen before closing other TUIs, adding a rule, or launching a
  command.
- Without executable yabai, open/focus/close behavior must still succeed through Ghostty.
- If yabai correlation times out, leave the Ghostty window usable, remove the labelled rule if it
  remains, log the degraded placement, and return success unless AppleScript itself failed.
- Never touch unrelated TUI generator, Neovim, browser, generic Ghostty, or yabai-space behavior.
- Use the SOPS git wrapper; stage named paths only; use Conventional Commits with a capitalized
  description and the Copilot co-author trailer from the repository instructions.

## File Structure

- `config/bin/yb` — owns Ghostty readiness, native TUI lifecycle, yabai snapshot correlation,
  stale-rule cleanup, geometry correction, and focus settlement. Keep helpers private and TUI-local
  unless an existing generic helper already has the exact contract.
- `test/integration/bin/yb.spec.ts` — owns fake `osascript`/yabai behavior and the TUI acceptance
  tests. Expand the existing stubs; do not create a parallel launcher test harness.
- `docs/TILING.md` — documents Automation permission failure behavior and the no-yabai guarantee
  already visible in the TUI user contract.
- No new production dependency, fixture file, or generated file is needed.

## Execution Setup

- Work in the existing repository checkout at `/Users/roalcantara/.local/share/dots`; do not create
  or use a Git worktree.
- Before Task 1, create and switch to a fresh branch named
  `feat/ghostty-applescript-tui-lifecycle`.
- If the checkout already has unrelated uncommitted changes, stop and ask the operator before
  switching branches or modifying files. Never stash, overwrite, or stage unrelated work.

## Acceptance Criteria

1. A scriptable, running Ghostty opens a named TUI, names its terminal exactly `tui:<name>`, and
   activates the returned window object in the creation transaction.
2. A stopped Ghostty is explicitly opened and made ready before preflight, rule creation, or command
   launch.
3. A preflight permission/capability failure exits non-zero with an actionable AppleScript error; it
   closes no TUI and adds/removes no yabai rule.
4. Reinvoking the same TUI focuses and activates its existing window without creating a rule or new
   terminal; exact-name duplicates are reduced to one terminal.
5. Invoking another TUI closes all other `tui:*` terminals before creation.
6. Yabai correction/focus requires a window that is both absent from the pre-create ID snapshot and
   titled `tui:<name>`. A title-less new ID is never acted on.
7. A delayed title is found within the existing bounded poll; multiple new Ghostty windows remain
   ambiguous until one has the exact title.
8. AppleScript creation failure removes `tui-<name>` and exits non-zero. Correlation timeout also
   attempts rule removal but keeps the successfully created Ghostty TUI open.
9. Without yabai, native open/focus/close succeeds with no `-m` calls.
10. Existing quoting, pause, placement, display, focus-settlement, exit-close, and validation tests
    remain green.
11. The live user workflow is verified on the operator's Mac after automated gates pass. Any check
    requiring Raycast, Ghostty interaction, display changes, yabai availability changes, or System
    Settings Automation permission pauses for operator action and is not marked complete without
    that operator's direct confirmation.

## Review Focus

- Automation/TCC denial must produce a visible failure and no mutation; pin it in Task 2.
- A first launch must not let its automatically opened Ghostty window consume the TUI rule; pin it
  in Tasks 1 and 2.
- A unique but title-less yabai window must never be geometry-corrected or focused; pin it in Task 3.
- Correlation failure must remove any remaining one-shot rule and preserve the open TUI; pin it in
  Task 3.
- Missing yabai and delayed Raycast focus must preserve the current native/no-yabai and focus-settle
  contracts; pin them in Tasks 2 and 3.

---

### Task 0: Create the implementation branch

**Files:**
- Modify: none

**Interfaces:**
- Consumes: the current checkout and approved spec/plan.
- Produces: a clean `feat/ghostty-applescript-tui-lifecycle` branch in the existing repository.

- [ ] **Step 1: Inspect the current checkout**

Run:

```bash
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
g status --short
g branch --show-current
```

Expected: no unrelated modified/untracked files. If unrelated work exists, stop and ask the
operator how to proceed; do not stash, reset, commit, or stage it.

- [ ] **Step 2: Create the branch without a worktree**

Run:

```bash
g switch -c feat/ghostty-applescript-tui-lifecycle
g branch --show-current
```

Expected: the second command prints `feat/ghostty-applescript-tui-lifecycle`. Do not create a
worktree or use `git worktree`.

### Task 1: Pin the Ghostty lifecycle test contract

**Files:**
- Modify: `test/integration/bin/yb.spec.ts`

**Interfaces:**
- Consumes: the existing `yb()` helper and its fake `open`, `osascript`, and yabai binaries.
- Produces: deterministic stub controls for `GHOSTTY_RUNNING`, `GHOSTTY_PREFLIGHT_FAIL`,
  `GHOSTTY_TUI_OPEN`, `GHOSTTY_TUI_DUPLICATES`, `GHOSTTY_CREATE_FAIL`, and delayed yabai window
  snapshots `YB_STUB_WINDOWS_1`, `_2`, `_3`, and `_N`; tests that fail against the current
  implementation.

- [ ] **Step 1: Extend `OSASCRIPT` with explicit branches**

  Recognize preflight, TUI prepare/focus, and creation independently before the generic `tui:`
  branch. Record calls with stable prefixes: `osascript tui-preflight`, `osascript tui-prepare`, and
  `osascript tui-new`. `GHOSTTY_PREFLIGHT_FAIL=1` makes preflight exit 1 and prints
  `Ghostty AppleScript is not available` to stderr. `GHOSTTY_CREATE_FAIL=1` makes only
  `tui-new` exit 1. Preserve the generic Ghostty branches used by the non-TUI tests.

- [ ] **Step 2: Extend the yabai stub with sequential window snapshots**

  Read a counter from the existing log sidecar and use `YB_STUB_WINDOWS_<N>` for query N. Define
  the first `query --windows` response as the pre-create snapshot and subsequent responses as
  post-create/delayed state. For compatibility, fall back each missing numbered variable to
  `YB_STUB_WINDOWS_2`; if neither exists, emit `[]`. Do not make `YB_STUB_QUERY` stand in for
  window-list state.

- [ ] **Step 3: Add failing native-lifecycle tests**

  Add:
  - `preflights Ghostty before mutating or adding a rule`, with `GHOSTTY_PREFLIGHT_FAIL=1`.
    Assert exit 1, output contains `Ghostty AppleScript is not available`, no `tui-prepare`,
    `tui-new`, or `-m rule` call occurs.
  - `launches and preflights Ghostty before taking the rule`, with `GHOSTTY_RUNNING=false` and a
    zero launch wait. Assert call order is `open -a Ghostty` < `osascript tui-preflight` <
    `-m rule --add`.
  - `names and activates the returned creation object`. Assert the `tui-new` script contains
    `set w to new window with configuration cfg`, `set t to focused terminal of selected tab of
    w`, `set name override of t to`, and `activate window w`.
  - `reconciles a duplicate exact name while focusing once`, with `GHOSTTY_TUI_OPEN=true` and
    `GHOSTTY_TUI_DUPLICATES=2`. Assert `tui-prepare` is recorded, the script contains exact-name
    duplicate handling and `activate window`, no `tui-new` and no rule calls occur.
  - `does not mutate TUI state until preflight succeeds`. Assert no `tui-prepare` call when
    preflight fails, even if `GHOSTTY_TUI_OPEN=true`.

- [ ] **Step 4: Run the focused tests and verify the first fail**

Run: `bun test test/integration/bin/yb.spec.ts -t "tui"`

Expected: FAIL because the current script has no `tui-preflight` branch/control and still combines
lookup and mutation.

Do not commit this red checkpoint by itself. Carry it into Task 2's implementation cycle so each
commit leaves the tested branch green.

### Task 2: Implement capability preflight and native Ghostty ownership

**Files:**
- Modify: `config/bin/yb`
- Test: `test/integration/bin/yb.spec.ts`

**Interfaces:**
- Consumes: the Task 1 stub prefixes and `GHOSTTY_*` controls.
- Produces: `ghostty_tui_ready() -> 0|1`, `ghostty_tui_prepare(title) -> print true|false`, and
  `ghostty_tui_create(line, title, path) -> 0|1`. `tui_open` uses these in that order.

- [ ] **Step 1: Add failing behavior assertions for error paths**

  Add:
  - `reports a compatible running-state failure without a rule`, where
    `GHOSTTY_PREFLIGHT_FAIL=1`.
  - `preserves opens without yabai`, with the missing `DOTS_YABAI` path; assert preflight,
    prepare, and creation still occur and no `-m` command occurs.
  - `removes the rule when creation fails`, with `GHOSTTY_CREATE_FAIL=1`; assert exit 1 and one
    `-m rule --remove tui-psc`.
  - Existing-TUI focus must contain `activate window` and its matched window object must be used,
    not only `activate` at the application scope.

- [ ] **Step 2: Implement `ghostty_tui_ready()`**

  In `config/bin/yb`, add a function with no arguments:
  1. Read running state with the existing `application "Ghostty" is running` form, outside a
     `tell application` block.
  2. If false, run `open -a Ghostty` and sleep `${YB_TUI_LAUNCH_WAIT:-1}`.
  3. Run one read-only `osascript` capability probe that counts Ghostty terminals/windows.
  4. On probe failure, print
     `yb tui: Ghostty AppleScript is unavailable; allow Automation access and use Ghostty 1.3 or newer`
     to stderr, trace/log the failure, and return 1.

  The function must not close TUI terminals or add/remove a rule.

- [ ] **Step 3: Implement `ghostty_tui_prepare(title)`**

  Add a function that accepts the exact title:
  1. In one AppleScript transaction, close terminals whose names start with `tui:` and are not
     the exact requested title.
  2. Iterate selected tabs/windows for the exact title. Retain the first matching terminal/window,
     close any additional exact-name terminal duplicates, focus the retained terminal, and
     `activate window` on its owning window.
  3. Print `true` only when a retained terminal was focused; otherwise print `false`.
  4. Propagate AppleScript failure; do not reinterpret stderr or non-zero status as `false`.

  If a terminal is outside a selected tab, do not activate an uncertain window. Duplicates in normal
  `yb tui` windows are selected terminals in one-tab windows.

- [ ] **Step 4: Implement `ghostty_tui_create(line, title, path)`**

  Add a function that executes the creation transaction:
  - creates `cfg`;
  - sets `command`;
  - sets `PATH=<path>` and `YB_TUI=<title>` in `environment variables`;
  - stores `w` from `new window with configuration cfg`;
  - stores `t` from `focused terminal of selected tab of w`;
  - sets `name override of t` to the exact title;
  - runs `activate window w`.

  Redirect normal AppleScript output, preserve exit status, and print no success output.

- [ ] **Step 5: Recompose `tui_open` without changing its inputs**

  Preserve `tui_open(name, command, width, height, pause)`. Sequence it as:
  1. build title/command;
  2. `ghostty_tui_ready`;
  3. `ghostty_tui_prepare`; return 0 immediately on `true`;
  4. query yabai display and add the rule when yabai is executable;
  5. call `ghostty_tui_create`;
  6. on creation failure, remove the labelled rule when an index exists and return 1;
  7. leave correlation and geometry in the Task 3 helper boundary.

  Keep the existing `pause` insertion, shell command escaping, and `TUI_CLOSE` unchanged.

- [ ] **Step 6: Run the focused suite**

Run: `bun test test/integration/bin/yb.spec.ts -t "tui"`

Expected: PASS for lifecycle, first-launch, creation-failure, quoting, pause, missing-yabai, and
close behavior.

- [ ] **Step 7: Run the whole yb integration suite**

Run: `bun test test/integration/bin/yb.spec.ts`

Expected: PASS, including non-TUI Ghostty, Neovim, browser, and yabai cases.

- [ ] **Step 8: Commit**

```bash
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
g add config/bin/yb test/integration/bin/yb.spec.ts
g commit -m "feat(yb): Own TUI lifecycle through Ghostty AppleScript" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 3: Correlate only the named new yabai window

**Files:**
- Modify: `config/bin/yb`
- Test: `test/integration/bin/yb.spec.ts`

**Interfaces:**
- Consumes: the pre-create Ghostty ID snapshot and the post-create `tui:<name>` title.
- Produces: `tui_window(title, before_json) -> "<id> <display> <frame-width> <frame-height>"` or
  empty after the bounded poll, and `tui_place(title, before_json, index, x0, y0, width, height,
  screen-width, screen-height) -> 0`. `new_window` remains unchanged for generic launchers.

- [ ] **Step 1: Add failing snapshot-correlation tests**

  Add:
  - `rejects a new title-less Ghostty window`: `YB_STUB_WINDOWS_1=[]`,
    later responses contain one new `Ghostty` ID with title `""`; assert no `-m window --display`,
    `--resize`, `--move`, or `--focus` and one `rule --remove`.
  - `accepts the named window after a delayed title`: first post-create response is title-less, next
    is `tui:psc`; assert one focus of that ID after correlation.
  - `does not select an unrelated concurrent Ghostty window`: post-create responses contain IDs 41
    (`tui:other`) and 42 (`tui:psc`); assert all geometry/focus calls use 42.
  - `requires both newness and title`: response includes old ID 7 titled `tui:psc` plus new ID 42
    titled `""`; assert no correction/focus.
  - `times out cleanly`: all later responses are `[]`; assert exit 0, rule removal, no yabai
    geometry/focus command, and
    `~/.local/state/dots/tiling.log` contains
    `tui: could not correlate tui:psc; Ghostty window left open`.

- [ ] **Step 2: Capture the pre-create Ghostty ID snapshot**

  In `tui_open`, immediately before the rule and `ghostty_tui_create`, query
  `"$yabai" -m query --windows` and emit a compact JSON array of Ghostty IDs. If that query fails,
  keep the snapshot as `[]` but continue; a later exact-title/new-ID window can still be identified
  only after it appears. Preserve the existing no-yabai branch.

- [ ] **Step 3: Implement `tui_window(title, before_json)`**

  Poll `${YB_WAIT_STEPS:-20}` times with the existing 0.05-second interval. On each query:
  - select only `.app == "Ghostty"`;
  - reject every `.id` present in `before_json`;
  - select only `.title == title`;
  - accept only if the result is unique;
  - print `id display floored-frame-width floored-frame-height`.

  If multiple exact-title matches appear, keep polling. Never return a title-less new window. Keep
  `new_window` unchanged.

- [ ] **Step 4: Implement timeout cleanup and degraded trace**

  Add a `tui_place` boundary or equivalent flow that:
  - calls `tui_window`;
  - on no result, runs quiet `rule --remove tui-<name>`, appends
    `tui: could not correlate <title>; Ghostty window left open` through `trace()` to
    `~/.local/state/dots/tiling.log`, and returns 0;
  - on a result, applies the existing wrong-display, resize, and move corrections with current
    tolerances and point math.

  Rule removal on timeout must not remove another named rule.

- [ ] **Step 5: Preserve focus settlement**

  After placement, focus the correlated ID, sleep `${YB_TUI_SETTLE:-0.25}`, query the focused
  window, and focus the same ID once more if needed. Do not use the first/new Ghostty ID as a focus
  candidate unless `tui_window` emitted it under the exact-title/new-ID rule.

- [ ] **Step 6: Run the focused TUI suite**

Run: `bun test test/integration/bin/yb.spec.ts -t "tui"`

Expected: PASS, including delayed correlation, ambiguity rejection, timeout cleanup, geometry, and
focus settlement.

- [ ] **Step 7: Run the whole yb suite**

Run: `bun test test/integration/bin/yb.spec.ts`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
g add config/bin/yb test/integration/bin/yb.spec.ts
g commit -m "fix(yb): Correlate TUI windows by title and snapshot" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 4: Document failure behavior and complete verification

**Files:**
- Modify: `docs/TILING.md`

**Interfaces:**
- Consumes: the completed `yb tui` lifecycle and correlation behavior.
- Produces: user-facing Automation, no-yabai, and degraded-placement guarantees plus the final
  manual verification record.

- [ ] **Step 1: Update the TUIs section**

  Add no more than one paragraph stating:
  - Ghostty 1.3+ AppleScript Automation access is required for TUI lifecycle operations;
  - an AppleScript denial prints an error before mutating any TUI;
  - without yabai the TUI still opens/focuses/closes but is not placed;
  - exact placement waits for a uniquely matching `tui:<name>` window, and an ambiguous window is
    left open instead of geometry-correcting an unrelated Ghostty window.

- [ ] **Step 2: Extend the Apps validation checklist**

  Add unchecked manual cases for: first launch with Ghostty stopped; repeated invocation; another
  TUI; unrelated Ghostty concurrency; Automation denial; no-yabai; and one/multiple displays.

- [ ] **Step 3: Run the relevant repository gates**

Run:

```bash
mise run test:specs
hk check --all
mise run zsh:verify
```

Expected: all three exit 0. Stop and fix only failures caused by the TUI change before continuing.

- [ ] **Step 4: Run the real manual matrix**

  Run the real checks on the Mac with operator assistance when the agent cannot perform the UI
  action. Ask the operator to invoke Raycast, interact with the TUI, change the focused display, or
  change Automation permission as needed. The operator must confirm each human-observed result;
  command output alone does not complete a UI-only acceptance check. Verify:
  1. Ghostty stopped: `psc` opens after one explicit launch and never tiles.
  2. Existing `psc`: second invocation focuses the same terminal/window with no duplicate.
  3. Duplicate exact names: only one remains after invocation.
  4. Another TUI closes `psc`, and only the new terminal is open.
  5. One display: 875x600 and a custom configured size are centred and floating.
  6. Multiple displays: each invocation lands on the focused display.
  7. A normal Ghostty window opened concurrently is never moved/resized/focused as the TUI.
  8. Tool exit closes only the matching terminal, including split/tab safety.
  9. Automation denial fails visibly before any TUI closes or rule is added.
  10. Missing yabai still opens/focuses/closes through Ghostty.

  Replace the corresponding checklist boxes with `[x]` only for cases actually verified. Record
  any accepted deviation beside the check.

- [ ] **Step 5: Re-run the gates after checklist edits**

Run:

```bash
mise run test:specs
hk check --all
mise run zsh:verify
```

Expected: all exit 0 after the documentation edit.

- [ ] **Step 6: Commit**

```bash
g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }
g add docs/TILING.md
g commit -m "docs(tiling): Explain Ghostty TUI lifecycle guarantees" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Final Branch Check

- [ ] Confirm no file outside the three named paths changed in the implementation branch.
- [ ] Confirm implementation happened on `feat/ghostty-applescript-tui-lifecycle` in the existing
  checkout, not in a worktree.
- [ ] Run `g status --short` through the SOPS wrapper and review every entry.
- [ ] Run `g diff --check` and the three repository gates one final time.
- [ ] Confirm every live checklist item is backed by direct operator confirmation or clearly
  remains unchecked with the blocker recorded.
- [ ] Confirm `docs/TILING.md` includes only manual checks the user actually completed.
- [ ] Confirm no task weakened the exact-title/new-ID correlation or no-flash policy.
