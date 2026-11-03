---
description: Review, as the plan's author, work another agent implemented — completeness against the plan, accuracy against the implementer's claims, cleanliness via code review — then patch small follow-ups or hand off large ones
argument-hint: Path to the plan, optionally base=<sha> and the implementer's report pasted after it
---

<task>
You wrote the plan; another agent, often another model, implemented it. Review their work for **completeness** (every
task of the plan is done), **accuracy** (it matches the plan and their claims hold), and **cleanliness** (the code
review finds nothing that matters). Patch small follow-ups yourself; write a handoff prompt for large ones. End with a
report: status, insights, highlights, next best move.
</task>

<context>
Arguments: $ARGUMENTS

- The plan is the first path in the arguments. `base=<sha>` overrides the start of the range.
- The implementer's claims come from the pasted report if any, else from their handoff note (`/wip:handoff`) at
  `$(git rev-parse --git-common-dir)/wip/<branch>.md`, each `/` of the branch turned into a hyphen (`feat/x` → `feat-x.md`). Claims are hypotheses to test, never
  facts (`receiving-code-review`): verify each against the code and a run before accepting it.
- Plan checkboxes are not evidence: executors often do not tick them.
- Uncommitted files you did not write belong to someone else (another agent may still be working): never stage, edit
  or revert them.
</context>

<workflow>

## 1. Collect (one shell call; read nothing else yet)

```bash
set +e
plan="<plan path>"; base="<base= argument, if given>"
branch=$(git branch --show-current)
note="$(git rev-parse --git-common-dir)/wip/$(echo "$branch" | tr / -).md"
[ -z "$base" ] && [ -f "$note" ] && base=$(sed -n 's/^base: *//p' "$note")
[ -z "$base" ] && base=$(git log --diff-filter=A --format=%H -1 -- "$plan") && echo "## base guessed: the commit that added the plan"
# A typed SHA can be wrong past its first characters: fall back to its short form, then say so.
git cat-file -e "$base^{commit}" 2>/dev/null || { base=$(git rev-parse --verify -q "${base:0:7}^{commit}") && echo "## base repaired from its short form: $base"; }
echo "## range $(git rev-parse --short "$base")..$(git rev-parse --short HEAD)"
# Code and the plan itself; other docs (research, other plans) are left out.
only=(-- . ":(exclude)docs/**" "$plan")
git log --oneline "$base"..HEAD "${only[@]}" | head -40
echo "## files"; git diff --stat=100 "$base"..HEAD "${only[@]}" | tail -40
echo "## uncommitted"; git status --short | head -20
echo "## tasks"; grep -n -E '^#{2,3} (Task|Step) ' "$plan"
echo "## claims"; [ -f "$note" ] && sed -n '/^\*\*Claims:\*\*/,/^\*\*Half done:\*\*/p' "$note"
```

If the range holds commits unrelated to the plan (other work on the branch), set them aside by subject and say so.

## 2. Completeness: plan → evidence

For each task heading, find its evidence: the commit(s) and files that implement it. Read a task's section of the plan
only to resolve doubt, never the whole plan up front. Table:

| Task | Evidence (commit · files) | Status: done / partial / missing / deviated |

A deviation is not a defect by itself: judge whether it was forced by the code as it is (the plan was wrong) or a
shortcut. Owner checkpoints the plan names are reported, not decided by you.

## 3. Accuracy: plan and claims → code

- Names, signatures, file paths and constants match the plan's code blocks, or the difference is justified.
- Each claim is tested: rerun the test it cites, read the line it names. Mark it **holds / refuted / unverified**.
- Run the repository's full gate (from its instruction files, e.g. `mise run gate`) once, and quote its result
  (`verification-before-completion`). A failing gate is the first finding.

## 4. Cleanliness: code review of the range

Run the agent's code-review skill on `base..HEAD` (`/code-review` in Claude Code). Without one, dispatch a fresh
subagent with `~/.agents/skills/requesting-code-review/code-reviewer.md`, filling DESCRIPTION, PLAN_OR_REQUIREMENTS
(the plan path), BASE_SHA, HEAD_SHA. Keep findings that survive your own check; drop the ones the plan decided
deliberately.

## 5. Follow-ups

- **Small** (about 20 lines or fewer, no design change, no file someone else is editing): patch it, run the affected
  tests and the gate, commit only your files with an explicit path list (never `-a`).
- **Large** or ambiguous: write a handoff prompt the implementer can run as is: the plan path, each finding with
  `file:line`, the expected result, how to verify it, and what not to touch.

## 6. Report

```markdown
**Status:** <complete | complete with follow-ups | incomplete> — <tasks done>/<tasks>; gate <pass | fail>
**Claims:** <n> hold · <n> refuted · <n> unverified (list the refuted and unverified)
**Findings:** <severity — file:line — finding — patched (sha) | handed off> (most severe first)
**Insights:** <what the work revealed about the plan or the code: wrong assumptions, rules that bit, reusable lessons>
**Highlights:** <what was done notably well>
**Next best move:** <one step; the handoff prompt below it if any>
```

</workflow>

<checklist>
- [ ] Every task of the plan has a row; checkboxes were not taken as evidence.
- [ ] Every claim tested and marked; the gate run and quoted.
- [ ] Code review run on the range; kept findings verified.
- [ ] Patches small, tested, committed with explicit paths; nothing of others touched.
- [ ] Report has status, claims, findings, insights, highlights, next best move.
</checklist>
