-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- set script encoding
vim.scriptencoding = 'utf-8'

-- Add any additional options here
--- **SEE:** https://neovim.io/doc/user/options.html
local options = {
  --- Set Buffer-scoped variables (`vim.b:`) for the current buffer. Invalid or unset key returns nil.
  --- Can be indexed with an integer to access variables for a specific buffer.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.b
  b = {},
  --- Set Window-scoped variables (`vim.w:`) for the current window. Invalid or unset key returns nil.
  --- Can be indexed with an integer to access variables for a specific window.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.w
  w = {},
  --- Set Tabpage-scoped variables (`vim.t:`) for the current tabpage. Invalid or unset key returns nil.
  --- Can be indexed with an integer to access variables for a specific tabpage.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.t
  t = {},
  --- Set global editor variables (`vim.g:`). Key with no value returns nil.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.g
  g = {},
  --- Set VIM variables (`vim.v:`). Invalid or unset key returns nil.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.v
  v = {},
  --- Set options (`:set`). Buffer/window-scoped options target the current buffer/window. Invalid key is an error.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.o
  o = {},
  --- Set global and buffer-scoped options for the current tab page (`:set map-options`).
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.opt
  opt = {},
  --- Set global options (`:setglobal`).
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.go
  go = {},
  --- Set buffer-scoped options for the buffer with number _{bufnr}_ (`:setlocal`).
  --- If _{bufnr}_ is omitted then the current buffer is used. Invalid _{bufnr}_ or key is an error.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.bo
  bo = {},
  --- Set windows-scoped options for the window with handle _{winid}_ and buffer with number _{bufnr}_.
  --- Like `:setlocal` if setting a global-local option or if _{bufnr}_ is provided, like `:set` otherw ise.
  --- **SEE:** https://neovim.io/doc/user/lua.html#vim.wo
  wo = {},
}

-- When running without a GUI
if #vim.api.nvim_list_uis() == 0 then
  options.g = {
    shortmess = '',   -- try to prevent echom from cutting messages off or prompting
    more = false,     -- don't pause listing when screen is filled
    cmdheight = 9999, -- helps avoiding |hit-enter| prompts.
    columns = 9999,   -- set the widest screen possible
    swapfile = false, -- don't use a swap file
  }
