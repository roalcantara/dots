-- https://github.com/ibhagwan/fzf-lua
-- Improved fzf.vim written in lua

-- FzfLua conviniently creates the below highlights:
--       key is the highlight group name
--       value[1] is the setup/call arg option name
--       value[2] is the default link if value[1] is undefined
--    FzfLuaNormal: { 'winopts.hl.normal', 'Normal' },
--    FzfLuaBorder: { 'winopts.hl.border', 'Normal' },
--    FzfLuaCursor: { 'winopts.hl.cursor', 'Cursor' },
--    FzfLuaCursorLine: { 'winopts.hl.cursorline', 'CursorLine' },
--    FzfLuaCursorLineNr: { 'winopts.hl.cursornr', 'CursorLineNr' },
--    FzfLuaSearch: { 'winopts.hl.search', 'IncSearch' },
--    FzfLuaTitle: { 'winopts.hl.title', 'FzfLuaNormal' },
--    FzfLuaScrollBorderEmpty: { 'winopts.hl.scrollborder_e', 'FzfLuaBorder' },
--    FzfLuaScrollBorderFull : { 'winopts.hl.scrollborder_f', 'FzfLuaBorder' },
--    FzfLuaScrollFloatEmpty : { 'winopts.hl.scrollfloat_e', 'PmenuSbar' },
--    FzfLuaScrollFloatFull  : { 'winopts.hl.scrollfloat_f', 'PmenuThumb' },
--    FzfLuaHelpNormal: { 'winopts.hl.help_normal', 'FzfLuaNormal' },
--    FzfLuaHelpBorder: { 'winopts.hl.help_border', 'FzfLuaBorder' },
--
-- Which can be easily customized:
-- :lua vim.api.nvim_set_hl(0, 'FzfLuaBorder', { link: 'FloatBorder' })
--
-- customize these highlights without having to modify your preset colorscheme highlight links
-- require('fzf-lua').setup{ winopts: { hl: { border: 'FloatBorder' } } }

