return {
  -- Fzf-Lua | Improved fzf.vim written in lua
  -- https://github.com/ibhagwan/fzf-lua | https://lazyvim.org/extras/editor/fzf
  {
    'ibhagwan/fzf-lua',
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
}
