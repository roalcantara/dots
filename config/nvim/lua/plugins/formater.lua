return {
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports", "golines", "gofmt" },
    },
    -- format_on_save = {
    --     lsp_fallback = true,
    --     async = false,
    -- },
  }
}
