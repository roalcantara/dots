local opts = { noremap = true, silent = true }
local exprs = { noremap = true, silent = true, expr = true }
local function fzf(command)
  return ':FzfLua ' .. tostring(command)
end
local function cmd(command)
  return '<CMD>' .. tostring(command) .. '<CR>'
end
local function t(command)
  return '<CMD>TroubleToggle ' .. tostring(command) .. '<CR>'
end
local function b(command)
  return ':' .. tostring(command) .. '<bang>'
end
local function esc(command)
  return '<ESC>' .. tostring(command)
end
local function cr(command)
  return ':' .. tostring(command) .. '<CR>'
end
local function set(command)
  return 'set ' .. tostring(command) .. '<CR>'
end
local function cm(command)
  return '<C-m>' .. tostring(command)
end
local function cw(command)
  return '<C-w>' .. tostring(command)
end
local function bs(command)
  return tostring(command) .. '<BS>'
end
local function co(command)
  return tostring(command) .. '<C-O>'
end
local function ec(command)
  return co(tostring(esc(command)))
end
local function eb(command)
  return bs(tostring(esc(command)))
end

require('legendary').setup({
  include_builtin = true,
  include_legendary_cmds = true,
  select_prompt = '',
  formatter = nil,
  most_recent_item_at_top = true,
  default_opts = {
    keymaps = {
      noremap = true,
      silent = false,
    },
    commands = {},
    autocmds = {},
  },
  col_separator_char = '│',
  default_item_formatter = nil,
  commands = {
    {
      ':Q',
      b('q'),
      description = ' Quit',
    },
    {
      ':W',
      b('w'),
      description = ' Write',
    },
    {
      ':QA',
      b('qa'),
      description = ' Quit all',
    },
    {
      ':WA',
      b('wa'),
      description = ' Write all',
    },
    {
      ':WQ',
      b('wq'),
      description = ' Write and Quit',
    },
    {
      ':E',
      ':ene <BAR> startinsert <CR>',
      description = ' Edit (or create) `<file>` in new buffer',
    },
    {
      ':History',
      fzf('oldfiles'),
      description = ' Show Recent opened files',
    },
    {
      ':Maps',
      fzf('keymaps'),
      description = ' Show mappings',
    },
    {
      ':Commands',
      fzf('commands'),
      description = ' Show commands',
    },
    {
      ':GFiles',
      fzf('git_files'),
      description = ' Show git files',
    },
    {
      ':Commits',
      fzf('git_commits'),
      description = ' Show commits',
    },
    {
      ':Branches',
      fzf('git_branches'),
      description = ' Show git branches',
    },
    {
      ':Grep',
      fzf('live_grep'),
      description = ' Live Grep current project',
    },
    {
      ':FTypes',
      fzf('filetypes'),
      description = ' Show filetypes',
    },
    {
      ':Qfix',
      fzf('quickfix'),
      description = ' Show Quickfix List',
    },
    {
      ':Help',
      fzf('help_tags'),
      description = 'ﬤ Show Help',
    },
    {
      ':Buffers',
      fzf('buffers'),
      description = ' Show Buffers',
    },
    {
      ':Files',
      fzf('files'),
      description = ' Find file',
    },
    {
      ':Find',
      fzf('lgrep_curbuf'),
      description = ' Live grep current buffer',
    },
  },
  keymaps = {
    {
      'k',
      'v:count:= 0 ? \'gk\' : \'k\'',
      description = 'K dealing with word wrap',
      opts = exprs,
    },
    {
      'j',
      'v:count:= 0 ? \'gj\' : \'j\'',
      description = 'J dealing with word wrap',
      opts = exprs,
    },
    {
      '<A-.>',
      {
        n = cr('Maps'),
      },
      description = ' Show mappings',
    },
    {
      '<A-Down>',
      {
        n = cr('MoveDown'),
        i = ':MoveDown gi',
        v = ':m \'>+1<CR>gv=gv',
      },
      description = 'Selection down',
    },
    {
      '<A-Up>',
      {
        n = cr('MoveUp'),
        i = ':MoveUp gi',
        v = ':m \'<-2<CR>gv=gv',
      },
      description = 'Selection up (https://is.gd/lWJg)',
    },
    {
      '<D-_>',
      {
        n = cr('CommentToggle'),
        i = cr('CommentToggle'),
      },
      description = 'Toggle comment',
    },
    {
      '<A-S-l>',
      {
        n = cr('LspDebug'),
      },
      description = ' Set LSP log level to debug (http://t.ly/6TZd)',
    },
    {
      '<A-S-p>',
      {
        n = cr('Filepath'),
      },
      description = ' Reveal the current file path (http://t.ly/6TZd)',
    },
    {
      '<D-b>',
      {
        n = cr('Buffers'),
      },
      description = ' Show Buffers',
    },
    {
      '<D-Bslash>',
      {
        n = cr('NvimTreeToggle'),
      },
      description = ' Toggle NvimTree',
    },
    {
      '<D-C-c>',
      {
        n = cr('Commits'),
      },
      description = ' Show commits',
    },
    {
      '<D-C-f>',
      {
        n = cr('Funcs'),
      },
      description = ' List all functions and their arguments',
    },
    {
      '<D-C-p>',
      {
        n = cr('Root'),
      },
      description = 'Reveal the project root',
    },
    {
      '<D-C-Tab>',
      {
        n = cr('Tabs'),
      },
      description = ' Show tabs',
    },
    {
      '<D-ESC>',
      {
        n = cr('Q'),
      },
      description = 'Quit',
    },
    {
      '<D-f>',
      {
        n = cr('Find'),
      },
      description = ' Live grep current buffer',
    },
    {
      '<D-h>',
      {
        n = cr('History'),
      },
      description = ' Show Recent opened files',
    },
    {
      '<D-kComma>',
      {
        n = cr('Help'),
      },
      description = ' Show Help',
    },
    {
      '<D-l>',
      {
        n = cr('Locate'),
      },
      description = 'Locate all occurrences of `<f-args>`',
    },
    {
      '<D-n>',
      {
        n = cr('E'),
      },
      description = 'Edit (or create) `<file>` in new buffer',
    },
    {
      '<D-p>',
      {
        n = cr('Files'),
      },
      description = ' Show files',
    },
    {
      '<D-S-b>',
      {
        n = cr('Branches'),
      },
      description = ' Show git branches',
    },
    {
      '<D-S-C-r>',
      {
        n = cr('Autoload'),
      },
      description = 'Auto reload functions at ease',
    },
    {
      '<D-S-c>',
      {
        n = cr('Commands'),
      },
      description = ' Show commands',
    },
    {
      '<D-S-f>',
      {
        n = cr('Grep'),
      },
      description = ' Live Grep current project',
    },
    {
      '<D-S-p>',
      {
        n = cr('GFiles'),
      },
      description = ' Show git files',
    },
    {
      '<D-S-q>',
      {
        n = cr('Quickfix'),
      },
      description = ' Show Quickfix List',
    },
    {
      '<D-S-r>',
      {
        n = cr('Reload'),
      },
      description = ' Reload the current file',
    },
    {
      '<D-S-s>',
      {
        n = cr('WA'),
      },
      description = 'Write all',
    },
    {
      '<D-S-t>',
      {
        n = cr('FTypes'),
      },
      description = ' Show filetypes',
    },
    {
      '<D-s>',
      {
        n = cr('W'),
      },
      description = 'Write',
    },
    {
      '<leader>p',
      {
        n = cr('Maps'),
      },
      description = 'Legendary keymaps',
    },
    {
      '<D-a>',
      {
        n = co('ggVG'),
      },
      description = 'Select all',
    },
    {
      '<D-y>',
      {
        n = co('U'),
        i = ec('U'),
        v = ec('U'),
      },
      description = ' Redo',
    },
    {
      '<D-z>',
      {
        n = co('u'),
        i = ec('u'),
        v = ec('u'),
      },
      description = ' Undo',
    },
    {
      '<A-Left>',
      {
        n = bs('b'),
        i = eb('b'),
        v = eb('b'),
      },
      description = 'To after the previous word',
    },
    {
      '<D-C-v>',
      {
        n = cw('<C-v>'),
        i = esc(cw('<C-v>')),
      },
      description = ' Vertial split',
    },
    {
      '<A-Right>',
      {
        n = '2e',
        i = esc('2e'),
        v = esc('2e'),
      },
      description = 'To after the next word',
    },
    {
      '<D-Right>',
      {
        n = '$',
        i = esc('$'),
        v = esc('$'),
      },
      description = 'Go to the end of line',
    },
    {
      '<D-Left>',
      {
        n = '0',
        i = esc('0'),
        v = esc('0'),
      },
      description = 'Go to the start of line',
    },
    {
      '<S-ESC>',
      {
        n = ':cq!',
      },
      description = 'Quit without saving!',
    },
    {
      '<S-TAB>',
      {
        n = '<gv',
      },
      description = 'Shifting blocks backward (https://is.gd/eo3b)',
    },
    {
      '<TAB>',
      {
        n = '>gv',
      },
      description = 'Shifting blocks forward (https://is.gd/eo3b)',
    },
    {
      '<D-Down>',
      {
        n = '<C-End>',
      },
      description = 'Page Down',
    },
    {
      '<D-Up>',
      {
        n = '<C-Home>',
      },
      description = 'Page Up',
    },
    {
      '<leader>xx',
      {
        n = cmd('TroubleToggle'),
      },
      description = ' [T]: Toggle',
      opts = opts,
    },
    {
      'gR',
      {
        n = t('lsp_references'),
      },
      description = ' [T]: References:  Word under cursor',
      opts = opts,
    },
    {
      'gD',
      {
        n = t('lsp_definitions'),
      },
      description = ' [T]: Definitions:  Word under cursor',
      opts = opts,
    },
    {
      '<leader>xw',
      {
        n = t('workspace_diagnostics'),
      },
      description = ' [T]: Diagnostics:  Workspace',
      opts = opts,
    },
    {
      '<leader>xd',
      {
        n = t('document_diagnostics'),
      },
      description = ' [T]: Diagnostics:  Document',
      opts = opts,
    },
    {
      '<leader>xl',
      {
        n = t('loclist'),
      },
      description = ' [T]:  Loclist',
      opts = opts,
    },
    {
      '<leader>xq',
      {
        n = t('quickfix'),
      },
      description = ' [T]: 覆 Quickfix',
      opts = opts,
    },
    {
      '<Leader><TAB><TAB>',
      {
        n = ':set invlist<CR>',
      },
      description = 'Toggle list Mode Quickly',
    },
    {
      '<Left>',
      {
        c = '<Space><BS><Left>',
      },
      description = 'Move the cursor to Left',
    },
    {
      '<Right>',
      {
        c = '<Space><BS><Right>',
      },
      description = 'Move the cursor to Right',
    },
  },
  funcs = {},
  autocmds = {
    {
      name = 'YankHighlight',
      clear = true,
      {
        'TextYankPost',
        function()
          return vim.highlight.on_yank()
        end,
        description = 'Highlight on yank. See `:help vim.highlight.on_yank()`',
        pattern = '*',
      },
    },
  },
  itemgroups = {},
  which_key = {
    auto_register = true,
  },
  scratchpad = {
    view = 'float',
    results_view = 'float',
    float_border = 'rounded',
    keep_contents = true,
  },
  sort = {
    most_recent_first = true,
    user_items_first = true,
    item_type_bias = nil,
    frecency = {
      db_root = string.format('%s/legendary/', vim.fn.stdpath('data')),
      max_timestamps = 10,
    },
  },
  cache_path = string.format('%s/legendary/', vim.fn.stdpath('cache')),
  log_level = 'info',
})

