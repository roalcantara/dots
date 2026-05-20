# Handoff: Implement `xc-git` merge

> **Superseded for package layout** by [xc-portable-tools/HANDOFF.md](../xc-portable-tools/HANDOFF.md).
> `xc-git` is now a **flat** executable at `config/bin/xc-git` (same layout as `xc-fabric`; no `xc-git/` package dir).
> Subcommand behavior (branch-preview, fixup-suggest, log-fzf) is unchanged; only the packaging changed.

**For:** Implementation agent — build per SDD; do not redesign behavior.

---

## Read first

1. `assets/specs/xc-git/requirements.md` (Req 1–11)
2. `assets/specs/xc-git/design.md` (§2 layout, §4.2 zparseopts, §14 docs)
3. `assets/specs/xc-git/tasks.md`

**Copy behavior from (then delete / wrap):**

- `config/bin/xc-git-branch-preview`
- `config/bin/xc-git-fixup-suggest`
- `config/bin/xc-git-log-fzf`

---

## Layout (required — no `lib/xc-git/`)

```tree
config/bin/xc-git/
  xc-git              # executable; symlink ~/.local/bin/xc-git → this file
  _common.zsh
  branch-preview.zsh
  fixup-suggest.zsh
  log-fzf.zsh
config/bin/xc-git-branch-preview   → exec "${0:h}/xc-git/xc-git" branch-preview "$@"
```

- `readonly XC_GIT_DIR="${${(%):-%x}:a:h}"` in `xc-git` and sourced modules.
- **Delete** `config/bin/lib/xc-git/` if present.

---

## Argument parsing

| Tool                                                               | Use for xc-git?                                                                   |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| mise [usage field](https://mise.jdx.dev/tasks/task-arguments.html) | **No** — only for `mise run xc-git:specs` `--scenario` in `mise.toml`             |
| **zparseopts**                                                     | **Yes** — `fixup-suggest` (full flags), `branch-preview` (help); see `psc`, `osx` |

---

## Hard constraints

- fixup-suggest: latest branch touch only; `git commit` when no touch; **zparseopts -D -F -E**
- log-fzf: do not change fzf binds
- gum: `_common.zsh` + `_xc_git_emit`; optional
- Tests: `XC_GIT` = `config/bin/xc-git`

---

## Docs to update

`config/bin/README.md`, root `README.md`, `config/git/config`, `gitx`, `dots`

---

## Verify

```bash
cd config/bin && mise run xc-git:specs
zsh config/bin/xc-git -h
xc-git fixup-suggest --dry-run .
env PATH=/usr/bin:/bin zsh config/bin/xc-git branch-preview HEAD
test ! -d config/bin/lib/xc-git
```

---

## Copy-paste prompt for next agent

```text
Implement xc-git per assets/specs/xc-git/ (requirements, design, tasks, HANDOFF).

LAYOUT: Single package dir config/bin/xc-git/ with executable config/bin/xc-git and sibling *.zsh modules. DELETE config/bin/lib/xc-git/. Do NOT use lib/xc-git/. Symlink target: ~/.local/bin/xc-git → config/bin/xc-git. Wrappers: exec "${0:h}/xc-git/xc-git" <subcommand> "$@".

PARSING: Do NOT use mise "usage" for the xc-git CLI (only for mise.toml xc-git:specs --scenario). Use zparseopts for fixup-suggest flags (-b/-n/-q/--dry-run/-h) like config/zsh/etc/functions/psc. XC_GIT_DIR="${${(%):-%x}:a:h}".

BEHAVIOR: Copy from xc-git-branch-preview, xc-git-fixup-suggest, xc-git-log-fzf without changing fixup algorithm or log-fzf UI.

DOCS: config/bin/README.md, README.md, config/git/config (fixup-suggest alias), gitx, dots git.

TESTS: tests/xc-git.spec.ts, XC_GIT=config/bin/xc-git, mise run xc-git:specs.

Commit: feat(bin): Unify xc-git helpers under xc-git CLI
```
