# commit-staged

Same workflow as **commit-all**, but only files that are **already staged** in the index. Produces **multiple atomic commits** from the current staged set, each following **Conventional Commits** and `.cursor/rules/git-guidelines.mdc`.

## Before you start

1. Run `git diff --cached --stat` and `git diff --cached`.  
2. If the index is empty, say so and stop.

## Analyse and chunk

1. Partition **only** staged paths into logical chunks (same grouping rules as commit-all: one topic per commit; merge truly identical cross-vendor copies when they are one change).
2. If **everything** is currently staged and chunks are needed, **unstage all** first so you can restage per chunk:  
   `git reset` (mixed is fine: keeps working tree, clears index).  
   Then for each chunk: `git add -- <pathspec>...` and commit.
3. Present a **plan** (chunks + proposed `type(scope): subject` with subject **≤ 50** chars) before committing, unless the user already approved an explicit plan in chat.

## Commit message rules

Same as **commit-all**:

- `type(scope):` imperative description; subject **≤ 50** chars, lowercase after prefix, no period.
- Body after blank line, **72**-char wrap, **what/why**; optional intent-only `Changes:` bullets.

## Execute (per chunk)

1. Ensure **only** this chunk is staged (`git add -- …` after reset, or partial paths if nothing else is staged).
2. `git diff --cached --stat` must match the chunk.
3. `git commit` with full message.
4. Repeat until all originally intended staged work is committed **or** the user asked to leave some paths unstaged (then state what remains).

## Safety

- Do not drop user changes: if you use `git reset` to unstage, do **not** use `--hard`.
- No force-push; no amend of published commits unless the user asks.

## Done

Show `git log --oneline -n <n>` for new commits.
