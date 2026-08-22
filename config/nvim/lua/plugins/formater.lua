return {
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        rust = { 'rustfmt' },
        javascript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
      }

      opts.default_format_opts = {
        lsp_format = 'fallback',
      }

      opts.format_on_save = {
        timeout_ms = 500,
      }

      opts.log_level = vim.log.levels.ERROR
      opts.notify_on_error = true
      opts.notify_no_formatters = true
    end,
  },
}
