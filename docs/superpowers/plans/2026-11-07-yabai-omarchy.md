# Omarchy-style tiling (dots) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ten yabai spaces (s1–s5 built-in, s6–s10 external), an `fn` layer in Karabiner that drives them
Omarchy-style, a focus border, and bootstrap automation for all of it.

**Architecture:** Karabiner rules call one helper, `~/.config/yabai/wm <action> [arg]`, so every key is a
one-line rule and every behaviour is testable in bash. `~/.config/yabai/spaces` keeps the ten labelled
spaces on the right screens and runs on yabai's display signals. The Karabiner rules are generated from a
TypeScript bindings table that also writes the hotkey list the kb extension shows.

**Tech Stack:** yabai 7.1 (scripting addition), Karabiner-Elements 16.3 + karabiner.ts 1.38.0, JankyBorders,
bash + jq, Bun tests, mise bootstrap.

**Spec:** `docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md`. The menu bar strip is a separate
plan in `roalcantara/kb-raycast` (`docs/superpowers/plans/2026-11-07-yabai-strip.md`).

## Global Constraints

- Space labels are `s1`…`s10`; `fn` + 1…9 → `s1`…`s9`, `fn` + 0 → `s10`.
- Two screens: `s1`–`s5` on the built-in screen, `s6`–`s10` on the external one. One screen: all ten on it.
- The built-in screen is the display whose `_spdisplays_displayID` (from
  `system_profiler SPDisplaysDataType -json`) has `spdisplays_connection_type = spdisplays_internal`;
  that ID equals yabai's display `id`.
- Never destroy a space that holds windows.
- Every Karabiner rule requires `fn`; none uses ⌘ as its only modifier. Rules call
  `$HOME/.config/yabai/wm` (Karabiner runs `shell_command` with `/bin/sh`, which expands `$HOME`); never a
  `/Users/<name>` path baked in at build time.
- `AppleFnUsageType = 0` in `com.apple.HIToolbox`.
- `~/.config/karabiner` is linked as a whole folder, never the file alone.
- Feedback from Karabiner commands is a sound or a log line, never `osascript` notifications.
- `yabairc` uses `sudo -n` for `--load-sa`, so a stale sudoers rule never blocks login.
- macOS only: every bootstrap entry carries `os = "macos"` or exits early off Darwin.
- Repo hard rules (AGENTS.md): SOPS git wrapper, named paths only, Conventional Commits.

## Review Focus

1. Lid open, nothing plugged in: every `fn` + 1…0 still lands on a space (Task 3, "one screen" test).
2. Fewer spaces wanted on a screen whose extra space holds windows: windows move, the space survives
   (Task 3, "keeps windows" test).
3. yabai not running or the scripting addition not loaded: `wm` exits non-zero within a second and logs
   why, instead of hanging Karabiner (Task 2, "yabai missing" test).
4. Karabiner's settings window rewrites `karabiner.json` (adds devices, reorders keys): the staleness check
   compares only the `dots` profile's rules, so it does not fail spuriously (Task 5, "ignores other
   fields" test).
5. `brew upgrade yabai` outside bootstrap: the sudoers hash goes stale; login must not hang, and the next
   bootstrap rewrites the rule (Task 4 `sudo -n` test, Task 6 "hash changed" test).

---

## File Structure

| File | Responsibility |
| --- | --- |
| `config/yabai/wm` | All window and space actions behind one CLI (bash) |
| `config/yabai/spaces` | Ensure the ten labelled spaces on the right screens (bash + jq) |
| `config/yabai/yabairc` | yabai config, rules, signals (rewritten) |
| `config/yabai/setup-sa` | sudoers rule for `--load-sa` and the arm64e boot argument |
| `config/borders/bordersrc` | JankyBorders settings |
| `config/karabiner/src/bindings.ts` | The key table: one entry per binding (pure data) |
| `config/karabiner/src/build.ts` | Writes the `dots` profile rules and `hotkeys.json`; `--check` mode |
| `config/karabiner/{package.json,bun.lock,tsconfig.json}` | karabiner.ts 1.38.0 |
| `config/karabiner/karabiner.json`, `config/karabiner/hotkeys.json` | Generated, committed |
| `config/karabiner/.gitignore` | `node_modules/`, `automatic_backups/` |
| `config/mise/conf.d/yabai.toml` | LaunchAgents, repos, hooks, task checks for this feature |
| `config/mise/conf.d/{macos,dotfiles}.toml`, `config/homebrew/Brewfile` | One entry each |
| `mise.toml` | `karabiner:build` task |
| `test/integration/bootstrap/{wm,spaces,yabai,karabiner}.spec.ts` | Specs |
| `test/integration/bootstrap/support/fake-yabai.ts` | Stateful yabai stand-in for the specs |
| `docs/TILING.md`, `docs/MACOS.md`, `README.md`, `AGENTS.md` | Docs |

