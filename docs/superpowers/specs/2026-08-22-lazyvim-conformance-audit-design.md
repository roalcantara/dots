# LazyVim Conformance & Lua Optimization Audit — Design

**Date:** 2026-08-22

**Scope:** `config/nvim/lua/config/**`, `config/nvim/lua/plugins/**`,
`config/nvim/lua/config/lazy.lua`

**Predecessor:** `2026-08-22-neovim-lazyvim-port-design.md`

## Problem

The Kickstart to LazyVim port preserved the previous configuration
wholesale. It works, but it was never diffed against what LazyVim already
provides. The result is three classes of defect:

1. **Duplication** — configuration LazyVim already applies, re-applied.
2. **Conflict** — configuration that fights LazyVim and loses silently, or
   wins in a way that discards LazyVim's guard rails.
3. **Cost** — eager `require` calls in plugin spec files that defeat
   lazy-loading.

Measured startup is **181ms** against LazyVim's <50ms target, and roughly
38ms of that is the configuration's own `core/` modules loaded during spec
collection.

## Governing principle

LazyVim wins wherever the two implementations do the same thing. Local code
wins where it does something LazyVim does not: the `<D-*>` keymap engine
(`core/vi/maps`), the `core/` library, the tokyonight palette, the snacks
pickers, and the LSP capability wiring in `core/vi/lsp`.

Divergent *preferences* are kept, not "conformed". These are deliberate and
stay (local value first, LazyVim default second):

- `maplocalleader` — `' '` over `'\'`
- `number` — `false` over `true`
- `cursorline` — `false` over `true`
- `conceallevel` — `0` over `2`
- `timeoutlen` — `500` over `300`
- `pumheight` — `50` over `10`
- `scrolloff` — `10` over `4`
- `autowrite` — `false` over `true`
- `completeopt` — `menuone,noinsert,noselect` over `menu,menuone,noselect`

Each retained divergence gains a trailing comment naming the LazyVim default
it overrides, so a future reader can tell intent from accident.

## Findings

### Class 1 — Duplication

`lua/config/autocmds.lua` — 8 of 12 groups reimplement
`lazyvim/config/autocmds.lua`: `checktime`, `highlight_yank`,
`resize_splits`, `last_loc`, `man_unlisted`, `wrap_spell`, `json_conceal`,
`auto_create_dir`. They register in separate augroups, so each fires twice.

`lua/config/options.lua` — roughly 37 lines restate LazyVim defaults
verbatim; a further 12 are Neovim defaults or outright no-ops (`ttyfast`,
`wildmenu`, `incsearch`, `encoding`, `lazyredraw`, `modifiable`, `autoread`,
`backspace`, and `winborder = nil`, which does nothing at all).

### Class 2 — Conflict

**C1** — `plugins/formater.lua:19`. `opts.format_on_save` is detected by
LazyVim's conform spec, warned about, and set to `nil`. The 500ms timeout
never applies.

**C2** — `config/options.lua:111,122-124`. Global `indentexpr`,
`foldmethod` and `foldexpr` pre-empt LazyVim's `set_default`, which is
guarded by `LazyVim.treesitter.have(ft, …)`. The unguarded expression wins,
producing fold and indent errors in buffers with no parser.

**C3** — `config/options.lua:79`. `showtabline = 0` hides the bufferline
that `<D-M-Left/Right>` drive.

**C4** — `config/options.lua:196` against `plugins/ui.lua`.
`snacks_animate = false` sits alongside a full `mini.animate` spec.

**C5** — `plugins/ui.lua`. `snacks.statuscolumn = { enabled = false }`
comments "we set this in options.lua"; `options.lua` never sets
`statuscolumn`. LazyVim's is what runs.

### Class 3 — Cost

From `--startuptime`, the top self-inflicted entries:

- `core/ui/statusline`, 15.6ms — top-level `require` in `plugins/ui.lua`
- `core/neo`, 12.1ms — top-level `require` in `config/options.lua`
- `core/ui/snacks/pickers`, 10.2ms — top-level `require` in
  `config/usercmds.lua`
