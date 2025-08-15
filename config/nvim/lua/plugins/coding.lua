return {
  -- Fzf-Lua | Improved fzf.vim written in lua
  -- https://github.com/ibhagwan/fzf-lua | https://lazyvim.org/extras/editor/fzf
  {
    'ibhagwan/fzf-lua',
    event = 'VeryLazy',
    cmd = 'FzfLua',
    dependencies = { 'echasnovski/mini.icons' },
  },

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
        ['Add Cursor Down'] = '<A-D-Down>',
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
      file_pattern = require('core/vi/paths').xdg_config_home('ghostty', 'config'),
      -- The ghostty executable to run.
      ghostty_cmd = 'ghostty',
      -- The timeout in milliseconds for the check command.
      -- If the command takes longer than this it will be killed.
      check_timeout = 1000,
    },
  },
}
