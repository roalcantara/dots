<!-- markdownlint-disable -->
# xc-fabric — Tasks

**Date:** 2026-05-02
**Status:** Ready for implementation
**Requires:** `specs/xc-fabric/design.md`, `specs/xc-fabric/requirements.md`

---

## Skills to invoke

Load before starting any task:

```txt
~/.cursor/skills/tdd-workflow/SKILL.md
~/.cursor/skills/bdd-scenarios/SKILL.md
~/.cursor/skills/bun-development/SKILL.md
~/.cursor/skills/bash-scripting/SKILL.md
```

---

## TDD Cycle (apply to every task)

1. Write failing spec first (`bun:test`) → confirm RED
2. Implement minimal code to pass → confirm GREEN
3. Refactor while keeping GREEN
4. Run `shellcheck xc-fabric` → zero errors
5. Commit following git commit guidelines

**Do not start the next task until every checkbox in the current task is ticked.**

---

## Shared test helpers

Add this block once at the top of `tests/xc-fabric.spec.ts` before any `describe`:

```typescript
#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) =>
  selected !== "" && selected !== id;
const script =
  Bun.env.XC_FABRIC ?? join(import.meta.dir, "..", "xc-fabric");

// Absolute path to pattern fixtures used across scenarios
const fixturesDir = join(
  import.meta.dir,
  "fixtures",
  "xc-fabric",
  "patterns"
);

// Creates a temp dir with named stub executables; caller must rmSync in finally.
function makeTmpStubs(stubs: Record<string, string>): string {
  const tmp = mkdtempSync(join(tmpdir(), "xc-fabric-spec-"));
  for (const [name, body] of Object.entries(stubs)) {
    writeFileSync(join(tmp, name), body, { mode: 0o755 });
  }
  return tmp;
}

// Minimal stubs: fabric present, gum present, glow/bat absent.
// Satisfies _boot_check_deps with no warnings.
const minimalStubs = {
  fabric: "#!/bin/sh\necho FABRIC_OUTPUT",
  gum:    "#!/bin/sh\nexit 0",
};

// Stubs without gum — exercises the plain-text fallback paths.
const noGumStubs = {
  fabric: "#!/bin/sh\necho FABRIC_OUTPUT",
};
```

**Fixture files to create once** at `tests/fixtures/xc-fabric/patterns/`:

```text
summarize/system.md        → first line: "Summarize content into key points."
extract_wisdom/system.md   → first line: "Extract insights and wisdom from text."
youtube_summary/system.md  → first line: "Summarize a YouTube video transcript."
```

---

## TASK 1: Script stub + spec scaffold + mise tasks

- [ ] 1.1 Create `xc-fabric` script with help handler only
  - Add `#!/usr/bin/env zsh` shebang and full `#?` help block (see Req-1; document all subcommands: default, `run`, `ls`, `update`, `show`, `strategies`, `scrape`)
  - Add `set -euo pipefail`
  - Handle `-h|--help` via **top-level `case "${1:-}"` before `main`** (same pattern as `xc-git-log-fzf`) OR as first branch inside `main` **without** calling `_boot_check_deps`
  - Run `chmod +x xc-fabric`
  - _Requirements: Req-1_

- [ ] 1.2 Create fixture files
  - Create `tests/fixtures/xc-fabric/patterns/` with three subdirectories
  - Each `system.md` contains one plain-text description line (see above)
  - _Requirements: Req-4, Req-6_

- [ ] 1.3 Create `tests/xc-fabric.spec.ts` with `help` scenario
  - Add shared helpers block (see above)
  - Add `help` scenario: assert exit 0, stdout contains `"xc-fabric"` and `"Usage:"`
  - Assert both `-h` and `--help` produce exit 0
  - _Requirements: Req-1, AC-1.1_

- [ ] 1.4 Add `xc-fabric:specs` and `setup` tasks to `mise.toml`
  - Follow exact same structure as `xc-git-log-fzf:specs` for `xc-fabric:specs`
  - Set `run = "bunx bun test tests/xc-fabric.spec.ts"`
  - List all **22** scenario IDs in `usage` block `choices` (see `design.md` §10)
  - Add `setup` per `design.md` §11 (`fabric-ai`, `bat`, `fzf`, Linux `xclip`)
  - **Do not** add `fabric-ai` to `[tools]` unless the repo owner chooses to — plan leaves `[tools]` unchanged
  - _Requirements: all_

**Completion criteria:**