- `showkeys`, 4.5ms — `init = function() vim.cmd('ShowkeysToggle') end`
  force-loads it at startup, defeating its own `cmd` and `event`

### Class 4 — Reinvented extras and spec hygiene

`lazyvim.json` shows `"extras": []`, yet `aerial.nvim`,
`treesitter-context`, `mini.animate` and `fzf-lua` all have official extras.
The aerial `opts` block is a near-verbatim copy of `extras.editor.aerial` —
the exact anti-pattern the LazyVim skill warns against.

Additionally:

- `fzf-lua` loads on `VeryLazy` but never wins `LazyVim.pick` registration
  (snacks gets there first), so it is dead weight.
- `render-markdown.nvim` is declared in both `markdown.lua` and `ui.lua`.
- `nvim-web-devicons` is pulled in as an aerial dependency while everything
  else uses `mini.icons`.
- `nui.nvim` is declared explicitly though noice provides it.
- `helpview.nvim` uses `lazy = false` where `ft = "help"` suffices.
- The lualine spec carries LazyVim-copied boilerplate and lists a `neo-tree`
  extension for a plugin that is not installed.

## Resolved decisions

1. **Bufferline** — keep `showtabline = 0`, repoint `<D-M-Left/Right>` at
   `bprevious`/`bnext`, and disable the LazyVim bufferline spec
   (`enabled = false`), since nothing consumes it once the keymaps are
   repointed.
2. **URL handling** — remove the `sontungexpt/url-open` spec, remove the
   `on_vim_enter_or_color_scheme` autocmd that exists only to feed it
   `UrlOpenHighlight`, and additionally drop LazyVim's `<leader>gB` and
   `<leader>gY` gitbrowse keymaps. Builtin `gx` becomes the only
   URL-opening path.

## Approach

Risk-ordered phases. Genuine bugs land first, while diffs are small enough
to bisect; cosmetic deduplication follows. One commit per phase, each
independently revertible.

### Phase 0 — Baseline

Wrap the existing `mise` tasks (`startuptime`, `tests`) in a re-runnable
capture that writes to a gitignored directory:

- median startuptime over 3 headless runs
- `nvim_get_keymap` across all modes
- `nvim_get_autocmds`, grouped
- `:checkhealth`
- the `:Lazy` plugin list
- resolved LSP servers and conform formatters per filetype

Every later phase diffs against this.

### Phase 1 — Active conflicts

- C1: delete `format_on_save`; set `vim.g.autoformat = true`; move the
  timeout to `default_format_opts.timeout_ms`.
- C2: delete `indentexpr`, `foldmethod` and `foldexpr` from `options.lua`.
  Retain `foldenable`, `foldlevel`, `foldlevelstart`, `foldminlines`,
  `foldnestmax` and `foldcolumn`.
- C3: repoint the two buffer-cycle keymaps; add
  `{ "akinsho/bufferline.nvim", enabled = false }`.
- C4: remove the `mini.animate` spec.
- C5: correct the stale comment.

### Phase 2 — Deduplicate `config/`

- Delete the 8 LazyVim-identical autocmd groups. Retain `on_lsp_attach` and
  `on_open_term`.
- Rewrite `close_with_q_or_esc` as an *extension* of LazyVim's
  `close_with_q` — contribute the extra filetypes and the `<Esc>` binding,
  rather than running a parallel group that double-binds `q` with a
  different body.
- Verify whether Neovim already detects `.yml` as `yaml`; drop
  `filetypedetect` only if it does.
- Strip the roughly 49 redundant lines from `options.lua`, annotating the
  retained divergences.

### Phase 3 — Extras and spec hygiene

- Import `lazyvim.plugins.extras.editor.aerial` and
  `lazyvim.plugins.extras.ui.treesitter-context` in `lazy.lua`, positioned
  between the LazyVim import and `{ import = "plugins" }`. Update
  `lazyvim.json`.