---

### Task 1: Packages, the fn default and the links

**Files:**
- Modify: `config/homebrew/Brewfile`, `config/mise/conf.d/macos.toml`, `config/mise/conf.d/dotfiles.toml`
- Create: `config/borders/bordersrc` (placeholder until Task 4), `config/karabiner/.gitignore`
- Test: `test/integration/bootstrap/yabai.spec.ts`

**Interfaces:**
- Produces: links `~/.config/karabiner` → `config/karabiner`, `~/.config/borders` → `config/borders`;
  the existing `pre-dotfiles` hook also moves a real `~/.config/karabiner` aside.

- [ ] **Step 1: Write the failing tests** in `yabai.spec.ts` (`describe("tiling packages and links")`):
  - `brew "FelixKratz/formulae/borders"` with `if OS.mac?`, and `cask "karabiner-elements" if OS.mac?`, are in the Brewfile; `brew "asmvik/formulae/yabai"` stays.
  - `macos.toml` declares `bootstrap.macos.defaults."com.apple.HIToolbox".AppleFnUsageType === 0`.
  - `dotfiles["~/.config/karabiner"]` and `dotfiles["~/.config/borders"]` equal `{ source: "~/.local/share/dots/config/<name>", relative: true }`.
  - Running the `pre-dotfiles` hook (reuse the `vscode-links.spec.ts` harness: stub `uname`, temp `HOME`) with a real `~/.config/karabiner/karabiner.json` moves the folder to `karabiner.pre-dots-<14 digits>` and leaves a link alone.
- [ ] **Step 2: Run** `bun test test/integration/bootstrap/yabai.spec.ts` — Expected: FAIL.
- [ ] **Step 3: Implement** the Brewfile lines (alphabetical, with the usual trailing comment), the HIToolbox default, the two links, and add `"$HOME/.config/karabiner"` to the hook's loop (the hook's `$user` loop gains a second loop over `~/.config/karabiner`; keep `DOTS_VSCODE_USER` behaviour). `.gitignore`: `node_modules/`, `automatic_backups/`.
- [ ] **Step 4: Run** the spec and `bun test test/integration/bootstrap` — Expected: PASS.
- [ ] **Step 5: Commit** `feat(macos): Install the tiling tools and set the fn key`.

### Task 2: The `wm` helper

**Files:**
- Create: `config/yabai/wm` (executable, bash, `set -euo pipefail`)
- Test: `test/integration/bootstrap/wm.spec.ts`

**Interfaces:**
- Produces: `wm <action> [arg]`. Actions and the yabai calls they make (`Y` = `yabai -m`):

| Action | Calls |
| --- | --- |
| `space <1-10>` | `Y space --focus s<n>` |
| `move <1-10>` / `move-stay <1-10>` | `Y window --space s<n>` then (move only) `Y space --focus s<n>` |
| `space-next` / `space-prev` / `space-recent` | `Y space --focus next\|prev\|recent`, falling back to `first`/`last` on this screen |
| `focus <west\|east\|north\|south>` | `Y window --focus <dir>`, else `Y display --focus <dir>` |
| `swap <dir>` | `Y window --swap <dir>` |
| `send-display <west\|east>` | `Y window --display <dir>` then `Y display --focus <dir>` |
| `display-other` | `Y display --focus recent` |
| `split` | `Y window --toggle split` |
| `layout <next\|prev>` | read `Y query --spaces --space` `.type`, set the next of `bsp → stack → float` with `Y space --layout` |
| `float` / `pin` | `Y window --toggle float`; pin = float + `--toggle sticky` + `--sub-layer above` |
| `zoom <full\|parent>` | `Y window --toggle zoom-fullscreen\|zoom-parent` |
| `scratchpad` / `scratchpad-send` | `Y window --toggle scratch` / `Y window --scratchpad scratch` |
| `resize <w-\|w+\|h-\|h+>` | w-: `--resize right:-40:0`, else `left:40:0`; w+: `right:40:0`, else `left:-40:0`; h-: `bottom:0:-40`, else `top:0:40`; h+: `bottom:0:40`, else `top:0:-40` (the second call only when the first exits non-zero) |
| `stack <dir>` / `stack-next` / `stack-prev` | `Y window --stack <dir>` / `Y window --focus stack.next\|stack.prev` |
| `balance` / `rotate` / `close` | `Y space --balance` / `Y space --rotate 90` / `Y window --close` |
| `app <name>` | `open -a "<name>"` |
| `nvim` | `open -na Ghostty --args -e nvim` |
| `system` / `hotkeys` | `open "raycast://extensions/roalcantara/kb/system.screen"` / `open "raycast://extensions/roalcantara/kb/hotkeys.screen"` (both commands come from the kb plan) |

  `wm` sets `PATH=/opt/homebrew/bin:/usr/bin:/bin`, honours `DOTS_YABAI` (yabai path) for tests, and
  appends failures to `~/.local/state/dots/wm.log`.

