return _G.imports('which-key', function(wk)
  local c
  c = function(command)
    return "<CMD> " .. tostring(command) .. " <CR>"
  end
  local f
  f = function(command)
    return c("FzfLua " .. tostring(command))
  end
  local t
  t = function(command)
    return c("TroubleToggle " .. tostring(command))
  end
  local mappings = {
    f = {
      name = ' Files',
      f = {
        f('files'),
        ' Find file'
      },
      r = {
        f('oldfiles'),
        ' Open Recent File'
      },
      w = {
        f('live_grep'),
        ' Live Grep project'
      },
      g = {
        f('git_files'),
        ' Show git files'
      },
      t = {
        f('filetypes'),
        ' Show filetypes'
      },
      n = {
        c('DashboardNewFile'),
        ' New File'
      },
      s = {
        c(':w<bang>'),
        ' Save'
      },
      q = {
        c(':wq<bang>'),
        ' Write and Quit'
      },
      d = {
        c(':q<bang>'),
        ' Discart and Quit'
      }
    },
    g = {
      name = ' Git',
      f = {
        f('git_files'),
        ' Show git files'
      },
      c = {
        f('git_commits'),
        ' Show commits'
      },
      b = {
        f('git_branches'),
        ' Show git branches'
      }
    },
    s = {
      name = '都 System',
      m = {
        c('Maps'),
        ' Mappings'
      },
      b = {
        c('Buffers'),
        ' Buffers'
      },
      l = {
        c('Commands'),
        ' List Commands'
      },
      h = {
        c('checkhealth'),
        ' Check Health'
      },
      s = {
        c('PackerSync'),
        ' Sync'
      },
      t = {
        c('PackerStatus'),
        ' Status'
      },
      c = {
        c('PackerCompile'),
        ' Compile'
      }
    },
    l = {
      name = ' Language Servers',
      i = {
        c('LspInfo'),
        ' Info'
      },
      e = {
        c('LspStop'),
        'ﭦ End'
      },
      r = {
        c('LspStart'),
        '奈 Start'
      },
      a = {
        c('LspInstall'),
        '烙 Install'
      },
      u = {
        c('LspUninstall'),
        ' Uninstall'
      },
      l = {
        c('LspRestart'),
        '勒 Restart'
      }
    },
    c = {
      name = ' Coding',
      q = {
        c('stq'),
        '[stq] Swap quotes'
      },
      t = {
        c('zA'),
        '[zA] Toggle Folding'
      },
      f = {
        c('zC'),
        '[zC] Fold'
      },
      a = {
        c('zM'),
        '[zM] Fold All'
      },
      u = {
        c('za'),
        '[zO] Unfold'
      },
      c = {
        c('zR'),
        '[zR] Unfold All'
      }
    },
    p = {
      name = '  Windows',
      ['<A-k>'] = {
        '<C-w>k',
        ' Go ↑'
      },
      ['<A-j>'] = {
        '<C-w>j',
        ' Go ↓'
      },
      ['<A-l>'] = {
        '<C-w>l',
        ' Go →'
      },
      ['<A-h>'] = {
        '<C-w>h',
        ' Go ←'
      }
    },
    d = {
      name = ' Diagnostics',
      w = {
        t('workspace_diagnostics'),
        ' Workspace'
      },
      d = {
        t('document_diagnostics'),
        ' Document'
      },
      l = {
        t('loclist'),
        ' Loclist'
      },
      q = {
        t('quickfix'),
        '覆 Quickfix'
      },
      r = {
        t('lsp_references'),
        ' References'
      },
      n = {
        function()
          return vim.diagnostic.goto_next()
        end,
        ' Next'
      },
      p = {
        function()
          return vim.diagnostic.goto_prev()
        end,
        ' Previous'
      }
    }
  }
  local opts = {
    mode = 'n',
    prefix = '<leader>',
    silent = false,
    noremap = true
  }
  wk.setup({
    triggers = 'auto',
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = false,
        suggestions = 20
      },
      presets = {
        text_objects = true,
        operators = true,
        windows = true,
        motions = true,
        nav = true,
        z = true,
        g = true
      }
    },
    operators = {
      gc = 'Comments'
    },
    key_labels = {
      ['<space>'] = 'Spc'
    },
    icons = {
      breadcrumb = '»',
      separator = '➜',
      group = '+'
    },
    popup_mappings = {
      scroll_down = '<c-d>',
      scroll_up = '<c-u>'
    },
    window = {
      border = 'none',
      position = 'bottom',
      margin = {
        0,
        0,
        1,
        0
      },
      padding = {
        2,
        2,
        2,
        2
      },
      winblend = 0
    },
    layout = {
      height = {
        min = 4,
        max = 25
      },
      width = {
        min = 20,
        max = 50
      },
      spacing = 8,
      align = 'left'
    },
    ignore_missing = false,
    hidden = {
      '<silent>',
      '<cmd>',
      '<Cmd>',
      '<CR>',
      'call',
      'lua',
      '^:',
      '^ '
    },
    show_help = true,
    show_keys = true,
    triggers_blacklist = {
      i = {
        'j',
        'k'
      },
      v = {
        'j',
        'k'
      }
    },
    disable = {
      buftypes = { },
      filetypes = {
        'TelescopePrompt'
      }
    }
  })
  return wk.register(mappings, opts)
end)
