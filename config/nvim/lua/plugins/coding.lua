return {
  -- Yanky | Yank history
  -- https://lazyvim.org/extras/coding/yanky#yankynvim-1
  {
    'gbprod/yanky.nvim',
    lazy = true,
    event = 'VeryLazy',
    keys = {
      -- stylua: ignore
      { "y",         "<Plug>(YankyYank)",      mode = { "n", "x" }, desc = "Yank Text" },
      { 'p',         '<Plug>(YankyPutAfter)',  mode = { 'n', 'x' }, desc = 'Put Text After Cursor' },
      { 'P',         '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put Text Before Cursor' },
      -- disable the default keymaps
      { '<leader>p', mode = { 'n', 'x' },      false },
      { 'gp',        mode = { 'n', 'x' },      false },
      { 'gP',        mode = { 'n', 'x' },      false },
      { '[y',        mode = { 'n', 'x' },      false },
      { ']y',        mode = { 'n', 'x' },      false },
      { ']p',        mode = { 'n', 'x' },      false },
      { '[p',        mode = { 'n', 'x' },      false },
      { ']P',        mode = { 'n', 'x' },      false },
      { '[P',        mode = { 'n', 'x' },      false },
      { '>p',        mode = { 'n', 'x' },      false },
      { '<p',        mode = { 'n', 'x' },      false },
      { '>P',        mode = { 'n', 'x' },      false },
      { '<P',        mode = { 'n', 'x' },      false },
      { '=p',        mode = { 'n', 'x' },      false },
      { '=P',        mode = { 'n', 'x' },      false },
    },
  },

  -- WhichKey | A popup that displays available keybindings in Neovim
  -- https://github.com/folke/which-key.nvim
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    keys = {
      -- disable the default keymaps
      { '<leader><tab>', mode = { 'n', 'v' }, false },
      { '<leader>d',     mode = { 'n', 'v' }, false },
      { '<leader>dp',    mode = { 'n', 'v' }, false },
      { '<leader>f',     mode = { 'n', 'v' }, false },
      { '<leader>g',     mode = { 'n', 'v' }, false },
      { '<leader>gh',    mode = { 'n', 'v' }, false },
      { '<leader>q',     mode = { 'n', 'v' }, false },
      { '<leader>s',     mode = { 'n', 'v' }, false },
      { '<leader>u',     mode = { 'n', 'v' }, false },
      { '<leader>x',     mode = { 'n', 'v' }, false },
      { '<leader>b',     mode = { 'n', 'v' }, false },
      { '<leader>w',     mode = { 'n', 'v' }, false },
      { '<c-w><space>',  mode = { 'n', 'v' }, false },
      { '<leader>?',     mode = { 'n', 'v' }, false },
      { 'gx',            mode = { 'n', 'v' }, false },
      { '[',             mode = { 'n', 'v' }, false },
      { ']',             mode = { 'n', 'v' }, false },
      { 'g',             mode = { 'n', 'v' }, false },
      { 'gs',            mode = { 'n', 'v' }, false },
      { 'z',             mode = { 'n', 'v' }, false },
    },
  },

  -- Enhance Neovim's native commentstring as a fallbacks,
  -- so there's no need to configure every language
  -- https://github.com/folke/ts-comments.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },

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
