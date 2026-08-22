# Implementation Plan: Replace pre-commit + gitlint with hk

**Date:** 2026-05-23
**Design Doc:** [design.md](./design.md)
**Target Directory:** `docs/specs/update-hooks/`
**Estimated Effort:** 1 focused session (~2-3 hours)

---

## Overview

Migrate the `dots` project from `pre-commit` + `gitlint` to `hk` — the high-performance Rust git hook manager by jdx. This plan drives implementation from the approved [design doc](./design.md).

---

## Prerequisites

- `mise` is already installed and `hk = "latest"` is declared in `mise.toml`
- Git 2.54+ (required for `hk install --global`)
- Tools in scope (`shellcheck`, `shfmt`, `markdownlint`, `hadolint`, `yamllint`, `taplo`) should be resolvable via `mise`

---

## Phase 1 — Create `hk.pkl` (Core Config)

### 1.1 Create `hk.pkl` at project root

**File:** `/Users/roalcantara/Work/dots/hk.pkl`

Content: Full Pkl config as defined in [design.md § Architecture](./design.md).

Key points:

- `amends` the versioned hk Config.pkl package
- Imports `Builtins.pkl` for `markdownlint` and `hadolint`
- Defines `stagingLinters` mapping (shellcheck, shfmt, markdownlint, hadolint, yamllint, taplo)
- Defines `pre-commit` hook with `fix = true` and `stash = "git"`
- Defines `commit-msg` hook with inline bash script that replicates all gitlint rules
- Defines `fix` and `check` hooks for manual/CI use

**Validation rules to encode from current `.gitlint`:**

- Types: `feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git`
- Title max-length: 80 chars
- Block WIP: no `wip:` prefix
- Ignore: merge, revert, fixup, squash commits
- Ignore: titles containing "release"
- Ignore: commits by dependabot (author check — note: commit-msg hook can't check author; this is a CI-level concern)

---

### 1.2 Create `config/hk/hkrc.pkl` (User-Level Dotfile)

**File:** `/Users/roalcantara/Work/dots/config/hk/hkrc.pkl`

This file is distributed as part of the dotfiles and will be symlinked to `~/.config/hk/config.pkl` by the install script.

Content:

```pkl
amends "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Config.pkl"

settings {
  jobs = 4
  mise = true
}
```

---

### 1.3 Create `config/hk/README.md`

Brief documentation of the hk configuration for this dotfiles project.

---

## Phase 2 — Install Hooks

### 2.1 Add `setup:hooks` task to `mise.toml`

```toml
"setup:hooks" = {
  description = "Install hk git hooks globally",
  run = "hk install --global"
}
```

This integrates hk installation into the existing `mise run` workflow alongside `setup:age` and `setup:git:filters`.

### 2.2 Update `install` script

The `install` shell script sets up the dotfiles environment. Add:

1. Symlink `config/hk/hkrc.pkl` → `~/.config/hk/config.pkl`
2. Call `mise run setup:hooks` (or `hk install --global` directly)

---

## Phase 3 — Remove Old Tooling

### 3.1 Delete `.pre-commit-config.yaml`

```
/Users/roalcantara/Work/dots/.pre-commit-config.yaml
```

### 3.2 Delete `.gitlint`

```
/Users/roalcantara/Work/dots/.gitlint
```

### 3.3 Delete `config/gitlint/` directory

```
/Users/roalcantara/Work/dots/config/gitlint/
```

This removes `config/gitlint/gitlint.cfg`.

### 3.4 Delete `config/git/lint/` directory

```
/Users/roalcantara/Work/dots/config/git/lint/
```

This removes `config/git/lint/config.ini`.

### 3.5 Remove gitlint reference from git config

In `config/git/config`, there is no direct gitlint reference to remove, but verify there are no gitlint hooks registered in `[core] hooksPath` or elsewhere.

---

## Phase 4 — Update Documentation

### 4.1 Update `README.md`

- Add section on `hk` as the git hook manager
- Remove any reference to `pre-commit` or `gitlint`
- Add `mise run setup:hooks` to the setup instructions

### 4.2 Update `config/git/README.md`

- Remove any reference to gitlint
- Add reference to `hk` for commit-msg validation

---

## Phase 5 — Verification

### 5.1 Verify hk is installed

```sh
mise run setup:hooks
hk --version
```

### 5.2 Test commit-msg rejection

```sh
# Should fail (non-conventional):
git commit --allow-empty -m "this is bad"

# Should fail (WIP):
git commit --allow-empty -m "wip: something"

# Should fail (too long > 80 chars):
git commit --allow-empty -m "feat: $(python3 -c 'print(\"x\" * 80)')"

# Should succeed:
git commit --allow-empty -m "chore: test hk commit-msg hook"
```

### 5.3 Test staged-file linting

```sh
# Create a bad shell file and stage it:
echo 'if [ "$1" == "" ]; then echo hi; fi' > /tmp/test.sh
cp /tmp/test.sh ./test-hk.sh
git add test-hk.sh
git commit -m "test: verify shellcheck hook"
# Should fail with shellcheck errors
git restore --staged test-hk.sh && rm test-hk.sh
```

### 5.4 Test `hk check`

```sh
hk check
```

### 5.5 Test `hk fix`

```sh
# Stage a badly formatted shell file:
echo 'echo "hello"
echo "world"' > test-shfmt.sh
git add test-shfmt.sh
hk fix
git restore --staged test-shfmt.sh && rm test-shfmt.sh
```

### 5.6 Confirm old tools are no longer required

```sh
# Should work without pre-commit or gitlint installed:
which pre-commit || echo "pre-commit not found — OK"
which gitlint || echo "gitlint not found — OK"
```

---

## File Changeset Summary

### New Files

| File | Purpose |
| ------ | --------- |
| `hk.pkl` | Primary hk project configuration |
| `config/hk/hkrc.pkl` | User-level hk defaults (distributed dotfile) |
| `config/hk/README.md` | Documentation for hk config |

### Modified Files

| File | Change |
| ------ | -------- |
| `mise.toml` | Add `setup:hooks` task |
| `install` | Add hkrc symlink + `hk install --global` |
| `README.md` | Update setup section |
| `config/git/README.md` | Remove gitlint references |

### Deleted Files

| File | Reason |
| ------ | -------- |
| `.pre-commit-config.yaml` | Replaced by `hk.pkl` |
| `.gitlint` | Replaced by commit-msg step in `hk.pkl` |
| `config/gitlint/gitlint.cfg` | Replaced |
| `config/gitlint/` directory | Replaced |
| `config/git/lint/config.ini` | Replaced |
| `config/git/lint/` directory | Replaced |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
| ------ | ------------ | ------------ |
| `pklr` (built-in evaluator) is experimental | Medium | Test thoroughly; fall back to `HK_PKL_BACKEND=pkl` if needed |
| Global hook install affects all repos | Low | hk is a no-op in repos without `hk.pkl` |
| `shfmt` not in mise.toml | Low | Add to `[tools]` section if missing |
| `taplo` not in mise.toml | Low | Add to `[tools]` section if missing |
| Concurrent fix steps corrupt files | Very Low | hk's R/W locking prevents this by design |

---

## Sequencing

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
  ↑
  (can partially test Phase 5.1 and 5.2 before Phase 3)
```

Do **not** delete the old tools (Phase 3) until Phase 5 passes.