- Reduce the local aerial and treesitter-context specs to genuine
  overrides.
- Remove `fzf-lua`, the `nvim-web-devicons` dependency, the explicit
  `nui.nvim`, and `url-open`.
- Collapse the duplicate `render-markdown` declaration into `markdown.lua`.
- Change `helpview.nvim` to `ft = "help"`.
- Strip LazyVim-copied boilerplate from the lualine spec; remove the
  `neo-tree` extension.
- Remove the `<leader>gB` and `<leader>gY` gitbrowse keymaps. LazyVim sets
  these in `lazyvim/config/keymaps.lua`, which loads before
  `config/keymaps.lua`, so they are removed with `pcall(vim.keymap.del, …)`
  from the local keymaps file rather than by editing LazyVim.

### Phase 4 — Startup

- Move top-level `require('core/…')` out of `plugins/ui.lua`,
  `config/options.lua` and `config/usercmds.lua` into the `opts`, `config`
  and command callbacks that use them.
- Remove showkeys' `init` auto-toggle and its redundant `event`.
- Convert `ghostty.nvim`'s `cond` to function form so `executable()` is not
  called during spec collection.
- Re-measure against baseline.

### Phase 5 — Lua quality and specs

- `keymaps.lua`: change `vim.schedule_wrap(fn)()` to `vim.schedule(fn)`;
  delete 38 lines of commented-out Kickstart leftovers.
- Audit `plugins/lsp.lua`: the mason `ensure_installed` list mixes
  lspconfig server names with mason package names. `pyrefly`, `kotlin_lsp`,
  `postgres_lsp`, `nxls`, `gradle_ls`, `groovyls`, `marksman` and
  `ruby_lsp` are suspect, and `pkl-lsp` is not a valid `lspconfig` key.
  This is scoped as an audit; if the names are already correct the task is
  a no-op.
- Extend the busted suite over the `core/` helpers the earlier phases
  touch: `core/vi/paths`, `core/vi/maps/parse_mappings`, `core/neo`.
- Add a spec asserting the deferred-require contract: loading
  `plugins/ui.lua` must not place `core/ui/statusline` into
  `package.loaded`. This is what prevents Phase 4's win from silently
  regressing.

## Verification

Every phase ends with the same four gates, diffed against Phase 0:

1. `nvim --headless +q` exits clean — zero errors, zero deprecation
   notices.
2. `mise run startuptime` — recorded per phase, so a regression is
   attributable to its cause.
3. Keymap and autocmd dumps diffed. This is the load-bearing gate: it
   proves the deleted autocmd groups were redundant (the count halves, the
   behaviour does not disappear) and catches a keymap that silently stopped
   being defined.
4. `:checkhealth` diffed — catches a removed plugin something else
   depended on.

## Risks

- **Semantic drift in Phase 2.** The duplicated autocmds differ in small
  ways: `last_loc` uses a different buffer flag, `wrap_spell` fires a
  `Neo.debug` notify. The dump diff catches structure, not semantics, so
  each deletion pair is reviewed line-by-line rather than trusting the
  "identical" label.
- **`close_with_q_or_esc` is a behaviour change, not a deletion.** It is the
  one genuine conflict inside an otherwise-cosmetic phase and warrants its
  own commit.
- **Extras import order.** Wrong placement in `lazy.lua` merges overrides in
  the wrong direction. Phase 3 verifies via `:Lazy` that aerial's final
  `opts` still contain the local `attach_mode`.
- **The startup target may not be reachable.** Phase 4 addresses roughly
  38ms of a 131ms gap. Reaching <50ms would require restructuring `core/`
  internals, which the chosen scope excludes. The phase succeeds if the
  eager-require cost is eliminated, not if 50ms is hit.

## Out of scope

- Restructuring `lua/core/` internals (lazy metatable accessors, module
  splitting).
- Adopting `extras.ui.mini-animate` or `extras.editor.fzf`.
- Any change to `core/vi/lsp`, `core/opt/llm`, or the snacks picker
  implementations beyond moving their `require` call sites.