- [ ] **Step 1: Write the failing tests**: a stub `yabai` on `PATH` (via `DOTS_YABAI`) records its argv to a file; for each table row assert the exact calls; `space 0` and `space 11` exit 2 with "usage"; `move 6` calls `window --space s6` then `space --focus s6`, `move-stay 6` only the first; when the stub for `window --focus east` exits 1, `focus east` calls `display --focus east`; **yabai missing** (`DOTS_YABAI=/nonexistent`): exit 1 in under 1 s and one line in the log.
- [ ] **Step 2: Run** `bun test test/integration/bootstrap/wm.spec.ts` — Expected: FAIL.
- [ ] **Step 3: Implement `wm`** as a `case` over the action, one function per row.
- [ ] **Step 4: Run** the spec and `shellcheck config/yabai/wm` — Expected: PASS, clean.
- [ ] **Step 5: Commit** `feat(yabai): Add the wm helper the fn layer calls`.

### Task 3: The `spaces` script

**Files:**
- Create: `config/yabai/spaces` (executable, bash + jq), `test/integration/bootstrap/support/fake-yabai.ts`
- Test: `test/integration/bootstrap/spaces.spec.ts`

**Interfaces:**
- Consumes: `DOTS_YABAI` like `wm`; `DOTS_DISPLAYS_JSON` (a file standing in for `system_profiler` output) for tests.
- Produces: `spaces` — idempotent; exit 0 when the layout already matches.
- `fake-yabai.ts`: `bun fake-yabai.ts <state.json> -m ...` implements `query --displays|--spaces|--windows`, `space --create <display-id>`, `space <sel> --destroy`, `space <sel> --display <display-id>`, `space <sel> --label <l>`, `window <id> --space <sel>`, mutating `state.json`. A shell shim `fake-yabai` passes the state path.

Algorithm (the part the tests do not fully determine): resolve the built-in display; wanted = `{builtin: 5, external: 5}` with two screens or `{builtin: 10}` with one. Move surplus spaces from the built-in screen to the external one (`space --display`) before creating any; create missing spaces; for each screen with too many, move windows from the surplus spaces to that screen's last kept space, then destroy them; finally label in display order (built-in first) by space index: `s1…`.

- [ ] **Step 1: Write the failing tests** against the fake: two screens with 1+1 spaces → 5+5, labels `s1`–`s5` on the built-in ID, `s6`–`s10` on the external one; **one screen** with 3 spaces → 10, labelled `s1`–`s10`; one screen with 10 → plug the external in (add it to state) → 5+5 with `s6`–`s10` moved, not recreated (same space `id`s); **keeps windows**: built-in with 7 spaces, space 7 holds window 42 → window 42 ends on a kept space and no space with windows was destroyed; second run makes no mutating call; the external screen listed first by yabai still gets `s6`–`s10`.
- [ ] **Step 2: Run** `bun test test/integration/bootstrap/spaces.spec.ts` — Expected: FAIL.
- [ ] **Step 3: Implement `spaces`** per the algorithm.
- [ ] **Step 4: Run** the spec and shellcheck — Expected: PASS, clean.
- [ ] **Step 5: Commit** `feat(yabai): Keep ten labelled spaces across one or two screens`.

### Task 4: yabairc, borders and the services

