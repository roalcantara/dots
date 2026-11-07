# Menu bar space strip (SwiftBar) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One SwiftBar menu bar item shows a numbered square per existing space (filled white = on screen and
focused, outline = on screen not focused, dimmed = elsewhere), replacing the kb Raycast strip.

**Architecture:** `yb bar` turns yabai's queries into SwiftBar output; a one-line plugin runs it; yabai signals
refresh it through SwiftBar's URL scheme; bootstrap installs and points SwiftBar at the plugin folder.

**Tech Stack:** SwiftBar 2.1 (SF Symbols titles), zsh + jq (`yb`), mise bootstrap, Bun tests; kb-raycast cleanup.

**Spec:** `docs/superpowers/specs/2026-11-07-menu-bar-strip-design.md`

## Global Constraints

- Branches: dots `feat/yabai` (PR #109), kb `feat/yabai-strip` (kb-raycast#1).
- Symbols: `<n>.square.fill` for focused and dimmed, `<n>.square` for on-screen-not-focused; `<n>` is the
  `s<n>` label, else the index. Colours `#000000,#FFFFFF` (on screen) and `#8A8A8E,#A9B0C2` (dimmed);
  `symbolize=true sfsize=17`, `sfconfig` = base64 of `{"renderingMode":"Palette","scale":"large","weight":"bold"}`.
- Built-in screen first (the `spdisplays_internal` display), then the others; `·` between screens.
- Refresh URL: `swiftbar://refreshplugin?name=spaces`.

## Review Focus

1. yabai not running: the item shows `·` and one dropdown line, never an error dump (Task 1 test).
2. One screen only: no dot (Task 1 test).
3. Unlabelled spaces (before `yb spaces` ran): numbers fall back to indices (Task 1 test).
4. A space with many apps: the dropdown line stays one line (apps joined with ", ") (Task 1 test).
5. Fresh Mac: SwiftBar's first launch must find the plugin folder without a prompt (Task 2 hook test).

---

### Task 1: `yb bar`

**Files:** Modify `config/bin/yb`; Test `test/integration/bin/yb.spec.ts`

**Interfaces:** Produces `yb bar` (stdout: SwiftBar plugin output). Consumes `DOTS_YABAI`, `DOTS_DISPLAYS_JSON`.

- [ ] **Step 1: Failing tests** (fake yabai with spaces s1 visible-not-focused, s2, s6, s7 focused, s8 with a
  Code window, s9; two screens): title is
  `:1.square: :2.square.fill: · :6.square.fill: :7.square.fill: :8.square.fill: :9.square.fill: | symbolize=true sfsize=17 sfconfig=… sfcolor=#000000,#FFFFFF sfcolor2=#8A8A8E,#A9B0C2 …`;
  second line `---`; then `Space 8 — Code | bash=… param1=space param2=8 terminal=false refresh=true sfimage=8.square.fill`;
  one screen → no `·`; unlabelled → indices; yabai missing → first line `· | …` and a "yabai is not answering" line.
- [ ] **Step 2: Run** `bun test test/integration/bin/yb.spec.ts` — FAIL.
- [ ] **Step 3: Implement** `bar` subcommand (usage `cmd "bar"`), reusing the spike's jq.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat(yb): Print the space strip for SwiftBar`.

### Task 2: SwiftBar in dots

**Files:** Create `config/swiftbar/plugins/spaces.sh`; Modify `config/homebrew/Brewfile`,
`config/mise/conf.d/{macos,dotfiles,yabai}.toml`, `config/yabai/yabairc`;
Test `test/integration/bootstrap/{yabai,macos-defaults}.spec.ts`

- [ ] **Step 1: Failing tests:** cask `swiftbar` on macOS; `/Applications/SwiftBar.app` in login items;
  `~/.config/swiftbar` linked; plugin is executable and runs `yb bar`; a `post-defaults` hook in yabai.toml
  writes `PluginDirectory $HOME/.config/swiftbar/plugins` and `SUHasLaunchedBefore true` (stub `defaults`),
  nothing off macOS; yabairc refreshes `swiftbar://refreshplugin?name=spaces` on the five events and no
  longer opens the kb yabai.screen deeplink.
- [ ] **Step 2: Run** — FAIL. **Step 3: Implement.** **Step 4: Run** — PASS, `hk check`.
- [ ] **Step 5: Commit** `feat(swiftbar): Show the space strip in the menu bar`.

### Task 3: kb cleanup (kb-raycast, `feat/yabai-strip`)

**Files:** Delete `apps/kb/src/yabai.screen.tsx` and its manifest entry; remove `toStrip`, `spaceGroups`,
`spaceMark` and their tests from `packages/core/src/yabai/snapshot.ts` if nothing else uses them.

- [ ] **Step 1:** Remove; `bun run test`, `bun run typecheck`, `bun run build` — PASS.
- [ ] **Step 2: Commit** `refactor(yabai): Leave the space strip to SwiftBar`.

### Task 4: Docs, cleanup, gates

- [ ] **Step 1:** `docs/TILING.md`: the strip section and checklist items point at SwiftBar; parts table.
- [ ] **Step 2:** Uninstall Spaceman; remove the trial's `spike_sb_*` yabai signals and scratch plugin;
  `mise bootstrap --only dotfiles,macos-defaults,task` plus a yabai restart; check the strip live.
- [ ] **Step 3:** `hk check --all`, `mise run test:specs`; commit `docs(tiling): Describe the SwiftBar strip`; push both branches.
