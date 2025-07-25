-- Linting configuration using system-installed linters
-- This replaces Mason-managed linters with system-installed ones

return {
  -- Linting with nvim-lint
  -- https://lazyvim.org/plugins/linting#nvim-lint
  {
    "mfussenegger/nvim-lint",
    opts = {
      -- Event to trigger linters
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },

      linters_by_ft = {
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'global linter' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
        -- ["*"] = { "typos" },
        lua = { "selene" },
        python = { "flake8" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        javascriptreact = { "eslint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
        yaml = { "yamllint" },
        yml = { "yamllint" },
        markdown = { "markdownlint" },
        dockerfile = { "hadolint" },
        go = { "golangci-lint" },
        rust = { "clippy" },
        java = { "checkstyle" },
        kotlin = { "ktlint" },
        php = { "phpstan" },
        ruby = { "rubocop" },
        sql = { "sqlfluff" },
        toml = { "otter" },
      },

      --- LazyVim extension to easily override linter options or add custom linters.
      ---@see https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
      ---@type table<string,table>
      linters = {
        -- Example of using selene only when a selene.toml file is present
        selene = {
          -- `condition` is another LazyVim extension that allows you to
          -- dynamically enable/disable linters based on the context.
          condition = function(ctx)
            return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        flake8 = {
          args = {
            "--max-line-length=100",
            "--extend-ignore=E203,W503",
          },
        },
        shellcheck = {
          args = {
            "--severity=warning",
            "--shell=bash",
          },
        },
        yamllint = {
          args = {
            "-c"
          },
          condition = function(ctx)
            return vim.fs.find({ "yamllint.yml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        eslint = {
          args = {
            "--config"
          },
          condition = function(ctx)
            return vim.fs.find({ ".eslintrc.js" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        otter = {
          args = {
            "--config"
          },
          condition = function(ctx)
            return vim.fs.find({ "otter.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
    -- config = function()
    --   local lint = require("lint")
    --   -- Set up autocmd for linting
    --   local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    --   vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    --     group = lint_augroup,
    --     callback = function()
    --       lint.try_lint()
    --     end,
    --   })

    --   -- Add commands for manual linting
    --   vim.api.nvim_create_user_command("Lint", function()
    --     lint.try_lint()
    --   end, { desc = "Run linter" })

    --   vim.api.nvim_create_user_command("LintToggle", function(args)
    --     if args.bang then
    --       -- LintToggle! will toggle globally
    --       vim.g.disable_linting = not vim.g.disable_linting
    --       print("Setting global linting to: " .. tostring(not vim.g.disable_linting))
    --     else
    --       -- LintToggle will toggle for the current buffer
    --       vim.b.disable_linting = not vim.b.disable_linting
    --       print("Setting buffer linting to: " .. tostring(not vim.b.disable_linting))
    --     end
    --   end, { bang = true, desc = "Toggle linting" })
    -- end,
  },
}
