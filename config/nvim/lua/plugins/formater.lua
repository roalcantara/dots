-- local has = require('core/vi/paths').has
-- local function get_available_formatters(lang, bufnr, possible_formatters, opts)
--   local formatters = {}
--   opts = opts or {}
--   if has(lang) then
--     for _, formatter in ipairs(possible_formatters) do
--       if require('conform').get_formatter_info(formatter, bufnr).available then
--         table.insert(formatters, formatter)
--       end
--     end
--   end
--   return vim.tbl_deep_extend('force', formatters, opts)
-- end

return {
  -- Lightweight yet powerful formatter plugin for Neovim
  -- https://github.com/stevearc/conform.nvim
  -- https://youtu.be/UVO_cq3xATo
  -- :lua require('conform').format() | :checkhealth conform | :h conform-formatters
  {
    'stevearc/conform.nvim',
    event = 'VeryLazy',
    opts = {
      -- :h conform-formatters
      -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatters
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform will run multiple formatters sequentially
        python = { 'isort', 'black' },
        -- You can customize some of the format options for the filetype (:help conform.format)
        rust = { 'rustfmt' },
        -- Conform will run the first available formatter
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
      },
      -- formatters_by_ft = {
      --   lua = function(bufnr)
      --     return get_available_formatters('lua', bufnr, { 'stylua' })
      --   end,
      --   -- Conform will run multiple formatters sequentially
      --   go = function(bufnr)
      --     return get_available_formatters('go', bufnr, { 'goimports', 'golines', 'gofmt' })
      --   end,
      --   python = function(bufnr)
      --     return get_available_formatters('python', bufnr, { 'ruff' })
      --   end,
      --   -- You can customize some of the format options for the filetype (:help conform.format)
      --   rust = function(bufnr)
      --     return get_available_formatters('rust', bufnr, { 'rustfmt' })
      --   end,
      --   -- Conform will run the first available formatter
      --   javascript = function(bufnr)
      --     return get_available_formatters('node', bufnr, { 'prettierd', 'prettier' }, { stop_after_first = true })
      --   end,
      --   typescript = function(bufnr)
      --     return get_available_formatters('node', bufnr, { 'prettierd', 'prettier' }, { stop_after_first = true })
      --   end,
      -- },
      -- Set this to change the default values when calling conform.format()
      -- This will also affect the default values for format_on_save/format_after_save
      default_format_opts = {
        lsp_format = 'fallback', -- Configure if and when LSP should be used for formatting. Defaults to "never".
      },
      -- Create autocmd (on BufWritePre) to format on save automatically
      -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatopts-callback
      -- https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#autoformat-with-extra-features
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500, -- Time in milliseconds to block for formatting. Defaults to 1000. No effect if async = true.
      },
      -- Set the log level. Use `:ConformInfo` to see the location of the log file.
      log_level = vim.log.levels.ERROR,
      -- Conform will notify you when a formatter errors
      notify_on_error = true,
      -- Conform will notify you when no formatters are available for the buffer
      notify_no_formatters = true,
      -- Custom formatters and overrides for built-in formatters
      -- formatters = {
      --   -- All formatters can be customized
      --   -- https://github.com/stevearc/conform.nvim/blob/master/README.md#customizing-formatters
      --   --   yamlfix = {
      --   --     -- Change where to find the command
      --   --     command = "local/path/yamlfix",
      --   --     -- Adds environment args to the yamlfix formatter
      --   --     env = {
      --   --       YAMLFIX_SEQUENCE_STYLE = "block_style",
      --   --     },
      --   --   },

      --   -- Some formatters have a bit more advanced logic built in to those functions and expose additional configuration options
      --   -- https://github.com/stevearc/conform.nvim/blob/master/doc/formatter_options.md#prettier
      --   -- prettier = {
      --   --   options = {
      --   --     -- Use a specific prettier parser for a filetype
      --   --     -- Otherwise, prettier will try to infer the parser from the file name
      --   --     ft_parsers = {
      --   --       --     javascript = "babel",
      --   --       --     javascriptreact = "babel",
      --   --       --     typescript = "typescript",
      --   --       --     typescriptreact = "typescript",
      --   --       --     vue = "vue",
      --   --       --     css = "css",
      --   --       --     scss = "scss",
      --   --       --     less = "less",
      --   --       --     html = "html",
      --   --       --     json = "json",
      --   --       --     jsonc = "json",
      --   --       --     yaml = "yaml",
      --   --       --     markdown = "markdown",
      --   --       --     ["markdown.mdx"] = "mdx",
      --   --       --     graphql = "graphql",
      --   --       --     handlebars = "glimmer",
      --   --     },
      --   --     -- Use a specific prettier parser for a file extension
      --   --     ext_parsers = {
      --   --       -- qmd = "markdown",
      --   --     },
      --   --   }
      --   -- }
      -- },
    },
  },
}