require('neo/lib/functions/imports') 'fzf-lua', (plugin) ->
  actions = require 'fzf-lua/actions'

  plugin.setup {
    global_resume: false,
    global_resume_query: true,
    winopts: {
      -- split: 'belowright new',             -- open in a split instead?
                                              -- 'belowright new'  : split below
                                              -- 'aboveleft new'   : split above
                                              -- 'belowright vnew' : split right
                                              -- 'aboveleft vnew   : split left

      -- Only valid when using a float window
      -- (i.e. when 'split' is not defined, default)
      height:             0.85,               -- window height
      width:              0.80,               -- window width
      row:                0.35,               -- window row position (0:top,  1:bottom)
      col:                0.50,               -- window col position (0:left, 1:right)
      fullscreen:         false,              -- start fullscreen?

      -- border argument passthrough to nvim_open_win(), also used
      -- to manually draw the border characters around the preview
      -- window, can be set to `false` to remove all borders or to
      border: {              -- 'false', 'none', 'single', 'double', 'thicc' or 'rounded' (default)
                            '╭',
                            '─'
                            '╮'
                            '│'
                            '╯'
                            '─'
                            '╰'
                            '│'
      },
      -- highlights should optimally be set by the colorscheme using FzfLuaXXX highlights
      hl: {
        -- If your colorscheme doesn't set these or you wish to override its defaults use these:
        normal:             'Normal',        -- window normal color (fg+bg)
        border:             'FloatBorder',   -- border color
        help_normal:        'Normal',        -- <F1> window normal
        help_border:        'FloatBorder',   -- <F1> window border

        -- Only used with the builtin previewer:
        cursor:             'Cursor',        -- cursor highlight (grep/LSP matches)
        cursorline:         'CursorLine',    -- cursor line
        cursorlinenr:       'CursorLineNr',  -- cursor line number
        search:             'IncSearch',     -- search matches (ctags|help)
        title:              'Normal',        -- preview border title (file/buffer)

        -- Only used with 'winopts.preview.scrollbar:             'float'
        scrollfloat_e:      'PmenuSbar',     -- scrollbar 'empty' section highlight
        scrollfloat_f:      'PmenuThumb',    -- scrollbar 'full' section highlight

        -- Only used with 'winopts.preview.scrollbar:             'border'
        scrollborder_e:     'FloatBorder',   -- scrollbar 'empty' section highlight
        scrollborder_f:     'FloatBorder',   -- scrollbar 'full' section highlight
      },
      preview: {
        default:            'bat',           -- override the default previewer?
                                            -- default uses the 'builtin' previewer

        border:             'border',        -- border|noborder, applies only to
                                            -- native fzf previewers (bat/cat/git/etc)

        wrap:               'nowrap',        -- wrap|nowrap
        hidden:             'nohidden',      -- hidden|nohidden
        vertical:           'down:45%',      -- up|down:size
        horizontal:         'right:60%',     -- right|left:size
        layout:             'flex',          -- horizontal|vertical|flex
        flip_columns:       120,             -- #cols to switch to horizontal on flex

        -- Only used with the builtin previewer:
        title:              true,            -- preview border title (file/buf)?
        title_align:        'left',          -- left|center|right, title alignment
        scrollbar:          'float',         -- `false` or string:'float|border'
                                                  -- float:  in-window floating border
                                                  -- border: in-border chars (see below)
        scrolloff:          '-2',                 -- float scrollbar offset from right
                                            -- applies only when scrollbar: 'float'
        scrollchars:        {'█', '' },      -- scrollbar chars ({ <full>, <empty> }
                                            -- applies only when scrollbar: 'border'
        delay:               100,            -- delay(ms) displaying the preview
                                            -- prevents lag on fast scrolling
        winopts: {                           -- builtin previewer window options
          number:            true,
          relativenumber:    false,
          cursorline:        true,
          cursorlineopt:     'both',
          cursorcolumn:      false,
          signcolumn:        'no',
          list:              false,
          foldenable:        false,
          foldmethod:        'manual',
        },
      },
      -- called once upon creation of the fzf main window
      -- can be used to add custom fzf-lua mappings
      on_create: () -> vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', '<Down>', {silent: true, noremap: true})
    },
    keymap: {
      -- These override the default tables completely
      -- no need to set to `false` to disable a bind
      -- delete or modify is sufficient
      builtin: {
        -- neovim `:tmap` mappings for the fzf win
        ['<F1>']:       'toggle-help',
        ['<F2>']:       'toggle-fullscreen',
        -- Only valid with the 'builtin' previewer
        ['<F3>']:       'toggle-preview-wrap',
        ['<F4>']:       'toggle-preview',
        -- Rotate preview clockwise/counter-clockwise
        ['<F5>']:       'toggle-preview-ccw',
        ['<F6>']:       'toggle-preview-cw',
        ['<S-down>']:   'preview-page-down',
        ['<S-up>']:     'preview-page-up',
        ['<S-left>']:   'preview-page-reset',
      },
      fzf: {
        -- fzf '--bind=' options
        ['ctrl-z']:       'abort',
        ['ctrl-u']:       'unix-line-discard',
        ['ctrl-f']:       'half-page-down',
        ['ctrl-b']:       'half-page-up',
        ['ctrl-a']:       'beginning-of-line',
        ['ctrl-e']:       'end-of-line',
        ['alt-a']:        'toggle-all',
        -- Only valid with fzf previewers (bat/cat/git/etc)
        ['f3']:           'toggle-preview-wrap',
        ['f4']:           'toggle-preview',
        ['shift-down']:   'preview-page-down',
        ['shift-up']:     'preview-page-up',
      },
    },
    actions: {
      -- These override the default tables completely
      -- no need to set to `false` to disable an action (delete or modify)
      -- The default action opens a single selection or sends multiple selection to quickfix
      -- providers that inherit these actions:
      --    files, git_files, git_status, grep, lsp
      --    oldfiles, quickfix, loclist, tags, btags, args
      files: {
        -- ['default']: actions.file_edit                 -- open all files whether (single or multiple)
        -- ['ctrl-y']: (selected) -> print(selected[1])   -- custom actions are available too
        ['default']: actions.file_edit_or_qf,             -- edit or quickfix
        ['alt-s']: actions.file_split,                    -- open in split
        ['alt-v']: actions.file_vsplit,                   -- open in vsplit
        ['alt-t']: actions.file_tabedit,                  -- select to tabedit
        ['alt-q']: actions.file_sel_to_qf,                -- select to quickfix
        ['alt-l']: actions.file_sel_to_ll                 -- select to loclist
      },
      buffers: {
        ['default']: actions.buf_edit_or_qf,
        ['alt-s']: actions.buf_split,
        ['alt-v']: actions.buf_vsplit,
        ['alt-t']: actions.buf_tabedit
        ['alt-q']: actions.buf_sel_to_qf
      }
    },
    previewers: {
      cat: {cmd: 'cat', args: '--number'},
      bat: {
        cmd: 'bat',
        args: '--style=numbers,changes --color always',
        theme: 'dracula',
        config: nil
      },
      head: {cmd: 'head', args: nil},
      git_diff: {
        cmd_deleted: 'git diff --color HEAD --',
        cmd_modified: 'git diff --color HEAD',
        cmd_untracked: 'git diff --color --no-index /dev/null',
        pager: 'delta --width=$FZF_PREVIEW_COLUMNS'
      },
      man: {
        cmd: 'man -c %s | col -bx'
      },
      builtin: {
        syntax:            true,         -- preview syntax highlight?
        syntax_limit_l:    0,            -- syntax limit (lines), 0:nolimit
        syntax_limit_b:    1024*1024,    -- syntax limit (bytes), 0:nolimit
        limit_b:           1024*1024*10, -- preview limit (bytes), 0:nolimit
        -- preview extensions using a custom shell command:
        -- for example, use `viu` for image previews
        -- will do nothing if `viu` isn't executable
        extensions: {
          -- neovim terminal only supports `viu` block output
          -- ['png']       :{ 'viu', '-b' },
          -- ['svg']       :{ 'chafa' },
          -- ['jpg']       :{ 'ueberzug' },
        },
        -- if using `ueberzug` in the above extensions map
        -- set the default image scaler, possible scalers:
        --   false (none), 'crop', 'distort', 'fit_contain',
        --   'contain', 'forced_cover', 'cover'
        -- https://github.com/seebye/ueberzug
        -- ueberzug_scaler :'cover',
      }
    },
    files: {
      previewer:          'bat',
      prompt:             'Files ❯ ',
      multiprocess:       true,         -- run command in a separate process
      git_icons:          true,         -- show git icons?
      file_icons:         true,         -- show file icons?
      color_icons:        true,         -- colorize file|git icons
      -- executed command priority is 'cmd' (if exists) 'find . -type f -printf '%P\n''
      -- otherwise auto-detect prioritizes `fd`:`rg`:`find`
      -- default options are controlled by 'fd|rg|find|_opts'
      -- NOTE: 'find -printf' requires GNU find
      cmd: 'fd',
      -- path_shorten   :1,              -- 'true' or number, shorten path?
      -- by default, cwd appears in the header only if {opts} contain a cwd
      -- parameter to a different folder than the current working directory
      -- show_cwd_prompt: true,      -- force display of the cwd as part of the query prompt string (fzf.vim style)
      -- show_cwd_header: true,      -- force display of the cwd as part of the headerline
      find_opts: [[-type f -not -path '*/\.git/*' -printf "%P\n"]],
      rg_opts: "--color=always --files --hidden --follow -g '!.git'",
      fd_opts: '--type f --ignore-case --follow --color=always --hidden --exclude .git --exclude .bash_sessions --exclude .gem --exclude .npm --exclude go/pkg --exclude node_modules',
      -- inherits from 'actions.files'
      actions: {
        -- here we can override or set bind to 'false' to disable a default action
      }
    },
    git: {
      files: {
        prompt: 'GitFiles ❯ ',
        cmd: 'git ls-files --exclude-standard',
        multiprocess: true,                          -- run command in a separate process
        git_icons: true,                             -- show git icons?
        file_icons: true,                            -- show file icons?
        color_icons: true,                           -- colorize file|git icons
        -- force display the cwd header line regardles of your current working
        -- directory can also be used to hide the header when not wanted
        show_cwd_header: true
      },
      status: {
        prompt: 'GitStatus ❯ ',
        -- consider using `git status -su` if you wish to see untracked files individually under their subfolders
        cmd: 'git status -s',
        previewer: 'git_diff',
        file_icons: true,
        git_icons: true,
        color_icons: true,
        preview_pager: 'delta --width=$FZF_PREVIEW_COLUMNS', -- use git-delta as pager
         -- actions inherit from 'actions.files' and merge
        actions: {
          right: {actions.git_unstage, actions.resume},
          left: {actions.git_stage, actions.resume}
        }
      },
      commits: {
        prompt: 'Commits ❯ ',
        cmd: 'git log --pretty=oneline --abbrev-commit --color',
        preview: "git show --pretty='%Cred%H%n%Cblue%an%n%Cgreen%s' --color {1}",
        preview_pager: 'delta --width=$FZF_PREVIEW_COLUMNS', -- use git-delta as pager
        actions: {default: actions.git_checkout}
      },
      bcommits: {
        prompt: 'BCommits ❯ ',
        -- default preview shows a git diff vs the previous commit
        -- if you prefer to see the entire commit you can use:
        --    git show --color {1} --rotate-to=<file>
        --      {1}    : commit SHA (fzf field index expression)
        --      <file> : filepath placement within the commands
        cmd: 'git log --pretty=oneline --abbrev-commit --color',
        preview: "git show --pretty='%Cred%H%n%Cblue%an%n%Cgreen%s' --color {1}",
        preview_pager: 'delta --width=$FZF_PREVIEW_COLUMNS', -- use git-delta as pager
        actions: {
          ['default']: actions.git_buf_edit,
          ['alt-s']: actions.git_buf_split,
          ['alt-v']: actions.git_buf_vsplit,
          ['alt-t']: actions.git_buf_tabedit
        }
      },
      branches: {
        prompt: 'Branches ❯ ',
        cmd: 'git branch --all --color',
        preview: 'git log --graph --pretty=oneline --abbrev-commit --color {1}',
        actions: {default: actions.git_switch}
      },
      stash: {
        prompt: 'Stash ❯ ',
        cmd: 'git --no-pager stash list',
        preview: 'git --no-pager stash show --patch --color {1}',
        fzf_opts: {['--no-multi']: '', ['--delimiter']: "'[:]'"}
        actions: {
          ['default']: actions.git_stash_apply,
          ['ctrl-x']: {actions.git_stash_drop, actions.resume}
        },
      },
      icons: {
        ['R']: {icon: 'R', color: 'yellow'  },
        ['C']: {icon: 'C', color: 'yellow'  },
        ['T']: {icon: 'T', color: 'magenta' },
        ['?']: {icon: '?', color: 'magenta' },
        ['M']: {icon: '★', color: 'yellow'  },
        ['D']: {icon: '✗', color: 'red'     },
        ['A']: {icon: '+', color: 'green'   }
      }
    },
    grep: {
      prompt: 'Rg ❯ ',
      input_prompt: 'Grep ❯ ',
      multiprocess: false,
      git_icons: true,
      file_icons: true,
      color_icons: true,
      -- executed command priority is 'cmd' (if exists)
      -- otherwise auto-detect prioritizes `rg` over `grep`
      -- default options are controlled by 'rg|grep_opts'
      cmd: 'rg --vimgrep',
      grep_opts: '--binary-files=without-match --line-number --recursive --color=auto --perl-regexp',
      rg_opts: '--column --line-number --no-heading --color=always --smart-case --max-columns=512',
      -- set to 'true' to always parse globs in both 'grep' and 'live_grep'
      -- search strings will be split using the 'glob_separator' and translated
      -- to '--iglob=' arguments, requires 'rg'
      -- can still be used when 'false' by calling 'live_grep_glob' directly
      rg_glob: false,
      glob_flag: '--iglob',
      glob_separator: '%s%-%-',
      -- advanced usage: for custom argument parsing define
      -- 'rg_glob_fn' to return a pair:
      --   first returned argument is the new search query
      --   second returned argument are addtional rg flags
      -- rg_glob_fn: function(query, opts)
      --   ...
      --   return new_query, flags
      -- end,
      no_header: false,                              -- hide grep|cwd header?
      no_header_i: false,                            -- hide interactive header?
      -- actions inherit from 'actions.files' and merge
      actions: {
        -- this action toggles between 'grep' and 'live_grep'
        ['ctrl-g']: {actions.grep_lgrep}
      },
    },
    args: {
      prompt: 'Args ❯ ',
      files_only: true,
       -- actions inherit from 'actions.files' and merge
      actions: {['ctrl-x']: {actions.arg_del, actions.resume}}
    },
    oldfiles: {
      prompt: 'History❯ ',
      cwd_only: false,
      stat_file: true,                      -- verify files exist on disk
      include_current_session: false        -- include bufs from current session
    },
    buffers: {
      prompt: 'Buffers ❯ ',
      file_icons: true,
      color_icons: true,
      sort_lastused: true,
      -- actions inherit from 'actions.buffers' and merge
      actions: {
        -- by supplying a table of functions we're telling fzf-lua to not close
        -- the fzf window, this way we can resume the buffers picker on the same
        -- window eliminating an otherwise unaesthetic win 'flash'
        ['ctrl-x']: {actions.buf_del, actions.resume}
      }
    },
    tabs: {
      prompt: 'Tabs ❯ ',
      tab_title: 'Tab',
      tab_marker: '<<',
      file_icons: true,
      color_icons: true,
      fzf_opts: { ['--delimiter']: "'[\\):]'", ['--with-nth']: '2..' }
      actions: {
        -- actions inherit from 'actions.buffers' and merge
        ['default']: actions.buf_switch,
        ['ctrl-x']: {actions.buf_del, actions.resume}
      },
    },
    lines: {
      previewer: 'builtin',
      prompt: 'Lines❯ ',
      show_unlisted: false,
      no_term_buffers: true,
      fzf_opts: { ['--delimiter']: "'[\\]:]'", ['--nth']: '2..', ['--tiebreak']: 'index' },
      -- actions inherit from 'actions.buffers' and merge
      actions: { }
    },
    blines: {
      previewer: 'builtin',
      prompt: 'BLines ❯ ',
      show_unlisted: true,
      no_term_buffers: false,
      fzf_opts: { ['--delimiter']: "'[\\]:]'", ['--with-nth']: '2..', ['--tiebreak']: 'index' },
      -- actions inherit from 'actions.buffers' and merge
      actions: { }
    },
    tags: {
      prompt: 'Tags ❯ ',
      ctags_file: 'tags',
      multiprocess: false,
      file_icons: true,
      git_icons: true,
      color_icons: true,
      rg_opts: '--no-heading --color=always --smart-case',
      grep_opts: '--color=auto --perl-regexp',
      no_header: false,          -- hide grep|cwd header?
      no_header_i: false         -- hide interactive header?
      -- actions inherit from 'actions.files' and merge this action toggles between 'grep' and 'live_grep'
      actions: {
        ['ctrl-g']: {actions.grep_lgrep}
      },
    },
    btags: {
      prompt: 'BTags ❯ ',
      ctags_file: 'tags',
      multiprocess: false,
      file_icons: true,
      git_icons: true,
      color_icons: true,
      rg_opts: '--no-heading --color=always',
      grep_opts: '--color=auto --perl-regexp',
      fzf_opts: {['--delimiter']: "'[\\]:]'", ['--with-nth']: '2..', ['--tiebreak']: 'index'}
      -- actions inherit from 'actions.files'
      actions: { }
    },
    colorschemes: {
      prompt: 'Colorschemes ❯ ',
      live_preview: true,
      actions: {['default']: actions.colorscheme},
      winopts: {height: 0.55, width: 0.30}
    },
    quickfix: {file_icons: true, git_icons: true},
    lsp: {
      prompt_postfix: '❯ ',                   -- will be appended to the LSP label
                                              -- to override use 'prompt' instead
      cwd_only: false,                        -- LSP/diagnostics for cwd only?
      async_or_timeout: 5000,                 -- timeout(ms) or 'true' for async calls
      file_icons: true,
      git_icons: false,
      lsp_icons: true,
      ui_select: true,
      severity: 'hint',
      icons: {
        ['Error']: {icon: '', color: 'red'},
        ['Warning']: {icon: '', color: 'yellow'},
        ['Information']: {icon: '', color: 'blue'},
        ['Hint']: {icon: '', color: 'magenta'}
      },
      -- settings for 'lsp_{document|workspace|lsp_live_workspace}_symbols'
      symbols: {
        async_or_timeout:   true,             -- symbols are async by default
        symbol_style:       1,                -- style for document/workspace symbols
                                              -- false: disable,    1: icon+kind
                                              --     2: icon only,  3: kind only
                                              -- NOTE: icons are extracted from
                                              -- vim.lsp.protocol.CompletionItemKind

        -- colorize using nvim-cmp's CmpItemKindXXX highlights
        -- can also be set to 'TS' for treesitter highlights ('TSProperty', etc)
        symbol_hl_prefix:   'CmpItemKind',    -- or 'false' to disable highlighting
        -- additional symbol formatting, works with or without style
        -- symbol_fmt:         (s)-> "[#{s}]"
      },
      code_actions: {
        prompt:               'Code Actions> ',
        ui_select:            true,       -- use 'vim.ui.select'?
        async_or_timeout:     5000,
        winopts: {
          row:                0.40,
          height:             0.35,
          width:              0.60,
        }
      }
    },
    diagnostics:{
      prompt:                'Diagnostics❯ ',
      cwd_only:               false,
      file_icons:             true,
      git_icons:              false,
      diag_icons:             true,
      icon_padding:           '',     -- add padding for wide diagnostics signs
      -- by default icons and highlights are extracted from 'DiagnosticSignXXX'
      -- and highlighted by a highlight group of the same name (which is usually
      -- set by your colorscheme, for more info see:
      --   :help DiagnosticSignHint'
      --   :help hl-DiagnosticSignHint'
      -- only uncomment below if you wish to override the signs/highlights
      -- define only text, texthl or both (':help sign_define()' for more info)
      -- signs: {
      --   ['Error']: { text: '', texthl: 'DiagnosticError' },
      --   ['Warn']: { text: '', texthl: 'DiagnosticWarn' },
      --   ['Info']: { text: '', texthl: 'DiagnosticInfo' },
      --   ['Hint']: { text: '', texthl: 'DiagnosticHint' },
      -- },
      -- limit to specific severity, use either a string or num:
      --    1 or 'hint'
      --    2 or 'information'
      --    3 or 'warning'
      --    4 or 'error'
      -- severity_only:   keep any matching exact severity
      -- severity_limit:  keep any equal or more severe (lower)
      -- severity_bound:  keep any equal or less severe (higher)
    },
    -- uncomment to use the old help previewer which used a
    -- minimized help window to generate the help tag preview
    -- helptags: { previewer: "help_tags" },
    -- uncomment to use `man` command as native fzf previewer
    -- (instead of using a neovim floating window)
    -- manpages: { previewer: "man_native" },

    -- padding can help kitty term users with
    -- double-width icon rendering
    file_icon_padding: ' ',
    -- optional override of file extension icon colors available colors (terminal):
    --    clear, bold, black, red, green, yellow
    --    blue, magenta, cyan, grey, dark_grey, white
    file_icon_colors: {['lua']: 'blue'}
    -- uncomment if your terminal/font does not support unicode character
    -- 'EN SPACE' (U+2002), the below sets it to 'NBSP' (U+00A0) instead
    -- nbsp: '\xc2\xa0',
  }
