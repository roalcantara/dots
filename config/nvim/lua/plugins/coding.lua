local neo = require('core/neo')

return {
  -- Fzf-Lua | Improved fzf.vim written in lua
  -- https://github.com/ibhagwan/fzf-lua | https://lazyvim.org/extras/editor/fzf
  {
    'ibhagwan/fzf-lua',
    event = 'VeryLazy',
    cmd = 'FzfLua',
    dependencies = { 'echasnovski/mini.icons' },
  },

  -- Mini Pairs | Autopair
  -- Auto pairs Automatically inserts a matching closing character when you type an opening character like ", [, or (.
  -- https://github.com/nvim-mini/mini.pairs | https://lazyvim.org/plugins/coding#minipairs
  {
    'nvim-mini/mini.pairs',
    event = 'VeryLazy',
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { 'string' },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
    config = neo.mini.pairs,
  },

  -- TS Comments | Comments for Treesitter
  -- Improves comment syntax, lets Neovim handle multiple types of comments for a single language, and relaxes rules for uncommenting.
  -- https://github.com/folke/ts-comments.nvim | https://www.lazyvim.org/plugins/coding#ts-commentsnvim
  {
    'folke/ts-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- Visual Multi | Multiple cursors
  -- https://github.com/mg979/vim-visual-multi
  {
    'mg979/vim-visual-multi',
    event = 'VeryLazy',
    init = function()
      -- Disable the default keymaps
      -- https://github.com/mg979/vim-visual-multi/issues/241
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        -- ['Visual All'] = '<D-C-g>',
        ['Find Under'] = '<D-C-g>',
        ['Find Subword Under'] = '<D-C-g>',
        ['Add Cursor Down'] = '<D-M-Down>',
        ['Add Cursor Up'] = '<A-D-Up>',
        ['Skip Region'] = '<D-k>',
        ['Remove Region'] = '<D-x>',
      }
      -- https://github.com/mg979/vim-visual-multi/wiki/Highlight-colors#selecting-a-theme
      vim.g.VM_theme = 'purplegray'
      vim.g.VM_highlight_matches = 'hi! Search ctermfg=228 cterm=underline'
      vim.g.VM_highlight_matches = 'hi! link Search PmenuSel'
      vim.g.VM_add_cursor_at_pos_no_mappings = 1
    end,
  },

  -- Automatically validate your Ghostty configuration on save
  -- https://github.com/isak102/ghostty.nvim
  {
    'isak102/ghostty.nvim',
    ft = 'ghostty',
    cond = vim.fn.executable('ghostty') == 1,
    opts = {
      -- The autocmd pattern matched against the filename of the buffer. If this pattern
      -- matches, ghostty.nvim will run on save in that buffer. This pattern is passed to
      -- nvim_create_autocmd, check ":h autocmd-pattern" for more information. Can be
      -- either a string or a list of strings
      file_pattern = neo.paths.xdg.config.path_for('ghostty', 'config'),
      -- The ghostty executable to run.
      ghostty_cmd = 'ghostty',
      -- The timeout in milliseconds for the check command.
      -- If the command takes longer than this it will be killed.
      check_timeout = 1000,
    },
  },
}
