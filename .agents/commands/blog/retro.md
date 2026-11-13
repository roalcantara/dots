---
description: Seven days after a post, record its numbers and the author's lessons (best comment, keep, change)
argument-hint: Optional post folder, linkedin impressions=… reactions=… comments=… reposts=…, note="…", then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:stats:*), Bash(mise run blog:record:*), Bash(mise run blog:report:*), Bash(mise run -q blog:report:*), Bash(mise run -q blog:todo:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat add:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit:*)
---

<task>
Close the loop on a published post: its numbers at 7 days and what the author learned, recorded on its task.
Arguments: $ARGUMENTS
</task>

<context>
- Where things stand: !`mise run -q blog:status $1`
- Tuning and recalibration rules: @docs/blog/PLAYBOOK.md ("Tuning each element", "Recalibration")
</context>

<workflow>
1. Name the post (argument, else the latest post that isn't closed); its stage should be `measure`.
2. Run `mise run blog:stats`. If LinkedIn numbers were given (`impressions=… reactions=… comments=… reposts=…`),
   run `mise run blog:record <post> linkedin <pairs>`; else ask the author to read them from LinkedIn's analytics.
3. Show the post's numbers against the baseline and the previous posts (`mise run -q blog:report`), in a few lines:
   what moved, which variable changed on purpose (`vars:`), and whether the playbook's rules for changing the
   backlog apply.
4. Ask the author for the best comment, one thing to keep and one to change. Record each as a comment on the post's
   task (`log.best-comment:`, `log.keep:`, `log.change:`), then commit `docs/blog/TODO.yaml` locally
   (`chore(blog): Close the loop on "<post>"`) and stop; the author pushes.
</workflow>

<checklist>
- [ ] Numbers recorded (API and LinkedIn).
- [ ] The three `log.*` comments are the author's words.
- [ ] Committed locally, not pushed.
</checklist>
