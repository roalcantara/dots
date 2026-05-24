# Handoff Prompt: Implement hk Migration

---

## Context

This is a `dots` dotfiles project at `/Users/roalcantara/Work/dots`. The project currently uses two Python-based git hook tools:

- **pre-commit** (`.pre-commit-config.yaml`) — git hook manager, only runs `gitlint` on `commit-msg`
- **gitlint** (`.gitlint`) — validates commit messages against Conventional Commits rules

The goal is to **replace both tools with [hk](https://hk.jdx.dev)** — a Rust-native git hook manager already declared as a tool in `mise.toml` (`hk = "latest"`). The migration should also expand hook coverage to lint staged files on pre-commit.

A complete SDD (Spec-Driven Development) artefact set has been prepared under `docs/specs/update-hooks/`:

| File | Purpose |
|------|---------|
| [design.md](./design.md) | Approved design: architecture, `hk.pkl` structure, decisions |
| [implementation-plan.md](./implementation-plan.md) | Phased plan with file changeset |
| [tasks.md](./tasks.md) | Checkbox task list to track progress |
| [hk-ecosystem.md](./hk-ecosystem.md) | Full hk feature map and opportunity analysis |

---

## Your Mission

Execute the implementation described in the SDD artefacts above, **using `tasks.md` as your progress tracker**.

---

## Key Facts to Know

### Current State
- `hk = "latest"` is already declared in `mise.toml [tools]`
- `mise.toml` has `settings.experimental = true` and `settings.auto_install = true`
- The project has extensive `mise.toml` tasks (`build`, `start`, `test`, `setup:age`, `setup:git:filters`)
- `.gitlint` encodes: types `feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git`, title max 80, WIP block, merge/revert/fixup/squash ignore, release-title ignore
- `config/gitlint/gitlint.cfg` has title max 72 — the ROOT `.gitlint` title max 80 takes precedence (it's what pre-commit uses)
- There's a rich `.editorconfig`, `.shellcheckrc`, `.hadolint.yaml` already in the project

### What to Create

1. **`hk.pkl`** at project root — the primary hk config (see design.md for full Pkl source)
2. **`config/hk/hkrc.pkl`** — user-level dotfile (symlinked to `~/.config/hk/config.pkl`)
3. **`config/hk/README.md`** — brief docs
4. **Add `setup:hooks` task** to `mise.toml`
5. **Update `install` script** to symlink hkrc.pkl and run `hk install --global`

### What to Delete (only after verification passes)

- `.pre-commit-config.yaml`
- `.gitlint`
- `config/gitlint/` directory
- `config/git/lint/` directory

### hk Pkl Syntax Reference

```pkl
// Project config structure:
amends "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Builtins.pkl"

local mySteps = new Mapping<String, Step> {
  ["step-name"] {
    glob  = List("*.sh")
    check = "shellcheck {{files}}"
    fix   = "shfmt -w {{files}}"
  }
  ["using-builtin"] = Builtins.markdownlint
}

hooks {
  ["pre-commit"] {
    fix   = true
    stash = "git"
    steps = mySteps
  }
  ["commit-msg"] {
    steps {
      ["validate"] {
        check = #"bash script here using $1 for the commit msg file"#
      }
    }
  }
}
```

### Important: hk Version

Use **v1.45.0** in package URLs (the current stable version). The `mise.toml` declares `hk = "latest"` which will resolve to v1.45.0 or newer.

### mise.toml Task Syntax

```toml
"setup:hooks" = { description = "Install hk git hooks globally", run = '''
#!/usr/bin/env bash
set -e
hk install --global
echo "✓ hk hooks installed globally"
''' }
```

---

## Execution Order

Follow the phases in `implementation-plan.md` exactly:

```
Phase 1 (Create hk.pkl + hkrc.pkl)
  → Phase 2 (Add mise task + update install script)
  → Phase 5 (Verify before deleting old tools)
  → Phase 3 (Delete old tools)
  → Phase 4 (Update docs)
  → Phase 5 (Final verification)
```

**Do not delete old tools until verification in Phase 5 passes.**

---

## Verification Commands

```sh
# 1. Install hooks
mise run setup:hooks

# 2. Check hk version
hk --version

# 3. Should FAIL (non-conventional):
git commit --allow-empty -m "this is bad"

# 4. Should FAIL (WIP):
git commit --allow-empty -m "wip: temp"

# 5. Should SUCCEED:
git commit --allow-empty -m "chore: test hk commit-msg hook"

# 6. Run check on all files:
hk check

# 7. Confirm old tools not needed:
which pre-commit || echo "pre-commit not found — OK"
which gitlint || echo "gitlint not found — OK"
```

---

## Files to Read First

Before starting, read:
1. `docs/specs/update-hooks/design.md` — full architecture and hk.pkl source
2. `docs/specs/update-hooks/implementation-plan.md` — detailed plan
3. `docs/specs/update-hooks/tasks.md` — your progress tracker
4. `docs/specs/update-hooks/hk-ecosystem.md` — hk feature reference
5. `.gitlint` — current rules to replicate
6. `mise.toml` — existing task structure to follow

---

## Commit Message to Use

When committing changes, use:

```
feat(hooks): replace pre-commit+gitlint with hk

Migrates git hook management from pre-commit (Python) + gitlint (Python)
to hk — a Rust-native hook manager by the same author as mise.

- Adds hk.pkl with pre-commit staged-file linting and commit-msg validation
- Adds config/hk/hkrc.pkl as distributed user-level defaults dotfile
- Adds setup:hooks mise task
- Removes .pre-commit-config.yaml, .gitlint, config/gitlint/
- Preserves all existing Conventional Commits rules

Tools now linted on pre-commit: shellcheck, shfmt, markdownlint, hadolint,
yamllint, taplo
```
