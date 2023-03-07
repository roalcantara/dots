-- Create key bindings that stick.
-- https://github.com/folke/which-key.nvim
_G.imports 'which-key', (wk) ->
  c = (command)-> "<CMD> #{command} <CR>"
  f = (command)-> c("FzfLua #{command}")
  t = (command)-> c("TroubleToggle #{command}")
  mappings = {
    --   f: {
    --     name: 'file', -- optional group name
    --     f: { '<cmd>FzfLua files<cr>', 'Find File' }, -- create a binding with label
    --     r: { '<cmd>Telescope oldfiles<cr>', 'Open Recent File', noremap=false, buffer: 123 }, -- additional options for creating the keymap
    --     n: { 'New File' }, -- just a label. don't create any mapping
    --     e: 'Edit File', -- same as above
    --     ['1']: 'which_key_ignore',  -- special label to hide it in the popup
    --     b: { ()-> print('bar') end, 'Foobar' } -- you can also pass functions!
    --   },
    f: {
      name: ' Files',
      f: { f('files'),                ' Find file'          },
      r: { f('oldfiles'),             ' Open Recent File'   },
      w: { f('live_grep'),            ' Live Grep project'  },
      g: { f('git_files'),            ' Show git files'     },
      t: { f('filetypes'),            ' Show filetypes'     },
      n: { c('DashboardNewFile'),     ' New File'           },
      s: { c(':w<bang>'),             ' Save'               },
      q: { c(':wq<bang>'),            ' Write and Quit'     },
      d: { c(':q<bang>'),             ' Discart and Quit'   }
    },
    g: {
      name: ' Git',
      f: { f('git_files'),            ' Show git files'      },
      c: { f('git_commits'),          ' Show commits'        },
      b: { f('git_branches'),         ' Show git branches'   }
    },
    s: {
      name: '都 System',
      m: { c('Maps'),                 ' Mappings'            },
      b: { c('Buffers'),              ' Buffers'             },
      l: { c('Commands'),             ' List Commands'       },
      h: { c('checkhealth'),          ' Check Health'        },
      s: { c('PackerSync'),           ' Sync'                },
      t: { c('PackerStatus'),         ' Status'              },
      c: { c('PackerCompile'),        ' Compile'             }
    },
    l: {
      name: ' Language Servers',
      i: { c('LspInfo'),              ' Info'                },
      e: { c('LspStop'),              'ﭦ End'                 },
      r: { c('LspStart'),             '奈 Start'              },
      a: { c('LspInstall'),           '烙 Install'            },
      u: { c('LspUninstall'),         ' Uninstall'           },
      l: { c('LspRestart'),           '勒 Restart'            }
    },
    c: {
      name: ' Coding',
      q: { c('stq'),                  '[stq] Swap quotes'     },
      t: { c('zA'),                   '[zA] Toggle Folding'   },
      f: { c('zC'),                   '[zC] Fold'             },
      a: { c('zM'),                   '[zM] Fold All'         },
      u: { c('za'),                   '[zO] Unfold'           },
      c: { c('zR'),                   '[zR] Unfold All'       }
    },
    p: {
      name: '  Windows',
      ['<A-k>']: { '<C-w>k',          ' Go ↑'                },
      ['<A-j>']: { '<C-w>j',          ' Go ↓'                },
      ['<A-l>']: { '<C-w>l',          ' Go →'                },
      ['<A-h>']: { '<C-w>h',          ' Go ←'                }
    },
    d: {
      name: ' Diagnostics',
      w: { t('workspace_diagnostics'),          ' Workspace'  },
      d: { t('document_diagnostics'),           ' Document'   },
      l: { t('loclist'),                        ' Loclist'    },
      q: { t('quickfix'),                       '覆 Quickfix'   },
      r: { t('lsp_references'),                 ' References' },
      n: {
          ()->
            vim.diagnostic.goto_next!,
          ' Next'
      },
      p: {
          ()->
            vim.diagnostic.goto_prev!,
          ' Previous'
      }
    }
  }
  opts = {
    mode: 'n', -- NORMAL mode
    -- prefix: use "<leader>f" for example for mapping everything related to finding files
    -- the prefix is prepended to every mapping part of `mappings`
    prefix: '<leader>',
    silent: false, -- use `silent` when creating keymaps
    noremap: true -- use `noremap` when creating keymaps
    -- buffer: nil, -- Global mappings. Specify a buffer number for buffer local mappings
    -- nowait: false -- use `nowait` when creating keymaps
  }

  wk.setup({
    triggers: 'auto', -- automatically setup triggers
    plugins: {
      marks: true, -- shows a list of your marks on ' and `
      registers: true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      spelling: {
        enabled: false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions: 20 -- how many suggestions should be shown in the list?
      },
      presets: {
        text_objects: true, -- help for text objects triggered after entering an operator
        operators: true, -- adds help for operators like d, y, ... & registers them for motion / text object comp
        windows: true, -- default bindings on <c-w>
        motions: true, -- adds help for motions
        nav: true, -- misc bindings to work with windows
        z: true, -- bindings for folds, spelling and others prefixed with z
        g: true -- bindings for prefixed with g
      }
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    operators: { gc: 'Comments' },
    key_labels: {['<space>']: 'Spc'},
    icons: {
      breadcrumb: '»', -- symbol used in the command line area that shows your active key combo
      separator: '➜', -- symbol used between a key and it's label
      group: '+' -- symbol used to group commands
    },
    popup_mappings: {
      scroll_down: '<c-d>', -- binding to scroll down inside the popup
      scroll_up: '<c-u>', -- binding to scroll up inside the popup
    },
    window: {
      border: 'none', -- border around the window (none, single, double, shadow)
      position: 'bottom', -- position of the window (top, bottom)
      margin: {0, 0, 1, 0}, -- extra margin around the window (top, right, bottom, left)
      padding: {2, 2, 2, 2}, -- extra padding around the command line (top, right, bottom, left)
      winblend: 0
    },
    layout: {
      height: {min: 4, max: 25}, -- min and max height of the columns
      width: {min: 20, max: 50}, -- min and max width of the columns
      spacing: 8, -- spacing between columns
      align: 'left' -- align columns left, center or right
    },
    ignore_missing: false, -- enable this to hide mappings for which you didn't specify a label
    hidden: {'<silent>', '<cmd>', '<Cmd>', '<CR>', 'call', 'lua', '^:', '^ '},
    show_help: true, -- show help message on the command line when the popup is visible
    show_keys: true, -- show the currently pressed key and its label as a message in the command line
    triggers_blacklist: {i: {'j', 'k'}, v: {'j', 'k'}}
    -- disable the WhichKey popup for certain buf types and file types.
    -- Disabled by deafult for Telescope
    disable: {
      buftypes: {},
      filetypes: { 'TelescopePrompt' }
    }
  })
  wk.register(mappings, opts)
