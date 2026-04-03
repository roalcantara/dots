# commit-all

Split **all uncommitted changes** (staged and unstaged) into **atomic commits** and commit each chunk with **Conventional Commits**, following `.cursor/rules/git-guidelines.mdc` and **passing the same checks as** `.pre-commit-config.yaml` (the `gitlint` hook) and repo **`.gitlint`**.

## Before you start

1. Run `git status -sb` and `git diff` (unstaged + overview). Use `git diff --stat` for a quick map.
2. If there is nothing to commit, say so and stop.

## Analyse and chunk

1. **Group by intent**, not only by folder. Prefer:
   - One commit per **topic** (feature, fix, chore, ci, docs, etc.).
   - Merge paths that are the **same change replicated** (e.g. `config/claude/*`, `config/cursor/*`, `config/github/*` skill/command mirrors) into **one** commit with a scope like `skills` or `agents` if that matches the change.
   - Keep **unrelated** edits separate even if they touch nearby files.
2. **Order chunks** so the history reads well (e.g. config/tooling before drive-by formatting, or dependencies last—use judgment).
3. Present a short **plan** to the user: table or list of chunks with paths + proposed full first line `type(scope): Description` (**description ≤ 50 characters**, imperative, **capital first letter**, **no period**).

## Commit message rules (must satisfy)

- Format: `type(optional-scope): Description` — **allowed types** must match **`.gitlint`** `[contrib-title-conventional-commits]` / pre-commit: `feat`, `fix`, `docs`, `style`, `ref`, `test`, `revert`, `chore`, `ci`, `build`, `perf`, `git`. Use **`ref`** for refactors (**not** `refactor`).
- **First line (title)**: entire line **≤ 80** characters (`.gitlint` `title-max-length`); keep the **description** after the prefix **≤ 50** characters when possible (project guideline). Imperative mood; **capitalize the first letter** of the description; no trailing period.
- **Body**: blank line after title; each body line **≤ 120** characters (`.gitlint` `body-max-line-length`); prefer **≤ 72** for readability (project guideline). Explain **what** and **why**. Ensure the body is non-trivial so `body-min-length` and related rules pass. Optional `Changes:` bullets for intent-level notes.

## Execute (per chunk)

For **each** chunk, in order:

1. **Stage only** that chunk’s paths: `git add -- <pathspec>...`  
   Avoid `git add -A` unless the chunk truly is the whole working tree for that commit.
2. **Verify** the index matches the chunk: `git diff --cached --stat` (and spot-check `git diff --cached` if needed).
3. **Commit** with the full message (title + body), e.g. `git commit -m "$(cat <<'EOF'
feat(scope): Add short imperative description here

Body explaining what and why. Wrap for readability; keep each
line within gitlint body limits.

Changes:
- High-level intent bullet
EOF
)"` or equivalent.
4. **Verify with pre-commit gitlint** (same as a real `git commit` with hooks): from the **repository root**, run:
   ```bash
   _f=$(mktemp)
   git log -1 --format=%B > "$_f"
   pre-commit run gitlint --hook-stage commit-msg --commit-msg-filename "$_f"
   rm -f "$_f"
   ```
   If this **fails**, fix the message and **`git commit --amend`** (or `git reset --soft HEAD~1` and recommit) until it **passes**.  
   *Optional:* If pre-commit’s unstaged-file stash is disruptive mid-batch, the same message can be checked with `gitlint --msg-filename "$_f"` from the repo root (uses `.gitlint`).
5. Repeat until **no** unstaged or uncommitted changes remain for the intended scope of this command.

## Safety

- Do **not** `--amend` or rewrite published history unless the user explicitly asks.
- Do **not** commit secrets or generated artifacts the repo should ignore; if you see any, stop and warn.

## Done

Show `git log --oneline -n <number-of-commits>` for the new commits and a one-line summary.
