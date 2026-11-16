---
description: Open the pull request for a blog post that passed the gate, with its title and body written (never merges)
argument-hint: Optional post folder (YYYY-MM-DD-slug), note="…" for the PR body, then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:check:*), Bash(mise run blog:push-branch:*), Bash(mise run -q blog:push-branch:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat add:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat commit:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat status:*), Bash(git -c filter.sops.clean=cat -c filter.sops.smudge=cat log:*), Bash(gh pr create:*), Bash(gh pr view:*)
---

<task>
Open the pull request that turns a post into a dev.to draft: commit what's pending on the post branch, push it, and
create the PR with a written title and body. Arguments: $ARGUMENTS
</task>

<context>
- Where things stand: !`mise run -q blog:status $1`
- Commit conventions: @docs/CONTRIBUTING.md
</context>

<workflow>
1. Name the post (argument, else the current `feat/post-*` branch). **Refuse unless its stage is `pr`**, quoting the
   status line: the gate must have passed on the current `post.md`.
2. Run `mise run blog:check <post>`; stop on any block.
3. On the post branch, commit pending changes to the post folder and `docs/blog/TODO.yaml` (named paths, through the
   SOPS git wrapper, Conventional message, the Co-Authored-By line from the session), then `mise run blog:push-branch`.
4. `gh pr create --base main` with:
   - **title:** `docs(blog): Add "<post title>"`
   - **body:** what the post is (its description), its RECIPE in one line, the gate verdict and STEPPS score from
     `review.md`, the author's notes, and this checklist for the author:
     `- [ ] Check the dev.to draft preview (link in the bot comment)`,
     `- [ ] Replace any <author: …> markers`,
     `- [ ] mise run blog:publish`,
     `- [ ] Merge (this publishes the post)`,
     `- [ ] /blog:share (LinkedIn, then the first comment)`;
     end with the session's PR attribution line.
5. Print the PR URL. **Never merge, never push to `main`, never set `published: true`.**
</workflow>

<checklist>
- [ ] Stage was `pr`; check had no blocks.
- [ ] Only the post branch pushed.
- [ ] PR created with title and body; not merged.
</checklist>
