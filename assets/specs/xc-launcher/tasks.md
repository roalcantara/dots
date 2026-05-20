<!-- markdownlint-disable -->
# xc launcher — Tasks

**Date:** 2026-05-20
**Status:** Ready for implementation
**Requires:** [design.md](./design.md), [requirements.md](./requirements.md)

**Prerequisite:** `xc-usage` on PATH; `##?` headers on target `xc-*` scripts.

---

## Task T1 — `config/bin/xc` skeleton + discovery + `list`

**Covers:** Req-1, Req-4

- [ ] Add `config/bin/xc` (Zsh), `#?` + `##?`, `xc-usage guard`
- [ ] Implement `_xc_bin_dir`, `_xc_discover` → TSV rows `name\tpath\tsummary`
- [ ] Discover flat `xc-*` executables only (no `xc-git/` package dir)
- [ ] Subcommand `list` prints aligned table
- [ ] Fixture: `tests/fixtures/xc-launcher/bin/xc-sample` with `##?`

**Verify:**

```bash
zsh config/bin/xc -h
zsh config/bin/xc list | grep xc-fabric
```

---

## Task T2 — fzf picker + stacked preview

**Covers:** Req-2

- [ ] `_xc_preview_help path name` — main + per-subcommand sections (design §4.2)
- [ ] `_xc_fzf_pick_tool` with `--preview` calling `_xc_preview_help` (or `xc _preview`)
- [ ] `--with-nth=1,3` `--delimiter=$'\t'`
- [ ] gum/fallback path when fzf missing
- [ ] Wire `xc` no-args → picker (cancel Esc → exit 0)

**Verify (manual):** `xc` → move selection → preview shows Usage/Options

---

## Task T3 — Subcommand drill-down + execute

**Covers:** Req-3

- [ ] `_xc_has_subcommands` / `_xc_parse_subcommands` from `##?`
- [ ] Second fzf for subcommands when applicable (`xc-git`, future tools)
- [ ] Optional `gum input` for extra args
- [ ] Run `command "$name" …`; propagate exit code
- [ ] Do not use `print -z` as primary

**Verify (manual):**

```bash
xc → xc-puts → args: --green hello
xc → xc-git → fixup-suggest → --dry-run .
```

---

## Task T4 — Tests + mise + README

**Covers:** Req-5

- [ ] `tests/xc.spec.ts` — list, help, fixture discovery, no-fzf message
- [ ] `mise.toml` task `xc:specs`
- [ ] `config/bin/README.md` section for `xc` launcher

**Verify:** `mise run xc:specs`

---

## Task T5 — Symlink + optional zsh hint

- [ ] Document `ln -sf ~/.config/bin/xc ~/.local/bin/xc`
- [ ] Optional one-line in `config/zsh/README.md`: "Run `xc` to browse all xc-* tools"

---

## Definition of done

- `xc` discovers tools; preview = `xc-usage print`; Enter runs command
- No hardcoded tool list in source
- Tests green; README updated