else
  options.g = {
    have_nerd_fonts = true,                    -- [go] Whether the system has Nerd Fonts installed
    deprecation_warnings = true,               -- enable deprecation warnings
    loaded_perl_provider = 0,                  -- disable perl provider
    cmdwinheight = 7,                          -- [go] Number of lines to use for the command-line window
    suffixes = '.bak,~,.o,.h,.info,.swp,.obj', -- [go] List of file suffixes to add to the 'wildignore' list
    python3_host_prog = 'v:lua.require("core/etc/paths").bin_for_python3_venv()',
  }
  options.o = {
    -- Search and Completion
    hlsearch = true,    -- When there is a previous search pattern, highlight all its matches
    breakindent = true, -- [wo] Every wrapped line will continue visually indented
    timeout = true,     -- [go] This option and 'timeoutlen' determine the behavior when part of a mapped key sequence has been received
    incsearch = true,   -- [go] Highlight match while typing search pattern

    -- Folds
    foldcolumn = '1',    -- '0' is not bad
    foldlevelstart = 99, -- Start unfolded
    foldenable = true,   -- Enable folds by default

    -- Editor UI
    background = 'dark',       -- [bo] Set background
    guifont = 'JetBrainsMonoNL Nerd Font:h16',
    showtabline = 0,           -- [go] Tells when the tab pages line is displayed => 0: never, 2: always, 1: only if there are at least two tab pages
    cmdheight = 0,             -- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
    showcmdloc = 'statusline', -- Show cmd in the statusline (https://github.com/nvim-lualine/lualine.nvim/issues/949)

    -- Line Display
    numberwidth = 3,    -- [wo] minimal number of columns to use for the line number {default 4}
    colorcolumn = '+1', -- [wo] colour the 81st (or 73rd) column so that we don`t type over our limit

    -- Text Editing
    autoindent = true,     -- [bo] Copy indent from current line when starting a new line
    smarttab = true,       -- [go] Use 'shiftwidth' when inserting <Tab>
    softtabstop = 2,       -- [bo] uses 'shiftwidth' counts for while performing editing operations
    textwidth = 72,        -- [bo] Maximum width of text that is being inserted
    preserveindent = true, -- [bo] Preserve the indent structure of the file

    -- Menus
    pumheight = 25,        -- [bo] Maximum number of entries in a popup
    wildignorecase = true, -- [go] ignored when completing file names and directories
    wildmenu = true,       -- command-line completion operates in an enhanced modes

    -- File Handling
    encoding = 'utf-8',     -- [bo] The encoding used inside the buffer
    fileencoding = 'utf-8', -- [bo] The encoding written to file
    swapfile = false,       -- [bo] Use a swapfile for the buffer.
    modeline = true,        -- [go] Enable modeline
    writebackup = false,    -- [bo] If a file is being edited by another program (or was written to a file) while you are editing it, it is still being saved and will be updated when you are done
    autoread = true,        -- [bo] If a file is changed outside of Neovim and you haven't changed it, automatically read it again.

    -- Mouse | https://neovim.io/doc/user/options.html#'mousem'
    mousemodel = 'extend', -- Enables all mouse features including: 1. Right click opens a menu, 2. Shift + left click extends selection, 3. Right drag extends selection

    -- https://neovim.io/doc/user/options.html#'winborder'
    winborder = 'rounded', -- [go] Border style for floating windows and popup menus
  }
  options.opt = {
    wildignore = { -- [go] Allow specified keys to cross line boundaries
      '._*',
      '.lock',
      '.sass-cache',
      '*.*~',
      '*.aux',
      '*.avi',
      '*.class',
      '*.dll',
      '*.doc',
      '*.DS_Stoe',
      '*.eot',
      '*.gem',
      '*.gif',
      '*.hg',
      '*.ico',
      '*.jar',
      '*.jpeg',
      '*.jpg',
      '*.o',
      '*.obj',
      '*.otf',
      '*.out',
      '*.pdf',
      '*.png',
      '*.pyc',
      '*.rar',
      '*.rbc',
      '*.svn',
      '*.swp',
      '*.tar.bz2',
      '*.tar.gz',
      '*.tar.xz',
      '*.toc',
      '*.ttf',
      '*.wav',
      '*.webm',
      '*.woff',
      '**/bower_modules/**',
      '**/node_modules/**',
      '*/.bundle/*',
      '*/vendor/cache/*',
      '*/vendor/gems/*',
      '*~ ',
      'tags.lock',
    },
    -- save/restore just these (with `:{mk,load}view`)
    viewoptions = {
      'cursor',
      'folds',
    },
    -- A list of file patterns that specify files to be skipped
    backupskip = {
      '/tmp/*',         -- skip all files in /tmp
      '/private/tmp/*', -- skip all files in /private/tmp
    },
    -- Influences the working of <BS>, <Del>, CTRL-W and CTRL-U in Insert mode.
    backspace = {
      'start',  -- allow backspacing over the start of insert; CTRL-W and CTRL-U
      'eol',    -- allow backspacing over line breaks (join lines)
      'indent', -- allow backspacing over autoindent
      -- 'stop'                     -- once at the start of insert
      -- 'nostop'                   -- like start, except CTRL-W and CTRL-U do not stop at the start of insert
    },
    pumheight = 25, -- [bo] Maximum number of entries in a popup
    -- scrolloff = 8, -- [go, wo] Minimum nr. of lines above and below cursor

    vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end), -- [go] Use the system clipboard for all yank, delete, change and put operations

    ignorecase = true, -- [go] Ignore case in search patterns
    smartcase  = true, -- [go] Override 'ignorecase' if the search pattern contains upper case characters
    signcolumn = 'yes', -- [wo] Always show the sign column, even if there are no signs
    updatetime = 250, -- [go] Time in milliseconds to wait before triggering the 'updatetime' event
    timeoutlen = 300, -- [go] Time in milliseconds to wait for a mapped sequence to complete
    splitright = true, -- [go] Force all vertical splits to be to the right of the current windows
    splitbelow = true, -- [go] Force all horizontal splits to be below the current windows
    list       = false, -- [go] Show whitespace characters in the buffering
    listchars  = { -- [go] Characters used to show whitespace characters in the buffer
      tab = '▸ ', -- Tab character
      trail = '·', -- Trailing spaces
      extends = '›', -- Character used to indicate that there is more text to the right
      precedes = '‹', -- Character used to indicate that there is more text to the left
      nbsp = '␣', -- Non-breaking space character
    },
    inccommand = 'split', -- [go] When using the command line, split the screen only when necessary
    cursorline = true, -- [wo] Highlight the line under the cursor
    scrolloff  = 10, -- [wo] Highlight the column under the cursor
    winborder  = 'rounded', -- [go] Border style for floating windows and popup menus
  }
  options.go = {
    emoji = true,                  -- [go] When on all Unicode emoji characters are considered to be full width
    equalalways = false,           -- [go] Windows are automatically made the same size
    switchbuf = 'useopen,uselast', -- [go] Sets behavior when switching to another buffer
    whichwrap = 'h,l,<,>,[,],~',   -- [go] Allow specified keys to cross line boundaries
    wildignorecase = true,         -- [go] Ignore case when completing file names
    wrapscan = true,               -- [go] Searches wrap around the end of the file
  }
end

for ctx, values in pairs(options) do
  for option, value in pairs(values) do
    if value then
      if type(value) == 'function' then
        value(vim[ctx][option])
      else
        vim[ctx][option] = value
      end
    end
  end
end

-- vim: ts=2 sts=2 sw=2 et
