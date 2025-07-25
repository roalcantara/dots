-- Formatting configuration using system-installed formatters
-- This replaces Mason-managed formatters with system-installed ones

return {
  -- Null-ls replacement for formatting and linting
  -- https://lazyvim.org/plugins/formatting#conformnvim
  -- https://github.com/stevearc/conform.nvim
  {
    "stevearc/conform.nvim",
    opts = function()
      -- local plugin = require("lazy.core.config").plugins["conform.nvim"]
      -- if plugin.config ~= M.setup then
      --   LazyVim.error({
      --     "Don't set `plugin.config` for `conform.nvim`.\n",
      --     "This will break **LazyVim** formatting.\n",
      --     "Please refer to the docs at https://lazyvim.org/plugins/formatting",
      --   }, { title = "LazyVim" })
      -- end
      local opts = {
        default_format_opts = {
          timeout_ms = 3000,
          async = false,           -- not recommended to change
          quiet = false,           -- not recommended to change
          lsp_format = "fallback", -- not recommended to change
          stop_after_first = true, -- This replaces the nested {} behavior (https://reddit.com/r/neovim/comments/1f3cnur/need_your_help_new_to_neovim/)
        },
        formatters_by_ft = {
          lua = { "stylua" },
          fish = { "fish_indent" },
          sh = { "shfmt", "beautysh" },
          go = { "goimports", "gofumpt" },
          python = { "black", "isort" },
          javascript = { "prettierd", "prettier" },
          typescript = { "prettierd", "prettier" },
          typescriptreact = { "prettierd", "prettier" },
          javascriptreact = { "prettierd", "prettier" },
          json = { "prettierd", "prettier" },
          jsonc = { "prettierd", "prettier" },
          yaml = { "yamlfmt" },
          yml = { "yamlfmt" },
          markdown = { "prettierd", "prettier" },
          bash = { "beautysh" },
          zsh = { "beautysh" },
          sql = { "sql-formatter" },
          toml = { "taplo" },
          rust = { "rustfmt" },
          java = { "google-java-format" },
          kotlin = { "ktlint" },
          dart = { "dart_format" },
          swift = { "swiftformat" },
          c = { "clang_format" },
          cpp = { "clang_format" },
          cs = { "csharpier" },
          php = { "php_cs_fixer" },
          ruby = { "rubocop" },
          html = { "prettierd", "prettier" },
          css = { "prettierd", "prettier" },
          scss = { "prettierd", "prettier" },
          less = { "prettierd", "prettier" },
          vue = { "prettierd", "prettier" },
          svelte = { "prettierd", "prettier" },
          graphql = { "prettierd", "prettier" },
          dockerfile = { "hadolint" },
        },
        -- The options you set here will be merged with the builtin formatters.
        -- You can also define any custom formatters here.
        --- @type table<string, function|table>
        formatters = {
          injected = { options = { ignore_errors = true } },
          -- Using sql_formatter only when a sql-formatter.json file is present
          sql_formatter = {
            prepend_args = { "--config" },
            condition = function(ctx)
              return vim.fs.find({ "sql-formatter.json" }, { path = ctx.filename, upward = true })[1]
            end,
          },
          -- Using shfmt with extra args
          shfmt = {
            prepend_args = { "-i", "2", "-ci" },
          },
          prettier = {
            prepend_args = { "--print-width", "100", "--tab-width", "2", "--use-tabs", "false" },
          },
          black = {
            prepend_args = { "--line-length", "100" },
          },
          goimports = {
            prepend_args = { "-local", "github.com/roalcantara" },
          }
        },
      }
      return opts
    end
  },
}