**Files:**
- Modify: `config/yabai/yabairc`; Create: `config/borders/bordersrc`, `config/mise/conf.d/yabai.toml`
- Test: `test/integration/bootstrap/yabai.spec.ts`

**Interfaces:**
- Consumes: `spaces` (Task 3).
- Produces: LaunchAgents `dev.mise.yabai` and `dev.mise.borders`.

`yabairc` keeps the current layout values (bsp, padding 12, gap 6, `auto_balance on`, `window_placement second_child`, mouse `fn` move/resize/swap) and changes: `focus_follows_mouse off`, `window_shadow float`, `window_animation_duration 0.0`; `sudo -n yabai --load-sa` (and the same in the `dock_did_restart` signal); signals `display_added`, `display_removed`, `display_moved` → `$HOME/.config/yabai/spaces`; the kb refresh on `space_changed`, `display_changed`, `window_created`, `window_destroyed` with `raycast://extensions/roalcantara/kb/yabai.screen?launchType=background`; `manage=off` rules for System Settings, Calculator, Archive Utility, Raycast, Karabiner-Elements, and windows with `subrole="^AXDialog$"`; runs `spaces` once at the end. Drop the commented Aegis block.

`bordersrc`: `borders active_color=0xffe1e3e4 inactive_color=0x00000000 width=5.0 style=round hidpi=on`.

`yabai.toml`: `[bootstrap.macos.launchd.agents.yabai]` program `/opt/homebrew/bin/yabai`, `keep_alive = true`, `environment = { PATH = "/opt/homebrew/bin:/usr/bin:/bin" }`; `.borders` program `/opt/homebrew/bin/borders`, same keys.

- [ ] **Step 1: Write the failing tests**: `sh -n` and `shellcheck -s sh` pass on `yabairc` and `bordersrc`; `yabairc` contains `sudo -n yabai --load-sa` and no bare `sudo yabai`; `focus_follows_mouse off`; each listed signal event appears with the right action; each listed app has `manage=off`; the two agents are declared as above.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** the three files.
- [ ] **Step 4: Run** the spec, `hk check` on the files — Expected: PASS.
- [ ] **Step 5: Commit** `feat(yabai): Run yabai and borders as services with the new rules`.

### Task 5: The Karabiner fn layer

**Files:**
- Create: `config/karabiner/{package.json,bun.lock,tsconfig.json}`, `config/karabiner/src/{bindings,build}.ts`, generated `config/karabiner/{karabiner.json,hotkeys.json}`
- Modify: `mise.toml` (task `karabiner:build`)
- Test: `test/integration/bootstrap/karabiner.spec.ts`

**Interfaces:**
- Consumes: `wm` actions (Task 2).
- Produces:
  - `export type Binding = { key: KeyCode; mods: Modifier[]; action: string; arg?: string; label: string; group: 'Spaces' | 'Windows' | 'Layout' | 'Apps' | 'System' }` and `export const bindings: readonly Binding[]` in `bindings.ts` (pure data; `mods` excludes `fn`, which `build.ts` always adds).
  - `build.ts [--check]`: writes the `dots` profile rules into `config/karabiner/karabiner.json` with `writeToProfile({ name: 'dots', karabinerJsonPath })`, one rule per group, each manipulator `to: [{ shell_command: '$HOME/.config/yabai/wm <action> <arg>' }]`, except Page Up/Down which map to `page_up`/`page_down` key codes; writes `hotkeys.json` as `[{ keys: "fn ⇧ 1", label, group }]`. `--check` builds in memory and exits 1 naming the first difference.
  - `mise run karabiner:build` = `bun install --frozen-lockfile --cwd config/karabiner && bun config/karabiner/src/build.ts`.
  - The seed `karabiner.json` has one profile `dots`, `selected: true`, `virtual_hid_keyboard.keyboard_type_v2 = "ansi"`.

The bindings are exactly the spec's key table (Key layout section), with `fn` + ⌥↑/↓ → Page Up/Down and `fn` + Esc → `wm system`, `fn` + k → `wm hotkeys`.

