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
// Satisfies _check_deps with no warnings.
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
  - Add `#!/usr/bin/env zsh` shebang and full `#?` help block (see Req-1; document all subcommands: default, `wizard`, `run`, `ls`, `update`, `show`, `strategies`, `scrape`)
  - Add `set -euo pipefail` and `readonly SCRIPT_NAME="${0:t}"`
  - Handle `-h|--help` via **top-level `case "${1:-}"` before `main`** (same pattern as `xc-git-log-fzf`) OR as first branch inside `main` **without** calling `_check_deps`
  - Run `chmod +x xc-fabric`
  - _Requirements: Req-1_

- [ ] 1.2 Create fixture files
  - Create `tests/fixtures/xc-fabric/patterns/` with three subdirectories
  - Each `system.md` contains one plain-text description line (see above)
  - _Requirements: Req-4, Req-7_

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

## TASK 2: Predicates + `_h_clip` + `_h_*` + `_check_deps` + fzf-first `_h_filter`

- [ ] 2.1 Implement `_has_*` predicate functions
  - `_has_fabric`, `_has_gum`, `_has_glow`, `_has_bat`, `_has_fzf` as
    `command -v <tool> >/dev/null 2>&1` — no output, pure boolean
  - _Requirements: Req-2, AC-2.1–AC-2.5_

- [ ] 2.2 Implement `_h_clip`
  - Per `design.md` §6.0 `_h_clip` block (Darwin `pbpaste`; Linux `wl-paste` / `xclip` / `xsel`)
  - _Requirements: Req-2, AC-2.18–AC-2.20_

- [ ] 2.3 Implement `_h_log` and level wrappers
  - `_h_info`, `_h_warn`, `_h_error`: return after `_h_log` (do **not** exit the script)
  - `_h_fatal`: `_h_log fatal "$@"` then `exit 1`
  - _Requirements: Req-2, AC-2.6–AC-2.10_

- [ ] 2.4 Implement interaction wrappers except `_h_filter`
  - `_h_prompt`, `_h_confirm`, `_h_spinner`, `_h_table`, `_h_choose`, `_h_write` per `design.md` Table A
  - _Requirements: Req-2, AC-2.11–AC-2.15, AC-2.17_

- [ ] 2.5 Implement `_h_filter` (3-tier: fzf → gum filter → read)
  - fzf path: `--preview-window 'right:60%:wrap'`, binds `ctrl-/`, `ctrl-o`, `ctrl-r`, `?` per `design.md` §6.0
  - Resolve `reload` subshell issue (`export -f` or inline pipeline — see design note)
  - _Requirements: Req-2, AC-2.16, Req-4_

- [ ] 2.6 Implement `_check_deps` and wire into `main`
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

- [ ] 3.1 Implement `_patterns_dir` helper
  - Return `${FABRIC_PATTERNS_DIR:-${HOME}/.config/fabric/patterns}`
  - _Requirements: Req-4, Req-7_

- [ ] 3.2 Implement `_list_patterns` helper
  - Iterate `$(_patterns_dir)/*/` — skip gracefully if dir missing
  - Extract description from `system.md` per design
  - _Requirements: Req-4, Req-7_

- [ ] 3.3 Implement `_is_youtube_url` and `_is_youtube_pattern` helpers
  - _Requirements: Req-6, Req-8_

- [ ] 3.4 Implement `cmd_ls` and wire into dispatch
  - _Requirements: Req-7_

- [ ] 3.5 Write `ls_raw` spec scenario
  - _Requirements: Req-7, AC-7.2_

- [ ] 3.6 Write `ls_table` spec scenario
  - Stub `gum` to echo argv to a temp file; assert `gum table` appears in argv
  - _Requirements: Req-7, AC-7.1_

**Completion criteria:**

- [ ] `mise run xc-fabric:specs --scenario ls_raw` GREEN
- [ ] `mise run xc-fabric:specs --scenario ls_table` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add ls subcommand and pattern helpers`

---

## TASK 4: `run` path + stdin/clipboard + exec + render + new scenarios

- [ ] 4.1 Implement `_read_input`
  - If `[[ ! -t 0 ]]` → `cat -`
  - Else → `_h_clip || _h_fatal "no input available (clipboard empty or unsupported on $(uname))"`
  - _Requirements: Req-4, Req-6_

- [ ] 4.2 Implement `_render_output`
  - Use `printf '%s\n' "$result" | glow|bat|cat` — never bare `echo "$result"` for content
  - _Requirements: Req-9_

- [ ] 4.3 Implement `_exec_fabric`
  - `printf '%s' "$input" | fabric …` or `printf '%s' "$input" | _h_spinner … -- fabric …` — **no** `sh -c` + `printf %q` (see `design.md` §6.7)
  - Honour `--output` (skip `_render_output`), `--copy`, `-v` / `--variable`, `--strategy`
  - _Requirements: Req-4, Req-6, Req-9, Req-10, Req-13_

- [ ] 4.4 Implement `cmd_run` (YouTube + non-YouTube URL + plain)
  - Per `design.md` §6.6 (`_is_youtube_url` first; generic `https?://` → `_exec_fabric_scrape` stub in Task 11 if not done yet — or implement `_exec_fabric_scrape` minimal here)
  - _Requirements: Req-6_

