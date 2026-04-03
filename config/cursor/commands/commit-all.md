# commit-all

Split **all uncommitted changes** (staged and unstaged) into **atomic commits** and commit each chunk with **Conventional Commits**, following the project rules in `.cursor/rules/git-guidelines.mdc` (and the same spirit as the extended commit guide: one logical change per commit, revert-friendly).

## Before you start

1. Run `git status -sb` and `git diff` (unstaged + overview). Use `git diff --stat` for a quick map.
2. If there is nothing to commit, say so and stop.

## Analyse and chunk

1. **Group by intent**, not only by folder. Prefer:
   - One commit per **topic** (feature, fix, chore, ci, docs, etc.).
   - Merge paths that are the **same change replicated** (e.g. `config/claude/*`, `config/cursor/*`, `config/github/*` skill/command mirrors) into **one** commit with a scope like `skills` or `agents` if that matches the change.
   - Keep **unrelated** edits separate even if they touch nearby files.
2. **Order chunks** so the history reads well (e.g. config/tooling before drive-by formatting, or dependencies last—use judgment).
3. Present a short **plan** to the user: table or list of chunks with paths + proposed `type(scope): subject` (subject **≤ 50 characters**, imperative, **no period**).

## Commit message rules (must satisfy)

- Format: `type(optional-scope): imperative description` — types from project guidelines: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`, `revert`.
- Subject: **≤ 50 chars**, **lowercase** after the type/scope prefix (per project git guidelines), imperative mood, no trailing period.
- Body: blank line after subject; wrap at **72** columns; explain **what** and **why**, not implementation noise. Optional `Changes:` bullets for intent-level notes.

## Execute (per chunk)

For **each** chunk, in order:

1. **Stage only** that chunk’s paths: `git add -- <pathspec>...`  
   Avoid `git add -A` unless the chunk truly is the whole working tree for that commit.
2. **Verify** the index matches the chunk: `git diff --cached --stat` (and spot-check `git diff --cached` if needed).
3. **Commit** with the full message (subject + body), e.g. `git commit -m "$(cat <<'EOF'
type(scope): Short imperative subject under fifty chars

Body line explaining what and why, wrapped at seventy-two
characters per line.

Changes:
- High-level intent bullet
EOF
)"` or equivalent.
4. Repeat until **no** unstaged or uncommitted changes remain for the intended scope of this command.

## Safety

- Do **not** `--amend` or rewrite published history unless the user explicitly asks.
- Do **not** commit secrets or generated artifacts the repo should ignore; if you see any, stop and warn.

## Done

Show `git log --oneline -n <number-of-commits>` for the new commits and a one-line summary.
