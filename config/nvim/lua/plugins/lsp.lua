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
-- LSP servers and clients are able to communicate to each other what features they support.
--  By default, Neovim doesn't support everything that is in the LSP specification.
--  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
--  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
-- NOTE: The following line is now commented as blink.cmp extends capabilites by default from its internal code: 1Code has comments. Press enter to view.
-- https://github.com/Saghen/blink.cmp/blob/102db2f5996a46818661845cf283484870b60450/plugin/blink-cmp.lua
-- It has been left here as a comment for educational purposes (as the predecessor completion plugin required this explicit step).
--
-- local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Language servers can broadly be installed in the following ways:
--  1) via the mason package manager; or
--  2) via your system's package manager; or
--  3) via a release binary from a language server's repo that's accessible somewhere on your system.

-- The servers table comprises the following sub-tables:
-- 1. mason
-- 2. others
-- Both these tables have an identical structure of language server names as keys and
-- a table of language server configuration as values.
--- @class LspServersConfig
--- @field mason table<string, vim.lsp.Config>
--- @field others table<string, vim.lsp.Config>
local ensured_installed = {
  --  Add any additional override configuration in any of the following tables. Available keys are:
  --  - cmd (table): Override the default command used to start the server
  --  - filetypes (table): Override the default list of associated filetypes for the server
  --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
  --  - settings (table): Override the default settings passed when initializing the server.
  --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
  --
  --  Feel free to add/remove any LSPs here that you want to install via Mason. They will automatically be installed and setup.
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          diagnostics = { globals = { 'vim', 'require' } },
        },
      },
    },
  },
  -- This table contains config for all language servers that are *not* installed via Mason.
  -- Structure is identical to the mason table from above.
  other_servers = {
    bashls = {},
    cssls = {},
    diagnosticls = {},
    docker_compose_language_service = {},
    dockerls = {},
    emmet_ls = {},
    eslint = {},
    html = {},
    jsonls = {},
    pyright = {},
    ruby_lsp = {},
    taplo = {},
    vimls = {},
    vtsls = {},
    yamlls = {},
  },
  tools = {
    -- VImScript language server, LSP for vim script
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vimls
    -- 'vim-language-server',

    -- Language server for Bash
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#bashls
    -- 'bash-language-server',

    -- (Redhat's) Language Server for YAML Files
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#yamlls
    -- 'yaml-language-server',

    -- LSP wrapper for typescript extension of vscode
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vtsls
    -- 'vtsls',

    -- EditorConfig checker
    -- https://github.com/editorconfig/editorconfig-vim
    'editorconfig-checker',

    -- A Bash beautifier for the masses
    -- https://github.com/lovesegfault/beautysh
    'beautysh',

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

    -- ⚠️ WARNING prettier unavailable: Command 'prettier' not found
    -- https://prettier.io
    'prettier',

    -- ⚠️ WARNING prettierd unavailable: Command 'prettierd' not found
    -- https://github.com/fsouza/prettierd
    'prettierd',

    -- Diagnostic language server integrate with linters
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#diagnosticls
    -- 'diagnostic-languageserver',

    -- (Microsoft's) Language service for Docker Compose documents
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#docker_compose_language_service
    -- 'docker-compose-language-service',

    -- Language server for dockerfiles
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#dockerls
    -- 'dockerls',

    -- Language server for JSON and JSON schema
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonls
    -- 'jsonls',

    -- Language server for Taplo, a TOML toolkit (https://taplo.tamasfe.dev/cli/usage/language-server.html)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#taplo
    -- 'taplo',

    -- Fast formatter, linter, for JavaScript, TypeScript, JSX, TSX, JSON, HTML, CSS and GraphQL written in Rust (https://biomejs.dev)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#biome
    { 'biome',         condition = has('biome') },

    -- Frontend-independent IDE "smartness" server for Elixir. Implements the "Language Server Protocol" standard and provides debugger support via the "Debug Adapter Protocol" (https://elixir-lsp.github.io/elixir-ls)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#elixirls
    { 'elixirls',      condition = has('elixir') },

    -- ESLint's Language server for javascript and typescript
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#eslint
    { 'eslint',        condition = has('eslint') },

    -- (Google's) Language server for golang
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gopls
    { 'gopls',         condition = has('go') },

    -- (Microsoft's) Language server for gradle files
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gradle_ls
    { 'gradle_ls',     condition = has('gradle') },

    -- Groovy Language server
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#groovyls
    { 'groovyls',      condition = has('groovy') },

    -- Language server for the KCL configuration and policy language (https://kcl-lang.io)
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#kcl
    { 'kcl',           condition = has('kcl') },

    -- Official Kotlin LSP implementation and support for VSCode
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#kotlin_lsp
    { 'kotlin_lsp',    condition = has('kotlin') },

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

    -- A tool to automatically apply fixes to Go source code
    -- https://github.com/mvdan/gofumpt
    { 'gofumpt',       condition = has('go') },

    -- A tool to help you write better Go code
    -- https://github.com/segmentio/golines
    { 'golines',       condition = has('go') },

    -- A tool to automatically add tags to Go functions
    -- https://github.com/fatih/gomodifytags
    { 'gomodifytags',  condition = has('go') },

    -- A tool to automatically generate Go test files
    -- https://github.com/cweill/gotests
    { 'gotests',       condition = has('go') },

    -- ⚠️ WARNING black unavailable: Command 'black' not found
    -- https://black.readthedocs.io
    { 'black',         condition = has('python') },

    -- ⚠️ WARNING isort unavailable: Command 'isort' not found
    -- https://pycqa.github.io/isort
    { 'isort',         condition = has('python') },

    -- ⚠️ WARNING rustfmt unavailable: Command 'rustfmt' not found
    -- https://rust-lang.github.io/rustfmt
    { 'rustfmt',       condition = has('rust') },
  }
}

-- Main LSP Configuration
return {
  -- This is a big one, make sure you understand it all. Also, make sure that
  -- it doesn't need more loading priority based on the fact that it comes
  -- before certain things in the default kickstart config, but is not first
  -- alphabetically in the plugins.
  {
    'neovim/nvim-lspconfig',
    priority = 1001,
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim',    opts = {} },
      -- Allows extra capabilities provided by blink.cmp
      'saghen/blink.cmp',
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

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
      -- NOTE: The following line is now commented as blink.cmp extends capabilites by default from its internal code: 1Code has comments. Press enter to view.
      -- https://github.com/Saghen/blink.cmp/blob/102db2f5996a46818661845cf283484870b60450/plugin/blink-cmp.lua
      -- It has been left here as a comment for educational purposes (as the predecessor completion plugin required this explicit step).
      --
      -- local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      --
      -- `mason` had to be setup earlier: to configure its options see the
      -- `dependencies` table for `nvim-lspconfig` above.
      --
      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(ensured_installed.servers or {})
      vim.list_extend(ensure_installed, ensured_installed.tools)
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- Either merge all additional server configs from the `servers` and `other_servers` tables
      -- to the default language server configs as provided by nvim-lspconfig, or
      -- define a custom server config that's unavailable on nvim-lspconfig.
      for server, config in pairs(vim.tbl_extend('keep', ensured_installed.servers, ensured_installed.other_servers)) do
        if not vim.tbl_isempty(config) then
          vim.lsp.config(server, config)
        end
      end

      -- After configuring our language servers, we now enable them.
      require('mason-lspconfig').setup {
        ensure_installed = {},         -- explicitly set to an empty table (it populates installs via mason-tool-installer by default)
        automatic_installation = true, -- automatically run vim.lsp.enable() for all servers that are installed via Mason
      }

      -- Manually run vim.lsp.enable for all langauge servers that are *not* installed via Mason
      if not vim.tbl_isempty(ensured_installed.other_servers) then
        vim.lsp.enable(vim.tbl_keys(ensured_installed.other_servers))
      end
    end
  }
}