- [ ] **Step 1: Write the failing tests**: `build.ts --check` exits 0 on the committed files; after changing one label in a temp copy it exits 1; **ignores other fields**: adding a `devices` array and another profile to a temp `karabiner.json` keeps `--check` at 0; every manipulator has `fn` in `mandatory`; no two manipulators share `key_code` + sorted modifiers; `fn`+1…0, `fn`+⇧+1…0 and `fn`+⇧⌥+1…0 call `wm space|move|move-stay 1…10`; no binding on ⌘ alone; `hotkeys.json` has one entry per binding.
- [ ] **Step 2: Run** `bun test test/integration/bootstrap/karabiner.spec.ts` — Expected: FAIL.
- [ ] **Step 3: Implement** `bindings.ts`, `build.ts`, the task; run `mise run karabiner:build` to generate the two JSON files.
- [ ] **Step 4: Run** the spec; tombi/taplo on `mise.toml` — Expected: PASS.
- [ ] **Step 5: Commit** `feat(karabiner): Generate the fn layer from a bindings table`.

### Task 6: Scripting addition setup

**Files:**
- Create: `config/yabai/setup-sa` (bash); Modify: `config/mise/conf.d/yabai.toml` (hook)
- Test: `test/integration/bootstrap/yabai.spec.ts`

**Interfaces:**
- Produces: `setup-sa` — honours `DOTS_SUDO`, `DOTS_YABAI`, `DOTS_CSRUTIL`, `DOTS_NVRAM` stubs; `[bootstrap.hooks.post-packages]` in `yabai.toml` runs it (combined with the existing hook in `bootstrap.toml`).

Behaviour: off Darwin, exit 0. Rule line: `<user> ALL=(root) NOPASSWD: sha256:<shasum -a 256 of yabai> <yabai path> --load-sa`. Write `/etc/sudoers.d/yabai` (0440 root:wheel) through `visudo -cf` on a temp file, only when the current file differs; if `csrutil status` shows SIP fully enabled, print the Recovery command and skip the boot argument; otherwise add `-arm64e_preview_abi` to `nvram boot-args` when missing and say a reboot is needed. Never fail the bootstrap: warn and exit 0.

- [ ] **Step 1: Write the failing tests** (stubs record calls): first run writes the rule with the stub hash; second run with the same hash makes no `sudo` write; **hash changed** → rewrites; invalid rule (stub `visudo` exits 1) → no install, warning, exit 0; SIP enabled → no `nvram` call, message contains `csrutil enable --without fs --without debug --without nvram`; boot-arg present → no `nvram` write.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** `setup-sa` and the hook.
- [ ] **Step 4: Run** the spec and shellcheck — Expected: PASS.
- [ ] **Step 5: Commit** `feat(yabai): Set up the scripting addition from bootstrap`.

### Task 7: kb clone, bootstrap checks, docs, gates

**Files:**
- Modify: `config/mise/conf.d/bootstrap.toml` (a `# tiling-checks: begin/end` snippet in the bootstrap task; `[bootstrap.repos]` has no `os` key and would clone in the Linux images too, so the snippet clones kb)
- Create: `docs/TILING.md`; Modify: `docs/MACOS.md`, `README.md`, `AGENTS.md`
- Test: `test/integration/bootstrap/yabai.spec.ts`

Checks snippet (macOS desktop only, warnings only): `~/Work/kb` missing → `git clone git@github.com:roalcantara/kb-raycast.git ~/Work/kb` (warn on failure); SIP fully enabled → the Recovery command; `yabai -m query --spaces` fails → "grant Accessibility to yabai"; always one line pointing at `docs/TILING.md` for the Karabiner approvals and the kb registration (`bun run --cwd ~/Work/kb dev` once).

`docs/TILING.md`: the key table (generated hotkeys are the source; the doc links `config/karabiner/src/bindings.ts`), spaces and screens, the four manual steps, troubleshooting (`wm.log`, `sudo -n yabai --load-sa`, re-run `mise run karabiner:build`).

- [ ] **Step 1: Write the failing tests**: with a stub `git`, a missing `~/Work/kb` is cloned from `git@github.com:roalcantara/kb-raycast.git` and an existing one is left alone; the checks snippet sits after `# ssh-keychain: end` and, with stubs, prints each warning in its condition and nothing when all pass.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** the entry, the snippet and the docs; link `docs/TILING.md` from README and AGENTS.
- [ ] **Step 4: Gates**: `hk check --all`, `mise run test:specs`, `mise bootstrap --only dotfiles,macos-defaults,macos-launchd-agents,task` on this Mac, then walk every row of the key table on both screens and with the lid alone.
- [ ] **Step 5: Commit** `docs(tiling): Document the fn layer and its setup`, tick this plan, push, open the PR.
