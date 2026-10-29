return {
  -- mason-org/mason.nvim
  -- LazyVim natively integrates with mason.nvim and automatically installs tools specified in `opts.ensure_installed`
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local has = require('core/vi/paths').has
      local tools = {
        'editorconfig-checker',
        'shellcheck',
        'shfmt',
        'stylua',
        'yamlfix',
        'yamlfmt',
        'yamllint',
        'prettier',
        'prettierd',
        { 'biome',         condition = has('biome') },
        { 'elixir-ls', condition = has('elixir') },
        { 'eslint-lsp', condition = has('eslint') },
        { 'gopls', condition = has('go') },
        { 'gradle-language-server', condition = has('gradle') },
        { 'groovy-language-server', condition = has('groovy') },
        { 'kcl', condition = has('kcl') },
        { 'kotlin-lsp', condition = has('kotlin') },
        { 'marksman', condition = has('marksman') },
        { 'nxls', condition = has('nxls') },
        { 'postgres-language-server', condition = has('psql') },
        { 'pyrefly', condition = has('python') },
        { 'ruby-lsp', condition = has('ruby') },
        { 'rust-analyzer', condition = has('rustc') },
        { 'ruff',          condition = has('python') },
        { 'gofumpt',       condition = has('go') },
        { 'golines',       condition = has('go') },
        { 'gomodifytags',  condition = has('go') },
        { 'gotests',       condition = has('go') },
        { 'black',         condition = has('python') },
        { 'isort',         condition = has('python') },
        { 'rustfmt',       condition = has('rust') },
      }

      opts.ensure_installed = opts.ensure_installed or {}
      for _, t in ipairs(tools) do
        if type(t) == 'string' then
          table.insert(opts.ensure_installed, t)
        elseif type(t) == 'table' and (not t.condition or t.condition()) then
          table.insert(opts.ensure_installed, t[1])
        end
      end
    end,
  },

  -- Neovim/nvim-lspconfig
  -- LazyVim centralizes server registration and automatically sets up servers defined under `opts.servers`
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local icons = require('core/ui/icons/icons_list')

      -- Merge diagnostics configuration
      opts.diagnostics = vim.tbl_deep_extend('force', opts.diagnostics or {}, {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
          },
        },
        virtual_lines = {
          current_line = true,
        },
      })

      -- Register custom server settings
      opts.servers = opts.servers or {}

      -- Lua Server
      opts.servers.lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            diagnostics = { globals = { 'vim', 'require' } },
          },
        },
      }

      -- Typescript/vtsls Server
      opts.servers.vtsls = {
        filetypes = {
          'javascript', 'javascriptreact', 'javascript.jsx',
          'typescript', 'typescriptreact', 'typescript.tsx',
        },
        settings = vim.tbl_deep_extend('force', {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = 'always' },
            suggest = { completeFunctionCalls = true },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = 'literals' },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        }, vim.fn.executable('bun') == 1 and { vtsls = { packageManager = 'bun' } } or {}),
      }

      -- Other standard servers configured automatically by LazyVim
      local other_servers = {
        "bashls", "cssls", "diagnosticls", "docker_compose_language_service",
        "dockerls", "emmet_ls", "eslint", "html", "jsonls", "pyright",
        "ruby_lsp", "taplo", "vimls", "yamlls",
      }
      for _, server in ipairs(other_servers) do
        opts.servers[server] = opts.servers[server] or {}
      end
    end,
  },
}
