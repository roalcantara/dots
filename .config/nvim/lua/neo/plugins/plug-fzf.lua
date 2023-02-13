return require('neo/lib/functions/imports')('fzf-lua', function(plugin)
  local actions = require('fzf-lua/actions')
  return plugin.setup({
    global_resume = false,
    global_resume_query = true,
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.50,
      fullscreen = false,
      border = {
        '╭',
        '─',
        '╮',
        '│',
        '╯',
        '─',
        '╰',
        '│'
      },
      hl = {
        normal = 'Normal',
        border = 'FloatBorder',
        help_normal = 'Normal',
        help_border = 'FloatBorder',
        cursor = 'Cursor',
        cursorline = 'CursorLine',
        cursorlinenr = 'CursorLineNr',
        search = 'IncSearch',
        title = 'Normal',
        scrollfloat_e = 'PmenuSbar',
        scrollfloat_f = 'PmenuThumb',
        scrollborder_e = 'FloatBorder',
        scrollborder_f = 'FloatBorder'
      },
      preview = {
        default = 'bat',
        border = 'border',
        wrap = 'nowrap',
        hidden = 'nohidden',
        vertical = 'down:45%',
        horizontal = 'right:60%',
        layout = 'flex',
        flip_columns = 120,
        title = true,
        title_align = 'left',
        scrollbar = 'float',
        scrolloff = '-2',
        scrollchars = {
          '█',
          ''
        },
        delay = 100,
        winopts = {
          number = true,
          relativenumber = false,
          cursorline = true,
          cursorlineopt = 'both',
          cursorcolumn = false,
          signcolumn = 'no',
          list = false,
          foldenable = false,
          foldmethod = 'manual'
        }
      },
      on_create = function()
        return vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', '<Down>', {
          silent = true,
          noremap = true
        })
      end
    },
    keymap = {
      builtin = {
        ['<F1>'] = 'toggle-help',
        ['<F2>'] = 'toggle-fullscreen',
        ['<F3>'] = 'toggle-preview-wrap',
        ['<F4>'] = 'toggle-preview',
        ['<F5>'] = 'toggle-preview-ccw',
        ['<F6>'] = 'toggle-preview-cw',
        ['<S-down>'] = 'preview-page-down',
        ['<S-up>'] = 'preview-page-up',
        ['<S-left>'] = 'preview-page-reset'
      },
      fzf = {
        ['ctrl-z'] = 'abort',
        ['ctrl-u'] = 'unix-line-discard',
        ['ctrl-f'] = 'half-page-down',
        ['ctrl-b'] = 'half-page-up',
        ['ctrl-a'] = 'beginning-of-line',
        ['ctrl-e'] = 'end-of-line',
        ['alt-a'] = 'toggle-all',
        ['f3'] = 'toggle-preview-wrap',
        ['f4'] = 'toggle-preview',
        ['shift-down'] = 'preview-page-down',
        ['shift-up'] = 'preview-page-up'
      }
    },
    actions = {
      files = {
        ['default'] = actions.file_edit_or_qf,
        ['alt-s'] = actions.file_split,
        ['alt-v'] = actions.file_vsplit,
        ['alt-t'] = actions.file_tabedit,
        ['alt-q'] = actions.file_sel_to_qf,
        ['alt-l'] = actions.file_sel_to_ll
      },
      buffers = {
        ['default'] = actions.buf_edit_or_qf,
        ['alt-s'] = actions.buf_split,
        ['alt-v'] = actions.buf_vsplit,
        ['alt-t'] = actions.buf_tabedit,
        ['alt-q'] = actions.buf_sel_to_qf
      }
    },
    previewers = {
      cat = {
        cmd = 'cat',
        args = '--number'
      },
      bat = {
        cmd = 'bat',
        args = '--style=numbers,changes --color always',
        theme = 'dracula',
        config = nil
      },
      head = {
        cmd = 'head',
        args = nil
      },
      git_diff = {
        cmd_deleted = 'git diff --color HEAD --',
        cmd_modified = 'git diff --color HEAD',
        cmd_untracked = 'git diff --color --no-index /dev/null',
        pager = 'delta --width=$FZF_PREVIEW_COLUMNS'
      },
      man = {
        cmd = 'man -c %s | col -bx'
      },
      builtin = {
        syntax = true,
        syntax_limit_l = 0,
        syntax_limit_b = 1024 * 1024,
        limit_b = 1024 * 1024 * 10,
        extensions = { }
      }
    },
    files = {
      previewer = 'bat',
      prompt = 'Files ❯ ',
      multiprocess = true,
      git_icons = true,
      file_icons = true,
      color_icons = true,
      cmd = 'fd',
      find_opts = [[-type f -not -path '*/\.git/*' -printf "%P\n"]],
      rg_opts = "--color=always --files --hidden --follow -g '!.git'",
      fd_opts = '--type f --ignore-case --follow --color=always --hidden --exclude .git --exclude .bash_sessions --exclude .gem --exclude .npm --exclude go/pkg --exclude node_modules',
      actions = { }
    },
    git = {
      files = {
        prompt = 'GitFiles ❯ ',
        cmd = 'git ls-files --exclude-standard',
        multiprocess = true,
        git_icons = true,
        file_icons = true,
        color_icons = true,
        show_cwd_header = true
      },
      status = {
        prompt = 'GitStatus ❯ ',
        cmd = 'git status -s',
        previewer = 'git_diff',
        file_icons = true,
        git_icons = true,
        color_icons = true,
        preview_pager = 'delta --width=$FZF_PREVIEW_COLUMNS',
        actions = {
          right = {
            actions.git_unstage,
            actions.resume
          },
          left = {
            actions.git_stage,
            actions.resume
          }
        }
      },
      commits = {
        prompt = 'Commits ❯ ',
        cmd = 'git log --pretty=oneline --abbrev-commit --color',
        preview = "git show --pretty='%Cred%H%n%Cblue%an%n%Cgreen%s' --color {1}",
        preview_pager = 'delta --width=$FZF_PREVIEW_COLUMNS',
        actions = {
          default = actions.git_checkout
        }
      },
      bcommits = {
        prompt = 'BCommits ❯ ',
        cmd = 'git log --pretty=oneline --abbrev-commit --color',
        preview = "git show --pretty='%Cred%H%n%Cblue%an%n%Cgreen%s' --color {1}",
        preview_pager = 'delta --width=$FZF_PREVIEW_COLUMNS',
        actions = {
          ['default'] = actions.git_buf_edit,
          ['alt-s'] = actions.git_buf_split,
          ['alt-v'] = actions.git_buf_vsplit,
          ['alt-t'] = actions.git_buf_tabedit
        }
      },
      branches = {
        prompt = 'Branches ❯ ',
        cmd = 'git branch --all --color',
        preview = 'git log --graph --pretty=oneline --abbrev-commit --color {1}',
        actions = {
          default = actions.git_switch
        }
      },
      stash = {
        prompt = 'Stash ❯ ',
        cmd = 'git --no-pager stash list',
        preview = 'git --no-pager stash show --patch --color {1}',
        fzf_opts = {
          ['--no-multi'] = '',
          ['--delimiter'] = "'[:]'"
        },
        actions = {
          ['default'] = actions.git_stash_apply,
          ['ctrl-x'] = {
            actions.git_stash_drop,
            actions.resume
          }
        }
      },
      icons = {
        ['R'] = {
          icon = 'R',
          color = 'yellow'
        },
        ['C'] = {
          icon = 'C',
          color = 'yellow'
        },
        ['T'] = {
          icon = 'T',
          color = 'magenta'
        },
        ['?'] = {
          icon = '?',
          color = 'magenta'
        },
        ['M'] = {
          icon = '★',
          color = 'yellow'
        },
        ['D'] = {
          icon = '✗',
          color = 'red'
        },
        ['A'] = {
          icon = '+',
          color = 'green'
        }
      }
    },
    grep = {
      prompt = 'Rg ❯ ',
      input_prompt = 'Grep ❯ ',
      multiprocess = false,
      git_icons = true,
      file_icons = true,
      color_icons = true,
      cmd = 'rg --vimgrep',
      grep_opts = '--binary-files=without-match --line-number --recursive --color=auto --perl-regexp',
      rg_opts = '--column --line-number --no-heading --color=always --smart-case --max-columns=512',
      rg_glob = false,
      glob_flag = '--iglob',
      glob_separator = '%s%-%-',
      no_header = false,
      no_header_i = false,
      actions = {
        ['ctrl-g'] = {
          actions.grep_lgrep
        }
      }
    },
    args = {
      prompt = 'Args ❯ ',
      files_only = true,
      actions = {
        ['ctrl-x'] = {
          actions.arg_del,
          actions.resume
        }
      }
    },
    oldfiles = {
      prompt = 'History❯ ',
      cwd_only = false,
      stat_file = true,
      include_current_session = false
    },
    buffers = {
      prompt = 'Buffers ❯ ',
      file_icons = true,
      color_icons = true,
      sort_lastused = true,
      actions = {
        ['ctrl-x'] = {
          actions.buf_del,
          actions.resume
        }
      }
    },
    tabs = {
      prompt = 'Tabs ❯ ',
      tab_title = 'Tab',
      tab_marker = '<<',
      file_icons = true,
      color_icons = true,
      fzf_opts = {
        ['--delimiter'] = "'[\\):]'",
        ['--with-nth'] = '2..'
      },
      actions = {
        ['default'] = actions.buf_switch,
        ['ctrl-x'] = {
          actions.buf_del,
          actions.resume
        }
      }
    },
    lines = {
      previewer = 'builtin',
      prompt = 'Lines❯ ',
      show_unlisted = false,
      no_term_buffers = true,
      fzf_opts = {
        ['--delimiter'] = "'[\\]:]'",
        ['--nth'] = '2..',
        ['--tiebreak'] = 'index'
      },
      actions = { }
    },
    blines = {
      previewer = 'builtin',
      prompt = 'BLines ❯ ',
      show_unlisted = true,
      no_term_buffers = false,
      fzf_opts = {
        ['--delimiter'] = "'[\\]:]'",
        ['--with-nth'] = '2..',
        ['--tiebreak'] = 'index'
      },
      actions = { }
    },
    tags = {
      prompt = 'Tags ❯ ',
      ctags_file = 'tags',
      multiprocess = false,
      file_icons = true,
      git_icons = true,
      color_icons = true,
      rg_opts = '--no-heading --color=always --smart-case',
      grep_opts = '--color=auto --perl-regexp',
      no_header = false,
      no_header_i = false,
      actions = {
        ['ctrl-g'] = {
          actions.grep_lgrep
        }
      }
    },
    btags = {
      prompt = 'BTags ❯ ',
      ctags_file = 'tags',
      multiprocess = false,
      file_icons = true,
      git_icons = true,
      color_icons = true,
      rg_opts = '--no-heading --color=always',
      grep_opts = '--color=auto --perl-regexp',
      fzf_opts = {
        ['--delimiter'] = "'[\\]:]'",
        ['--with-nth'] = '2..',
        ['--tiebreak'] = 'index'
      },
      actions = { }
    },
    colorschemes = {
      prompt = 'Colorschemes ❯ ',
      live_preview = true,
      actions = {
        ['default'] = actions.colorscheme
      },
      winopts = {
        height = 0.55,
        width = 0.30
      }
    },
    quickfix = {
      file_icons = true,
      git_icons = true
    },
    lsp = {
      prompt_postfix = '❯ ',
      cwd_only = false,
      async_or_timeout = 5000,
      file_icons = true,
      git_icons = false,
      lsp_icons = true,
      ui_select = true,
      severity = 'hint',
      icons = {
        ['Error'] = {
          icon = '',
          color = 'red'
        },
        ['Warning'] = {
          icon = '',
          color = 'yellow'
        },
        ['Information'] = {
          icon = '',
          color = 'blue'
        },
        ['Hint'] = {
          icon = '',
          color = 'magenta'
        }
      },
      symbols = {
        async_or_timeout = true,
        symbol_style = 1,
        symbol_hl_prefix = 'CmpItemKind'
      },
      code_actions = {
        prompt = 'Code Actions> ',
        ui_select = true,
        async_or_timeout = 5000,
        winopts = {
          row = 0.40,
          height = 0.35,
          width = 0.60
        }
      }
    },
    diagnostics = {
      prompt = 'Diagnostics❯ ',
      cwd_only = false,
      file_icons = true,
      git_icons = false,
      diag_icons = true,
      icon_padding = ''
    },
    file_icon_padding = ' ',
    file_icon_colors = {
      ['lua'] = 'blue'
    }
  })
end)
