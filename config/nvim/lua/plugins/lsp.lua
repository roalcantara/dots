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
        "shellcheck",
        "shfmt",
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
    opts = {
      --     -- you can do any additional lsp server setup here
      --     -- return true if you don't want this server to be setup with lspconfig
      --     ---@type table<string, fun(server, opts):boolean?>
      setup = {
        --       -- example to setup with typescript.nvim
        --       -- tsserver = function(_, opts)
        --       --   require("typescript").setup({ server = opts })
        --       --   return true
        --       -- end,
        --       -- Specify * to use this function as a fallback for any server
        ["*"] = function(server, opts)
          --- Remove LSP keymaps
          -- vim.api.nvim_create_autocmd({ 'LspAttach' }, {
          --   callback = function(ev)
          --     if ev.file:match('%.vim$') then
          --       pcall(vim.keymap.del, 'n', 'K', { buffer = ev.buf })
          --     end
          --   end,
          -- })
          vim.schedule(function()
            require("core/vi/ui/lsp").setup_capabilities(server, opts)
          end)
        end,
      },
    },
  },

  -- Otter.nvim provides LSP features and a code completion source for code embedded in other documents
  -- https://github.com/jmbuhr/otter.nvim
  {
    'jmbuhr/otter.nvim',
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
