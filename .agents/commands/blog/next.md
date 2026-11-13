---
description: Show where the blog's posts stand and take the next step (runs only safe steps; asks before the rest)
argument-hint: Optional post folder (YYYY-MM-DD-slug), then free notes
allowed-tools: Bash(mise run -q blog:status:*), Bash(mise run blog:status:*), Bash(mise run blog:check:*), Bash(mise run blog:report:*), Bash(mise run blog:stats:*)
---

<task>
Tell the author where the blog stands and move the current post one step forward. Arguments: $ARGUMENTS
</task>

<context>
Stages and next steps (computed by `blog:status`, from docs/blog/TODO.yaml, the post folders, the gate review and
the pull requests):

!`mise run -q blog:status $1`

How a post moves: @docs/blog/README.md (QUICK REFERENCE).
</context>

<workflow>
1. Read the status above. Name the post you mean (an argument wins; else the current `feat/post-*` branch; else the
   latest post that isn't closed) and its stage.
2. If the next step is `mise run blog:check`, `blog:report` or `blog:stats` (48 h after publishing), run it and
   report the result.
3. Otherwise print the exact command to run next and why, without running it: `/blog:pick`, `mise run blog:new …`,
   `/blog:draft`, `mise run blog:cover …`, `/blog:gate`, `/blog:pr`, `mise run blog:publish`, merging the PR,
   `/blog:share`, `/blog:retro`. For `blog:new` and `blog:cover`, propose the full command line with its arguments.
4. Never push, open or merge pull requests, or publish.
</workflow>

<checklist>
- [ ] One post named, with its stage.
- [ ] At most one step run, and only a safe one.
- [ ] The next command printed exactly.
</checklist>
