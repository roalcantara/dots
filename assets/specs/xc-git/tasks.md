<!-- markdownlint-disable -->
# xc-git — Tasks

**Date:** 2026-05-20
**Status:** Ready for implementation
**Requires:** [design.md](./design.md), [requirements.md](./requirements.md)

---

## Skills to invoke

Load before starting:

```txt
~/.cursor/skills/bash-scripting/SKILL.md
~/.cursor/skills/bun-development/SKILL.md
~/.cursor/skills/test-driven-development/SKILL.md
~/.cursor/skills/verification-before-completion/SKILL.md
```

---

## TDD cycle (every task)

1. Add or extend failing spec in `tests/xc-git.spec.ts` → RED
2. Implement minimal change → GREEN
3. `shellcheck` on touched zsh files
4. `mise run xc-git:specs` (full suite before marking task done)

**Do not start the next task until all checkboxes in the current task are ticked.**

---

## Task 1 — Package dir `config/bin/xc-git/` + dispatcher

**Covers:** Req-1, Req-9, Req-10

- [ ] Create `config/bin/xc-git/` (directory); remove `config/bin/lib/xc-git/` if it exists
- [ ] Add `config/bin/xc-git/_common.zsh` per [design.md §4.1](./design.md#41-shared-optional-gum-_commonzsh)
- [ ] Add executable `config/bin/xc-git` dispatcher per [design.md §4](./design.md#4-subcommand-registry) (`XC_GIT_DIR`, not `XC_GIT_LIB`)
- [ ] Remove obsolete single-file `config/bin/xc-git` at bin root if present (file cannot coexist with directory name — use directory layout only)
- [ ] Stub `branch-preview.zsh`, `fixup-suggest.zsh`, `log-fzf.zsh` in same directory
- [ ] Spec: `help` — `XC_GIT` points at `config/bin/xc-git`; `-h` lists subcommands
- [ ] Spec: `dispatch` — unknown subcommand exit 1

**Verify:** `zsh config/bin/xc-git -h`

---

## Task 2 — Migrate `branch-preview`

**Covers:** Req-2, Req-5, Req-9, Req-11

- [ ] Implement `config/bin/xc-git/branch-preview.zsh` with `_xc_git_emit` + `zparseopts` for help
- [ ] Wrapper `config/bin/xc-git-branch-preview`: `exec "${0:h}/xc-git/xc-git" branch-preview "$@"`
- [ ] Spec: `xc-git branch-preview -h`; manual without gum on PATH

**Verify:** `gitx fzb` preview string (wrapper or `xc-git branch-preview`)

---

## Task 3 — Migrate `fixup-suggest` + `zparseopts`

**Covers:** Req-3, Req-5, Req-9, Req-11

- [ ] Implement `config/bin/xc-git/fixup-suggest.zsh`; replace `while/case` flags with `zparseopts` per [design.md §4.2](./design.md#42-cli-argument-parsing-zparseopts-not-mise-usage) (reference: `config/zsh/etc/functions/psc`)
- [ ] Wrapper: `exec "${0:h}/xc-git/xc-git" fixup-suggest "$@"`
- [ ] Port tests to `tests/xc-git.spec.ts` with `XC_GIT=config/bin/xc-git`
- [ ] Spec: unknown flag `-z` exits non-zero

**Verify:**

```bash
xc-git fixup-suggest --dry-run .gitattributes
xc-git fixup-suggest --dry-run config/bin/README.md
```

---

## Task 4 — Migrate `log-fzf`

**Covers:** Req-4, Req-5, Req-6

- [ ] `config/bin/xc-git/log-fzf.zsh`; wrapper `exec "${0:h}/xc-git/xc-git" log-fzf "$@"`
- [ ] Update `gitx` `_gitx_fzlog` per design §9
- [ ] Port log-fzf specs

---

## Task 5 — mise `xc-git:specs` + `config/bin/README.md`

**Covers:** Req-7, Req-8, Req-11 (mise usage for scenarios only)

- [ ] `xc-git:specs` in `mise.toml`; `env.XC_GIT = "{{ config_root }}/xc-git/xc-git"`
- [ ] mise `usage` block: `flag "--scenario"` with choices (NOT used by xc-git CLI)
- [ ] README: `### xc-git`, symlink `xc-git/xc-git`, deps gum/fzf/delta

---

## Task 6 — Integration docs

**Covers:** Req-8

- [ ] `config/git/config`, root `README.md`, `gitx`, `dots` per design §14

---

## Task 7 — Wrapper delegation specs

**Covers:** Req-5

- [ ] Wrappers delegate to `xc-git/xc-git`; `wc -l` ≤ 5 each

---

## Task 8 — Final verification

- [ ] `shellcheck config/bin/xc-git config/bin/xc-git/*.zsh config/bin/xc-git-*`
- [ ] Confirm `config/bin/lib/xc-git` deleted
- [ ] `mise run xc-git:specs`

---

## Definition of done

- Package at `config/bin/xc-git/` only; no `lib/xc-git/`.
- `fixup-suggest` uses `zparseopts`; mise `usage` only on `xc-git:specs` task.
- `XC_GIT` test env → `config/bin/xc-git`.
- Integration docs + all specs green.
