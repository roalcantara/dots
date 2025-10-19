-- =============================================================================
-- Uses Neovim's built-in LSP client/framework
-- -----------------------------------------------------------------------------
-- 💡 TL;DR:
-- 1. |mason-tool-installer.nvim| installs/updates LSP servers and tools automatically (via *mason.nvim*)
-- 2. |nvim-lspconfig| provides default LSP client configuration for various servers (:h vim.lsp.config())
--  ➡ LSP server configuration can be extended:
--    ➡ To *STATICALLY* extend the Lua language server configuration:
--      · use vim.lsp.config('lua_ls', { ... })
--      · create the file ~/.config/nvim/lua/lsp/lua_ls.lua
--    ➡ To *DYNAMICALLY* extend any LSP server configuration:
--      · :h lsp-attach
--      · Client:on_attach()
-- 4. |mason-lspconfig.nvim| enables installed servers automatically (:h vim.lsp.enable())
-- 5. When LSP is active in a buffer, Nvim sets some defaults:
--    · options     (:h lsp-defaults)
--    · mappings    (https://neovim.io/doc/user/lsp.html#grr)
--    · diagnostics (:h diagnostic-defaults)
-- -----------------------------------------------------------------------------
-- 🔖 REFERENCES
-- https://neovim.io/doc/user/lsp.html#lsp-config
-- https://neovim.io/doc/user/lsp.html
-- https://youtu.be/tdhxpn1XdjQ | https://youtu.be/5YQlibmXa0E
-- =============================================================================

local has = require('core/vi/paths').has

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    {
      'mason-org/mason-lspconfig.nvim',
      opts = {
        -- Manages LSP servers only
        -- Purpose: Manages LSP servers only
        -- Scope: Uses nvim-lspconfig server names (lua_ls, pyright)
        ensure_installed = {
          'lua_ls',
          'pyright',
        },
        automatic_enable = true,
      },
    },
    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      opts = {
        -- Purpose: Manages all other development tools
        -- Scope: Formatters, linters, debuggers, and additional LSP servers
        -- Names: Uses mason.nvim package names (bash-language-server, stylua)
        ensure_installed = {
          -- =====================================================================
          -- LSP SERVERS
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
          -- =====================================================================

          -- Language server for Bash
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls
          'bash-language-server',

          -- Fast formatter, linter, for JavaScript, TypeScript, JSX, TSX, JSON, HTML, CSS and GraphQL written in Rust (https://biomejs.dev)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#biome
          { 'biome',     condition = has('biome') },

          -- Diagnostic language server integrate with linters
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#diagnosticls
          'diagnostic-languageserver',

          -- (Microsoft's) Language service for Docker Compose documents
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#docker_compose_language_service
          'docker-compose-language-service',

          -- (Docker's) Language server for Dockerfiles, Compose files, and Bake files
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#docker_language_server
          -- 'docker_language_server',

          -- Language server for dockerfiles
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#dockerls
          'dockerls',

          -- Frontend-independent IDE "smartness" server for Elixir. Implements the "Language Server Protocol" standard and provides debugger support via the "Debug Adapter Protocol" (https://elixir-lsp.github.io/elixir-ls)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#elixirls
          { 'elixirls',  condition = has('elixir') },

          -- ESLint's Language server for javascript and typescript
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
          { 'eslint',    condition = has('eslint') },

          -- (Google's) Language server for golang
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gopls
          { 'gopls',     condition = has('go') },

          -- (Microsoft's) Language server for gradle files
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gradle_ls
          { 'gradle_ls', condition = has('gradle') },

          -- Groovy Language server
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#groovyls
          { 'groovyls',  condition = has('groovy') },

          -- Language server for JSON and JSON schema
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonls
          'jsonls',

          -- Language server for the KCL configuration and policy language (https://kcl-lang.io)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#kcl
          { 'kcl',        condition = has('kcl') },

          -- Official Kotlin LSP implementation and support for VSCode
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#kotlin_lsp
          { 'kotlin_lsp', condition = has('kotlin') },

          -- Lua Language server (https://github.com/LuaLS/lua-language-server)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
          'lua-language-server',

          -- Language server for Markdown providing completion, cross-references, diagnostics, and more (https://github.com/artempyanykh/marksman)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#marksman
          { 'marksman',      condition = has('marksman') },

          -- Language server for Nx Workspaces (https://github.com/nrwl/nx-console/tree/master/apps/nxls)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#nxls
          { 'nxls',          condition = has('nxls') },

          -- Language server and tools for Postgres, focusing on developer experience and reliable SQL tooling (https://pgtools.dev)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#postgres_lsp
          { 'postgres_lsp',  condition = has('psql') },

          -- Fast Python type checker written in Rust (https://pyrefly.org)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#pyrefly
          { 'pyrefly',       condition = has('python') },

          -- Language server maintained by Shopify, with built-in RuboCop integration, which provides the best dev experience for Ruby/Rails projects
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ruby_lsp
          { 'ruby_lsp',      condition = has('ruby') },

          -- Rust Language server
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#rust_analyzer
          { 'rust-analyzer', condition = has('rustc') },

          -- Extremely fast Python linter and code formatter, written in Rust (https://docs.astral.sh/ruff)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#ruff
          { 'ruff',          condition = has('python') },

          -- Language server for Taplo, a TOML toolkit (https://taplo.tamasfe.dev/cli/usage/language-server.html)
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#taplo
          'taplo',

          -- VImScript language server, LSP for vim script
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vimls
          'vim-language-server',

          -- LSP wrapper for typescript extension of vscode
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
          'vtsls',

          -- (Redhat's) Language Server for YAML Files
          -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
          'yaml-language-server',

          -- =====================================================================
          -- TOOLS
          -- =====================================================================

          -- EditorConfig checker
          -- https://github.com/editorconfig/editorconfig-vim
          'editorconfig-checker',

          -- A Bash beautifier for the masses
          -- https://github.com/lovesegfault/beautysh
          'beautysh',

          -- A tool to automatically apply fixes to Go source code
          -- https://github.com/mvdan/gofumpt
          { 'gofumpt',      condition = has('go') },

          -- A tool to help you write better Go code
          -- https://github.com/segmentio/golines
          { 'golines',      condition = has('go') },

          -- A tool to automatically add tags to Go functions
          -- https://github.com/fatih/gomodifytags
          { 'gomodifytags', condition = has('go') },

          -- A tool to automatically generate Go test files
          -- https://github.com/cweill/gotests
          { 'gotests',      condition = has('go') },

          -- A shell script static analysis tool
          -- https://shellcheck.net
          'shellcheck',

          -- A shell parser, formatter, and interpreter with bash support. Requires Go 1.23 or later
          -- https://pkg.go.dev/mvdan.cc/sh
          'shfmt',

          -- Deterministic code formatter for Lua 5.1, 5.2, 5.3, 5.4, LuaJIT, Luau and CfxLua/FiveM Lua
          -- https://github.com/JohnnyMorganz/StyLua
          'stylua',

          -- Simple opinionated yaml formatter that keeps your comments
          -- https://lyz-code.github.io/yamlfix
          'yamlfix',

          -- (Google's) Extensible command line tool or library to format yaml files
          -- https://github.com/google/yamlfmt
          'yamlfmt',

          -- A linter for YAML files
          -- https://yamllint.readthedocs.io
          'yamllint',
        },
        -- if set to true this will check each tool for updates. If updates
        -- are available the tool will be updated. This setting does not
        -- affect :MasonToolsUpdate or :MasonToolsInstall.
        auto_update = true, -- (default: false)

        -- automatically install / update on startup. If set to false nothing
        -- will happen on startup. You can use :MasonToolsInstall or
        -- :MasonToolsUpdate to install tools and check for updates.
        -- Default: true
        run_on_start = true,

        -- set a delay (in ms) before the installation starts. This is only
        -- effective if run_on_start is set to true.
        -- e.g.: 5000 = 5 second delay, 10000 = 10 second delay, etc...
        -- Default: 0
        start_delay = 3000, -- 3 second delay

        -- Only attempt to install if 'debounce_hours' number of hours has
        -- elapsed since the last time Neovim was started. This stores a
        -- timestamp in a file named stdpath('data')/mason-tool-installer-debounce.
        -- This is only relevant when you are using 'run_on_start'. It has no
        -- effect when running manually via ':MasonToolsInstall' etc....
        -- Default: nil
        debounce_hours = 5, -- at least 5 hours between attempts to install/update

        -- By default all integrations are enabled. If you turn on an integration
        -- and you have the required module(s) installed this means you can use
        -- alternative names, supplied by the modules, for the thing that you want
        -- to install. If you turn off the integration (by setting it to false) you
        -- cannot use these alternative names. It also suppresses loading of those
        -- module(s) (assuming any are installed) which is sometimes wanted when
        -- doing lazy loading.
        -- integrations = {
        --   ['mason-lspconfig'] = true,
        --   ['mason-null-ls'] = true,
        --   ['mason-nvim-dap'] = true,
        -- },
      },
    },
  },
  config = function()
    local icons = require('core/ui/icons/icons_list')

    -- https://gpanders.com/blog/whats-new-in-neovim-0-11
    -- https://neovim.io/doc/user/diagnostic.html#diagnostic-defaults
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
          [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
          [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
        },
      },
      -- https://gpanders.com/blog/whats-new-in-neovim-0-11/#virtual-text-handler-changed-from-opt-out-to-opt-in
      -- Neovim no longer enables the "virtual text" diagnostic handler by default. It must now be opted-into explicitly
      -- virtual_text = {
      --   -- Only enable virtual text diagnostics for the current cursor line
      --   current_line = true
      -- },
      -- https://gpanders.com/blog/whats-new-in-neovim-0-11/#virtual-lines
      virtual_lines = {
        -- Only show virtual line diagnostics for the current cursor line
        current_line = true,
      },
    })
  end,
}
