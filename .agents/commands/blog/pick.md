---
description: Choose the next blog topic from the schedule, recent news and comments; record the author's decision
argument-hint: Optional note="…" (anything to weigh, e.g. note="secrets leak in the news"), then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:report:*), Bash(mise run -q blog:report:*), Bash(mise run blog:todo:*), Bash(mise run -q blog:todo:*), WebSearch, WebFetch
---

<task>
Propose keeping or swapping the next topic of the dots blog, for the author to decide; then record the decision.
Notes from the author: $ARGUMENTS
</task>

<context>
- Rules: @docs/blog/PLAYBOOK.md, sections "Choosing the next topic", "Topics" and "Communities".
- Where things stand: !`mise run -q blog:status`
</context>

<workflow>
1. Run `mise run -q blog:todo -- list`: the next open topic task (one `topic-<n>` tag, not `in-between` or
   `community`) is the **scheduled** topic; the next two scheduled topics and the backlog are the **candidates**.
2. Run `mise run -q blog:report`: the last posts' numbers, `log.*` lessons and notes (questions asked in comments,
   what worked, what to change).
3. For the scheduled topic and each candidate, search the web for the past 14 days: news about the subject (for
   example "secrets leaked GitHub", "restic", "Conventional Commits", "AI coding agents") and releases of the tools
   involved. Keep only credible sources.
4. Score exactly as the playbook says: the scheduled order is the base; add **timeliness** (a recent, credible,
   widely discussed event the topic genuinely helps with), **demand** (a question asked in comments by two or more
   people) and **readiness** (drafts, images and facts can be ready by Tuesday without cutting the gate). Weigh the
   author's notes.
5. Apply every guardrail: the news is a one- or two-sentence hook with a source, never the subject; no news about
   harm to people (tragedies, layoffs, blame), only the problem class; only the next topic moves, one slot at most;
   the theme alternation may break once in a row, never twice; a timely topic that isn't ready or adds nothing new
   waits, and an in-between LinkedIn post can react to the news instead.
6. Show the `<pick_block>` below, filled in, and ask the author to decide keep or swap.
7. After the author answers, record it on the chosen topic's task:
   `mise run -q blog:todo -- add --comment "pick: <YYYY-MM-DD> <keep|swap> <reason> <source>" --task-id <id>`, then
   commit `docs/blog/TODO.yaml` locally (`chore(blog): Pick the next topic`) and stop; the author pushes. On a swap,
   also move the two tasks' due dates with `blog:todo -- update <id> --due "<YYYY-MM-DD> 09:00"`.
8. End with the next command: `mise run blog:new <slug> --task <id>`.
</workflow>

<checklist>
- [ ] Every candidate searched; only credible sources.
- [ ] The author decided; nothing recorded before that.
- [ ] `pick:` comment recorded and committed locally, not pushed.
</checklist>

<pick_block>

```markdown
### Next pick · <YYYY-MM-DD>

- **Scheduled:** <topic>
- **Proposal:** keep | swap with <topic>
- **Why:** <one line>
- **Hook from the news (if any):** <one sentence> — <source link>
```

</pick_block>
