# Handoff: `xc` interactive launcher

**Spec:** `assets/specs/xc-launcher/`  
**Orchestration:** [subagent-driven-development](~/.claude/skills/subagent-driven-development/SKILL.md) — tasks T1→T5 sequentially, spec + quality review each.

**User request:** Keep each `xc-*` in its **own file**; add **`config/bin/xc`** launcher only.
`xc` + Enter → list **other** tools → fzf preview = main help + **each subcommand's** help (like
multiple `-h`), then run the real script. Prefer **fzf**; gum fallback only.

---

## Read first

1. [requirements.md](./requirements.md)
2. [design.md](./design.md) — §4 fzf preview, §5 execution
3. [tasks.md](./tasks.md)

**Reference:** `config/zsh/etc/functions/gitx` `_gitx_launcher` (lines ~696–728) — **do not copy** paste behavior; copy only discovery inspiration.

**Depends on:** `config/bin/xc-usage` Task **1b** (`preview`, `print --scope`, `list-subs`) + [xc-usage §11.5](../xc-usage/design.md#115-xc-fabric-dispatcher-template-canonical) docopt blocks in each `xc-*` tool.

---

## Global constraints

- Zsh script at `config/bin/xc`
- Descriptions from **first `##?` line** per file — never hardcode `xc-fabric`, etc.
- Preview: `command xc-usage preview {path} --tool {name}` (stacked main + subs per xc-usage §5.8)
- Exclude `xc` from discovery list
- Do NOT merge xc-fabric/xc-git/etc. into xc
- fzf: `--preview-window='right:60%:wrap'`
- Symlink: `~/.local/bin/xc`

---

## Parent agent copy-paste

```text
Implement assets/specs/xc-launcher/ using subagent-driven-development (T1→T5).

Prerequisites:
- xc-portable-tools: flat config/bin/xc-git (file, not xc-git/ directory)
- xc-usage Task 1b: xc-usage preview PATH --tool NAME (stacked main + sub help)

Build config/bin/xc:
- Discover flat xc-* FILES in $XDG_CONFIG_HOME/bin (xc-git, xc-fabric, xc-puts, …) — skip directories named xc-*
- xc list = table; bare xc = fzf with --preview 'command xc-usage preview {2} --tool {1}'
- Enter runs command (optional 2nd fzf for ##? Subcommands:, optional gum input for args)
- NOT print -z paste (unlike gitx _gitx_launcher)

Tests: tests/xc.spec.ts, mise run xc:specs
Do not commit unless user asks.
```

---

## Task T1 implementer prompt

```text
Task T1: xc skeleton + discovery + list

Work in: /Users/roalcantara/Work/dots/config/bin

Create config/bin/xc (zsh):
- #? license + ##? per design.md §6
- xc-usage guard at top
- _xc_discover: scan config/bin for executable FILES matching xc-* (not directories; xc-git is config/bin/xc-git file)
- Summary from first ##? line (text after " - " if present)
- Subcommand: xc list → print name, path, summary
- Env override XC_BIN_DIR for tests

Fixture: tests/fixtures/xc-launcher/bin/xc-alpha with minimal ##?

Verify: zsh config/bin/xc list; zsh config/bin/xc -h
Report: DONE | BLOCKED + suggested commit feat(bin): Add xc tool discovery and list
```

---

## Task T2 implementer prompt

```text
Task T2: fzf + live preview

Depends on T1 complete.

Add _xc_fzf_pick_tool:
- Input: TSV rows name\tpath\tsummary
- fzf --delimiter TAB --with-nth=1,3
- --preview='command xc-usage preview {2} --tool {1}'
- --prompt='xc ❯ ' --header per design.md §4.1
- Bare xc (no args) calls this; Esc → exit 0

Fallback: if no fzf, try gum choose + gum pager; else stderr hint exit 1

Manual verify: run xc, move cursor, preview updates with Usage/Options

Report: DONE | DONE_WITH_CONCERNS
```

---

## Task T3 implementer prompt

```text
Task T3: Subcommands + execute

Depends on T2.

After tool pick:
- If ##? has Subcommands: or Commands: block, parse lines into 2nd fzf (name + description columns)
- gum input for optional extra args (or skip if empty)
- Run: command "$name" [$subcmd] [$args] — foreground, exit with child status
- Do NOT use print -z as primary path

Test manually: xc → xc-puts → --green test
xc → xc-git → fixup-suggest (if available)

Report: DONE
```

---

## Task T4 implementer prompt

```text
Task T4: tests + mise + README

tests/xc.spec.ts:
- xc -h exit 0
- XC_BIN_DIR=fixtures/... xc list contains xc-alpha
- spawn xc list in real repo contains xc-usage

mise.toml: xc:specs

config/bin/README.md: document xc launcher + symlink

mise run xc:specs
```

---

## Task T5 implementer prompt

```text
Task T5: docs symlink

Document ln -sf in README (if not T4)
config/zsh/README.md one line about xc launcher
```

---

## Spec / quality reviewer (template)

```text
Review Task TN against assets/specs/xc-launcher/requirements.md.
Confirm: flat-file discovery only, fzf preview uses xc-usage preview (not plain print), execute not paste.
Reply ✅ or ❌ with gaps.
```
