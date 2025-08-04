--- Check if a command is available
--- @param name string The name of the command to check
--- @return function True if the command is available, false otherwise
local function has(name)
  return function()
    return vim.fn.executable(name) == 1
  end
end

-- Install and upgrade third party tools automatically
-- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  'neovim/nvim-lspconfig',
  { 'mason-org/mason.nvim',           opts = {} },
  { 'mason-org/mason-lspconfig.nvim', opts = {} },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      -- LSP servers to ensure are installed
      -- It expects Mason package names by default
      -- It also accepts lspconfig package names, as mason-lspconfig is installed
      ensure_installed = {
        -- =====================================================================
        -- LSP servers
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

        -- Language server for Gleam Programming Language (https://gleam.run)
        -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#gleam
        { 'gleam',     condition = has('gleam') },

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
        -- Tools
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
      integrations = {
        ['mason-lspconfig'] = true,
        ['mason-null-ls'] = true,
        ['mason-nvim-dap'] = true,
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsStartingInstall',
        callback = function()
          vim.schedule(function()
            print('[mason-tool-installer] is starting...')
          end)
        end,
        desc = 'MasonToolsStartingInstall',
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsUpdateCompleted',
        callback = function(e)
          vim.schedule(function()
            print('[mason-tool-installer] done! ===> ' .. vim.inspect(e.data) .. '\r\n')
          end)
        end,
        desc = 'MasonToolsUpdateCompleted',
      })
    end,
  },
}