- [ ] After 1.4 exists: `mise run xc-fabric:specs --scenario help` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add script stub with help handler and specs scaffold`

---

## TASK 2: `_boot_*` + `_ui_*` + `_boot_check_deps` + fzf-first `_ui_filter`

- [ ] 2.1 Implement `_boot_caps`, `_boot_clip`, `_boot_paths`
  - `_CAPS` associative array for `fabric-ai`, `gum`, `glow`, `bat`, `fzf`
  - `_CLIP_CMD` argv array for clipboard; `_PATTERNS_DIR` string
  - _Requirements: Req-2_

- [ ] 2.2 Implement `_ui_clip`
  - Executes cached `_CLIP_CMD` per `design.md` §6.0
  - _Requirements: Req-2, AC-2.14–AC-2.15_

- [ ] 2.3 Implement `_ui_log` and level wrappers
  - `_ui_log_info`, `_ui_log_warn`, `_ui_log_error`: return after `_ui_log` (do **not** exit the script)
  - `_ui_log_fatal`: `_ui_log fatal "$@"` then `exit 1`
  - _Requirements: Req-2, AC-2.4–AC-2.8_

- [ ] 2.4 Implement interaction wrappers except `_ui_filter`
  - `_ui_prompt`, `_ui_confirm`, `_ui_spinner`, `_ui_table` per `design.md` Table A
  - _Requirements: Req-2, AC-2.9–AC-2.12_

- [ ] 2.5 Implement `_ui_filter` (3-tier: fzf → gum filter → read)
  - fzf path: `--preview-window 'right:60%:wrap'`, binds `ctrl-/`, `ctrl-o`, `ctrl-r`, `?` per `design.md` §6.0
  - Resolve `reload` subshell issue (`export -f` or inline pipeline — see design note)
  - _Requirements: Req-2, AC-2.13, Req-4_

- [ ] 2.6 Implement `_boot_check_deps` and wire into `main`
  - Req-3 AC-3.1–AC-3.4 only (no former “glow present → continue” no-op)
  - _Requirements: Req-3_

- [ ] 2.7 Write `missing_fabric` spec scenario
  - `makeTmpStubs({ gum: "#!/bin/sh\nexit 0" })` — fabric absent, gum present
  - Assert exit code **1**; stderr contains `"fabric"`
  - _Requirements: Req-3, AC-3.1_

**Completion criteria:**

- [ ] `mise run xc-fabric:specs --scenario missing_fabric` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add helpers, clipboard, fzf picker, and dependency guard`

---

## TASK 3: Pattern helpers + `ls` + `ls_table` scenario

- [ ] 3.1 Implement `_boot_paths` / `_PATTERNS_DIR`
  - Set `_PATTERNS_DIR="${FABRIC_PATTERNS_DIR:-${HOME}/.config/fabric/patterns}"` once in `main`
  - _Requirements: Req-4, Req-6_

- [ ] 3.2 Implement `_pattern_list` helper
  - Iterate `"${_PATTERNS_DIR}"/*/` — skip gracefully if dir missing
  - Extract description from `system.md` per design
  - _Requirements: Req-4, Req-6_

- [ ] 3.3 Implement `_url_is_youtube` and `_url_pattern_implies_yt` helpers
  - _Requirements: Req-5, Req-7_

- [ ] 3.4 Implement `cmd_ls` and wire into dispatch
  - _Requirements: Req-6_

- [ ] 3.5 Write `ls_raw` spec scenario
  - _Requirements: Req-6, AC-6.2_

- [ ] 3.6 Write `ls_table` spec scenario
  - Stub `gum` to echo argv to a temp file; assert `gum table` appears in argv
  - _Requirements: Req-6, AC-6.1_

**Completion criteria:**

- [ ] `mise run xc-fabric:specs --scenario ls_raw` GREEN
- [ ] `mise run xc-fabric:specs --scenario ls_table` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add ls subcommand and pattern helpers`

---

## TASK 4: `run` path + stdin/clipboard + exec + render + new scenarios

- [ ] 4.1 Implement `_ui_input_read`
  - If `[[ ! -t 0 ]]` → `cat -`
  - Else → `_ui_clip || _ui_log_fatal "no input available (clipboard empty or unsupported)"`
  - _Requirements: Req-4, Req-5_

- [ ] 4.2 Implement `_ui_render_markdown`
  - Use `printf '%s\n' "$result" | glow|bat|cat` — never bare `echo "$result"` for content
  - _Requirements: Req-8_

- [ ] 4.3 Implement `_fabric_exec_stdin`
  - `printf '%s' "$input" | fabric …` or `printf '%s' "$input" | _ui_spinner … -- fabric …` — **no** `sh -c` + `printf %q` (see `design.md` §6.6)
  - Honour `--output` (skip `_ui_render_markdown`), `--copy`, `-v` / `--variable`, `--strategy`
  - _Requirements: Req-4, Req-5, Req-8, Req-9, Req-12_

- [ ] 4.4 Implement `cmd_run` (YouTube + non-YouTube URL + plain)
  - Per `design.md` §6.5 (`_url_is_youtube` first; generic `https?://` → `_fabric_exec_scrape` stub in Task 11 if not done yet — or implement `_fabric_exec_scrape` minimal here)
  - _Requirements: Req-5_

