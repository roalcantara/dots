<!-- markdownlint-disable -->
# External deltas (implementation reference)

This file records changes intended for repo files **outside** this SDD folder.
Apply during implementation; keep this list in sync with `design.md` §11–§12.

## `config/bin/mise.toml`

1. **`[tools]`** — add `yq = "latest"` when using `config/bin/config.yml` for `xc-fabric` metadata; keep other tool lines as the repo already defines them.

2. **Extend** `[tasks.setup]` so `yq` is installed the same way as `bat` / `fzf` (for example `command -v yq || mise use -g yq@latest`).

3. **Add** `[tasks."xc-fabric:specs"]` — mirror `xc-git-log-fzf:specs`:

   - `description`, `dir = "{{ config_root }}"`
   - `env = { XC_FABRIC = "{{ config_root }}/xc-fabric" }`
   - `usage` with `flag "--scenario <scenario>"` and `choices` listing all **22** scenario IDs from `design.md` §10
   - `run = "bunx bun test tests/xc-fabric.spec.ts"`

## `config/bin/config.yml`

1. **Add** tracked `config/bin/config.yml` with root key `scripts` and per-script keys (for example `xc-fabric`).
2. **Under** `scripts.xc-fabric.patterns.<name>` store optional `description` and `tags` (see `design.md` for picker overlay rules).

## `config/bin/README.md`

1. **OVERVIEW** — mention `xc-fabric` alongside other `xc-*` scripts; subcommands: default, `run`, `ls`, `update`, `show`, `strategies`, `scrape`.

2. **DEPENDENCIES** — Fabric required; FZF, Gum, Glow, Bat, yq optional (roles per `design.md`). Note `config.yml` metadata is optional: without `yq` or the file, `xc-fabric` uses `system.md` descriptions only.

3. **LINKS** — add footnotes (renumber to fit existing `[0]`… chain in the real file):

   - Fabric — `https://github.com/danielmiessler/Fabric`
   - fzf — `https://github.com/junegunn/fzf`
   - Gum — `https://github.com/charmbracelet/gum`
   - Glow — `https://github.com/charmbracelet/glow`
   - bat — `https://github.com/sharkdp/bat`

4. **RUNNING SPECS → WITH MISE**

   - Document `mise run setup` (first-time / CI).
   - Document `mise run xc-fabric:specs` and each `--scenario` value (22 lines or a compact reference + pointer to `design.md` §10).

5. **RUNNING SPECS → WITHOUT MISE** — `bunx bun test tests/xc-fabric.spec.ts` from `config/bin/`.
