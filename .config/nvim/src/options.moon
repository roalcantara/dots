path = require 'etc/fn/path'

--- Returns the proper clipboard command for the current platform.
--- @see https://neovim.io/doc/user/options.html#'clipboard'
clipboard = () ->
  return {
    cache_enabled: 0,
    name: 'macOS-clipboard',
    copy: { ['+']: 'pbcopy', ['*']: 'pbcopy' },
    paste: { ['+']: 'pbpaste', ['*']: 'pbpaste' }
  } if vim.loop.os_uname!.sysname == 'Darwin'
  'unnamedplus'

--- Set options and variables
--- @see https://neovim.io/doc/user/options.html
--- @see https://www.cs.oberlin.edu/~kuperman/help/vim/home.html
--- @see https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua
options = {
  --- Global variables
  --- Usually used to plugins settings and the leader key
  --- @see https://neovim.io/doc/user/lua.html#vim.g
  --- @see https://neovim.io/doc/user/eval.html#g%3A
  g: {
    --- disable_distribution_plugins
    loaded_2html_plugin: 1
    loaded_getscript: 1
    loaded_getscriptPlugin: 1
    loaded_gzip: 1
    loaded_logipat: 1
    loaded_matchit: 1
    loaded_netrw: 1
    loaded_netrwFileHandlers: 1
    loaded_netrwPlugin: 1
    loaded_netrwSettings: 1
    loaded_rrhelper: 1
    loaded_spellfile_plugin: 1
    loaded_tar: 1
    loaded_tarPlugin: 1
    loaded_vimball: 1
    loaded_vimballPlugin: 1
    loaded_zip: 1
    loaded_zipPlugin: 1

    --- Filetype.vim has been replaced by filetype.lua
    --- @see https://tinyurl.com/28uj5aeg
    did_load_filetypes: 1

    --- Sets Leader key for map commands
    --- @see https://neovim.io/doc/user/options.html#'mapleader'
    mapleader: ' '

    --- Sets Leader key for map local commands
    --- @see https://neovim.io/doc/user/options.html#'maplocalleader'
    maplocalleader: [[\\]]

    --- Allows syntax-based folding for zsh scripts
    --- @see https://neovim.io/doc/user/options.html#'zsh_fold_enable'
    zsh_fold_enable: 1

    --- Enables lua, python and ruby syntax highlighting inside .vim files
    --- @see https://neovim.io/doc/user/options.html#'vimsyn_embed'
    vimsyn_embed: 'lPr'

    --- Use the clipboard as the unnamed register
    --- @see https://neovim.io/doc/user/options.html#'clipboard'
    clipboard: clipboard!

    --- Use fuzzy as is the default matching strategy
    --- @see https://youtu.be/tOjVHXaUrzo
    completion_matching_strategy_list: {
      'fuzzy',
      'subscring',
      'exact'
    }

    --- Enable treesitter highlighting for Lua
    ts_highlight_lua: true

    -- Padding after nerd symbols
    global_symbol_padding: '  '

    -- markdown
    -- Use proper syntax highlighting in code blocks
    markdown_fenced_languages: {
      'html',
      'python',
      'sh',
      'bash=sh',
      'javascript',
      'js=javascript',
      'json',
      'go',
      'typescript',
      'ts=typescript',
      'yaml',
      'yml=yaml'
    }
  },
  --- Get or set list and map-style options (like :set)
  --- It allows accessing them as Lua tables and offers object-oriented method for adding and removing entries.
  --- For numeric options the value can be given in decimal, hex (preceded with 0x) or octal (preceded with '0').
  --- @example To set list-style options:
  ---   (  VimScript  ):>  set wildignore=*.o,*.a,__pycache__
  ---   ( Lua's vim.o ):>  vim.o.wildignore: '*.o,*.a,__pycache__'
  ---   (Lua's vim.opt):>  vim.opt.wildignore: { '*.o', '*.a', '__pycache__' }
  --- @example To set map-style options:
  ---   (  VimScript  ):>  set listchars=space:_,tab:>~
  ---   ( Lua's vim.o ):>  vim.o.listchars: 'space:_,tab:>~'
  ---   (Lua's vim.opt):>  vim.opt.listchars: { space: '_', tab: '>~' }
  --- @example It returns a lua-representation of the option via `:get()`:
  ---   (  VimScript  ):>  echo wildignore
  ---   ( Lua's vim.o ):>  print(vim.o.wildignore)
  ---   (Lua's vim.opt):>  vim.pretty_print(vim.opt.wildignore:get())
  --- @example vim.opt.wildignore:append { "*.pyc", "node_modules" } (:set+=)
  --- @example vim.opt.wildignore:prepend { "new_first_value" } (:set^=)
  --- @example vim.opt.wildignore:remove { "node_modules" } (:set-=)
  --- @see https://neovim.io/doc/user/lua.html#vim.opt
  --- @see https://neovim.io/doc/user/options.html#%3Aset
  opt: {
    autoindent: false,
    autowriteall: true, -- automatically :write before running commands and changing files
    backspace: {'indent', 'eol', 'start'},
    backup: false, -- creates a backup file
    backupskip: {
      '/tmp/*',
      '$TMPDIR/*',
      '$TMP/*',
      '$TEMP/*',
      '*/shm/*',
      '/private/var/*',
      '.vault.vim'
    },
    breakindentopt: {'shift:2', 'min:20'},
    --- [bo] enables automatic C program indenting
    --- @see https://neovim.io/doc/user/options.html#'cindent'
    cindent: false,
    cmdheight: 1, -- more space in the neovim command line for displaying messages
    colorcolumn: '+1',
    completeopt: 'menuone,noinsert,noselect',
    concealcursor: 'niv',
    conceallevel: 1, -- so that `` is visible in markdown files
    confirm: false, -- make vim do not prompt me to save before doing destructive things
    cursorline: false, -- highlight the current line
    diffopt: (option)-> option\append({'vertical', 'iwhite', 'hiddenoff', 'foldcolumn:0', 'context:1000000', 'algorithm:histogram', 'indent-heuristic'}),
    equalalways: false,
    errorbells: false,
    expandtab: true, -- convert tabs to spaces
    fillchars: (option)-> option\append({ stl: ' ', stlnc: ' ', vert: '▕', fold: '⣿', eob: ' ', diff: '⣿', msgsep: '‾', foldopen: '▾', foldsep: '│', foldclose: '▸' }),
    fileencoding: 'utf-8', -- the encoding written to a file
    fileformats: {'unix', 'mac', 'dos'},
    formatoptions: {
      ['1']: true,
      ['2']: false, -- Use indent from 2nd line of a paragraph
      a: false, -- Auto formatting is BAD.
      c: true, -- Auto-wrap comments using textwidth
      j: true, -- remove a comment leader when joining lines.
      l: true, -- Only break if the line was not longer than 'textwidth' when the insert -- started and only at a white character that has been entered during the -- current insert command.
      n: true, -- Recognize numbered lists
      o: true, -- Automatically insert the current comment leader after hitting 'o' or 'O'
      q: true, -- continue comments with gq'
      r: true, -- Continue comments when pressing Enter
      t: false, -- autowrap lines using text width value
      v: false
    },
    hidden: true, -- required to keep multiple buffers and open multiple buffers
    hlsearch: true, -- highlight all matches on previous search pattern
    ignorecase: true, -- ignore case in search patterns
    jumpoptions: 'stack',
    keymodel: 'startsel,stopsel',
    linebreak: true,
    list: true,
    --- [go, wo] Strings to use in 'list' mode and for the :list command.
    --- It is a comma-separated list of string settings.
    --- @see https://neovim.io/doc/user/options.html#'listchars'
    listchars: { space: '·', tab: '»·', trail: '·', eol: '↲' },
    magic: true,
    mouse: 'a', -- allow the mouse to be used in neovim
    mousefocus: true,
    mousemodel: 'extend',
    mousetime: 500,
    number: true, -- set numbered lines
    numberwidth: 3, -- set number column width to 2 {default 4}
    pumheight: 15, -- pop up menu height
    pumwidth: 20,
    redrawtime: 1500,
    relativenumber: false, -- set relative numbered lines
    ruler: false,
    scrolloff: 8, -- is one of my fav
    selection: 'inclusive',
    sessionoptions: {'globals', 'buffers', 'curdir', 'help', 'winpos'},
    shiftround: true,
    shiftwidth: 2, -- the number of spaces inserted for each indentation
    shortmess: {
      t: true, -- truncate file messages at start
      a: true, -- abbreviate messages
      A: true, -- ignore annoying swap file messages
      o: true, -- file-read message overwrites previous
      O: true, -- file-read message overwrites previous
      I: true, -- don't give the intro message when starting :intro
      s: true,
      c: true,
      W: true, -- Dont show [w] or written when writing
      T: true, -- truncate non-file messages in middle
      f: true, -- (file x of x) instead of just (x of x
      F: true, -- Don't give file info when editing a file, NOTE: this breaks autocommand messages
    },
    showcmd: true,
    -- https://neovim.io/doc/user/options.html#'showcmdloc'
    -- showcmdloc: 'statusline', -- display the (partially) entered command in another location: last -> Last line of the screen (default), statusline -> Status line of the current window, tabline ->	First line of the screen if 'showtabline' is enabled
    showmode: false, -- we don't need to see things like -- INSERT -- anymore
    showtabline: 0, -- always show tabs
    sidescrolloff: 8,
    signcolumn: 'auto:1', -- always show the sign column otherwise it would shift the text each time
    smartcase: true, -- smart case
    smartindent: true, -- make indenting smarter again
    smarttab: true,
    spell: false,
    spellcapcheck: '', -- don't check for capital letters at start of sentence
    spellfile: path.spellfile!,
    spelllang: 'en',
    spelloptions: 'camel',
    spellsuggest: (option)-> option\prepend {12},
    splitbelow: true, -- force all horizontal splits to go below current window
    splitright: true, -- force all vertical splits to go to the right of current window
    startofline: false,
    swapfile: false, -- creates a swapfile
    switchbuf: 'useopen,uselast',
    synmaxcol: 2500,
    tabstop: 2, -- insert 2 spaces for a tab
    termguicolors: true, -- set term gui colors (most terminals support this)
    textwidth: 72,
    timeout: true,
    timeoutlen: 500, -- time to wait for a mapped sequence to complete (in milliseconds)
    title: true, -- set the title of window to the value of the titlestring
    titlestring: '%<%F%=%l/%L - ', -- what the title of the window will be set to
    ttimeout: true,
    ttimeoutlen: 10,
    undofile: true, -- enable persistent undo
    undolevels: 1000,
    updatetime: 100, -- faster completion
    viewdir: path.view!,
    viewoptions: {'cursor', 'folds'}, -- save/restore just these (with `:{mk,load}view`)
    virtualedit: 'block,onemore', -- allow cursor to move where there is no text in visual block mode
    wildignore: {
      '*.hg',
      '*.svn',
      '*.aux',
      '*.out',
      '*.toc',
      '*.o',
      '*.obj',
      '*.dll',
      '*.jar',
      '*.pyc',
      '*.rbc',
      '*.class',
      '*.gif',
      '*.ico',
      '*.jpg',
      '*.jpeg',
      '*.png',
      '*.avi',
      '*.wav',
      '*.webm',
      '*.eot',
      '*.otf',
      '*.ttf',
      '*.woff',
      '*.doc',
      '*.pdf',
      '*.tar.gz',
      '*.tar.bz2',
      '*.rar',
      '*.tar.xz',
      '.sass-cache',
      '*/vendor/gems/*',
      '*/vendor/cache/*',
      '*/.bundle/*',
      '*.gem',
      '*.*~',
      '*~ ',
      '*.swp',
      '.lock',
      '*.DS_Stoe',
      '._*',
      'tags.lock',
      '**/node_modules/**',
      '**/bower_modules/**'
    },
    wrap: true, -- display lines as one long line
    wrapscan: true, -- Searches wrap around the end of the file
    writebackup: false -- files edited by another program are not allowed to be edited
  },
  --- Get or set options (like :set)
  --- Invalid key is an error
  --- It works on buffer|window scoped options using the current buffer/window
  --- @see https://neovim.io/doc/user/lua.html#vim.o
  --- @see https://neovim.io/doc/user/options.html#%3Aset
  o: {
    --- [g] Enables 24-bit RGB color in the TUI.  Uses "gui" :highlight attributes instead of "cterm" attributes. guifg
    --- Requires an ISO-8613-3 compatible terminal.
    --- @see https://neovim.io/doc/user/options.html#'backup'
    backup: false,

    --- [go] Options for Insert mode completion
    --- @see https://neovim.io/doc/user/options.html#'completeopt'
    completeopt: 'menuone,noinsert,noselect',

    --- [g] Enables 24-bit RGB color in the TUI.  Uses "gui" :highlight attributes instead of "cterm" attributes. guifg
    --- Requires an ISO-8613-3 compatible terminal.
    --- @see https://neovim.io/doc/user/options.html#'errorbells'
    errorbells: false,

    --- [bo] Do not converts tabs to spaces - don't use actual tab character (ctrl-v)
    --- @see https://neovim.io/doc/user/options.html#'expandtab'
    expandtab: true,

    --- [go] Whether enable background buffer when it is abandoned
    --- @see https://neovim.io/doc/user/options.html#'hidden'
    hidden: true,

    --- [go] Highlight match while typing search pattern
    --- @see https://neovim.io/doc/user/options.html#'incsearch'
    incsearch: true,

    --- [bo] -- number of spaces to use for each step of (auto)indent
    --- @see https://neovim.io/doc/user/options.html#'shiftwidth'
    shiftwidth: 2,

    --- [go] Show current mode on status line
    --- @see https://neovim.io/doc/user/options.html#'showmode'
    showmode: false,

    --- [go] Override the 'ignorecase' option if the search pattern contains upper case characters.
    --- @see https://neovim.io/doc/user/options.html#'smartcase'
    smartcase: true,

    --- [bo] uses 'shiftwidth' counts for while performing editing operations, like inserting a <Tab> or using <BS>. This is useful to keep the 'ts' setting at its standard value of 8, while being able to edit like it is set to 'sts'.
    --- @see https://neovim.io/doc/user/options.html#'softtabstop'
    softtabstop: -1,

    --- [g] Enables 24-bit RGB color in the TUI.  Uses "gui" :highlight attributes instead of "cterm" attributes. guifg
    --- Requires an ISO-8613-3 compatible terminal.
    --- @see https://neovim.io/doc/user/options.html#'syntax'
    syntax: 'on',

    --- [g] Enables 24-bit RGB color in the TUI.  Uses "gui" :highlight attributes instead of "cterm" attributes. guifg
    --- Requires an ISO-8613-3 compatible terminal.
    --- @see https://neovim.io/doc/user/options.html#'termguicolors'
    termguicolors: true,

    --- [go] Where to store undo files
    --- @see https://neovim.io/doc/user/options.html#'undodir'
    undodir: path.undo!,

    --- [bo] automatically saves undo history to an undo file when writing a buffer to a file, and restores undo history from the same file on buffer read
    --- @see https://neovim.io/doc/user/options.html#'undofile'
    undofile: true,
  },
  --- Get or set global options (like :setglobal)
  --- It only accesses the global value of a global-local option (unlike vim.o)
  --- It is mostly useful for use with global-local options.
  --- @see https://neovim.io/doc/user/lua.html#vim.go
  --- @see https://neovim.io/doc/user/options.html#%3Asetglobal
  go: {
    --- [go] Keep backup file after overwriting a file
    --- @see https://neovim.io/doc/user/options.html#'backup'
    backup: false,

    --- [go] List of directories for the backup file
    --- @see https://neovim.io/doc/user/options.html#'backupdir'
    backupdir: path.backup!,

    --- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
    --- @see https://neovim.io/doc/user/options.html#'cmdheight'
    cmdheight: 1,

    --- [go] Lines for the command-line window
    --- @see https://neovim.io/doc/user/options.html#'cmdwinheight'
    cmdwinheight: 2,

    --- [go] Options for Insert mode completion
    --- @see https://neovim.io/doc/user/options.html#'completeopt'
    completeopt: 'menuone,noinsert,noselect',

    --- [go] List of directory names for the swap file
    --- @see https://neovim.io/doc/user/options.html#'directory'
    directory: path.swap!,

    --- [go] List of flags for how to display text
    --- @see https://neovim.io/doc/user/options.html#'display'
    display: 'lastline,msgsep',

    --- [go] When on all Unicode emoji characters are considered to be full width
    --- @see https://neovim.io/doc/user/options.html#'emoji'
    emoji: true,

    --- [go] Windows are automatically made the same size
    --- @see https://neovim.io/doc/user/options.html#'equalalways'
    equalalways: false,

    --- [go] Automatically detected values for 'fileformat'
    --- @see https://neovim.io/doc/user/options.html#'fileformats'
    fileformats: 'unix,mac,dos',

    --- [go] Fold level when starting to edit a file
    --- @see https://neovim.io/doc/user/options.html#'foldlevelstart'
    foldlevelstart: 10,

    --- [go, bo] Program to use for the :grep command.
    --- @see https://neovim.io/doc/user/options.html#'grepprg'
    grepprg: 'rg --hidden --vimgrep --smart-case --',

    --- [go] Whether enable background buffer when it is abandoned
    --- @see https://neovim.io/doc/user/options.html#'hidden'
    hidden: true,

    --- [go] Number of command-lines that are remembered
    --- @see https://neovim.io/doc/user/options.html#'history'
    history: 10000,

    --- [go] Highlight matches with last search pattern
    --- @see https://neovim.io/doc/user/options.html#'hlsearch'
    hlsearch: true,

    --- [go] Ignore case in search patterns and in the tags file.
    --- @see https://neovim.io/doc/user/options.html#'ignorecase'
    ignorecase: true,

    --- [go] (nosplit|split) When nonempty, shows the effects of :substitute, :smagic, :snomagic and user commands with the :command-preview flag as you type.
    --- @see https://neovim.io/doc/user/options.html#'inccommand'
    inccommand: 'nosplit',

    --- [go] Highlight match while typing search pattern
    --- @see https://neovim.io/doc/user/options.html#'incsearch'
    incsearch: true,

    --- [go] Whether to join two spaces after a period with a join command
    --- @see https://neovim.io/doc/user/options.html#'joinspaces'
    joinspaces: false,

    --- [go] Specifies how jumping is done. [stack: like a web browser]
    --- @see https://neovim.io/doc/user/options.html#'jumpoptions'
    jumpoptions: 'stack',

    --- [go] Using cursor keys stops selection.
    --- @see https://neovim.io/doc/user/options.html#'keymodel'
    keymodel: 'startsel,stopsel',

    --- [go] Tells when last window has status lines
    --- @see https://neovim.io/doc/user/options.html#'laststatus'
    laststatus: 2,

    --- [go] Changes special characters in search patterns (extended regular expressions)
    --- @see https://neovim.io/doc/user/options.html#'magic'
    magic: true,

    --- [go] Enable the use of mouse clicks
    --- n: Normal mode | v: Visual mode | i: Insert mode | c: Command-line mode | h: all previous modes when editing a help file | a: all previous modes | r: for hit-enter and more-prompt prompt
    --- @see https://neovim.io/doc/user/options.html#'mouse'
    mouse: 'a',

    --- [go] The window that the mouse pointer is on is automatically activated.
    --- When changing the window layout or window focus in another way,
    --- the mouse pointer is moved to the window with keyboard focus.
    --- @see https://neovim.io/doc/user/options.html#'mousefocus'
    mousefocus: true,

    --- [go] Right mouse button extends a selection - like in an xterm.
    --- @see https://neovim.io/doc/user/options.html#'mousemodel'
    mousemodel: 'extend',

    --- [go] Max time in msec between two mouse clicks for the second click to be recognized as a multi click
    --- @see https://neovim.io/doc/user/options.html#'mousetime'
    mousetime: 500,

    --- [go] Max number of items to show in the popup menu
    --- @see https://neovim.io/doc/user/options.html#'pumheight'
    pumheight: 15,

    --- [go] Timeout for 'hlsearch' and :match highlighting
    --- @see https://neovim.io/doc/user/options.html#'redrawtime'
    redrawtime: 1500,

    --- [go] Show cursor line and column in the status line
    --- @see https://neovim.io/doc/user/options.html#'ruler'
    ruler: false,

    --- [go, wo] Minimum nr. of lines above and below cursor
    --- @see https://neovim.io/doc/user/options.html#'scrolloff'
    scrolloff: 5,

    --- [go] This option defines the behavior of the selection - Visual and Select modes
    --- @see https://neovim.io/doc/user/options.html#'selection'
    selection: 'inclusive',

    --- [go] Use .shada file upon startup and exiting - preserve jump history
    --- @see https://neovim.io/doc/user/options.html#'shada'
    shada: [[!,'300,<50,@100,s10,h]],

    --- [go] Rounds indent to multiple of 'shiftwidth' (applies to > and < cmds)
    --- @see https://neovim.io/doc/user/options.html#'shiftround'
    shiftround: true,

    --- [go] List of flags, reduce length of messages (default: filnxtToOF )
    --- @see https://neovim.io/doc/user/options.html#'shortmess'
    shortmess: 'Tfnwx',

    --- [go] Show (partial) command in status line
    --- @see https://neovim.io/doc/user/options.html#'showcmd'
    showcmd: true,

    -- [go] Display the (partially) entered command in another location
    -- https://neovim.io/doc/user/options.html#'showcmdloc'
    -- showcmdloc: 'statusline', -- last -> Last line of the screen (default), statusline -> Status line of the current window, tabline ->	First line of the screen if 'showtabline' is enabled

    --- [go] Show current mode on status line
    --- @see https://neovim.io/doc/user/options.html#'showmode'
    showmode: false,

    --- [go] Tells when the tab pages line is displayed
    --- @see https://neovim.io/doc/user/options.html#'showtabline'
    showtabline: 1,

    --- [go] Override the 'ignorecase' option if the search pattern contains upper case characters.
    --- @see https://neovim.io/doc/user/options.html#'smartcase'
    smartcase: true,

    --- [go] Use 'shiftwidth' when inserting <Tab>
    --- @see https://neovim.io/doc/user/options.html#'smarttab'
    smarttab: true,

    --- [go] New window from split is below the current one
    --- @see https://neovim.io/doc/user/options.html#'splitbelow'
    splitbelow: true,

    --- [go] New window is put right of the current one
    --- @see https://neovim.io/doc/user/options.html#'splitright'
    splitright: true,

    --- [go] Commands move cursor to first non-blank in line
    --- @see https://neovim.io/doc/user/options.html#'startofline'
    startofline: false,

    --- [go] Sets behavior when switching to another buffer
    --- @see https://neovim.io/doc/user/options.html#'switchbuf'
    switchbuf: 'useopen',

    --- [go] Then it will wait <timeoutlen> for keys that may follow <c-f>.
    --- @see https://neovim.io/doc/user/options.html#'timeout'
    timeout: true,

    --- [go] Let Vim set the title of the window
    --- @see https://neovim.io/doc/user/options.html#'timeoutlen'
    timeoutlen: 500,

    --- [go] Time out time in milliseconds
    --- @see https://neovim.io/doc/user/options.html#'ttimeout'
    ttimeout: true,

    --- [go] Percentage of 'columns' used for window title
    --- @see https://neovim.io/doc/user/options.html#'ttimeoutlen'
    ttimeoutlen: 10,

    --- [go] Where to store undo files
    --- @see https://neovim.io/doc/user/options.html#'undodir'
    undodir: path.undo!,

    --- [go] After this many milliseconds flush swap file
    --- @see https://neovim.io/doc/user/options.html#'updatetime'
    updatetime: 300,

    --- [go] Directory where to store files with :mkview
    --- @see https://neovim.io/doc/user/options.html#'viewdir'
    viewdir: path.view!,

    --- [go, wo] Allows the cursor can be positioned where there is no actual character
    --- @see https://neovim.io/doc/user/options.html#'virtualedit'
    --- @example 'block':> Allow virtual editing in Visual block mode
    --- @example 'insert':> Allow virtual editing in Insert mode
    --- @example 'all':> Allow virtual editing in all modes
    --- @example 'onemore':> allow one more character for blockwise selection
    --- @example 'none':> When used as local value, do not allow virtual editing even when the global value is set.
    --- @example 'none':> When used as global value is the same as "".
    virtualedit: 'block,onemore',

    --- [go] Allow specified keys to cross line boundaries
    --- @see https://neovim.io/doc/user/options.html#'whichwrap'
    whichwrap: 'h,l,<,>,[,],~',

    --- [go] Ignore case when completing file names
    --- @see https://neovim.io/doc/user/options.html#'wildignorecase'
    wildignorecase: true,

    --- [go] Searches wrap around the end of the file
    --- @see https://neovim.io/doc/user/options.html#'wrapscan'
    wrapscan: true,

    --- [go] Make a backup before overwriting a file
    --- @see https://neovim.io/doc/user/options.html#'writebackup'
    writebackup: true,
  },
  --- Get or set buffer-scoped options for the buffer with number. (like both :set and :setlocal)
  --- If [{bufnr}] is omitted then the current buffer is used.
  --- If {bufnr} or key is invalid is an error.
  --- @see https://neovim.io/doc/user/lua.html#vim.bo
  --- @see https://neovim.io/doc/user/options.html#global-local
  bo: {
    --- [bo] Copy indent from current line when starting a new line
    --- typing <CR> in Insert mode or when using the "o" or "O" command.
    --- @see https://neovim.io/doc/user/options.html#'autoindent'
    autoindent: true,

    --- [bo] enables automatic C program indenting
    --- @see https://neovim.io/doc/user/options.html#'cindent'
    cindent: false,

    --- [bo] Do not converts tabs to spaces - don't use actual tab character (ctrl-v)
    --- @see https://neovim.io/doc/user/options.html#'expandtab'
    expandtab: true,

    --- [bo] Automatically detected character encodings
    --- @see https://neovim.io/doc/user/options.html#'fileencoding'
    fileencoding: 'utf-8',

    --- [bo] a sequence of letters which describes how automatic formatting is to be done
    --- @see https://neovim.io/doc/user/options.html#'formatoptions'
    formatoptions: '1jcroqlj',

    --- [bo] -- number of spaces to use for each step of (auto)indent
    --- @see https://neovim.io/doc/user/options.html#'shiftwidth'
    shiftwidth: 2,

    --- [bo] The indentation is done according to the previous line
    --- @see https://neovim.io/doc/user/options.html#'smartindent'
    smartindent: true,

    --- [bo] uses 'shiftwidth' counts for while performing editing operations, like inserting a <Tab> or using <BS>. This is useful to keep the 'ts' setting at its standard value of 8, while being able to edit like it is set to 'sts'.
    --- @see https://neovim.io/doc/user/options.html#'softtabstop'
    softtabstop: -1,

    --- [bo] Name of the word list file where words are added for the zg and zw commands.
    --- @see https://neovim.io/doc/user/options.html#'spellfile'
    spellfile: path.spellfile!,

    --- [bo] A comma-separated list of word list names for when the 'spell' is on.
    --- @see https://neovim.io/doc/user/options.html#'spelllang'
    --- @example set spelllang=en_us,nl,medical
    spelllang: 'en',

    --- [bo] Use a swapfile for the buffer.
    --- This option can be reset when a swapfile is not wanted for a specific buffer.
    --- @see https://neovim.io/doc/user/options.html#'swapfile'
    swapfile: false,

    --- [bo] maximum column in which to search for syntax items
    --- @see https://neovim.io/doc/user/options.html#'synmaxcol'
    synmaxcol: 2500,

    --- [bo] Number of spaces that a <Tab> in the file counts for
    --- @see https://neovim.io/doc/user/options.html#'tabstop'
    tabstop: 2,

    --- [bo] Maximum width of text that is being inserted.
    --- A longer line will be broken after white space to get this width.
    --- @see https://neovim.io/doc/user/options.html#'textwidth'
    textwidth: 72,

    --- [bo] Maximum number of changes that can be undone.
    --- @see https://neovim.io/doc/user/options.html#'undolevels'
    undolevels: 1000,

    --- [bo] automatically saves undo history to an undo file when writing a buffer to a file, and restores undo history from the same file on buffer read
    --- @see https://neovim.io/doc/user/options.html#'undofile'
    undofile: true,

    --- [go] Show current mode on status line
    --- @see https://neovim.io/doc/user/options.html#'showmode'
    showmode: false
  },
  --- Get or set window-scoped options for the window with number. (like :set)
  --- If [{winid}] is omitted then the current window is used.
  --- If [{winid}] is omitted then the current window is used.
  --- If {winid} or key is invalid is an error.
  --- It does not access local-options (:setlocal)
  --- @see https://neovim.io/doc/user/lua.html#vim.wo
  wo: {
    --- [wo] Every wrapped line will continue visually indented
    --- @see https://neovim.io/doc/user/options.html#'breakindent'
    breakindent: true,

    --- [wo] Indent wrapped lines by 2 spaces, but not less than 20 spaces
    --- @see https://neovim.io/doc/user/options.html#'breakindentopt'
    breakindentopt: 'shift:2,min:20',

    --- [wo] colour the 81st (or 73rd) column so that we don’t type over our limit
    --- @see https://neovim.io/doc/user/options.html#'colorcolumn'
    colorcolumn: '+1',

    --- [wo] sets the modes in which text in the cursor line can also be concealed
    --- @see https://neovim.io/doc/user/options.html#'concealcursor'
    concealcursor: 'niv',

    --- [wo] determine how text with the "conceal" syntax attribute is shown - so that I can see `` in markdown files
    --- @see https://neovim.io/doc/user/options.html#'conceallevel'
    conceallevel: 0,

    --- [wo] Highlight the screen line of the cursor
    --- @see https://neovim.io/doc/user/options.html#'cursorline'
    cursorline: false,

    --- [wo] when off, all folds are open
    --- @see https://neovim.io/doc/user/options.html#'foldenable'
    foldenable: true,

    --- [wo] Enable list mode - show <Tab> and <EOL>
    --- @see https://neovim.io/doc/user/options.html#'list'
    list: true,

    --- [wo] show line numbers
    --- @see https://neovim.io/doc/user/options.html#'number'
    number: true,

    --- [wo] minimal number of columns to use for the line number.
    --- @see https://neovim.io/doc/user/options.html#'numberwidth'
    numberwidth: 3,

    --- [wo] show line numbers relative to the current line
    --- @see https://neovim.io/doc/user/options.html#'relativenumber'
    relativenumber: false,

    --- [wo] always show the signcolumn, otherwise it would shift the text each time
    --- @see https://neovim.io/doc/user/options.html#'signcolumn'
    signcolumn: 'auto:1',

    --- [go, wo] Minimum nr. of lines above and below cursor
    --- @see https://neovim.io/doc/user/options.html#'scrolloff'
    scrolloff: 5,

    --- [wo] Wrap long lines at a blank
    --- @see https://neovim.io/doc/user/options.html#'linebreak'
    linebreak: true,

    --- [wo] This option changes how text is displayed.
    --- It doesn't change the text in the buffer, see 'textwidth' for that.
    --- @see https://neovim.io/doc/user/options.html#'wrap'
    wrap: false,

    --- [go, wo] Allows the cursor can be positioned where there is no actual character
    --- @see https://neovim.io/doc/user/options.html#'virtualedit'
    --- @example 'block':> Allow virtual editing in Visual block mode
    --- @example 'insert':> Allow virtual editing in Insert mode
    --- @example 'all':> Allow virtual editing in all modes
    --- @example 'onemore':> allow one more character for blockwise selection
    --- @example 'none':> When used as local value, do not allow virtual editing even when the global value is set.
    --- @example 'none':> When used as global value is the same as "".
    virtualedit: 'block,onemore',

    --- [go] Show current mode on status line
    --- @see https://neovim.io/doc/user/options.html#'showmode'
    showmode: false
  },
  --- Tabpage-scoped variables for the current tabpage.
  --- It is deleted when the tab page is closed. Invalid or unset key returns nil.
  --- Can be indexed with an integer to access variables for a specific tabpage.
  --- @see https://neovim.io/doc/user/lua.html#vim.t
  --- @see https://neovim.io/doc/user/eval.html#t%3A
  t: {
    --- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
    --- @see https://neovim.io/doc/user/options.html#'cmdheight'
    cmdheight: 1
  }
}

for ctx, values in pairs(options)
  for option, value in pairs(values)
    if value
      if type(value) == 'function'
        value(vim[ctx][option])
      else
        vim[ctx][option] = value
