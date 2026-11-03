---
description: Start a session with a short current-state brief — recent history, uncommitted work, the next ready task and the last handoff (to implement a plan, use /wip:run) — as pointers, not contents
argument-hint: Optional task the operator already has in mind (e.g. "8g Task 1")
---

<task>
Give yourself, at the lowest token cost, the state a fresh session cannot see: what changed recently, what is
uncommitted, what is next, and what the last session left unsaid. Print a brief of at most 30 lines, then stop.
</task>

<context>
Evidence behind this shape (`kb` repo, `docs/superpowers/research/2026-10-13-session-brief-check.md`):

- Recent history plus a short state note, the **next ready task** rather than the whole plan, lean current state
  rather than a log, and pointers rather than contents: each is recommended by three or more independent sources
  (Anthropic's long-running harness, Beads, the Ralph loop, Cline's memory bank, handoff skills).
- Repository overviews raise cost without raising success (Gloaguen et al., arXiv 2602.11988): never summarise the
  architecture, the docs or the code here. The agent's instruction files already carry the conventions.

Operator's task, if given: $ARGUMENTS
</context>

<workflow>

## 1. Probe (one shell call, bounded output)

Run this block as is; each probe is capped, and a missing tool prints nothing.

```bash
set +e
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repository"; exit 0; }
cd "$root"
branch=$(git branch --show-current); head=$(git rev-parse --short HEAD)
echo "## where"; echo "$(basename "$root") · $branch @ $head"
echo "## uncommitted"; git status --short | head -15
echo "## recent"; git log --oneline -8
echo "## handoff"; f="$(git rev-parse --git-common-dir)/wip/$(echo "$branch" | tr / -).md"; [ -f "$f" ] && cat "$f"
echo "## tasks"
if command -v bd >/dev/null && [ -d .beads ]; then bd ready 2>/dev/null | head -5
elif [ -f TODO.md ]; then grep -n -m 5 -E '^\s*[-*] \[ \]|^\s*[-*] \[~\]' TODO.md
else
  # No task list: fall back to plans with unticked boxes, newest first (noisy where executors do not tick them).
  echo "## open plans"
  git ls-files '*plans/*.md' '*PLAN*.md' 2>/dev/null | while read -r p; do
    n=$(grep -c -- "- \[ \]" "$p"); [ "$n" -gt 0 ] && printf "%s\t%s open · %s\n" "$(git log -1 --format=%cs -- "$p")" "$n" "$p"
  done | sort -r | head -3 | cut -f2
fi
```

## 2. Read nothing else

Do not open the plans, ADRs, docs or code the probes point to. Each is loaded later, only when the task needs it.

## 3. Judge the handoff

- No handoff: say so; the brief rests on git and the task list.
- Stale handoff: its `commit` is not an ancestor of HEAD (`git merge-base --is-ancestor`), or more than 20 commits
  behind: mark it stale and trust git over it.
- Uncommitted files the handoff does not mention may belong to another agent or the operator: list them as "not
  mine", never stage or edit them.

## 4. Print the brief (≤ 30 lines)

```markdown
**Where:** <repo> · <branch> @ <sha> · <n> uncommitted (<k> not mine)
**Recent:** <3–5 commit subjects that matter, newest first>
**Handoff** (<date>, <fresh | stale | none>): <half-done work, decisions, do-not-retry — one line each>
**Next:** <one task: the operator's, else the handoff's next step, else the first ready task> — <why it is next>
**Pointers for Next:** <paths to read first, at most 5; no contents>
```

## 5. Stop

Ask the operator to confirm **Next** or name another task. Begin only after they answer.

</workflow>

<checklist>
- [ ] One probe call; nothing else read before the operator confirms the task.
- [ ] Brief ≤ 30 lines; no architecture, conventions or doc summaries.
- [ ] Exactly one Next, with its reason.
- [ ] Stale handoff flagged; files not mine listed and left alone.
</checklist>