require('which-key').register({
  f = {
    name = ' Files',
    f = {
      fzf('files'),
      ' Find file',
    },
    r = {
      fzf('oldfiles'),
      ' Open Recent File',
    },
    w = {
      fzf('live_grep'),
      ' Live Grep project',
    },
    g = {
      fzf('git_files'),
      ' Show git files',
    },
    t = {
      fzf('filetypes'),
      ' Show filetypes',
    },
    n = {
      ':ene <BAR> startinsert <CR>',
      ' New File',
    },
    s = {
      cmd(':w<bang>'),
      ' Save',
    },
    q = {
      cmd(':wq<bang>'),
      ' Write and Quit',
    },
    d = {
      cmd(':q<bang>'),
      ' Discart and Quit',
    },
  },
  g = {
    name = ' Git',
    f = {
      fzf('git_files'),
      ' Show git files',
    },
    c = {
      fzf('git_commits'),
      ' Show commits',
    },
    b = {
      fzf('git_branches'),
      ' Show git branches',
    },
  },
  s = {
    name = '都 System',
    m = {
      cmd('Maps'),
      ' Mappings',
    },
    b = {
      cmd('Buffers'),
      ' Buffers',
    },
    c = {
      cmd('Commands'),
      ' List Commands',
    },
    h = {
      cmd('checkhealth'),
      ' Check Health',
    },
    s = {
      cmd('Lazy sync'),
      ' Sync Plugins',
    },
    p = {
      cmd('Lazy show'),
      ' Show Plugins',
    },
    t = {
      cmd('Lazy profile'),
      ' Profile Plugins',
    },
  },
  l = {
    name = ' Language Servers',
    i = {
      cmd('LspInfo'),
      ' Info',
    },
    e = {
      cmd('LspStop'),
      'ﭦ End',
    },
    r = {
      cmd('LspStart'),
      '奈 Start',
    },
    a = {
      cmd('LspInstall'),
      '烙 Install',
    },
    u = {
      cmd('LspUninstall'),
      ' Uninstall',
    },
    l = {
      cmd('LspRestart'),
      '勒 Restart',
    },
  },
  c = {
    name = ' Coding',
    q = {
      cmd('stq'),
      '[stq] Swap quotes',
    },
    t = {
      cmd('zA'),
      '[zA] Toggle Folding',
    },
    f = {
      cmd('zC'),
      '[zC] Fold',
    },
    a = {
      cmd('zM'),
      '[zM] Fold All',
    },
    u = {
      cmd('za'),
      '[zO] Unfold',
    },
    c = {
      cmd('zR'),
      '[zR] Unfold All',
    },
  },
  p = {
    name = '  Windows',
    ['<A-k>'] = {
      '<C-w>k',
      ' Go ↑',
    },
    ['<A-j>'] = {
      '<C-w>j',
      ' Go ↓',
    },
    ['<A-l>'] = {
      '<C-w>l',
      ' Go →',
    },
    ['<A-h>'] = {
      '<C-w>h',
      ' Go ←',
    },
  },
  d = {
    name = ' Diagnostics',
    w = {
      t('workspace_diagnostics'),
      ' Workspace',
    },
    d = {
      t('document_diagnostics'),
      ' Document',
    },
    l = {
      t('loclist'),
      ' Loclist',
    },
    q = {
      t('quickfix'),
      '覆 Quickfix',
    },
    r = {
      t('lsp_references'),
      ' References',
    },
    n = {
      function()
        return vim.diagnostic.goto_next()
      end,
      ' Next',
    },
    p = {
      function()
        return vim.diagnostic.goto_prev()
      end,
      ' Previous',
    },
  },
}, {
  mode = 'n',
  prefix = '<leader>',
  silent = false,
  noremap = true,
})
