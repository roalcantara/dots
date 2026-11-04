---
description: End a session by writing the handoff note the next session reads with /wip:resume — only what git and the task list cannot tell it (why, half-done work, what not to retry, the next step)
argument-hint: Optional plan=<path> (the plan this work implements), to=<session> (notify its author), then free notes (e.g. "plan=docs/superpowers/plans/x.md to=kb-c0 empty view first")
---

<task>
Write, or replace, this branch's handoff note: the state the next session needs and cannot derive. It is current
state, never a log. At most 40 lines.
</task>

<context>
The note lives outside the working tree, per branch, shared by every worktree of the repository:

`$(git rev-parse --git-common-dir)/wip/<branch>.md`, with every `/` in the branch name turned into a hyphen
(`feat/design-system` → `feat-design-system.md`). Compute it, never type it:

```bash
note="$(git rev-parse --git-common-dir)/wip/$(git branch --show-current | tr / -).md"; mkdir -p "$(dirname "$note")"
```

It is never committed. `/wip:resume` reads it and flags it stale when its commit falls behind HEAD.

What the next session can already derive, and the note must not repeat: commit history, the diff, the task list,
plan checkboxes, the instruction files.

Arguments: $ARGUMENTS

- `plan=<path>`: the plan this work implements. Without it, use the plan named in this session's task; if none, the work
  implements no plan.
- `to=<session>`: the plan author's session, to notify in step 5.
- Anything else: the operator's notes, included in the note.
</context>

<workflow>

0. **Guard: is there anything to hand off?** If this session made no commit, changed no file and decided nothing (the
   existing note's `commit:` equals HEAD and `git status --short` is empty, or there is no work in this conversation),
   write nothing and stop with: "Nothing to hand off: this session did no work. To start a plan, run
   `/wip:run plan=<path>`." Never replace a useful note with an empty one.
1. **Commit or say why not.** Finished work goes in commits with descriptive messages first; the note covers only
   what stays uncommitted or unsaid. Stage your own files with `git add <paths>`, then `git commit` (never
   `git commit <paths>` or `-a`).
2. **Gather.** `git status --short`, `git log --oneline -5`, and this session's own decisions and dead ends.
3. **Write the note**, replacing the old one (to `$note`, computed above):

```markdown
---
branch: <branch>
base: <full sha HEAD had before this piece of work (this plan or task) began: the parent of its first commit, never the branch start>
commit: <full sha of HEAD>
date: <yyyy-mm-dd hh:mm>
---

**Goal:** <what the work is for, one line>
**Done this session:** <commit subjects, or "nothing committed">
**Claims:** <what you assert is complete and verified, each with its evidence: task id, test, gate run> ("none")
**Half done:** <path — what is in it and what is missing> (one per line; "none")
**Decisions:** <decision — why> (only those not in a commit message, ADR or plan)
**Do not retry:** <approach — why it failed>
**Not mine:** <uncommitted paths that belong to another agent or the operator>
**Next:** <one step, concrete enough to start without asking>
**Pointers:** <paths the next session should read first, at most 5>
```

4. **Check it.** Every SHA was pasted from `git rev-parse` output, never typed or completed from a short form, and
   resolves (`git cat-file -e <sha>^{commit}`); no placeholders; every path exists; nothing repeated from git or the task list; ≤ 40 lines. Print
   the note's path and its **Next** line.
5. **Ask for review, if the work implements a plan.** Print the line the plan's author runs:
   `/wip:review <plan path> base=<base>` (the plan from `plan=` or the session's task; base from the note). If the operator named the authoring session (`to=<name>` in the arguments) and the agent
   can message other sessions (Claude Code: `SendMessage`), also send that line there, with one sentence of what
   landed. Print it either way: agents without cross-session messages (e.g. omp) rely on the operator to paste it.

</workflow>

<checklist>
- [ ] Nothing written when the session did no work (step 0).
- [ ] Finished work committed first; only own files staged.
- [ ] Old note replaced, not appended to.
- [ ] Only what git and the task list cannot tell; ≤ 40 lines.
- [ ] Every claim carries its evidence; nothing claimed that was not run.
- [ ] Exactly one Next.
</checklist>
