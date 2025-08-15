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
        go = { 'goimports', 'golines', 'gofmt' },
        -- Conform will run multiple formatters sequentially
        python = { 'isort', 'black' },
        -- You can customize some of the format options for the filetype (:help conform.format)
        rust = { 'rustfmt' },
        -- Conform will run the first available formatter
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
      },
      -- Create autocmd (on BufWritePre) to format on save automatically
      -- https://github.com/stevearc/conform.nvim?tab=readme-ov-file#formatopts-callback
      -- https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#autoformat-with-extra-features
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,        -- Time in milliseconds to block for formatting. Defaults to 1000. No effect if async = true.
        lsp_format = 'fallback', -- Configure if and when LSP should be used for formatting. Defaults to "never".
      },
      formatters = {
        -- All formatters can be customized
        -- https://github.com/stevearc/conform.nvim/blob/master/README.md#customizing-formatters
        --   yamlfix = {
        --     -- Change where to find the command
        --     command = "local/path/yamlfix",
        --     -- Adds environment args to the yamlfix formatter
        --     env = {
        --       YAMLFIX_SEQUENCE_STYLE = "block_style",
        --     },
        --   },

        -- Some formatters have a bit more advanced logic built in to those functions and expose additional configuration options
        -- https://github.com/stevearc/conform.nvim/blob/master/doc/formatter_options.md#prettier
        -- prettier = {
        --   options = {
        --     -- Use a specific prettier parser for a filetype
        --     -- Otherwise, prettier will try to infer the parser from the file name
        --     ft_parsers = {
        --       --     javascript = "babel",
        --       --     javascriptreact = "babel",
        --       --     typescript = "typescript",
        --       --     typescriptreact = "typescript",
        --       --     vue = "vue",
        --       --     css = "css",
        --       --     scss = "scss",
        --       --     less = "less",
        --       --     html = "html",
        --       --     json = "json",
        --       --     jsonc = "json",
        --       --     yaml = "yaml",
        --       --     markdown = "markdown",
        --       --     ["markdown.mdx"] = "mdx",
        --       --     graphql = "graphql",
        --       --     handlebars = "glimmer",
        --     },
        --     -- Use a specific prettier parser for a file extension
        --     ext_parsers = {
        --       -- qmd = "markdown",
        --     },
        --   }
        -- }
      },
    }
  },
}
