# Design Spec: Porting Kickstart Neovim to LazyVim

- **Date:** 2026-08-22
- **Author:** AI Coding Agent
- **Status:** Proposed

## 1. Background & Objectives

The current Neovim configuration (`~/.config/nvim`) is based on a Kickstart template that borrows patterns from LazyVim. It is frequently outdated, requiring manual overrides and fixes.
This spec outlines the migration of this configuration to a standard, structured **LazyVim** configuration. The objective is to establish a robust base on LazyVim while fully preserving:

1. All custom logic and library modules in `lua/core/`.
2. Core configuration settings (options, keymaps, autocommands, user commands).
3. Custom plugin specifications and integrations (LSP configurations, blink.cmp completion sources, conform.nvim formatters, UI configs, AI helpers).
4. Supporting files (`mise.toml`, `.luarc.json`, `neovim.yml`, `specs/` folder, `tools/` folder, and `snippets/` directory).

---

## 2. Architecture & Directory Layout

### Legacy Layout
- `init.lua`: Bootstraps local configuration, requires `core/neo` library, and loads `config` module.
- `lua/config/`: Options, keymaps, autocmds, usercmds, and `lazy.lua` setup.
- `lua/plugins/`: Custom plugin specs loaded as top-level specifications.
- `lua/core/`: Elaborate library module containing utility functions, statusline configuration, and custom integrations.

### Target LazyVim Layout

We will transition to the standard LazyVim layout, keeping `core/` intact:

```
~/.config/nvim/
├── init.lua                      # Entry point, calls config.lazy
├── lua/
│   ├── core/                     # UNCHANGED: Custom library helpers (git, ui, paths, etc.)
│   ├── config/
│   │   ├── lazy.lua              # Bootstraps lazy.nvim and imports LazyVim + plugins
│   │   ├── options.lua           # Custom options (overriding LazyVim defaults)
│   │   ├── keymaps.lua           # Custom keymaps (using core/vi/maps)
│   │   ├── autocmds.lua          # Custom autocommands (using core/vi/au)
│   │   └── usercmds.lua          # Custom user commands (loaded explicitly)
│   └── plugins/
│       ├── lsp.lua               # LSP overrides (opts.servers, mason-tool-installer)
│       ├── completion.lua        # Blink.cmp overrides (opts.sources, compat)
│       ├── formater.lua          # Conform.nvim formatting overrides
│       ├── ui.lua                # UI plugin specifications (tokyonight, snacks, noice, etc.)
│       ├── coding.lua            # Coding plugins (mini.pairs, visual-multi)
│       ├── markdown.lua          # Markdown utilities
│       └── ai.lua                # AI specs (copilot)
├── snippets/                     # Custom snippets folder
├── specs/                        # Spec/testing framework
├── tools/                        # Docker/supporting tools
├── mise.toml                     # Tool version configuration
├── .luarc.json                   # Workspace settings
└── neovim.yml                    # Workspace metadata
```

---

## 3. Detailed Component Specifications

### 3.1. Scaffolding & Setup (`lua/config/lazy.lua`)

Bootstraps `lazy.nvim` and loads specifications in the correct order:

1. Load `LazyVim/LazyVim` with `lazyvim.plugins` import.
2. Load user customizations from `plugins`.

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- import LazyVim plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import your plugins/overrides
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

### 3.2. Options (`lua/config/options.lua`)
- Sets the `<leader>` key and custom `vim.opt` configurations.
- Retains variables like `vim.g.deprecation_warnings = false` and other global mappings needed by `core/`.

### 3.3. Keymaps & User Commands
- **`lua/config/keymaps.lua`**: Uses `require('core/vi/maps').set_keymaps` to load keymaps in batch, maintaining compatibility with the custom mapping engine.
- **`lua/config/usercmds.lua`**: Maintained as-is. Loaded explicitly by adding `require('config.usercmds')` at the end of `init.lua` or `keymaps.lua`.

### 3.4. Plugin Configurations (Deep Merging)

We will customize existing LazyVim specs by overriding their `opts` and dependencies rather than replacing their configuration blocks:

- **`lsp.lua`**: Customizes `"neovim/nvim-lspconfig"`.
  - Maps servers and custom configurations to `opts.servers`.
  - Adds `WhoIsSethDaniel/mason-tool-installer.nvim` to auto-install all specified formatters and linters.
- **`completion.lua`**: Customizes `"saghen/blink.cmp"`.
  - Appends your custom sources (`blink-copilot`, `blink-cmp-conventional-commits`, `blink-cmp-git`, `colorful-menu.nvim`) to default sources.
  - Appends dependencies.
- **`formater.lua`**: Customizes `"stevearc/conform.nvim"`.
  - Merges custom formatters by filetype (`formatters_by_ft`), autoformat on save behavior (`format_on_save`), and fallback formatting settings.
- **`ui.lua`, `coding.lua`, `markdown.lua`, `ai.lua`**:
  - Convert absolute plugin configurations to `opts` updates for plugins pre-configured by LazyVim (e.g. `snacks.nvim`, `noice.nvim`, `mini.pairs`, `nvim-treesitter`).
  - Leave independent plugins (e.g., `ghostty.nvim`, `live-preview.nvim`) as clean independent specs.

---

## 4. Backup & Safety Execution Plan

1. Verify if `~/.config/nvim` exists.
2. Check for existing backup folders in `~/.config/`.
3. If `nvim.bak` exists, determine backup destination as `nvim.bak.<timestamp>` (e.g., `nvim.bak.20260822_150405`). Otherwise, use `nvim.bak`.
4. Copy `/Users/roalcantara/.config/nvim` recursively to the designated backup path.
5. Clean the configuration folder and write the new files.

---

## 5. Testing & Validation Plan

### 5.1. Headless Health Check

Ensure no syntax or initialization errors on start:

```bash
nvim --headless -c "checkhealth" -c "qa"
```

### 5.2. Startup Profiling

Verify startup performance is preserved:

```bash
nvim --headless -c "Lazy profile" -c "qa"
```

### 5.3. Loaded Plugins Verification

Verify that both core LazyVim plugins and your custom overrides are loaded correctly:

```bash
nvim --headless +"lua local lazy = require('lazy'); for _, p in ipairs(lazy.plugins()) do print(string.format('%s|loaded=%s', p.name, tostring(p._.loaded ~= nil))) end" +quit
```
