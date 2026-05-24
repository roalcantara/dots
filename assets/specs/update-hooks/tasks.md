# Task List: Replace pre-commit + gitlint with hk

**Date:** 2026-05-23
**Plan:** [implementation-plan.md](./implementation-plan.md)
**Design:** [design.md](./design.md)

---

## Phase 1 — Create hk.pkl (Core Config)

- [x] **1.1** Create `hk.pkl` at project root
  - [x] `amends` versioned Config.pkl package
  - [x] `import` Builtins.pkl
  - [x] Define `stagingLinters` mapping
    - [x] `shellcheck` step (glob: `*.sh`, `*.bash`, `*.zsh`, `install`, `script/*.sh`)
    - [x] `shfmt` step (glob: `*.sh`, `*.bash`, `*.zsh`) with `check` and `fix`
    - [x] `markdownlint` step via Builtins (glob: `**/*.md`)
    - [x] `hadolint` step via Builtins (glob: `**/Dockerfile*`)
    - [x] `yamllint` step (glob: `**/*.yml`, `**/*.yaml`)
    - [x] `taplo` step (glob: `**/*.toml`) with `check` and `fix`
  - [x] Define `pre-commit` hook (`fix = true`, `stash = "git"`, `steps = stagingLinters`)
  - [x] Define `commit-msg` hook with inline bash validation script
    - [x] Encode conventional-commit types: `feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git`
    - [x] Title max-length: 80 chars
    - [x] Block WIP commits (`wip:` prefix)
    - [x] Ignore merge, revert, fixup, squash commits
    - [x] Ignore commits containing "release" in title
  - [x] Define `fix` hook (same steps as pre-commit, `fix = true`)
  - [x] Define `check` hook (same steps, check-only)

- [x] **1.2** Create `config/hk/hkrc.pkl`
  - [x] `amends` versioned Config.pkl package
  - [x] Set `settings.jobs = 4`
  - [x] Set `settings.mise = true`

- [x] **1.3** Create `config/hk/README.md`
  - [x] Document purpose of hkrc.pkl
  - [x] Document symlink target: `~/.config/hk/config.pkl`
  - [x] Document available `hk` commands: `hk fix`, `hk check`, `hk run`

---

## Phase 2 — Install Hooks

- [x] **2.1** Add `setup:hooks` task to `mise.toml`
  - [x] Task: `hk install --global`
  - [x] Add description: "Install hk git hooks globally"
  - [x] Add `depends = ["setup:age"]` if appropriate for ordering

- [x] **2.2** Update `install` script
  - [x] Add symlink: `config/hk/hkrc.pkl` → `~/.config/hk/config.pkl`
  - [x] Add `hk install --global` call (or `mise run setup:hooks`)

---

## Phase 3 — Remove Old Tooling

- [x] **3.1** Delete `.pre-commit-config.yaml`
- [x] **3.2** Delete `.gitlint`
- [x] **3.3** Delete `config/gitlint/gitlint.cfg`
- [x] **3.4** Delete `config/gitlint/` directory
- [x] **3.5** Delete `config/git/lint/config.ini`
- [x] **3.6** Delete `config/git/lint/` directory
- [x] **3.7** Verify no gitlint references remain in `config/git/config`
- [x] **3.8** Verify no gitlint/pre-commit in `mise.toml` `[tools]`

---

## Phase 4 — Update Documentation

- [x] **4.1** Update `README.md`
  - [x] Replace pre-commit/gitlint setup instructions with `hk` instructions
  - [x] Add `mise run setup:hooks` to setup section
  - [x] Add brief explanation of `hk fix` and `hk check`

- [x] **4.2** Update `config/git/README.md`
  - [x] Remove gitlint references
  - [x] Add hk reference for commit-msg validation

---

## Phase 5 — Verification

- [x] **5.1** Run `mise run setup:hooks` — verify exits 0
- [x] **5.2** Run `hk --version` — verify output
- [x] **5.3** Test commit-msg rejection
  - [x] `git commit --allow-empty -m "this is bad"` → FAIL
  - [x] `git commit --allow-empty -m "wip: something"` → FAIL
  - [x] `git commit --allow-empty -m "feat: $(python3 -c 'print(\"x\" * 80)')"` → FAIL (too long)
  - [x] `git commit --allow-empty -m "chore: test hk commit-msg hook"` → SUCCESS
- [x] **5.4** Test staged-file linting
  - [x] Create bad `.sh` file, stage it, attempt commit → shellcheck fails
  - [x] Stage well-formed `.sh` → commit succeeds
- [x] **5.5** Run `hk check` on all files — verify output
- [x] **5.6** Run `hk fix` on staged files — verify formatting applied
- [x] **5.7** Confirm no Python/pre-commit/gitlint required:
  - [x] `which pre-commit || echo "OK"`
  - [x] `which gitlint || echo "OK"`
