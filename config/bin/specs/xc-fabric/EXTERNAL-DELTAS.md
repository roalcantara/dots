<!-- markdownlint-disable -->
# External deltas (implementation reference)

This file records changes intended for repo files **outside** this SDD folder.
Apply during implementation; keep this list in sync with `design.md` §11–§12.

## `config/bin/mise.toml`

1. **Leave `[tools]` unchanged** unless the maintainer explicitly adds tools project-wide.

2. **Add** `[tasks."xc-fabric:specs"]` — mirror `xc-git-log-fzf:specs`:

   - `description`, `dir = "{{ config_root }}"`
   - `env = { XC_FABRIC = "{{ config_root }}/xc-fabric" }`
   - `usage` with `flag "--scenario <scenario>"` and `choices` listing all **21** scenario IDs from `design.md` §10
   - `run = "bunx bun test tests/xc-fabric.spec.ts"`

3. **Add** `[tasks.setup]` — body per `design.md` §11 (`fabric-ai`, `bat`, `fzf`, conditional `xclip` on Linux).

## `config/bin/README.md`

1. **OVERVIEW** — mention `xc-fabric` alongside other `xc-*` scripts; subcommands: default, `wizard`, `run`, `ls`, `update`, `show`, `strategies`, `scrape`.

2. **DEPENDENCIES** — Fabric required; FZF, Gum, Glow, Bat optional (roles per `design.md`).

3. **LINKS** — add footnotes (renumber to fit existing `[0]`… chain in the real file):

   - Fabric — `https://github.com/danielmiessler/Fabric`
   - fzf — `https://github.com/junegunn/fzf`
   - Gum — `https://github.com/charmbracelet/gum`
   - Glow — `https://github.com/charmbracelet/glow`
   - bat — `https://github.com/sharkdp/bat`

4. **RUNNING SPECS → WITH MISE**

   - Document `mise run setup` (first-time / CI).
   - Document `mise run xc-fabric:specs` and each `--scenario` value (21 lines or a compact reference + pointer to `design.md` §10).

5. **RUNNING SPECS → WITHOUT MISE** — `bunx bun test tests/xc-fabric.spec.ts` from `config/bin/`.
