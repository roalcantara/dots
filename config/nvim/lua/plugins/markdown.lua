-- MARKDOWN RELATED PLUGINS AND CONFIGURATIONS
-- https://youtu.be/TrbZlA4UIFU
-- https://github.com/jakobwesthoff/nvim-from-scratch/tree/markdown-integration
return {
  -- {
  --   -- Modern browser with synchronised scrolling and flexible configuration
  --   -- https://github.com/iamcco/markdown-preview.nvim
  --   'iamcco/markdown-preview.nvim',
  --   -- https://github.com/folke/lazy.nvim/discussions/1713
  --   -- Loads this plugin and its configuration only when any of these commands are run:
  --   cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  --   -- Builds the plugin by installing the necessary dependencies
  --   build = function() vim.fn['mkdp#util#install']() end,
  --   ft = { 'markdown' },
  -- },
  {
    -- View Markdown, HTML (along with CSS, JavaScript), AsciiDoc, and SVG files
    -- in a web browser with live updates
    -- https://github.com/brianhuster/live-preview.nvim
    -- -----------------------------------------------------
    -- :LivePreview start               Start the live preview with hot reload.
    -- :LivePreview start  /path/to/md  Parse the passed file path.
    -- :LivePreview closes              Stop the live preview server.
    -- :LivePreview pick                Open a picker and select a file to preview
    -- :LivePreview help                See document about each subcommand
    -- :checkhealth livepreview         Run |checkhealth| for `live-preview.nvim`
    'brianhuster/live-preview.nvim',
    dependencies = {
      'ibhagwan/fzf-lua',
      'folke/snacks.nvim',
    },
  },
  {
    -- Improve viewing Markdown files
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    --- @module 'render-markdown'
    --- @type render.md.UserConfig
    opts = {
      render_modes = { 'n', 'c', 't' },
    },
  },
}
