# HANDOFF: project structure — Tasks 9–11

Tasks 1–8 (assets layout migration) are **complete**. Implementation resumes at
**Task 9** in [tasks.md](tasks.md).

## Goal

Document and implement the **bin ↔ Zsh helper model**, **target-first
`xc-usage`**, and **`xc-md`** per [requirements.md](requirements.md)
Requirements 10–12 and [design.md § Purpose of `xc-*` helpers](design.md#purpose-of-xc-helpers).

**Not in scope:** migrating `gen` to `config/bin` (no `xc-gen`).

## Read first

- `assets/specs/project-structure/requirements.md` (Req 10–12)
- `assets/specs/project-structure/design.md` (Purpose of xc-* helpers, xc-md, xc-usage)
- `assets/specs/project-structure/tasks.md` (Tasks 9–11)
- `assets/specs/xc-usage/` (update in Task 10 — keep aligned)
- `config/bin/xc-usage`, `config/zsh/etc/functions/gen`, `config/zsh/etc/functions/show_usage`
- `assets/guides/GIT_COMMITS_GUIDE.md`, `assets/guides/TESTING_GUIDE.md`

## Verification

After Task 10:

```bash
mise run -C assets integration bin xc-usage
mise run -C assets test bin
```

After Task 11:

```bash
zsh -c 'source config/zsh/etc/functions/gen; gen -h'   # from repo root, adjust FPATH
xc-usage gen   # must match gen ##? block
```

## Next task group

**Task 9: Document bin ↔ Zsh architecture** — README and guide updates only; no
behavior change until Task 10.
