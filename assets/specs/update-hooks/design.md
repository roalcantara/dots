<!-- markdownlint-disable-file -->
# Design: Replace pre-commit + gitlint with hk

**Date:** 2026-05-23
**Status:** Approved
**Scope:** `docs/specs/update-hooks/`

---

## Background

The `dots` dotfiles project currently uses two Python-based tools to enforce git hygiene:

| Tool                                         | Role                  | Config                                                                 |
| -------------------------------------------- | --------------------- | ---------------------------------------------------------------------- |
| [pre-commit](https://pre-commit.com) v0.17.0 | Git hook manager      | `.pre-commit-config.yaml`                                              |
| [gitlint](https://jorisroovers.com/gitlint)  | Commit-message linter | `.gitlint`, `config/gitlint/gitlint.cfg`, `config/git/lint/config.ini` |

**What they do today:**
- `pre-commit` installs a `commit-msg` hook that calls `gitlint`
- `gitlint` validates every commit message against the `contrib-title-conventional-commits` ruleset plus custom rules (max-length, wip-block, body-min-length, release/dependabot ignores)

**Pain points:**
- Python runtime dependency; slow startup
- `pre-commit` only manages one hook (`commit-msg`); its capabilities are underutilised
- `gitlint` is in maintenance mode (last release v0.19.1, 2023)
- Three separate config files for essentially one concern (commit-msg linting)
- No parallelism for staged-file checks
- No built-in integration with `mise`, which is already the project's tool manager

---

## Why hk?

[hk](https://hk.jdx.dev) is a Rust-native git hook manager authored by the same person as `mise`. It is already declared in `mise.toml`:

```toml
[tools]
hk = "latest"
```

hk offers everything pre-commit + gitlint do and much more:

| Capability                             | pre-commit + gitlint | hk                                 |
| -------------------------------------- | -------------------- | ---------------------------------- |
| Commit-msg validation                  | ✅ (gitlint)          | ✅ (custom step or regex)           |
| Staged-file checks                     | ❌                    | ✅                                  |
| Parallel linting with R/W locks        | ❌                    | ✅                                  |
| Auto-stash unstaged changes            | ❌                    | ✅                                  |
| Global install (one config, all repos) | ❌                    | ✅ (Git 2.54+)                      |
| 90+ built-in linter presets            | ❌                    | ✅ (Builtins.pkl)                   |
| mise-native integration                | ❌                    | ✅ (HK_MISE=1 or hk install --mise) |
| Written in Rust (fast startup)         | ❌                    | ✅                                  |
| Configuration language                 | YAML                 | Pkl (type-safe, modulable)         |

---

## Scope of This Spec

Replace pre-commit + gitlint **and** adopt every applicable hk feature that improves, simplifies, speeds up, or prettifies the project. The spec is broken into three areas:

1. **Core Migration** — replace the two tools with `hk.pkl`
2. **New Hook Coverage** — add hooks for linting staged files (shell, markdown, YAML, TOML, Dockerfiles, editorconfig)
3. **Ecosystem Adoption** — global install, mise integration, `hk fix`, `hk check`, CI integration

---

## Architecture

```
dots/
├── hk.pkl                  # NEW: primary project hk config
├── config/
│   └── hk/
│       └── hkrc.pkl        # NEW: user-level hk defaults (distributed as dotfile)
├── docs/specs/update-hooks/ # SDD artefacts (this directory)
├── .pre-commit-config.yaml  # REMOVE after migration
├── .gitlint                 # REMOVE after migration
└── config/gitlint/          # REMOVE after migration
```

### `hk.pkl` (project config)

```pkl
amends "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Builtins.pkl"

// Linters applied to staged files on pre-commit
local stagingLinters = new Mapping<String, Step> {
  ["shellcheck"] {
    glob = List("*.sh", "*.bash", "*.zsh", "install", "script/*.sh")
    check = "shellcheck --rcfile .shellcheckrc {{files}}"
  }
  ["shfmt"] {
    glob = List("*.sh", "*.bash", "*.zsh")
    check = "shfmt -d {{files}}"
    fix   = "shfmt -w {{files}}"
  }
  ["markdownlint"] = (Builtins.markdownlint) {
    glob = List("**/*.md")
  }
  ["hadolint"] = (Builtins.hadolint) {
    glob = List("**/Dockerfile", "**/Dockerfile.*")
  }
  ["yamllint"] {
    glob  = List("**/*.yml", "**/*.yaml")
    check = "yamllint {{files}}"
  }
  ["taplo"] {
    glob  = List("**/*.toml")
    check = "taplo fmt --check {{files}}"
    fix   = "taplo fmt {{files}}"
  }
}

hooks {
  // ── pre-commit ──────────────────────────────────────────────────────────
  ["pre-commit"] {
    fix   = true
    stash = "git"          // auto-stash unstaged changes
    steps = stagingLinters
  }

  // ── commit-msg ──────────────────────────────────────────────────────────
  ["commit-msg"] {
    steps {
      ["conventional-commits"] {
        // Validates: <type>(<scope>)!: <subject>
        // Allowed types mirror current .gitlint contrib-title-conventional-commits
        check = #"""
          #!/usr/bin/env bash
          set -euo pipefail
          msg=$(head -1 "$1")
          # Ignore merge/revert/fixup/squash/release/dependabot commits
          if echo "$msg" | grep -qiE "^(Merge |Revert |fixup! |squash! )"; then exit 0; fi
          if echo "$msg" | grep -qiE "release"; then exit 0; fi
          pattern='^(feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git)(\([a-zA-Z0-9/_-]+\))?!?: .{1,}'
          if ! echo "$msg" | grep -qE "$pattern"; then
            echo "❌ Commit message does not follow Conventional Commits:"
            echo "   $msg"
            echo ""
            echo "   Expected: <type>(<scope>): <subject>"
            echo "   Types: feat|fix|docs|style|ref|test|revert|chore|ci|build|perf|git"
            exit 1
          fi
          # Title length check (≤80 chars, mirror current .gitlint rule)
          if [ "${#msg}" -gt 80 ]; then
            echo "❌ Title too long (${#msg} chars, max 80): $msg"
            exit 1
          fi
          # Block WIP commits
          if echo "$msg" | grep -qiE "^wip[: ]"; then
            echo "❌ WIP commit not allowed: $msg"
            exit 1
          fi
          echo "✅ Commit message OK"
        """#
      }
    }
  }

  // ── hk fix / hk check (manual) ─────────────────────────────────────────
  ["fix"] {
    fix   = true
    steps = stagingLinters
  }
  ["check"] {
    steps = stagingLinters
  }
}
```

### `config/hk/hkrc.pkl` (user-level distributed dotfile)

```pkl
// User-level hk defaults for all repos on this machine.
// Distributed as part of the dots dotfiles — symlinked to ~/.config/hk/config.pkl
amends "package://github.com/jdx/hk/releases/download/v1.45.0/hk@1.45.0#/Config.pkl"

settings {
  jobs    = 4        // parallel hook steps
  mise    = true     // always use mise x for tool invocation
}
```

---

## Hook Coverage Map

| Hook         | Steps                                                      | Purpose                               |
| ------------ | ---------------------------------------------------------- | ------------------------------------- |
| `pre-commit` | shellcheck, shfmt, markdownlint, hadolint, yamllint, taplo | Staged-file linting & auto-fix        |
| `commit-msg` | conventional-commits                                       | Message validation (replaces gitlint) |
| `fix`        | same as pre-commit steps                                   | Manual `hk fix` invocation            |
| `check`      | same as pre-commit steps                                   | Manual `hk check` / CI invocation     |

---

## Migration Plan (summary — details in `implementation-plan.md`)

1. Verify `hk latest` is installed via `mise` (already declared in `mise.toml`)
2. Create `hk.pkl` at project root
3. Create `config/hk/hkrc.pkl` for user-level defaults
4. Update `install` script to call `hk install --global` and symlink `hkrc.pkl`
5. Remove `.pre-commit-config.yaml`, `.gitlint`, `config/gitlint/`
6. Remove `gitlint` from any `mise.toml` tool list (it's not listed, but verify)
7. Update `mise.toml` to add `setup:hooks` task
8. Update README and relevant docs
9. Verify with test commits

---

## Decisions Made

| Decision                       | Choice                           | Rationale                                                                       |
| ------------------------------ | -------------------------------- | ------------------------------------------------------------------------------- |
| Commit-msg validation approach | Custom shell script in `check =` | Avoids Python gitlint dependency; encodes all existing rules; type-safe via Pkl |
| Conventional-commits types     | Same as current `.gitlint`       | No behaviour change; fully backward-compatible                                  |
| Title max-length               | 80 chars                         | Current `.gitlint` [title-max-length] line-length=80                            |
| Global vs per-repo install     | Global (`hk install --global`)   | Recommended for Git 2.54+; zero per-repo maintenance                            |
| Pkl backend                    | `pklr` (built-in Rust evaluator) | Removes pkl CLI dependency; experimental but sufficient                         |
| Stash strategy                 | `stash = "git"`                  | Prevents unstaged changes from being accidentally staged by fix steps           |
| Parallelism                    | `jobs = 4` (hkrc default)        | Matches typical CI runner count                                                 |

---

## Out of Scope

- Changing the conventional-commit types
- Adding new linting categories (e.g., Python linters) — no Python files in project
- CI/CD changes to GitHub Actions workflows (separate concern)

---

## Success Criteria

- [ ] `git commit` with a non-conventional message is blocked
- [ ] `git commit` with a conforming message succeeds without Python/gitlint on PATH
- [ ] Staged `.sh` files are checked by shellcheck + shfmt on commit
- [ ] Staged `*.md` files are checked by markdownlint on commit
- [ ] Staged `Dockerfile*` files are checked by hadolint on commit
- [ ] `hk fix` auto-formats staged files without corrupting unstaged changes
- [ ] `hk check` works as a standalone CI entry-point
- [ ] No `pre-commit`, `gitlint`, or Python runtime required after migration
