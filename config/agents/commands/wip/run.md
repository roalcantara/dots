---
description: Implement a written plan end to end — resume brief, execute every task with the review rules built in, stop at owner checkpoints, then hand off and ask the plan's author for review
argument-hint: plan=<path> (required), optional to=<session> (the plan author's session), then free notes (e.g. "plan=docs/superpowers/plans/x.md to=kb-c0 start at Task 2")
---

<task>
You are the implementer of a plan someone else wrote. Start from the repository's current state, execute the plan's
tasks in order, and finish with a handoff the author can review. You do not redesign the plan: where it is wrong, you
deviate minimally and say why.
</task>

<context>
Arguments: $ARGUMENTS

- `plan=<path>`: the plan to execute. Required: without it, stop and ask for it.
- `to=<session>`: the plan author's session, passed on to `/wip:handoff`.
- Anything else: the operator's notes (e.g. where to start); they override the plan's order only where they say so.

This command is the first half of a loop: `/wip:run` (implementer) → `/wip:handoff` (end of this session) →
`/wip:review` (the plan's author). The rules below come from reviews of earlier runs; each was broken once.
</context>

<workflow>

## 1. Start

1. Run `/wip:resume`'s probe and brief (`~/.agents/commands/wip/resume.md`, steps 1–4). If the branch's handoff note
   names this plan, continue from its **Next** and respect its **Do not retry**; if it names another plan, say so and
   ask before going on.
2. Record the **base**: `git rev-parse HEAD` now, before your first commit. The handoff needs it.
3. Read the plan's header (goal, architecture, expectations, rules for every task) and its task headings. Read each
   task's body only when you reach it.
4. Show the operator a three-line start: the plan, the base, the first task. Then begin without waiting, unless the
   brief raised a question.

## 2. Execute

Use `superpowers:executing-plans` (or `superpowers:subagent-driven-development` if the plan asks for it), task by task,
with these rules on top of the plan's own:

- **One commit per task**, after its tests and the gate pass. Stage your files with `git add <paths>`, then
  `git commit`: never `git commit <paths>`, never `git commit -a`. Uncommitted files you did not write belong to
  someone else: leave them alone.
- **Lint exceptions:** never a crate- or module-wide `allow`. A scoped `#[expect(…, reason = "…")]` only, and its
  reason names the plan task that removes it, or the reason it must stay. Never invent a history ("kept for backward
  compatibility").
- **Tests claim only what they assert.** A test's name and your claims describe what the test checks, nothing more.
- **Deviations:** when the plan's code does not fit the code as it is, make the smallest change that keeps the plan's
  intent, and record it in the commit body ("Deviation: …, because …").
- **Owner checkpoints:** when a task says to stop and ask the owner, do its preparatory steps first (capture, compare,
  measure), then stop and ask with the evidence: list every artefact by path (each screenshot, report, diff) and say
  you opened each one and what it shows. Never decide for the owner, and never write their approval: no "approved by
  owner" or sign-off line in any file. The owner writes it, after reviewing.
- **Look before you claim.** A screenshot, image or generated file counts as checked only once you have opened it and
  it shows what its name says. Two artefacts that should differ but are byte-identical are a failure, not a pass.
- **After an interrupted turn** (a provider error, an aborted request, a retry), re-read the repository state
  (`git status`, the last commit, the files you were editing) before continuing; never assume the interrupted step
  finished.
- **Measure before optimising:** if a task asks to make something faster, measure before and after, and keep the change
  only if the numbers improve.
- **Blocked:** if a task cannot be done (a dependency will not build, a test cannot pass without changing a gate),
  stop, say why, and go to step 3. Never weaken a gate to get past it.

## 3. Finish

Run `/wip:handoff plan=<plan path> to=<session if given>` (`~/.agents/commands/wip/handoff.md`), with:

- `base:` the commit recorded in step 1.2;
- **Claims** per task: done / partial / not started, each with its evidence (commit, test, gate run);
- the `/wip:review <plan> base=<base>` line sent to the author's session, or printed for the operator to paste.

</workflow>

<checklist>
- [ ] Base recorded before the first commit; brief shown.
- [ ] One commit per task, staged with `git add` then `git commit`; nothing of others touched.
- [ ] No module-wide `allow`; every `expect` reason names its removing task or why it stays.
- [ ] Test names and claims match what the tests assert.
- [ ] Owner checkpoints prepared and asked with every artefact listed and opened; no approval written for the owner.
- [ ] Every generated artefact opened and checked against its name before it was claimed.
- [ ] Handoff written with base and claims per task; the review line sent or printed.
</checklist>