- [ ] 4.5 Write `run_raw`, `clip_macos`, `clip_linux`, `run_copy`, `run_output`, `run_variable` scenarios
  - `clip_macos`: `uname` stub + `pbpaste` stub on `PATH`
  - `clip_linux`: `uname` Linux + `xclip` stub
  - _Requirements: Req-5, Req-2_

- [ ] 4.6 Write `render_fallback` scenario
  - Stub `bat`, omit `glow`; assert `bat` in command pipeline for rendered output
  - _Requirements: Req-8_

**Completion criteria:**

- [ ] All six scenarios above GREEN via `mise run xc-fabric:specs --scenario <id>`
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add run path with stdin, clipboard, and passthrough flags`

---

## TASK 5: YouTube + `--yt-*` + extended `yt_flags`

- [ ] 5.1–5.3 Implement `_fabric_build_yt_args`, `_fabric_exec_youtube`, global `--yt-*` flags
  - Use `printf '%s' | _ui_spinner -- fabric …` pattern (no `sh -c` quoting)
  - _Requirements: Req-5, Req-7_

- [ ] 5.4 Write `run_youtube_url`, `run_youtube_pattern` scenarios
  - _Requirements: Req-5_

- [ ] 5.5 Extend `yt_flags` scenario
  - Assert `--yt-metadata` → `--metadata` in fabric args
  - Assert `--yt-playlist` → `--playlist` in fabric args
  - _Requirements: Req-7, AC-7.3, AC-7.4_

**Completion criteria:**

- [ ] `run_youtube_url`, `run_youtube_pattern`, `yt_flags` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add YouTube detection with flags passthrough`

---

## TASK 6: `update`, `show`, `strategies`, `scrape` subcommands + specs

- [ ] 6.1 Implement `cmd_update` (`fabric -U`) per `design.md` §6.9
- [ ] 6.2 Implement `cmd_show` (`fabric --readpattern`)
- [ ] 6.3 Implement `cmd_strategies` (`fabric --liststrategies | _ui_table`)
- [ ] 6.4 Implement `_fabric_exec_scrape` + `cmd_scrape` (YouTube URL → `_fabric_exec_youtube` with default pattern per design)
- [ ] 6.5 Write scenarios: `update`, `show`, `strategies`, `strategy_passthrough`, `scrape_url`
  - _Requirements: Req-10–Req-13_

**Completion criteria:**

- [ ] All five scenarios GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add update, show, strategies, and scrape subcommands`

---

## TASK 7: Picker scenarios (`picker_fzf_preferred`, `picker_fzf_stdin_lines`, `picker_gum_fallback`)

- [ ] 7.1 `picker_fzf_preferred`
  - PATH: stub `fzf` writes full argv to temp file and exits 0 printing first line of stdin; include stub `gum` too
  - Invoke code path that runs `_ui_filter` with fzf (e.g. dry test via `xc-fabric` internal or smallest public entry that hits `_ui_filter` — may require `SOURCE=1` test hook or run `zsh -c '. ./xc-fabric; …'` per project convention)
  - Assert argv contains `--preview-window` and `toggle-preview` bind
  - _Requirements: Req-2, Req-4_

- [ ] 7.2 `picker_fzf_stdin_lines`
  - PATH: stub `fzf` logs stdin; assert one line per fixture pattern and exactly one tab per line with no embedded newlines in each row
  - _Requirements: Req-2, Req-4_

- [ ] 7.3 `picker_gum_fallback`
  - PATH: no `fzf`, stub `gum` logs argv
  - Assert `gum filter` invoked, not `fzf`
  - _Requirements: Req-2, Req-4_

**Completion criteria:**

- [ ] All three scenarios GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `test(bins/xc-fabric): Add fzf vs gum picker preference specs`

---

## TASK 8: TUI paths — `cmd_default`

> Full interactive flows require a real TTY. Automated specs cover picker argv only (Task 7).

- [ ] 8.1 Implement `cmd_default` per `design.md` §6.4
- [ ] 8.2 Complete global argument parser and `main` dispatch
  - Dispatch: `run`, `ls`, `update`, `show`, `strategies`, `scrape`, `""` → default, unknown → `_ui_log_fatal`
  - Parse: `--raw/-r`, `--model`, `--copy/-c`, `--output/-o`, `-v`/`--variable`, `--strategy`, `--no-preview`, `--yes/-y`, all `--yt-*`
  - `_boot_paths`, `_boot_caps`, `_boot_clip` before `_boot_check_deps`; ERR trap per design
  - _Requirements: Req-1–Req-13_

- [ ] 8.3 Manual smoke test (record in commit body when applicable)

  ```sh
  xc-fabric --help
  xc-fabric ls --raw
  echo "Hello world" | xc-fabric run summarize --raw
  xc-fabric ls
  ```

**Completion criteria:**

- [ ] `mise run xc-fabric:specs` (all **22** scenarios) GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] Manual smoke test passes
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add default interactive picker`

