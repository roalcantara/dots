-- https://github.com/mrjones2014/legendary.nvim
-- A legend for your keymaps, commands, and autocmds, with which-key.nvim integration
require('neo/lib/functions/imports') 'legendary', (plugin) ->
  opts = { noremap: true, silent: true }
  exprs = { noremap: true, silent: true, expr: true }
  fzf = (command)-> ":FzfLua #{command}"
  cmd = (command)-> "<CMD>#{command}<CR>"
  finder = (command)-> cmd("lua require('neo/etc/commands/finder').find_${command}()")
  t = (command)-> cmd("TroubleToggle #{command}")
  l = (command)-> ":Legendary #{command}"
  b = (command)-> ":#{command}<bang>"
  e = (command)-> "<ESC>#{command}"
  cr = (command)-> ":#{command}<CR>"
  cm = (command)-> "<C-m>#{command}"
  cw = (command)-> "<C-w>#{command}"
  bs = (command)-> "#{command}<BS>"
  co = (command)-> "#{command}<C-O>"
  ec = (command)-> co("#{e(command)}")
  eb = (command)-> bs("#{e(command)}")

  plugin.setup({
    -- Include builtins by default, set to false to disable
    include_builtin: true,
    -- Include the commands that legendary.nvim creates itself
    -- in the legend by default, set to false to disable
    include_legendary_cmds: true,
    -- Customize the prompt that appears on your vim.ui.select() handler
    -- Can be a string or a  that-> takes the `kind` and returns
    -- a string. See "Item Kinds" below for details. By default,
    -- prompt is 'Legendary' when searching all items,
    -- 'Legendary Keymaps' when searching keymaps,
    -- 'Legendary Commands' when searching commands,
    -- and 'Legendary Autocmds' when searching autocmds.
    select_prompt: '',
    -- Optionally pass a custom formatter .-> This
    ---> receives the item as a parameter and must return a table of
    -- non-nil string values for display. It must return the same
    -- number of values for each item to work correctly.
    -- The values will be used as column values when formatted.
    -- See  `get_default_format_values->(item)` in
    -- `lua/legendary/formatter.lua` to see default implementation.
    formatter: nil,
    -- When you trigger an item via legendary.nvim,
    -- show it at the top next time you use legendary.nvim
    most_recent_item_at_top: true,
    -- default opts to merge with the `opts` table
    -- of each individual item
    default_opts: {
      keymaps: { noremap: true, silent: false },
      commands: {},
      autocmds: {},
    },
    -- Character to use to separate columns in the UI
    col_separator_char: '│',
    -- Optionally pass a custom formatter function. This function
    -- receives the item as a parameter and the mode that legendary
    -- was triggered from (e.g. `function(item, mode): string[]`)
    -- and must return a table of non-nil string values for display.
    -- It must return the same number of values for each item to work correctly.
    -- The values will be used as column values when formatted.
    -- See function `default_format(item)` in `lua/legendary/ui/format.lua` to see default implementation.
    default_item_formatter: nil,
    -- Initial commands to bind
    commands: {
      -- easily create user commands
      { ':Q',         b('q'),               description: ' Quit' },
      { ':W',         b('w'),               description: ' Write' },
      { ':QA',        b('qa'),              description: ' Quit all' },
      { ':WA',        b('wa'),              description: ' Write all' },
      { ':WQ',        b('wq'),              description: ' Write and Quit' },
      { ':E',         ':DashboardNewFile',  description: ' Edit (or create) `<file>` in new buffer' },
      { ':History',   fzf('oldfiles'),      description: ' Show Recent opened files' },
      { ':Maps',      l('keymaps'),         description: ' Show mappings' },
      { ':Commands',  l('commands'),        description: ' Show commands' },
      { ':GFiles',    fzf('git_files'),     description: ' Show git files' },
      { ':Commits',   fzf('git_commits'),   description: ' Show commits' },
      { ':Branches',  fzf('git_branches'),  description: ' Show git branches' },
      { ':Grep',      fzf('live_grep'),     description: ' Live Grep current project' },
      { ':FTypes',    fzf('filetypes'),     description: ' Show filetypes' },
      { ':Qfix',      fzf('quickfix'),      description: ' Show Quickfix List' },
      { ':Help',      fzf('help_tags'),     description: 'ﬤ Show Help' },
      { ':Buffers',   fzf('buffers'),       description: ' Show Buffers' },
      { ':Files',     finder('files'),      description: ' Find file' },
      { ':Find',      fzf('lgrep_curbuf'),  description: ' Live grep current buffer' },
    },
    -- Initial keymaps to bind
    keymaps: {
      -- map keys to a command
      --
      -- map keys to a
      ---> { '<leader>h', ()-> print('hello world!') end, description = 'Say hello' },
      -- keymaps have opts.silent = true by default, but you can override it
      -- { '<leader>s', ':SomeCommand<CR>', description = 'Non-silent keymap', opts = { silent = false } },
      -- create keymaps with different implementations per-mode
      -- { '<leader>c', { n = ':LinewiseCommentToggle<CR>', x = ':'<,'>BlockwiseCommentToggle<CR>' },
      --   description = 'Toggle comment', },
      -- create item groups to create sub-menus in the finder
      -- note that only keymaps, commands, and s->
      -- can be added to item groups
      -- {
      --   -- groups with same itemgroup will be merged
      --   itemgroup = 'short ID',
      --   description = 'A submenu of items...',
      --   icon = '',
      --   keymaps = {
      --     -- more keymaps here
      --   },
      -- }
      -- { '<leader>ff', ':Telescope find_files', description: 'Find files' },
      { 'k', "v:count:= 0 ? 'gk' : 'k'",                                                            description: 'K dealing with word wrap', opts: exprs },
      { 'j', "v:count:= 0 ? 'gj' : 'j'",                                                            description: 'J dealing with word wrap', opts: exprs },
      { '<A-.>',      { n: cr('Maps')                                                            }, description: ' Show mappings' },
      { '<A-Down>',   { n: cr('MoveDown'),        i: ':MoveDown gi',     v: ':m \'>+1<CR>gv=gv'  }, description: 'Selection down' },
      { '<A-Up>',     { n: cr('MoveUp'),          i: ':MoveUp gi',       v: ':m \'<-2<CR>gv=gv'  }, description: 'Selection up (https://is.gd/lWJg)' },
      { '<D-_>',      { n: cr('CommentToggle'),   i: cr('CommentToggle')                         }, description: 'Toggle comment' },
      { '<A-S-l>',    { n: cr('LspDebug')                                                        }, description: ' Set LSP log level to debug (http://t.ly/6TZd)' },
      { '<A-S-p>',    { n: cr('Filepath')                                                        }, description: ' Reveal the current file path (http://t.ly/6TZd)' },
      { '<D-b>',      { n: cr('Buffers')                                                         }, description: ' Show Buffers' },
      { '<D-Bslash>', { n: cr('NvimTreeToggle')                                                  }, description: ' Toggle NvimTree' },
      { '<D-C-c>',    { n: cr('Commits')                                                         }, description: ' Show commits' },
      { '<D-C-f>',    { n: cr('Funcs')                                                           }, description: ' List all functions and their arguments' },
      { '<D-C-p>',    { n: cr('Root')                                                            }, description: 'Reveal the project root' },
      { '<D-C-Tab>',  { n: cr('Tabs')                                                            }, description: ' Show tabs' },
      { '<D-ESC>',    { n: cr('Q')                                                               }, description: 'Quit' },
      { '<D-f>',      { n: cr('Find')                                                            }, description: ' Live grep current buffer' },
      { '<D-h>',      { n: cr('History')                                                         }, description: ' Show Recent opened files' },
      { '<D-kComma>', { n: cr('Help')                                                            }, description: ' Show Help' },
      { '<D-l>',      { n: cr('Locate')                                                          }, description: 'Locate all occurrences of `<f-args>`' },
      { '<D-n>',      { n: cr('E')                                                               }, description: 'Edit (or create) `<file>` in new buffer' },
      { '<D-p>',      { n: cr('Files')                                                           }, description: ' Show files' },
      { '<D-S-b>',    { n: cr('Branches')                                                        }, description: ' Show git branches' },
      { '<D-S-C-r>',  { n: cr('Autoload')                                                        }, description: 'Auto reload functions at ease' },
      { '<D-S-c>',    { n: cr('Commands')                                                        }, description: ' Show commands' },
      { '<D-S-f>',    { n: cr('Grep')                                                            }, description: ' Live Grep current project' },
      { '<D-S-p>',    { n: cr('GFiles')                                                          }, description: ' Show git files' },
      { '<D-S-q>',    { n: cr('Quickfix')                                                        }, description: ' Show Quickfix List' },
      { '<D-S-r>',    { n: cr('Reload')                                                          }, description: ' Reload the current file' },
      { '<D-S-s>',    { n: cr('WA')                                                              }, description: 'Write all' },
      { '<D-S-t>',    { n: cr('FTypes')                                                          }, description: ' Show filetypes' },
      { '<D-s>',      { n: cr('W')                                                               }, description: 'Write' },
      { '<leader>p',  { n: cr('Maps')                                                            }, description: 'Legendary keymaps' },
      { '<D-a>',      { n: co('ggVG')                                                            }, description: 'Select all' },
      { '<D-y>',      { n: co('U'),               i: ec('U'),            v: ec('U')              }, description: ' Redo' },
      { '<D-z>',      { n: co('u'),               i: ec('u'),            v: ec('u')              }, description: ' Undo' },
      { '<A-Left>',   { n: bs('b'),               i: eb('b'),            v: eb('b')              }, description: 'To after the previous word' },
      { '<Enter>',    { n: cm(e('0')),            i: cm(e('0'))                                  }, description: 'Go to the beginning of the next line' },
      { '<D-C-v>',    { n: cw('<C-v>'),           i: e(cw('<C-v>'))                              }, description: ' Vertial split' },
      { '<A-Right>',  { n: '2e',                  i: e('2e'),            v: e('2e')              }, description: 'To after the next word' },
      { '<D-Right>',  { n: '$',                   i: e('$'),             v: e('$')               }, description: 'Go to the end of line' },
      { '<D-Left>',   { n: '0',                   i: e('0'),             v: e('0')               }, description: 'Go to the start of line' },
      { '<S-ESC>',    { n: ':cq!'                                                                }, description: 'Quit without saving!' },
      { '<S-TAB>',    { n: '<gv'                                                                 }, description: 'Shifting blocks backward (https://is.gd/eo3b)' },
      { '<TAB>',      { n: '>gv'                                                                 }, description: 'Shifting blocks forward (https://is.gd/eo3b)' }
      { '<D-Down>',   { n: '<C-End>'                                                             }, description: 'Page Down' },
      { '<D-Up>',     { n: '<C-Home>'                                                            }, description: 'Page Up' },
      { '<leader>xx', { n: cmd('TroubleToggle')                                                  }, description: ' [T]: Toggle', opts: opts },
      { 'gR',         { n: t('lsp_references')                                                   }, description: ' [T]: References:  Word under cursor', opts: opts }
      { 'gD',         { n: t('lsp_definitions')                                                  }, description: ' [T]: Definitions:  Word under cursor', opts: opts }
      { '<leader>xw', { n: t('workspace_diagnostics')                                            }, description: ' [T]: Diagnostics:  Workspace', opts: opts },
      { '<leader>xd', { n: t('document_diagnostics')                                             }, description: ' [T]: Diagnostics:  Document', opts: opts },
      { '<leader>xl', { n: t('loclist')                                                          }, description: ' [T]:  Loclist', opts: opts },
      { '<leader>xq', { n: t('quickfix')                                                         }, description: ' [T]: 覆 Quickfix', opts: opts },
    },
    -- Initial functions to bind
    funcs: {
      -- Make arbitrary Lua s-> that can be executed via the item finder
      -- {
      --   ()->
      --     doSomeStuff()
      --   end,
      --   description = 'Do some stuff with a Lua !',->
      -- },
      -- {
      --   -- groups with same itemgroup will be merged
      --   itemgroup = 'short ID',
      --   -- don't need to copy the other group data because
      --   -- it will be merged with the one from the keymaps table
      --   funcs = {
      --     -- more funcs here
      --   },
      -- },
    },
    -- Initial augroups/autocmds to bind
    autocmds: {
      -- Create autocmds and augroups
      -- { 'BufWritePre', vim.lsp.buf.format, description = 'Format on save' },
      -- {
      --   name = 'MyAugroup',
      --   clear = true,
      --   -- autocmds here
      -- },
      { name: 'YankHighlight', clear: true,
        { 'TextYankPost', () -> vim.highlight.on_yank!,
          description: 'Highlight on yank. See `:help vim.highlight.on_yank()`',
          pattern: '*'
        }
      }
    },
    -- Initial item groups to bind,
    -- note that item groups can also
    -- be under keymaps, commands, autocmds, or funcs
    itemgroups: {},
    which_key: {
      -- Automatically add which-key tables to legendary
      -- see ./doc/WHICH_KEY.md for more details
      auto_register: true,
      -- you can put which-key.nvim tables here,
      -- or alternatively have them auto-register,
      -- see ./doc/WHICH_KEY.md
      mappings: {},
      opts: { mode: 'n', prefix: '<leader>' },
      -- controls whether legendary.nvim actually binds they keymaps,
      -- or if you want to let which-key.nvim handle the bindings.
      -- if not passed, true by default
      do_binding: true
    },
    scratchpad: {
      -- How to open the scratchpad buffer
      view: 'float', -- 'current' => current window, 'float' => floating window
      -- How to show the results of evaluated Lua code
      results_view: 'float', -- 'print' => `print(result)`, 'float' => floating window
      -- Border style for floating windows related to the scratchpad
      float_border: 'rounded',
      -- Whether to restore scratchpad contents from a cache file
      keep_contents: true
    },
    -- Options for list sorting. Note that fuzzy-finders will still
    -- do their own sorting. For telescope.nvim, you can set it to use
    -- `require('telescope.sorters').fuzzy_with_index_bias({})` when
    -- triggered via `legendary.nvim`. Example config for `dressing.nvim`:
    --
    -- require('dressing').setup({
    --  select = {
    --    get_config = function(opts)
    --      if opts.kind == 'legendary.nvim' then
    --        return {
    --          telescope = {
    --            sorter = require('telescope.sorters').fuzzy_with_index_bias({})
    --          }
    --        }
    --      else
    --        return {}
    --      end
    --    end
    --  }
    -- })
    sort: {
      -- sort most recently used item to the top
      most_recent_first: true,
      -- sort user-defined items before built-in items
      user_items_first: true,
      -- sort the specified item type before other item types,
      -- value must be one of: 'keymap', 'command', 'autocmd', 'group', nil
      item_type_bias: nil,
      -- settings for frecency sorting.
      -- https://en.wikipedia.org/wiki/Frecency
      -- Set `frecency = false` to disable.
      -- this feature requires sqlite.lua (https://github.com/tami5/sqlite.lua)
      -- and will be automatically disabled if sqlite is not available.
      -- NOTE: THIS TAKES PRECEDENCE OVER OTHER SORT OPTIONS!
      frecency: {
        -- the directory to store the database in
        db_root: string.format('%s/legendary/', vim.fn.stdpath('data')),
        -- the maximum number of timestamps for a single item
        -- to store in the database
        max_timestamps: 10,
      },
    },
    -- Directory used for caches
    cache_path: string.format('%s/legendary/', vim.fn.stdpath('cache')),
    -- Log level
    log_level: 'info' -- 'trace', 'debug', 'info', 'warn', 'error', 'fatal'
  })
