<!-- markdownlint-disable -->
# xc-usage — Tasks

**Date:** 2026-05-20
**Status:** Tasks **1** and **1b** done; **Tasks 3–5** (scoped `-h` on bins) open
**Requires:** [design.md](./design.md), [requirements.md](./requirements.md)

**Orchestration:** [HANDOFF.md](./HANDOFF.md) — generic implementer prompt per task; one subagent at a time.

**Skills (every task):**

```text
~/.claude/skills/bash-scripting/SKILL.md
~/.claude/skills/bun-development/SKILL.md
~/.claude/skills/test-driven-development/SKILL.md
~/.claude/skills/verification-before-completion/SKILL.md
```

**TDD cycle (every task):**

1. Failing spec in `tests/xc-usage.spec.ts` (or bin spec) → RED
2. Minimal change in `config/bin/xc-usage` / bins → GREEN
3. `shellcheck` touched zsh
4. `mise run xc-usage:specs` (and task-specific verify) before done

**Task pattern:** Checkboxes → **ACCEPTANCE CRITERIA** (command, exit code, observable output).

**Blocked by this epic:** [xc-launcher](../xc-launcher/tasks.md) T2 (`preview`); portable-tools scoped help is **out of** portable T1 — lives here as Task 1b.

---

## Task 1 — `xc-usage` executable + core commands

**Covers:** Req-1, Req-2, Req-3, Req-4, Req-5, Req-6, Req-6a, Req-8 (core)

