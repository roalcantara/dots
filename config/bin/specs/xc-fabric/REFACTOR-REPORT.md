<!-- markdownlint-disable -->
# xc-fabric Refactor Report

**Date:** 2026-05-03
**Scope:** Implementation of the cleanup, optimization, and DRY-up plan for [`xc-fabric`](../../xc-fabric).

## Summary

Removed the unused `wizard` subcommand and dead helpers, replaced per-call `command -v` / `uname` / clipboard branching with one-time `_boot_caps`, `_boot_clip`, and `_PATTERNS_DIR`, merged duplicate picker/formatting logic, and centralized fzf preview construction inside `_ui_filter` with a memoized `_boot_preview_cmd`. All **22** Bun scenarios remain green; `shellcheck` passes via `mise exec -- shellcheck xc-fabric`.

## Changes made (by phase)

### Phase 1 — Remove wizard

- **Files:** [`xc-fabric`](../../xc-fabric) help block, `_parse_args` subcommand list, `main` dispatch; [`requirements.md`](requirements.md), [`design.md`](design.md), [`tasks.md`](tasks.md), [`EXTERNAL-DELTAS.md`](EXTERNAL-DELTAS.md).
- **Rationale:** No automated scenario covered `wizard`; keeping it inflated the script and duplicated `cmd_default`’s picker path without test safety.
- **Skills:** **bdd-scenarios** — absence of executable specs for a subcommand is a strong signal to drop or spec it before shipping.

### Phase 2 — Remove dead code

- **Removed:** `SCRIPT_NAME`, `_h_write`, `_h_choose` (and Table A references in design).
- **Rationale:** Zero call sites; carrying them obscures the real control flow.
- **Skills:** **refactor** (remove unreachable / unused symbols).

### Phase 3 — Memoize one-time evaluations

- **Added:** `typeset -gA _CAPS`, `_boot_caps`; `typeset -ga _CLIP_CMD`, `_boot_clip`; `_PATTERNS_DIR` + `_boot_paths`; `_PREVIEW_CMD` + `_boot_preview_cmd`.
- **`main`:** `_boot_paths`, `_boot_caps`, `_boot_clip` before `_boot_check_deps`; same inits for `--reload-list` (paths + caps; clip not required).
- **Rationale:** OS, PATH, and patterns dir do not change mid-process; repeated `command -v` and clipboard probing were pure overhead.
- **Skills:** **bash-scripting** (one-shot init, arrays for argv); **dry-principle** (single source for patterns dir).

### Phase 4 — Preview inside `_ui_filter`

- **`_ui_filter`:** If `--preview` is passed, use it; else if `NO_PREVIEW` use plain `sed` snippet; else `_boot_preview_cmd` (memoized glow → bat → sed chain).
- **`cmd_default`:** Single pipeline into `_ui_filter` (no caller-side preview branch).
- **Rationale:** Eliminates duplicated if/else between former `cmd_default` / `cmd_wizard` and keeps preview policy in one place.
- **Skills:** **dry-principle**, **refactor**.

### Phase 5 — Hoist fzf branch in `_pat_emit_picker_lines`

- **`use_fzf=$(( _CAPS[fzf] ))` before the `while` loop** instead of testing inside every row.
- **Rationale:** Even as an integer lookup, hoisting makes intent obvious and avoids redundant work in tight loops.
- **Skills:** **bash-scripting**.

### Phase 6 — Merge row formatters

- **`_pat_row_format`** with mode `fzf` | `plain` replaces `_format_pattern_fzf_row` + `_format_pattern_plain_row`.
- **Rationale:** Same data shape; only width/separator/ANSI differ.
- **Skills:** **dry-principle**.

### Phase 7 — Specs and external deltas

- **requirements.md:** Rewrote Req-2 for `_boot_*` / `_CAPS` / `_CLIP_CMD`; removed wizard Req-5; renumbered downstream requirements (5–13); aligned `_ui_read_input` / `_boot_check_deps` / render wording with implementation.
- **design.md / tasks.md / EXTERNAL-DELTAS.md:** Architecture, helper tables, task text, and README delta list updated to match code (including `fabric-ai`, section renumbering, D-* decision renumber after removing wizard-only D-7).
- **Skills:** **docs-writer** (implicit: clear normative docs aligned with behavior).

### Phase 8 — Subsystem-prefixed private names (`_boot_*`, `_ui_*`, `_pat_*`, `_url_*`, `_fabric_*`)

