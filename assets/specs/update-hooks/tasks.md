# Task List: Replace pre-commit + gitlint with hk

**Date:** 2026-05-23
**Plan:** [implementation-plan.md](./implementation-plan.md)
**Design:** [design.md](./design.md)

---

## Phase 1 — Create hk.pkl (Core Config)

- [ ] **1.1** Create `hk.pkl` at project root
  - [ ] `amends` versioned Config.pkl package
  - [ ] `import` Builtins.pkl
  - [ ] Define `stagingLinters` mapping
    - [ ] `shellcheck` step (glob: `*.sh`, `*.bash`, `*.zsh`, `install`, `script/*.sh`)
    - [ ] `shfmt` step (glob: `*.sh`, `*.bash`, `*.zsh`) with `check` and `fix`
    - [ ] `markdownlint` step via Builtins (glob: `**/*.md`)
    - [ ] `hadolint` step via Builtins (glob: `**/Dockerfile*`)
    - [ ] `yamllint` step (glob: `**/*.yml`, `**/*.yaml`)
    - [ ] `taplo` step (glob: `**/*.toml`) with `check` and `fix`
  - [ ] Define `pre-commit` hook (`fix = true`, `stash = "git"`, `steps = stagingLinters`)
  - [ ] Define `commit-msg` hook with inline bash validation script
    - [ ] Encode conventional-commit types: `feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git`
    - [ ] Title max-length: 80 chars
    - [ ] Block WIP commits (`wip:` prefix)
    - [ ] Ignore merge, revert, fixup, squash commits
    - [ ] Ignore commits containing "release" in title
  - [ ] Define `fix` hook (same steps as pre-commit, `fix = true`)
  - [ ] Define `check` hook (same steps, check-only)

- [ ] **1.2** Create `config/hk/hkrc.pkl`
  - [ ] `amends` versioned Config.pkl package
  - [ ] Set `settings.jobs = 4`
  - [ ] Set `settings.mise = true`

- [ ] **1.3** Create `config/hk/README.md`
  - [ ] Document purpose of hkrc.pkl
  - [ ] Document symlink target: `~/.config/hk/config.pkl`
  - [ ] Document available `hk` commands: `hk fix`, `hk check`, `hk run`

---

## Phase 2 — Install Hooks

- [ ] **2.1** Add `setup:hooks` task to `mise.toml`
  - [ ] Task: `hk install --global`
  - [ ] Add description: "Install hk git hooks globally"
  - [ ] Add `depends = ["setup:age"]` if appropriate for ordering

- [ ] **2.2** Update `install` script
  - [ ] Add symlink: `config/hk/hkrc.pkl` → `~/.config/hk/config.pkl`
  - [ ] Add `hk install --global` call (or `mise run setup:hooks`)

---

## Phase 3 — Remove Old Tooling

- [ ] **3.1** Delete `.pre-commit-config.yaml`
- [ ] **3.2** Delete `.gitlint`
- [ ] **3.3** Delete `config/gitlint/gitlint.cfg`
- [ ] **3.4** Delete `config/gitlint/` directory
- [ ] **3.5** Delete `config/git/lint/config.ini`
- [ ] **3.6** Delete `config/git/lint/` directory
- [ ] **3.7** Verify no gitlint references remain in `config/git/config`
- [ ] **3.8** Verify no gitlint/pre-commit in `mise.toml` `[tools]`

---

## Phase 4 — Update Documentation

- [ ] **4.1** Update `README.md`
  - [ ] Replace pre-commit/gitlint setup instructions with `hk` instructions
  - [ ] Add `mise run setup:hooks` to setup section
  - [ ] Add brief explanation of `hk fix` and `hk check`

- [ ] **4.2** Update `config/git/README.md`
  - [ ] Remove gitlint references
  - [ ] Add hk reference for commit-msg validation

---

## Phase 5 — Verification

- [ ] **5.1** Run `mise run setup:hooks` — verify exits 0
- [ ] **5.2** Run `hk --version` — verify output
- [ ] **5.3** Test commit-msg rejection
  - [ ] `git commit --allow-empty -m "this is bad"` → FAIL
  - [ ] `git commit --allow-empty -m "wip: something"` → FAIL
  - [ ] `git commit --allow-empty -m "feat: $(python3 -c 'print(\"x\" * 80)')"` → FAIL (too long)
  - [ ] `git commit --allow-empty -m "chore: test hk commit-msg hook"` → SUCCESS
- [ ] **5.4** Test staged-file linting
  - [ ] Create bad `.sh` file, stage it, attempt commit → shellcheck fails
  - [ ] Stage well-formed `.sh` → commit succeeds
- [ ] **5.5** Run `hk check` on all files — verify output
- [ ] **5.6** Run `hk fix` on staged files — verify formatting applied
- [ ] **5.7** Confirm no Python/pre-commit/gitlint required:
  - [ ] `which pre-commit || echo "OK"`
  - [ ] `which gitlint || echo "OK"`
