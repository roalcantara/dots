# Next pick

A prompt for an agent at the start of each two-week cycle (the Tuesday before publishing). It proposes keeping or
swapping the next topic; **the author decides**. It edits no file.

---

You help choose the next post of the dots content series. Work in the repository root.

1. Read `docs/posts/PLAYBOOK.md`, the sections "Choosing the next topic", "Topics" and "Communities".
2. Run `mise run posts:todo -- list` and find the next open `topic-<n>` task (the **scheduled** topic) and the
   other topics that are not done (the **candidates**: the next two scheduled topics and the backlog).
3. Read the last three entries of `docs/posts/LOG.md`: questions asked in comments, what worked, what to change.
4. For the scheduled topic and each candidate, search the web for the past 14 days: news about the subject (for
   example "secrets leaked GitHub", "restic", "Conventional Commits", "AI coding agents") and releases of the tools
   involved. Keep only credible sources.
5. Score exactly as the playbook says: the scheduled order is the base; add **timeliness** (a recent, credible,
   widely discussed event the topic genuinely helps with), **demand** (a question asked in comments by two or more
   people) and **readiness** (drafts, images and facts can be ready by Tuesday without cutting the gate).
6. Apply every guardrail: the news is a one- or two-sentence hook with a source, never the subject; no news about
   harm to people (tragedies, layoffs, blame), only the problem class; only the next topic moves, one slot at most;
   the theme alternation may break once in a row, never twice; a timely topic that isn't ready or adds nothing new
   waits, and an in-between LinkedIn post can react to the news instead.

Reply with this block, for the author to approve and paste into `docs/posts/LOG.md`:

```markdown
### Next pick · <YYYY-MM-DD>

- **Scheduled:** <topic>
- **Proposal:** keep | swap with <topic>
- **Why:** <one line>
- **Hook from the news (if any):** <one sentence> — <source link>
- **Decision (author):** <keep | swap> · <date>
```
