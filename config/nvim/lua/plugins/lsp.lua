-- LSP servers and clients communicate which features they support through "capabilities".
--  By default, Neovim supports a subset of the LSP specification.
--  With blink.cmp, Neovim has _more_ capabilities which are communicated to the LSP servers.
--  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
-- This uses the new Neovim 0.11 native LSP configuration system with nvim-lspconfig as config source

return {
  -- Portable package manager for Neovim that runs everywhere Neovim runs.
  -- Easily install and manage LSP servers, DAP servers, linters, and formatters.
  -- https://github.com/mason-org/mason.nvim
  -- https://lazyvim.org/plugins/lsp#masonnvim-1
  -- https://lazyvim.org/plugins/lsp#masonnvim-2
  {
    "mason-org/mason.nvim",
    version = "^1.0.0",
    opts = {
      ensure_installed = {
        "beautysh",
        "delve",
        "flake8",
        "gofumpt",
        "goimports",
        "gomodifytags",
        "impl",
        "selene",
        "shellcheck",
        "shfmt",
        "sql-formatter",
        "stylua",
        "yamlfix",
        "yamlfmt",
        "yamllint",
      },
    }
  },

  -- nvim-lspconfig provides LSP configurations (not the framework)
  -- https://github.com/neovim/nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    event = 'VeryLazy',
    config = function()
      -- Enable all configured LSP servers using nvim-lspconfig configurations
      -- These configurations are provided by nvim-lspconfig in its lsp/ directory
      vim.lsp.enable({
        'ast_grep',
        'bashls',
        'biome',
        'copilot',
        'cssls',
        'diagnosticls',
        'docker_compose_language_service',
        'dockerls',
        'eslint',
        'gopls',
        'html',
        'jsonls',
        'kotlin_language_server',
        'lua_ls',
        'marksman',
        'neocmake',
        'pyright',
        'rubocop',
        'ruby_lsp',
        'taplo',
        'ruff',
        'vimls',
        'vtsls',
        'yamlls',
      })

      -- Configure diagnostic display
      vim.diagnostic.config({
        virtual_text = { current_line = true },
        virtual_lines = true,
        underline = true,
        signs = true,
      })
    end,
  },

  -- Otter.nvim provides LSP features and a code completion source for code embedded in other documents
  -- https://github.com/jmbuhr/otter.nvim
  {
    'jmbuhr/otter.nvim',
    ft = 'toml',
    event = 'VeryLazy',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      -- TREE-SITTER-GHOSTTY - A tree-sitter parser for ghostty
      -- https://github.com/bezhermoso/tree-sitter-ghostty | https://mise.jdx.dev/mise-cookbook/neovim.html#enable-lsp-for-embedded-lang-in-run-commands
      {
        'bezhermoso/tree-sitter-ghostty',
        build = 'make nvim_install',
        cond = require('core/vi/fn/paths').is_executable('ghostty'),
      },
    },
    config = function()
      vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = vim.api.nvim_create_augroup('EmbedToml', {}),
        pattern = { 'toml' },
        callback = function()
          require('otter').activate()
        end,
      })
    end,
  },
}
