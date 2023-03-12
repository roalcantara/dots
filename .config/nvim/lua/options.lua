local options = {
  g = {
    mapleader = ' ',
    maplocalleader = [[\\]],
    loaded_2html_plugin = 1,
    loaded_getscript = 1,
    loaded_getscriptPlugin = 1,
    loaded_gzip = 1,
    loaded_logipat = 1,
    loaded_matchit = 1,
    loaded_netrw = 1,
    loaded_netrwFileHandlers = 1,
    loaded_netrwPlugin = 1,
    loaded_netrwSettings = 1,
    loaded_rrhelper = 1,
    loaded_spellfile_plugin = 1,
    loaded_tar = 1,
    loaded_tarPlugin = 1,
    loaded_vimball = 1,
    loaded_vimballPlugin = 1,
    loaded_zip = 1,
    loaded_zipPlugin = 1,
    did_load_filetypes = 1,
    zsh_fold_enable = 1,
    vimsyn_embed = 'lPr',
    clipboard = require('fn/clipboard'),
    ts_highlight_lua = true,
    global_symbol_padding = '  ',
    python3_host_prog = '/usr/local/bin/python3',
    ruby_host_prog = '/usr/local/opt/ruby/bin/neovim-ruby-host',
    node_host_prog = '~/.local/bin/node_modules/neovim',
    loaded_perl_provider = 0,
    colorscheme = 'tokyonight',
  },
  opt = {
    backup = false, -- creates a backup file
    clipboard = 'unnamedplus', -- allows neovim to access the system clipboard
    cmdheight = 1, -- more space in the neovim command line for displaying messages
    conceallevel = 0, -- so that `` is visible in markdown files
    fileencoding = 'utf-8', -- the encoding written to a file
    foldmethod = 'manual', -- folding, set to "expr" for treesitter based folding
    foldexpr = '', -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
    guifont = 'monospace:h17', -- the font used in graphical neovim applications
    hidden = true, -- required to keep multiple buffers and open multiple buffers
    ignorecase = true, -- ignore case in search patterns
    mouse = 'a', -- allow the mouse to be used in neovim
    pumheight = 10, -- pop up menu height
    showmode = false, -- we don't need to see things like -- INSERT -- anymore
    smartcase = true, -- smart case
    splitbelow = true, -- force all horizontal splits to go below current window
    splitright = true, -- force all vertical splits to go to the right of current window
    swapfile = false, -- creates a swapfile
    termguicolors = true, -- set term gui colors (most terminals support this)
    timeoutlen = 1000, -- time to wait for a mapped sequence to complete (in milliseconds)
    title = true, -- set the title of window to the value of the titlestring
    undodir = undodir, -- set an undo directory
    undofile = true, -- enable persistent undo
    updatetime = 100, -- faster completion
    writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
    expandtab = true, -- convert tabs to spaces
    shiftwidth = 2, -- the number of spaces inserted for each indentation
    tabstop = 2, -- insert 2 spaces for a tab
    cursorline = true, -- highlight the current line
    number = true, -- set numbered lines
    numberwidth = 4, -- set number column width to 2 {default 4}
    signcolumn = 'yes', -- always show the sign column, otherwise it would shift the text each time
    wrap = false, -- display lines as one long line
    scrolloff = 8, -- minimal number of screen lines to keep above and below the cursor.
    sidescrolloff = 8, -- minimal number of screen lines to keep left and right of the cursor.
    showcmd = false,
    ruler = false,
    laststatus = 3,

    -- completions
    hlsearch = true, -- highlight all matches on previous search pattern
    whichwrap = 'b,s,<,>,[,],~', -- [strg] (b,s) allow specified keys to cross line boundaries https://neovim.io/doc/user/options.html#'whichwrap'
    wildmenu = true, -- command-line completion operates in an enhanced mode
    wildmode = 'list:full',
    wildignorecase = true, -- ignored when completing file names and directories
    wildignore = {
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
      '**/bower_modules/**',
    },
  },
}

for ctx, values in pairs(options) do
  for option, value in pairs(values) do
    if type(value) == 'function' then
      value(vim[ctx][option])
    else
      vim[ctx][option] = value
    end
  end
end
