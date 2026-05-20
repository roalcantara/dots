# Handoff: xc-usage

**Status:** **Task 1 + 1b done** in `xc-usage`; **Tasks 3–5** (wire `xc-fabric`, `xc-skills`, `xc-git` to scoped `-h`) still open.

**Authoritative sources (do not duplicate here):**

| File                                 | Use for                                                       |
| ------------------------------------ | ------------------------------------------------------------- |
| [requirements.md](./requirements.md) | Req-1–12; implementation status vs each req                   |
| [design.md](./design.md)             | CLI contracts, §5.6–5.9 scoped help, §11.5 xc-fabric template |
| [tasks.md](./tasks.md)               | **Task 1, 1b, 2–11** + **ACCEPTANCE CRITERIA**                |

**Canonical `##?` in repo:** `config/bin/xc-fabric` lines 3–47 (main) + sub blocks after `### Subcommand help blocks`.

**Related epics:**

- [xc-portable-tools/HANDOFF.md](../xc-portable-tools/HANDOFF.md) — flat `config/bin/xc-git`, PATH bins (run before or in parallel with Task 4 here)
- [xc-launcher/HANDOFF.md](../xc-launcher/HANDOFF.md) — `xc` fzf; **blocked on Task 1b** (`preview`)

---

## What is already in the repo

| Area                                            | State                                                                           |
| ----------------------------------------------- | ------------------------------------------------------------------------------- |
| `config/bin/xc-usage`                           | `guard`, `print`, `validate`, `--metadata`, `--no-help-footer`                  |
| `tests/xc-usage.spec.ts`                        | Task 1 scenarios + `metadata` dual-header; **no** `scope_*` / `preview_stacked` |
| `tests/fixtures/xc-usage/dispatcher-docopt.zsh` | Present for future 1b tests                                                     |
| `mise.toml`                                     | `xc-usage:specs`, `xc-usage:validate`                                           |
| `xc-fabric` / `xc-skills`                       | `##?` blocks (incl. subs on fabric); **no** `xc-usage print --scope` wiring     |
| `xc-git`                                        | Flat `config/bin/xc-git`; still uses `_xc_git_subhelp`                          |
| `xc-puts`, `xc-toast`                           | Exist with `guard`; scoped `-h` needs 1b + Task 5                               |

---

## Epic order (with portable-tools + launcher)

1. **xc-usage Tasks 3–5** — wire bins to scoped help (`print --scope`, drop `_xc_git_subhelp`)
2. **xc-launcher** — `preview` in fzf
3. **xc-launcher** — after 1b
4. **xc-usage Tasks 2, 6–11** — README, `show_usage`, Zsh phase 2 (can overlap docs)

Portable-tools T7 (Req-8 table) is separate; see portable HANDOFF.

---

## Parent orchestrator

1. Load [tasks.md](./tasks.md) into TodoWrite; run tasks in dependency order (1 → 1b → 3–5 before launcher).
2. Per task: **Implementer** → **Spec reviewer** → **Code quality reviewer**; one implementer at a time.
3. Worktree: `/Users/roalcantara/Work/dots`
4. Do not commit unless the user asked.

---

## Generic implementer prompt (copy per task)

Replace `TASK_ID` with `1`, `1b`, `2`, … `11` (e.g. `1b`). Send **only** this block.

```text
You are implementing exactly one task from the xc-usage epic in the dots repository.

Task:
TASK_ID — see assets/specs/xc-usage/tasks.md section "## Task TASK_ID"

Worktree:
/Users/roalcantara/Work/dots

Authoritative spec (read these; do not rely on this prompt for details):
- assets/specs/xc-usage/tasks.md — checkboxes + ACCEPTANCE CRITERIA for Task TASK_ID
- assets/specs/xc-usage/requirements.md — Req-* in "Covers" for that task
- assets/specs/xc-usage/design.md — normative CLI and wiring (§5.6–5.9 for Task 1b/3–5)

Project rules:
- Single file config/bin/xc-usage; no config/bin/lib/xc-usage/
- Runtime: zsh, grep, sed only — no mise inside xc-usage
- ##? = docopt help; #? = metadata only (print --metadata)
- xc-git = flat file config/bin/xc-git (NOT xc-git/xc-git/ directory)
- Bin top-level: command xc-usage guard "${0:a}" "$@"
- Do NOT change HANDOFF.md, requirements.md, design.md, or tasks.md unless the task is docs-only (2, 5, 9)
- Prefer verify-then-complete if AC already passes

Skills (load before coding):
~/.claude/skills/bash-scripting/SKILL.md
~/.claude/skills/bun-development/SKILL.md
~/.claude/skills/test-driven-development/SKILL.md
~/.claude/skills/verification-before-completion/SKILL.md

Done when:
Every bullet under "### ACCEPTANCE CRITERIA" for Task TASK_ID in tasks.md passes.

Return a short report:
1. Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
2. Files changed
3. Commands run + exit codes
4. AC checklist: each AC line → PASS or FAIL
5. Suggested commit subject

Stop and report BLOCKED if AC cannot be verified or scope needs redesign beyond design.md.
```

---

## Generic spec reviewer prompt

Replace `TASK_ID`.

```text
You are the spec compliance reviewer for xc-usage Task TASK_ID.

Read tasks.md "## Task TASK_ID" ACCEPTANCE CRITERIA and requirements.md "Covers" reqs.

Compare implementer report + git diff to AC only.

Reply: ✅ Spec compliant OR ❌ numbered gaps per AC bullet.
```

---

## Generic code quality reviewer prompt

Replace `TASK_ID`.

```text
You are the code quality reviewer for xc-usage Task TASK_ID.

Review git diff for Task TASK_ID only: shellcheck on xc-usage / touched bins, no lib/xc-usage/, flat xc-git preserved.

Reply: ✅ Approved OR ❌ Important/Minor with file:line.
```

---

## Parent agent — one-line dispatch

```text
Execute assets/specs/xc-usage/tasks.md in order: verify Task 1 → Task 1b → Tasks 3–5 → launcher epic → Tasks 2,6–11. Use HANDOFF.md generic prompts per task. Do not commit unless user asks.
```