---

## TASK 9: Update `README.md` + verify `mise.toml`

- [ ] 9.1 Verify `mise.toml`
  - `xc-fabric:specs` and `setup` present; `run` line correct; **22** `choices` in `usage`
  - _Requirements: all_

- [ ] 9.2 Update `README.md` per `design.md` §12 (OVERVIEW, DEPENDENCIES, LINKS `[20]–[25]`, RUNNING SPECS for all 22 scenarios + `setup`)

**Completion criteria:**

- [ ] `mise run xc-fabric:specs` GREEN
- [ ] `mise tasks` lists both `xc-fabric:*` tasks
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `docs(bins/xc-fabric): Update README and verify mise tasks`

---

## TASK 10: Picker UI polish (fzf list, preview, header bar)

Verification for the narrow UX pass (list hygiene, darker preview chrome, footer-style layout).

- [x] 10.1 `_pattern_list_sanitize_desc` strips TAB/newline from descriptions; `_pattern_list_lines` prints one `pattern<TAB>display` line per row with trailing newline; `_pattern_list_lines` uses a `picker_mode` local (no `mode=fzf` assignment form that could confuse logs)
- [x] 10.2 `_ui_filter` fzf tier: `--layout=default`, `--border=rounded`, `--header="$header"`, `--preview-window` with `border-rounded`, `--color` includes `preview-bg` and `header-bg` (fzf **0.27+**)
- [x] 10.3 Specs: `picker_fzf_preferred` asserts layout + color tokens; `picker_fzf_stdin_lines` still enforces single-tab rows
- [x] 10.4 SDD + README aligned (`requirements.md` AC-2.13 / Req-4 edges, `design.md` §6.2 / Table B / §8 / scenario count, `README.md` note for `GLOW_STYLE` + fzf version)

**Completion criteria:**

- [x] `mise run xc-fabric:specs` GREEN

---

## TASK SEQUENCING

```text
TASK 1 → TASK 2 → TASK 3 → TASK 4 → TASK 5 → TASK 6 → TASK 7 → TASK 8 → TASK 9 → TASK 10
```

**FUNDAMENTAL-FIRST:**

1. Predicates + `_ui_*` (incl. `_ui_clip`, `_ui_filter`) + `_boot_check_deps` before subcommands;
2. Pattern helpers before `ls` / default / `run`;
3. Non-YouTube `run` before YouTube (`TASK 4` then `TASK 5`);
4. Extra subcommands (`update`, `show`, `strategies`, `scrape`) before full TUI wiring;
5. Picker argv specs before declaring TUI manual-only complete;
6. Docs last.

---

## FINAL ACCEPTANCE GATE

```sh
mise run setup   # once per machine / CI image
mise run xc-fabric:specs
shellcheck xc-fabric
# Manual
xc-fabric --help
xc-fabric ls --raw
echo "test" | xc-fabric run summarize --raw
xc-fabric ls
```

---

## TASKS VALIDATION CHECKLIST

**Completeness:**

- [x] All design components from `design.md` have corresponding tasks
- [x] All requirements (Req-1 through Req-13) are referenced
- [x] Testing tasks included within each feature task
- [x] Integration task (Task 9) connects docs + mise verification

**Clarity:**

- [x] Each sub-task specifies what code to write or modify
- [x] Requirements references included on every sub-task
- [x] Completion criteria are observable (GREEN / zero-errors)

**Sequencing:**

- [x] Helpers before subcommands (Task 2 before 3–8)
- [x] Pattern helpers before consumers (Task 3 before 4–8)
- [x] `run` core before YouTube (Task 4 before 5)
- [x] Subcommands `update`…`scrape` before full `main` TUI (Tasks 6–7 before 8)
- [x] Docs after code (Task 9 last)

**Feasibility:**

- [x] Each task is a focused increment
- [x] TUI-only paths clearly separated with explicit manual-test instructions
