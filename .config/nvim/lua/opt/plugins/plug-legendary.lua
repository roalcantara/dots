return _G.imports('legendary', function(plugin)
  local opts = {
    noremap = true,
    silent = true
  }
  local exprs = {
    noremap = true,
    silent = true,
    expr = true
  }
  local fzf
  fzf = function(command)
    return ":FzfLua " .. tostring(command)
  end
  local cmd
  cmd = function(command)
    return "<CMD>" .. tostring(command) .. "<CR>"
  end
  local t
  t = function(command)
    return "<CMD>TroubleToggle " .. tostring(command) .. "<CR>"
  end
  local b
  b = function(command)
    return ":" .. tostring(command) .. "<bang>"
  end
  local esc
  esc = function(command)
    return "<ESC>" .. tostring(command)
  end
  local cr
  cr = function(command)
    return ":" .. tostring(command) .. "<CR>"
  end
  local cm
  cm = function(command)
    return "<C-m>" .. tostring(command)
  end
  local cw
  cw = function(command)
    return "<C-w>" .. tostring(command)
  end
  local bs
  bs = function(command)
    return tostring(command) .. "<BS>"
  end
  local co
  co = function(command)
    return tostring(command) .. "<C-O>"
  end
  local ec
  ec = function(command)
    return co(tostring(esc(command)))
  end
  local eb
  eb = function(command)
    return bs(tostring(esc(command)))
  end
  return plugin.setup({
    include_builtin = true,
    include_legendary_cmds = true,
    select_prompt = '',
    formatter = nil,
    most_recent_item_at_top = true,
    default_opts = {
      keymaps = {
        noremap = true,
        silent = false
      },
      commands = { },
      autocmds = { }
    },
    col_separator_char = '│',
    default_item_formatter = nil,
    commands = {
      {
        ':Q',
        b('q'),
        description = ' Quit'
      },
      {
        ':W',
        b('w'),
        description = ' Write'
      },
      {
        ':QA',
        b('qa'),
        description = ' Quit all'
      },
      {
        ':WA',
        b('wa'),
        description = ' Write all'
      },
      {
        ':WQ',
        b('wq'),
        description = ' Write and Quit'
      },
      {
        ':E',
        ':DashboardNewFile',
        description = ' Edit (or create) `<file>` in new buffer'
      },
      {
        ':History',
        fzf('oldfiles'),
        description = ' Show Recent opened files'
      },
      {
        ':Maps',
        fzf('keymaps'),
        description = ' Show mappings'
      },
      {
        ':Commands',
        fzf('commands'),
        description = ' Show commands'
      },
      {
        ':GFiles',
        fzf('git_files'),
        description = ' Show git files'
      },
      {
        ':Commits',
        fzf('git_commits'),
        description = ' Show commits'
      },
      {
        ':Branches',
        fzf('git_branches'),
        description = ' Show git branches'
      },
      {
        ':Grep',
        fzf('live_grep'),
        description = ' Live Grep current project'
      },
      {
        ':FTypes',
        fzf('filetypes'),
        description = ' Show filetypes'
      },
      {
        ':Qfix',
        fzf('quickfix'),
        description = ' Show Quickfix List'
      },
      {
        ':Help',
        fzf('help_tags'),
        description = 'ﬤ Show Help'
      },
      {
        ':Buffers',
        fzf('buffers'),
        description = ' Show Buffers'
      },
      {
        ':Files',
        fzf('files'),
        description = ' Find file'
      },
      {
        ':Find',
        fzf('lgrep_curbuf'),
        description = ' Live grep current buffer'
      }
    },
    keymaps = {
      {
        'k',
        "v:count:= 0 ? 'gk' : 'k'",
        description = 'K dealing with word wrap',
        opts = exprs
      },
      {
        'j',
        "v:count:= 0 ? 'gj' : 'j'",
        description = 'J dealing with word wrap',
        opts = exprs
      },
      {
        '<A-.>',
        {
          n = cr('Maps')
        },
        description = ' Show mappings'
      },
      {
        '<A-Down>',
        {
          n = cr('MoveDown'),
          i = ':MoveDown gi',
          v = ':m \'>+1<CR>gv=gv'
        },
        description = 'Selection down'
      },
      {
        '<A-Up>',
        {
          n = cr('MoveUp'),
          i = ':MoveUp gi',
          v = ':m \'<-2<CR>gv=gv'
        },
        description = 'Selection up (https://is.gd/lWJg)'
      },
      {
        '<D-_>',
        {
          n = cr('CommentToggle'),
          i = cr('CommentToggle')
        },
        description = 'Toggle comment'
      },
      {
        '<A-S-l>',
        {
          n = cr('LspDebug')
        },
        description = ' Set LSP log level to debug (http://t.ly/6TZd)'
      },
      {
        '<A-S-p>',
        {
          n = cr('Filepath')
        },
        description = ' Reveal the current file path (http://t.ly/6TZd)'
      },
      {
        '<D-b>',
        {
          n = cr('Buffers')
        },
        description = ' Show Buffers'
      },
      {
        '<D-Bslash>',
        {
          n = cr('NvimTreeToggle')
        },
        description = ' Toggle NvimTree'
      },
      {
        '<D-C-c>',
        {
          n = cr('Commits')
        },
        description = ' Show commits'
      },
      {
        '<D-C-f>',
        {
          n = cr('Funcs')
        },
        description = ' List all functions and their arguments'
      },
      {
        '<D-C-p>',
        {
          n = cr('Root')
        },
        description = 'Reveal the project root'
      },
      {
        '<D-C-Tab>',
        {
          n = cr('Tabs')
        },
        description = ' Show tabs'
      },
      {
        '<D-ESC>',
        {
          n = cr('Q')
        },
        description = 'Quit'
      },
      {
        '<D-f>',
        {
          n = cr('Find')
        },
        description = ' Live grep current buffer'
      },
      {
        '<D-h>',
        {
          n = cr('History')
        },
        description = ' Show Recent opened files'
      },
      {
        '<D-kComma>',
        {
          n = cr('Help')
        },
        description = ' Show Help'
      },
      {
        '<D-l>',
        {
          n = cr('Locate')
        },
        description = 'Locate all occurrences of `<f-args>`'
      },
      {
        '<D-n>',
        {
          n = cr('E')
        },
        description = 'Edit (or create) `<file>` in new buffer'
      },
      {
        '<D-p>',
        {
          n = cr('Files')
        },
        description = ' Show files'
      },
      {
        '<D-S-b>',
        {
          n = cr('Branches')
        },
        description = ' Show git branches'
      },
      {
        '<D-S-C-r>',
        {
          n = cr('Autoload')
        },
        description = 'Auto reload functions at ease'
      },
      {
        '<D-S-c>',
        {
          n = cr('Commands')
        },
        description = ' Show commands'
      },
      {
        '<D-S-f>',
        {
          n = cr('Grep')
        },
        description = ' Live Grep current project'
      },
      {
        '<D-S-p>',
        {
          n = cr('GFiles')
        },
        description = ' Show git files'
      },
      {
        '<D-S-q>',
        {
          n = cr('Quickfix')
        },
        description = ' Show Quickfix List'
      },
      {
        '<D-S-r>',
        {
          n = cr('Reload')
        },
        description = ' Reload the current file'
      },
      {
        '<D-S-s>',
        {
          n = cr('WA')
        },
        description = 'Write all'
      },
      {
        '<D-S-t>',
        {
          n = cr('FTypes')
        },
        description = ' Show filetypes'
      },
      {
        '<D-s>',
        {
          n = cr('W')
        },
        description = 'Write'
      },
      {
        '<leader>p',
        {
          n = cr('Maps')
        },
        description = 'Legendary keymaps'
      },
      {
        '<D-a>',
        {
          n = co('ggVG')
        },
        description = 'Select all'
      },
      {
        '<D-y>',
        {
          n = co('U'),
          i = ec('U'),
          v = ec('U')
        },
        description = ' Redo'
      },
      {
        '<D-z>',
        {
          n = co('u'),
          i = ec('u'),
          v = ec('u')
        },
        description = ' Undo'
      },
      {
        '<A-Left>',
        {
          n = bs('b'),
          i = eb('b'),
          v = eb('b')
        },
        description = 'To after the previous word'
      },
      {
        '<Enter>',
        {
          n = cm(esc('0')),
          i = cm(esc('0'))
        },
        description = 'Go to the beginning of the next line'
      },
      {
        '<D-C-v>',
        {
          n = cw('<C-v>'),
          i = esc(cw('<C-v>'))
        },
        description = ' Vertial split'
      },
      {
        '<A-Right>',
        {
          n = '2e',
          i = esc('2e'),
          v = esc('2e')
        },
        description = 'To after the next word'
      },
      {
        '<D-Right>',
        {
          n = '$',
          i = esc('$'),
          v = esc('$')
        },
        description = 'Go to the end of line'
      },
      {
        '<D-Left>',
        {
          n = '0',
          i = esc('0'),
          v = esc('0')
        },
        description = 'Go to the start of line'
      },
      {
        '<S-ESC>',
        {
          n = ':cq!'
        },
        description = 'Quit without saving!'
      },
      {
        '<S-TAB>',
        {
          n = '<gv'
        },
        description = 'Shifting blocks backward (https://is.gd/eo3b)'
      },
      {
        '<TAB>',
        {
          n = '>gv'
        },
        description = 'Shifting blocks forward (https://is.gd/eo3b)'
      },
      {
        '<D-Down>',
        {
          n = '<C-End>'
        },
        description = 'Page Down'
      },
      {
        '<D-Up>',
        {
          n = '<C-Home>'
        },
        description = 'Page Up'
      },
      {
        '<leader>xx',
        {
          n = cmd('TroubleToggle')
        },
        description = ' [T]: Toggle',
        opts = opts
      },
      {
        'gR',
        {
          n = t('lsp_references')
        },
        description = ' [T]: References:  Word under cursor',
        opts = opts
      },
      {
        'gD',
        {
          n = t('lsp_definitions')
        },
        description = ' [T]: Definitions:  Word under cursor',
        opts = opts
      },
      {
        '<leader>xw',
        {
          n = t('workspace_diagnostics')
        },
        description = ' [T]: Diagnostics:  Workspace',
        opts = opts
      },
      {
        '<leader>xd',
        {
          n = t('document_diagnostics')
        },
        description = ' [T]: Diagnostics:  Document',
        opts = opts
      },
      {
        '<leader>xl',
        {
          n = t('loclist')
        },
        description = ' [T]:  Loclist',
        opts = opts
      },
      {
        '<leader>xq',
        {
          n = t('quickfix')
        },
        description = ' [T]: 覆 Quickfix',
        opts = opts
      }
    },
    funcs = { },
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
          pattern = '*'
        }
      }
    },
    itemgroups = { },
    which_key = {
      auto_register = true,
      mappings = { },
      opts = {
        mode = 'n',
        prefix = '<leader>'
      },
      do_binding = true
    },
    scratchpad = {
      view = 'float',
      results_view = 'float',
      float_border = 'rounded',
      keep_contents = true
    },
    sort = {
      most_recent_first = true,
      user_items_first = true,
      item_type_bias = nil,
      frecency = {
        db_root = string.format('%s/legendary/', vim.fn.stdpath('data')),
        max_timestamps = 10
      }
    },
    cache_path = string.format('%s/legendary/', vim.fn.stdpath('cache')),
    log_level = 'info'
  })
end)
