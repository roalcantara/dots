-- LSP servers and clients communicate which features they support through "capabilities".
--  By default, Neovim supports a subset of the LSP specification.
--  With blink.cmp, Neovim has _more_ capabilities which are communicated to the LSP servers.
--  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
-- This can vary by config, but in general for nvim-lspconfig:

return {
  {
    "williamboman/mason.nvim",
    event = 'VeryLazy',
    opts = {
      ensure_installed = {
        "beautysh",
        "flake8",
        "goimports",
        "gofumpt",
        "gomodifytags",
        "impl",
        "delve",
        "selene",
        "shellcheck",
        "shfmt",
        "sql-formatter",
        "stylua",
        "yamlfix",
        "yamlfmt",
        "yamllint",
      },
    },
  },
  -- add tsserver and setup with typescript.nvim instead of lspconfig
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
}
