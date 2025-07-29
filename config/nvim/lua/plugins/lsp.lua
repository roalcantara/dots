return {
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
  { "neovim/nvim-lspconfig" },
}