- **Code:** Renamed helpers per [design.md](design.md) §13 D-10 / §3 pointer (e.g. `_init_*`→`_boot_*`, `_h_*`/`_ln*`→`_ui_*`, pattern picker pipeline→`_pat_*`, YouTube predicates→`_url_*`, `fabric-ai` orchestration→`_fabric_*`); merged-argv scratch array is `_fabric_common_argv_tail`.
- **Bugfix:** `_url_is_youtube` and `_url_pattern_implies_yt` previously ended with unconditional `return 0`, so `elif _url_pattern_implies_yt` was always true — fixed so the function exit status matches `[[ … ]]`.
- **Docs:** `design.md`, `requirements.md`, `tasks.md`, and this report updated for new symbol names; D-10 text aligned with implemented buckets.
- **Skills:** **refactor**, **docs-writer**, [Google Shell Style Guide — Function names](https://google.github.io/styleguide/shellguide.html#s7.1-function-names) (lowercase / underscores; no `::` in a single-file executable).

## Skills used (decision → skill)

| Decision                                        | Skill(s) applied                                                                             |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Remove `wizard`                                 | **bdd-scenarios** — no scenario coverage                                                     |
| Delete `_h_write` / `_h_choose` / `SCRIPT_NAME` | **refactor**                                                                                 |
| `_boot_caps` + `_CAPS`                          | **bash-scripting**                                                                           |
| `_boot_clip` + `_CLIP_CMD`                      | **bash-scripting**                                                                           |
| `_PATTERNS_DIR` global                          | **dry-principle**                                                                            |
| `_boot_preview_cmd` memoization                 | **bash-scripting**                                                                           |
| Preview logic inside `_ui_filter`               | **dry-principle**, **refactor**                                                              |
| Hoist `use_fzf` out of pattern loop             | **bash-scripting**                                                                           |
| Merge format row functions                      | **dry-principle**                                                                            |
| Spec renumbering + design sync                  | **docs-writer** (narrative + consistency)                                                    |
| Regression safety                               | **tdd-workflow** / **bun-development** (22 `bun:test` scenarios, `mise run xc-fabric:specs`) |

## Before / after results

| Metric                                                          | Baseline     | After        |
| --------------------------------------------------------------- | ------------ | ------------ |
| Total lines (`wc -l < xc-fabric`)                               | 914          | 814          |
| Non-blank lines (`grep -c '[^[:space:]]'`)                      | 820          | 731          |
| Defined functions (`grep -c '^[[:alpha:]_][[:alnum:]_]*()'`)    | 50           | 42           |
| `$(...)` subshells in source                                    | 49           | 33           |
| `command -v` occurrences in source                              | 10           | 10           |
| `$(uname)` in source                                            | 3            | 1            |
| `_patterns_dir` call sites                                      | 6            | 0            |
| `wizard` references in script                                   | 6            | 0            |
| Dead-code pattern (`_h_write\|_h_choose\|SCRIPT_NAME`)          | 3            | 0            |
| ShellCheck issues (`^In `)                                      | 0            | 0            |
| `--help` mean time (hyperfine, warmup 3)                        | ~18.2 ms     | ~11.3 ms     |
| `ls --raw` mean time (hyperfine, fixture `FABRIC_PATTERNS_DIR`) | ~21.8 ms     | ~19.6 ms     |
| Peak RSS `ls --raw` (`/usr/bin/time -l`, bytes)                 | 3 457 024    | 3 424 256    |
| Test suite wall (`time -p mise run xc-fabric:specs`)            | ~8.00 s real | ~8.41 s real |

**Notes:**

- `command -v` count in *source* is unchanged because `_boot_caps` / `_boot_clip` still use six-plus probes once; **runtime** probes from `_has_*` per log/picker/render call are eliminated.
- `$(uname)` appears once in `_boot_clip` only; `_ui_clip` no longer calls it.
- Test suite wall time varies with machine load; treat as noise unless trend is tracked over multiple runs.

## Conclusion

The script lost **100 lines** and **8 functions** while preserving behavior covered by automation. Hyperfine shows a clear improvement on the `--help` cold path (less work before first useful output). Quality gates: **22/22** tests pass; **ShellCheck** clean under `mise exec`.

## Suggested commit

```text
ref(xc-fabric): Subsystem names, fix URL predicates, sync SDD

Rename private helpers to _boot_/_ui_/_pat_/_url_/_fabric_ buckets;
fix _url_* predicate exit status; align design/requirements/tasks.
```