- [ ] 4.5 Write `run_raw`, `clip_macos`, `clip_linux`, `run_copy`, `run_output`, `run_variable` scenarios
  - `clip_macos`: `uname` stub + `pbpaste` stub on `PATH`
  - `clip_linux`: `uname` Linux + `xclip` stub
  - _Requirements: Req-6, Req-2_

- [ ] 4.6 Write `render_fallback` scenario
  - Stub `bat`, omit `glow`; assert `bat` in command pipeline for rendered output
  - _Requirements: Req-9_

**Completion criteria:**

- [ ] All six scenarios above GREEN via `mise run xc-fabric:specs --scenario <id>`
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add run path with stdin, clipboard, and passthrough flags`

---

## TASK 5: YouTube + `--yt-*` + extended `yt_flags`

- [ ] 5.1–5.3 Implement `_build_yt_args`, `_exec_fabric_youtube`, global `--yt-*` flags
  - Use `printf '%s' | _h_spinner -- fabric …` pattern (no `sh -c` quoting)
  - _Requirements: Req-6, Req-8_

- [ ] 5.4 Write `run_youtube_url`, `run_youtube_pattern` scenarios
  - _Requirements: Req-6_

- [ ] 5.5 Extend `yt_flags` scenario
  - Assert `--yt-metadata` → `--metadata` in fabric args
  - Assert `--yt-playlist` → `--playlist` in fabric args
  - _Requirements: Req-8, AC-8.3, AC-8.4_

**Completion criteria:**

- [ ] `run_youtube_url`, `run_youtube_pattern`, `yt_flags` GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add YouTube detection with flags passthrough`

---

## TASK 6: `update`, `show`, `strategies`, `scrape` subcommands + specs

- [ ] 6.1 Implement `cmd_update` (`fabric -U`) per `design.md` §6.10
- [ ] 6.2 Implement `cmd_show` (`fabric --readpattern`)
- [ ] 6.3 Implement `cmd_strategies` (`fabric --liststrategies | _h_table`)
- [ ] 6.4 Implement `_exec_fabric_scrape` + `cmd_scrape` (YouTube URL → `_exec_fabric_youtube` with default pattern per design)
- [ ] 6.5 Write scenarios: `update`, `show`, `strategies`, `strategy_passthrough`, `scrape_url`
  - _Requirements: Req-11–Req-14_

**Completion criteria:**

- [ ] All five scenarios GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add update, show, strategies, and scrape subcommands`

---

## TASK 7: Picker scenarios (`picker_fzf_preferred`, `picker_gum_fallback`)

- [ ] 7.1 `picker_fzf_preferred`
  - PATH: stub `fzf` writes full argv to temp file and exits 0 printing first line of stdin; include stub `gum` too
  - Invoke code path that runs `_h_filter` with fzf (e.g. dry test via `xc-fabric` internal or smallest public entry that hits `_h_filter` — may require `SOURCE=1` test hook or run `zsh -c '. ./xc-fabric; …'` per project convention)
  - Assert argv contains `--preview-window` and `toggle-preview` bind
  - _Requirements: Req-2, Req-4_

- [ ] 7.2 `picker_gum_fallback`
  - PATH: no `fzf`, stub `gum` logs argv
  - Assert `gum filter` invoked, not `fzf`
  - _Requirements: Req-2, Req-4_

**Completion criteria:**

- [ ] Both scenarios GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `test(bins/xc-fabric): Add fzf vs gum picker preference specs`

---

## TASK 8: TUI paths — `cmd_default` and `cmd_wizard`

> Full interactive flows require a real TTY. Automated specs cover picker argv only (Task 7).

- [ ] 8.1 Implement `cmd_default` per `design.md` §6.4
- [ ] 8.2 Implement `cmd_wizard` per `design.md` §6.5 (**no** `fabric --listmodels | _h_choose`; confirm step is `_h_confirm "Run <pattern>?"` only)
- [ ] 8.3 Complete global argument parser and `main` dispatch
  - Dispatch: `wizard`, `run`, `ls`, `update`, `show`, `strategies`, `scrape`, `""` → default, unknown → `_h_fatal`
  - Parse: `--raw/-r`, `--model`, `--copy/-c`, `--output/-o`, `-v`/`--variable`, `--strategy`, `--no-preview`, `--yes/-y`, all `--yt-*`
  - ERR trap per design
  - _Requirements: Req-1–Req-14_

- [ ] 8.4 Manual smoke test (record in commit body when applicable)

  ```sh
  xc-fabric --help
  xc-fabric ls --raw
  echo "Hello world" | xc-fabric run summarize --raw
  xc-fabric ls
  xc-fabric wizard
  ```

**Completion criteria:**

- [ ] `mise run xc-fabric:specs` (all **22** scenarios) GREEN
- [ ] `shellcheck xc-fabric` zero errors
- [ ] Manual smoke test passes
- [ ] execute command `/commit-all` using the following title adding appropriate body:
   `feat(bins/xc-fabric): Add default interactive picker and wizard`

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

## TASK SEQUENCING

```text
TASK 1 → TASK 2 → TASK 3 → TASK 4 → TASK 5 → TASK 6 → TASK 7 → TASK 8 → TASK 9
```

**FUNDAMENTAL-FIRST:**

1. Predicates + `_h_clip` + `_h_*` + `_h_filter` + `_check_deps` before subcommands;
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
xc-fabric wizard
```

---

## TASKS VALIDATION CHECKLIST

**Completeness:**

- [x] All design components from `design.md` have corresponding tasks
- [x] All requirements (Req-1 through Req-14) are referenced
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