- [x] Add `config/bin/xc-usage` with `##?` self-header per [design.md §5.1](./design.md#51-top-level-argv-routing)
- [x] Implement `_xc_usage_emit` per [design.md §6](./design.md#6-help-extraction) — **no mise / #USAGE**
- [x] Implement top-level routing: empty / `-h` / `--help` before subcommands
- [x] Implement `guard`, `print` (with default help footer per §5.4), `validate` per §5.5
- [x] Implement `print --metadata` (`#?` only)
- [x] Add fixtures: `with-docopt.zsh`, `legacy-hash.zsh`, `missing-help-flag.zsh`, `with-metadata.zsh`, `dispatcher-docopt.zsh`
- [x] Add `tests/xc-usage.spec.ts`: `self_help`, `guard_*`, `missing_docopt`, `print`, `validate_*`, `footer`, `metadata`
- [x] Add `xc-usage:specs` to `config/bin/mise.toml`
- [x] Spec: `env -i PATH=/usr/bin:/bin HOME=$HOME zsh config/bin/xc-usage -h` succeeds (no mise on PATH)

### ACCEPTANCE CRITERIA _(verify; mark PASS before starting 1b)_

- `zsh config/bin/xc-usage -h` → exit **0**; stdout contains `guard`, `print`, `validate`
- `zsh config/bin/xc-usage guard tests/fixtures/xc-usage/with-docopt.zsh -h` → exit **0**; stdout contains `Usage:`
- `zsh config/bin/xc-usage guard tests/fixtures/xc-usage/with-docopt.zsh arg` → exit **2**; stdout empty
- `zsh config/bin/xc-usage validate tests/fixtures/xc-usage/with-docopt.zsh` → exit **0**
- `zsh config/bin/xc-usage print --metadata tests/fixtures/xc-usage/with-metadata.zsh` → exit **0**; stdout contains `License RIT`; stdout has **no** `Usage:`
- `mise run xc-usage:specs` → exit **0**

---

## Task 1b — Scoped help + preview (Req-12)

**Covers:** Req-12

**Prerequisite:** Task 1 AC all PASS.

- [x] Implement `_xc_usage_scope_main`, `_xc_usage_scope_sub`, `_xc_usage_list_subs`, `_xc_usage_preview` per [design.md §5.6–5.8](./design.md#56-scoped-help---scope-list-subs-preview)
- [x] Extend `print` with `--scope main` and `--scope sub:<name>` (unknown sub → exit 1)
- [x] Omitting `--scope` on `print` keeps legacy emit-all-`##?` behavior
- [x] Add subcommands `list-subs`, `preview` to `xc-usage` `##?` self-header
- [x] Tests: `scope_main`, `scope_sub`, `scope_sub_missing`, `list_subs`, `preview_stacked` on `dispatcher-docopt.zsh`
- [x] Add mise `xc-usage:specs` scenario choices for new IDs
- [x] `validate` warns when `Subcommands:` exists but a listed sub has no `##? <tool> <sub> -` title

### ACCEPTANCE CRITERIA _(Req-12)_

- `zsh config/bin/xc-usage print tests/fixtures/xc-usage/dispatcher-docopt.zsh --scope main` → exit **0**; stdout contains `Subcommands:`; stdout does **not** contain `xc-alpha ping -` (sub block title)
- `zsh config/bin/xc-usage print tests/fixtures/xc-usage/dispatcher-docopt.zsh --scope sub:ping` → exit **0**; stdout contains `xc-alpha ping`
- `zsh config/bin/xc-usage print tests/fixtures/xc-usage/dispatcher-docopt.zsh --scope sub:missing` → exit **1**; stderr names unknown sub
- `zsh config/bin/xc-usage list-subs tests/fixtures/xc-usage/dispatcher-docopt.zsh` → exit **0**; stdout lists `ping` and `pong` (one per line)
- `zsh config/bin/xc-usage preview tests/fixtures/xc-usage/dispatcher-docopt.zsh --tool xc-alpha` → exit **0**; stdout contains `Main command:` and `Subcommand:` section headers
- `zsh config/bin/xc-usage -h` → stdout documents `list-subs` and `preview`
- `mise run xc-usage:specs` → exit **0**

---

## Task 2 — README + convention (`#?` vs `##?`)

**Covers:** Req-3, Req-5, Req-7 (docs), Req-8

- [ ] Update `config/bin/README.md`: §11.1 template, §11.2 three-layer table, `guard` / `print` / `validate`, symlink `~/.local/bin/xc-usage`
- [ ] Document `#?` (metadata) vs `##?` (docopt); `print --metadata`
- [ ] Explicit: mise `usage` field = `mise run` only; **not** `xc-usage`
- [ ] Document `guard` exit codes 0 / 1 / 2

### ACCEPTANCE CRITERIA

- `rg -q '##\\?' config/bin/README.md` → match
- `rg -q 'xc-usage guard' config/bin/README.md` → match
- `rg -q 'three-layer|mise run' config/bin/README.md` → match (wording per design §11.2)

---

## Task 3 — `xc-fabric` + `xc-skills` (scoped `-h`)

**Covers:** Req-4, Req-6, Req-7, Req-12

**Prerequisite:** Task 1b.

- [ ] **xc-fabric:** sub `##?` blocks for `run`, `ls`, `update`, `show`, `strategies`, `scrape` (after marker; may already exist — verify)
- [ ] **xc-fabric:** top `-h` → `command xc-usage print "${0:a}" --scope main`; sub `-h` → `--scope sub:<name>`
- [ ] **xc-skills:** main + `sync` + `collect` sub blocks; remove monolithic mixed Options from main
- [ ] **xc-skills:** replace full-file `usage()` print with scoped `xc-usage print "$SCRIPT_PATH" --scope …`
- [ ] Smoke: main `-h` shorter than dumping all subs inline

### ACCEPTANCE CRITERIA

- `zsh config/bin/xc-fabric -h` → exit **0**; stdout matches `rg -q '^Options:'`
- `zsh config/bin/xc-fabric run -h` → exit **0**; stdout matches `rg -q 'run <pattern>'` (or authored Usage)
- `test "$(zsh config/bin/xc-fabric run -h | wc -l | tr -d ' ')" -lt "$(zsh config/bin/xc-fabric -h | wc -l | tr -d ' ')"` → true (sub help narrower than main)
- `zsh config/bin/xc-skills -h` → exit **0**; stdout matches `rg -q 'Subcommands:'`
- `zsh config/bin/xc-skills sync -h` → exit **0**; stdout matches `rg -q 'prune'`
- `zsh config/bin/xc-usage preview config/bin/xc-fabric --tool xc-fabric` → exit **0**; stdout matches `rg -q 'run'` (stacked preview)

---

## Task 4 — `xc-git` flat file (scoped `-h`)

**Covers:** Req-4, Req-6, Req-7, Req-12

**Prerequisite:** Task 1b. **Coordinate:** [xc-portable-tools](../xc-portable-tools/tasks.md) T4 if git file not yet flat.

- [ ] Target: **only** `config/bin/xc-git` (file); `test ! -d config/bin/xc-git/`
- [ ] Normalize sub blocks to [design.md §11.5](./design.md#115-xc-fabric-dispatcher-template-canonical)
- [ ] Top `-h` → `command xc-usage print "${REPLY}" --scope main` after `_xc_git_resolve_self`
- [ ] Sub `-h` → `--scope sub:branch-preview|fixup-suggest|log-fzf`; **delete** `_xc_git_subhelp`
- [ ] `mise run xc-git:specs` → exit **0**

### ACCEPTANCE CRITERIA

- `test -f config/bin/xc-git && test ! -d config/bin/xc-git/` → true
- `zsh config/bin/xc-git -h` → exit **0**; stdout matches `rg -q 'Subcommands:'`
- `zsh config/bin/xc-git fixup-suggest -h` → exit **0**; stdout matches `rg -q 'fixup-suggest'`
- `zsh config/bin/xc-git branch-preview -h` → exit **0**; stdout matches `rg -q 'branch-preview'`
- `rg '_xc_git_subhelp' config/bin/xc-git` → no match (function removed)
- `mise run xc-git:specs` → exit **0**

---

## Task 5 — `xc-puts`, `xc-toast` + spec cleanup

**Covers:** Req-6, Req-7, Req-12

**Prerequisite:** Task 1b for `--scope main` on `-h` (optional: guard-only until 1b).

- [ ] `xc-puts`, `xc-toast`: single `##?` block; `-h` → `guard` or `print --scope main`
- [ ] Update `assets/specs/xc-git/design.md` help note: `##?` + `xc-usage` (docs only)
- [ ] Confirm no `config/bin/lib/xc-usage/`
- [ ] `rg "grep '\\^#\\?'" config/bin --glob 'xc-*'` → no help extraction outside `xc-usage`

### ACCEPTANCE CRITERIA

- `zsh config/bin/xc-puts -h` → exit **0**; stdout contains `Usage:`
- `zsh config/bin/xc-toast -h` → exit **0**; stdout contains `Usage:`
- `test ! -d config/bin/lib/xc-usage` → true
- `mise run xc-puts:specs` and `mise run xc-toast:specs` → exit **0**

---

## Task 6 — Phase 1 gate

**Covers:** Req-7

**Prerequisite:** Tasks 1, 1b, 3–5.

- [ ] `shellcheck config/bin/xc-usage`
- [ ] `mise run xc-usage:specs`
- [ ] `mise run xc-git:specs` (if Task 4 touched)
- [ ] `env -i PATH=/usr/bin:/bin HOME=$HOME zsh config/bin/xc-usage -h` → exit **0**

### ACCEPTANCE CRITERIA

- All commands above → exit **0**

---

## Task 7 — `show_usage` → `xc-usage print`

**Covers:** Req-9

- [ ] Rewrite `config/zsh/etc/functions/show_usage` per [design.md §10.2](./design.md#102-show_usage-implementation-normative)
- [ ] Remove inline `grep '^##?'` from `show_usage`
- [ ] Manual: `show_usage psc` / `show_usage /path/to/psc` work

### ACCEPTANCE CRITERIA

- `rg "grep '\\^##\\?'" config/zsh/etc/functions/show_usage` → no match
- `zsh -ic 'autoload -Uz show_usage; show_usage psc 2>&1 | head -5'` → stdout contains `Usage:` (or documented skip if psc missing in env)

---

## Task 8 — Zsh autoload inventory

**Covers:** Req-10

- [ ] Migrate inventory in [design.md §10.3](./design.md#103-migration-inventory) to `show_usage` / `xc-usage print`
- [ ] `rg` audit: no stray `grep '^##?'` in `config/zsh/etc/functions` except removed from `show_usage`

### ACCEPTANCE CRITERIA

- Per-task checklist in design §10.3 marked done in implementer report
- `rg "grep '\\^##\\?'" config/zsh/etc/functions` → only zero matches or justified exceptions documented

---

## Task 9 — Zsh + bin documentation

**Covers:** Req-5, Req-11

- [ ] Create `config/zsh/README.md` per design §11
- [ ] `config/bin/README.md` cross-links `config/zsh/README.md`
- [ ] `assets/specs/xc-git/design.md` help convention updated

### ACCEPTANCE CRITERIA

- `test -f config/zsh/README.md` → true
- `rg 'config/zsh/README' config/bin/README.md` → match

---

## Task 11 — `xc-usage:validate` mise task

**Covers:** Req-6a, Req-8

- [x] `xc-usage:validate` in `mise.toml` loops primary bins (may already exist — verify)
- [ ] Document in README: dev/CI only

### ACCEPTANCE CRITERIA

- `mise run xc-usage:validate` → exit **0** after Tasks 3–5
- `rg 'xc-usage:validate' config/bin/README.md` → match

---

## Task 10 — Final verification (full stack)

**Covers:** Req-7–11

**Prerequisite:** Tasks 6–9, 11 as applicable.

- [ ] `mise run xc-usage:specs`
- [ ] `mise run xc-usage:validate`
- [ ] `xc-usage` works with mise **not** on PATH
- [ ] Task 8 inventory complete

### ACCEPTANCE CRITERIA

- `mise run xc-usage:specs` → exit **0**
- `mise run xc-usage:validate` → exit **0**
- `env -i PATH=/usr/bin:/bin:$HOME/.local/bin HOME=$HOME command xc-usage -h` → exit **0** (when `~/.local/bin` symlink exists)

---

## Definition of done (full epic)

- Single `config/bin/xc-usage`; no `lib/xc-usage/`.
- **Req-12:** `list-subs`, `print --scope`, `preview` implemented and tested.
- Primary bins use scoped `-h` where applicable; flat `xc-git` only.
- **`show_usage`** delegates to `xc-usage print` (phase 2).
- `mise run xc-usage:specs` green; `xc-usage` standalone (no mise runtime).
