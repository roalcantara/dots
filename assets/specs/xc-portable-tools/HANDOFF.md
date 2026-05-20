# Handoff: xc-portable-tools

**Status:** Ready — some work may already exist in repo; each task is **verify or complete**, not redo from scratch.

**Authoritative sources (do not duplicate here):**

| File                                 | Use for                                                                           |
| ------------------------------------ | --------------------------------------------------------------------------------- |
| [requirements.md](./requirements.md) | Req-1–8, Req-8 final verification table (25 rows)                                 |
| [design.md](./design.md)             | Layout, XDG paths, flat `config/bin/xc-git`, decisions                            |
| [tasks.md](./tasks.md)               | **Task T1–T8** work items + **ACCEPTANCE CRITERIA** (definition of done per task) |

**Related epics (separate handoffs — do not implement inside portable tasks unless the task says so):**

- [xc-usage/HANDOFF.md](../xc-usage/HANDOFF.md) — scoped `print --scope`, `preview` (Req-12)
- [xc-launcher/HANDOFF.md](../xc-launcher/HANDOFF.md) — `config/bin/xc` launcher (after `xc-usage preview`)

**Supersedes:** [xc-git/HANDOFF.md](../xc-git/HANDOFF.md) for package layout (flat `xc-git` only).

---

## Parent orchestrator

1. Load [tasks.md](./tasks.md) T1→T8 into TodoWrite; run **in order**; one implementer at a time.
2. Per task: dispatch **Implementer** (generic prompt below with `3`) → **Spec reviewer** → **Code quality reviewer**.
3. **T7 last** — Req-8 table must be all PASS before epic close.
4. Worktree: `/Users/roalcantara/Work/dots`
5. **Do not commit** unless the user asked; suggest a conventional commit per task when done.

**Epic order:** T1–T6, T8 → (optional) xc-usage / xc-launcher handoffs → **T7**.

---

## Generic implementer prompt (copy per task)

Replace `3` with `T1` … `T8` (e.g. `T2`). Send **only** this block to the implementer subagent.

```text
You are implementing exactly TASK 3 from assets/specs/xc-portable-tools/tasks.md

Worktree: /Users/roalcantara/Work/dots

Authoritative spec (read these; do not rely on this prompt for details):
- assets/specs/xc-portable-tools/tasks.md — work checkboxes + ACCEPTANCE CRITERIA for TASK 3
- assets/specs/xc-portable-tools/requirements.md — Req-* referenced in "Covers" for TASK 3
- assets/specs/xc-portable-tools/design.md — architecture and file layout

Project rules:
- XDG paths; conventional commits; shellcheck on touched zsh bins under config/bin/
- Bin help: #? = license/metadata only; ##? = docopt help via xc-usage (see config/bin/README.md)
- command xc-usage guard "${0:a}" "$@" on new zsh bins; bash uses explicit SCRIPT_PATH where needed
- xc-git MUST be a flat file config/bin/xc-git (same as xc-fabric). NOT config/bin/xc-git/ directory
- Do NOT implement xc-usage --scope / preview or config/bin/xc unless TASK 3 explicitly says so (other handoffs)
- Do NOT implement docopt inference from code (xc-usage design §13)
- Do NOT change unrelated tools, specs, or production behavior outside TASK 3 scope
- Do NOT update HANDOFF.md, requirements.md, design.md, or tasks.md unless TASK 3 is T6/T8 (docs tasks)
- Prefer verify-then-complete: if the repo already satisfies AC, run checks and report DONE with evidence

Skills (load before coding):
~/.claude/skills/bash-scripting/SKILL.md
~/.claude/skills/bun-development/SKILL.md
~/.claude/skills/test-driven-development/SKILL.md
~/.claude/skills/verification-before-completion/SKILL.md

Done when:
Every bullet under "### ACCEPTANCE CRITERIA" for TASK 3 in tasks.md passes (command, exit code, observable output).

Return a short report (not a full file dump):
1. Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
2. Files changed (paths only)
3. Commands run + exit codes (paste relevant stdout/stderr one-liners)
4. AC checklist: copy each AC line from tasks.md → PASS or FAIL
5. Suggested commit subject (conventional commits; user commits manually)

Stop and report BLOCKED if:
- AC requires behavior you cannot verify in this environment
- Task scope conflicts with another epic and tasks.md does not resolve it
- You would need to redesign beyond design.md
```

---

## Generic spec reviewer prompt

Replace `3` (e.g. `T2`).

```text
You are the spec compliance reviewer for xc-portable-tools TASK 3.

Read:
- assets/specs/xc-portable-tools/tasks.md — section `## TASK 3`, ACCEPTANCE CRITERIA only
- assets/specs/xc-portable-tools/requirements.md — Req-* listed in "Covers" for that task

Compare the implementer's report and git diff to those AC bullets only.

Reply:
- ✅ Spec compliant — if every AC bullet is PASS with evidence
- ❌ Spec gaps — numbered list mapping AC bullet → what is missing or extra scope
```

---

## Generic code quality reviewer prompt

Replace `3`.

```text
You are the code quality reviewer for xc-portable-tools TASK 3.

Review the git diff for TASK 3 only.

Check:
- shellcheck-worthy issues on touched config/bin/* zsh scripts
- Flat xc-git path (no package directory reintroduced)
- No accidental restore of lib/xc-git/ or xc-git-* wrappers
- Tests match project patterns (Bun specs under config/bin/tests/)

Reply:
- ✅ Approved
- ❌ Issues — Important / Minor with file:line references
```

---

## Parent agent — one-line dispatch

```text
Execute assets/specs/xc-portable-tools/: tasks T1→T8 in order using HANDOFF.md generic prompts (Implementer → Spec → Quality per task). T7 last. Do not commit unless user asks.
```
