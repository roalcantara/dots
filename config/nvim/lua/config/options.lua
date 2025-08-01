-- When running without a GUI
vim.g.ft_ignore_pat = '\\.\\(Z\\|gz\\|bz2\\|zip\\|tgz\\)$'
vim.g.have_nerd_fonts = true                    -- [go] Whether the system has Nerd Fonts installed
vim.g.cmdwinheight = 7                          -- [go] Number of lines to use for the command-line window
vim.g.suffixes = '.bak,~,.o,.h,.info,.swp,.obj' -- [go] List of file suffixes to add to the 'wildignore' list
vim.g.loaded_perl_provider = 0                  -- disable perl provider
vim.g.python3_host_prog = require('core/vi/paths').bin_for_python3_venv()

-- Disable deprecation warnings
-- https://lazyvim.org/news#11x
vim.g.deprecation_warnings = false

-- https://neovim.io/doc/user/insert.html#ft-ruby-omni
vim.g.rubycomplete_buffer_loading = 1
vim.g.rubycomplete_classes_in_global = 1
vim.g.rubycomplete_rails = 1

-- LSP Hover Configuration
vim.g.lsp_hover_mouse_delay = 1000            -- [go] Mouse hover delay in milliseconds for LSP hover documentation
vim.o.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard

-- Performance optimizations
vim.opt.lazyredraw = false                    -- Don't redraw while executing macros
vim.opt.ttyfast = true                        -- Faster terminal connection
vim.opt.updatetime = 100                      -- Save swap file and trigger CursorHold
vim.opt.timeoutlen = 300                      -- Lower than default (1000) to quickly trigger which-key
vim.opt.ttimeoutlen = 10                      -- Faster key code timeout

-- Search and Completion
vim.opt.incsearch = true                      -- [go] Highlight match while typing search pattern
vim.opt.hlsearch = true                       -- When there is a previous search pattern, highlight all its matches

-- Folds
vim.opt.foldenable = true                     -- Enable folds by default
vim.opt.foldcolumn = '1'                      -- '0' is not bad
vim.opt.foldlevelstart = 99                   -- Start unfolded

-- Editor UI
vim.opt.background = 'dark'                   -- [bo] Set background
vim.opt.showcmdloc = 'statusline'             -- Show cmd in the statusline (https://github.com/nvim-lualine/lualine.nvim/issues/949)
vim.opt.cmdheight = 0                         -- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
vim.opt.showtabline = 0                       -- [go] Tells when the tab pages line is displayed => 0: never, 2: always, 1: only if there are at least two tab pages
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.swapfile = false                      -- Don't use a swap file

-- Line Display
vim.opt.numberwidth = 3                       -- [wo] minimal number of columns to use for the line number {default 4}
vim.opt.colorcolumn = '+1'                    -- [wo] colour the 81st (or 73rd) column so that we don`t type over our limit

-- Text Editing
vim.opt.textwidth = 72                        -- [bo] Maximum width of text that is being inserted
vim.opt.autoindent = true                     -- [bo] Copy indent from current line when starting a new line
vim.opt.smarttab = true                       -- [go] Use 'shiftwidth' when inserting <Tab>
vim.opt.softtabstop = 2                       -- [bo] uses 'shiftwidth' counts for while performing editing operations
vim.opt.preserveindent = true                 -- [bo] Preserve the indent structure of the file
vim.opt.smartcase = true                      -- Don't ignore case with capitals
vim.opt.smartindent = true                    -- Insert indents automatically
vim.opt.ignorecase = true                     -- Ignore case
vim.opt.linebreak = true                      -- Wrap lines at convenient points
vim.opt.shiftround = true                     -- Round indent
vim.opt.shiftwidth = 2                        -- Size of an indent
vim.opt.tabstop = 2                           -- Number of spaces tabs count for

-- Menus
vim.opt.wildignorecase = true                 -- [go] ignored when completing file names and directories
vim.opt.wildmenu = true                       -- command-line completion operates in an enhanced modes
vim.opt.pumheight = 50                        -- [bo] Maximum number of entries in a popup
vim.opt.pumblend = 10                         -- Popup blend

-- File Handling
vim.opt.encoding = 'utf-8'                    -- [bo] The encoding used inside the buffer
vim.opt.modeline = true                       -- [go] Enable modeline

vim.opt.completeopt = 'menu,menuone,noselect' -- Completion options
vim.opt.expandtab = true                      -- Use spaces instead of tabs
vim.opt.foldlevel = 99                        -- Open all folds by default
vim.opt.grepformat = '%f:%l:%c:%m'            -- Format for grep results
vim.opt.grepprg = 'rg --vimgrep'              -- Use ripgrep for grep
vim.opt.inccommand = 'nosplit'                -- preview incremental substitute
vim.opt.jumpoptions = 'view'                  -- Jump to the position of the last edit
vim.opt.laststatus = 3                        -- global statusline
vim.opt.list = true                           -- Show some invisible characters (tabs...
vim.opt.mouse = 'a'                           -- Enable mouse mode
vim.opt.number = true                         -- Print line number
vim.opt.relativenumber = true                 -- Relative line numbers
vim.opt.showmode = false                      -- Dont show mode since we have a statusline
vim.opt.sidescrolloff = 8                     -- Columns of context
vim.opt.signcolumn = 'yes'                    -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.spelllang = { 'en' }                  -- Set spell checking language to English
vim.opt.spell = false                         -- Disable spell checking
vim.opt.splitbelow = true                     -- Put new windows below current
vim.opt.splitkeep = 'screen'                  -- Keep the screen position when splitting
vim.opt.splitright = true                     -- Put new windows right of current
vim.opt.termguicolors = true                  -- True color support
vim.opt.undofile = true                       -- Enable persistent undo
vim.opt.undolevels = 10000.                   -- Number of undos to keep
vim.opt.virtualedit = 'block'                 -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = 'longest:full,full'        -- Command-line completion mode
vim.opt.winborder = nil                       -- Rounded borders for windows
vim.opt.winminwidth = 5                       -- Minimum window width
vim.opt.wrap = false                          -- Disable line wrap
vim.opt.fillchars = {                         -- Customize fill characters
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
