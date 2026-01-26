local paths = require('core/vi/paths')

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- BASIC SETTINGS
vim.opt.encoding = 'UTF-8'    -- [bo] The encoding used inside the buffer
vim.opt.errorbells = false    -- Disable error sounds
vim.opt.modeline = true       -- [go] Enable modeline
vim.opt.ttyfast = true        -- Faster terminal connection
vim.opt.timeoutlen = 500      -- Time in ms to wait for mapped sequence. Lower than default (1000) to quickly trigger which-key
vim.opt.ttimeoutlen = 10      -- No wait for key code sequences. Faster key code timeout
vim.opt.lazyredraw = false    -- redraw while executing macros (butter UX)
vim.opt.modifiable = true     -- Allow editing buffers
vim.opt.redrawtime = 10000    -- Timeout for syntax highlighting redraw
vim.opt.maxmempattern = 20000 -- Max memory for pattern matching
vim.opt.spelllang = { 'en' }  -- Set language for spellchecking
vim.opt.spell = false         -- Disable spell checking
vim.opt.mouse = 'a'           -- Enable mouse support
vim.opt.autochdir = false     -- Don't change directory automatically
vim.opt.iskeyword:append('-') -- Treat dash as part of a word
vim.opt.jumpoptions = 'view'  -- Jump to the position of the last edit

-- CMD/PUM/WILD/COMPLETION SETTINGS
vim.opt.cmdheight = 0                             -- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
vim.opt.cmdwinheight = 7                          -- [go] Number of lines to use for the command-line window
vim.opt.pumblend = 10                             -- Popup menu transparency
vim.opt.pumheight = 50                            -- [bo] Maximum number of entries in a popup
vim.opt.wildmenu = true                           -- Enable command-line completion menu
vim.opt.wildignorecase = true                     -- Case-insensitive tab completion in commands
vim.opt.wildmode = 'longest:full,full'            -- Completion mode for command-line
vim.opt.completeopt = 'menuone,noinsert,noselect' -- Completion options ('menu,menuone,noselect')

-- MAIN UI/UX SETTINGS
vim.opt.termguicolors = true                                         -- Enable 24-bit colors
vim.opt.background = 'dark'                                          -- [bo] Set background
vim.opt.colorcolumn = '+1'                                           -- [wo] colour the 81st (or 73rd) column so that we don't type over our limit
vim.opt.laststatus = 3                                               -- Global statusline
vim.opt.showmode = false                                             -- Dont show mode since we have a statusline
vim.opt.showcmdloc = 'statusline'                                    -- Show cmd in the statusline (https://github.com/nvim-lualine/lualine.nvim/issues/949)
vim.opt.winblend = 0                                                 -- Floating window transparency
vim.opt.winborder = nil                                              -- No borders for windows
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true }) -- Shorten messages like warnings, infos, etc.
vim.opt.guicursor =
{                                                                    -- Cursor Settings (default "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor")
  'n-c-v:block-nCursor',                                             -- In Normal, Command-line and Visual mode, use a block cursor with colors from the "nCursor" highlight group
  'i-ci:ver30-iCursor-blinkwait300-blinkon200-blinkoff150',          -- In Insert and Command-line Insert mode, use a 30% vertical bar cursor with colors from the "iCursor" highlight group; Blink a bit faster.
  'r-cr:hor20',                                                      -- In Replace, Command-line Replace mode, use a horizontal cursor with colors from the "rCursor" highlight group
  'o:hor50',                                                         -- In Operator-pending mode, use a horizontal cursor with colors from the "o" highlight group
  't:block-blinkon500-blinkoff500-TermCursor',                       -- In Terminal mode, use a block cursor with colors from the "TermCursor" highlight group; Blink a bit faster.
  'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor',            -- In All modes: blinking & highlight groups, use a blinking cursor with colors from the "Cursor" highlight group and "lCursor" highlight group; Blink a bit faster.
  'sm:block-blinkwait175-blinkoff150-blinkon175',                    -- Showmatch mode
}

-- MAIN EDITOR SETTINGS
vim.opt.relativenumber = true          -- Relative line numbers with current line absolute
vim.opt.number = false                 -- Disable separate absolute numbers column
vim.opt.textwidth = 72                 -- [bo] Maximum width of text that is being inserted
vim.opt.virtualedit = 'block'          -- Allow cursor to move where there is no text in visual block mode
vim.opt.signcolumn = 'yes'             -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.backspace = 'indent,eol,start' -- Make backspace behave naturally
vim.opt.cursorline = false             -- Do not highlight current line

-- VISUAL SETTINGS
vim.opt.list = true        -- Show some invisible characters
vim.opt.wrap = false       -- Don't wrap lines
vim.opt.linebreak = true   -- Wrap lines at convenient points
vim.opt.concealcursor = '' -- Show markup even on cursor line
vim.opt.conceallevel = 0   -- Don't hide markup
vim.opt.matchtime = 2      -- How long to show matching bracket
vim.opt.synmaxcol = 300    -- Syntax highlighting column limit
vim.opt.scrolloff = 10     -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8  -- Keep 8 columns left/right of cursor
vim.opt.showtabline = 0    -- [go] Tells when the tab pages line is displayed => 0: never, 2: always, 1: only if there are at least two tab pages
vim.opt.winminwidth = 5    -- Minimum window width
vim.opt.numberwidth = 3    -- [wo] minimal number of columns to use for the line number {default 4}
vim.opt.fillchars = {      -- Customize fill characters
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
vim.opt.listchars = {
  tab = '» ',
  trail = '·',
  nbsp = '␣',
}

-- WINDOW SPLITTING SETTINGS
vim.opt.splitbelow = true    -- Put new windows below current
vim.opt.splitright = true    -- Put new windows right of current
vim.opt.splitkeep = 'screen' -- Keep the screen position when splitting

-- INDENTATION & TABBING
vim.opt.autoindent = true                                          -- [bo] Copy indent from current line when starting a new line
vim.opt.expandtab = true                                           -- Use spaces instead of tabs
vim.opt.preserveindent = true                                      -- [bo] Preserve the indent structure of the file
vim.opt.shiftround = true                                          -- Round indent
vim.opt.shiftwidth = 2                                             -- Indent width
vim.opt.smartindent = true                                         -- Insert indents automatically
vim.opt.smarttab = true                                            -- [go] Use 'shiftwidth' when inserting <Tab>
vim.opt.softtabstop = 2                                            -- [bo] uses 'shiftwidth' counts for while performing editing operations
vim.opt.tabstop = 2                                                -- Tab width
vim.opt.indentexpr =
"v:lua.require'nvim-treesitter'.indentexpr()"                      -- Use treesitter for indentation (https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file)

-- FOLDING SETTINGS
vim.opt.foldcolumn =
'0'                                                  -- When and how to draw the foldcolumn: "0": disable (GOOD!); "auto": resize to the minimum amount of folds to display; "auto:[1-9]": resize to accommodate multiple folds up to the selected level; "[1-9]": displays a fixed col numb
vim.opt.foldenable = true                            -- Enable folds by default
vim.opt.foldlevel = 99                               -- Keep all folds open by default
vim.opt.foldlevelstart = 99                          -- Start unfolded
vim.opt.foldminlines = 1                             -- Minimum number of lines for a fold
vim.opt.foldnestmax = 3                              -- Maximum fold depth
vim.opt.foldmethod = 'expr'                          -- Use expression for folding
vim.opt.foldexpr =
'v:lua.vim.treesitter.foldexpr()'                    -- Use treesitter for folding (https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#folding)

-- SEARCH/FIND/REPLACE/GREP/SELECTION SETTINGS
vim.opt.hlsearch = true            -- When there is a previous search pattern, highlight all its matches
vim.opt.showmatch = true           -- Highlight matching brackets
vim.opt.ignorecase = true          -- Case-insensitive search
vim.opt.incsearch = true           -- [go] Highlight match while typing search pattern
vim.opt.smartcase = true           -- Case-sensitive if uppercase in search
vim.opt.inccommand = 'nosplit'     -- preview incremental substitute
vim.opt.selection = 'inclusive'    -- Use inclusive selection
vim.opt.path:append('**')          -- Search into subfolders with `gf`
vim.opt.grepprg = 'rg --vimgrep'   -- Use ripgrep if available
vim.opt.grepformat = '%f:%l:%c:%m' -- filename, line number, column, content

-- FILE HANDLING SETTINGS
vim.opt.autoread = true                      -- Auto-reload file if changed outside
vim.opt.autowrite = false                    -- Don't auto-save on some events
vim.opt.backup = false                       -- Don't create backup files
vim.opt.swapfile = false                     -- Don't create swap files
vim.opt.updatetime = 300                     -- Time in ms to trigger CursorHold
vim.opt.writebackup = false                  -- Don't backup before overwriting
vim.opt.diffopt:append('vertical')           -- Vertical diff splits
vim.opt.diffopt:append('algorithm:patience') -- Better diff algorithm
vim.opt.diffopt:append('linematch:60')       -- Better diff highlighting (smart line matching)

-- UNDO SETTINGS
vim.opt.undofile = true                            -- Enable persistent undo
vim.opt.undolevels = 10000                         -- Number of undos to keep
vim.opt.undodir = paths.stdpaths.ensured.undodir() -- Set undo directory and ensure it exists

-- CLIPBOARD SETTINGS
-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  if vim.env.SSH_TTY then
    vim.opt.clipboard = ''
  elseif vim.fn.executable('xclip') == 1 then -- Try to use xclip first
    vim.opt.clipboard = {
      name = 'xclip',
      copy = { ['+'] = 'xclip -selection clipboard', ['*'] = 'xclip -selection primary' },
      paste = { ['+'] = 'xclip -selection clipboard -o', ['*'] = 'xclip -selection primary -o' },
      cache_enabled = 0,
    }
  elseif vim.fn.executable('xsel') == 1 then -- Try to use xsel as fallback
    vim.opt.clipboard = {
      name = 'xsel',
      copy = { ['+'] = 'xsel --clipboard --input', ['*'] = 'xsel --primary --input' },
      paste = { ['+'] = 'xsel --clipboard --output', ['*'] = 'xsel --primary --output' },
      cache_enabled = 0,
    }
  else -- Use system clipboard
    vim.opt.clipboard:append('unnamedplus')
  end
end)

-- GLOBAL LANGUAGE PROVIDERS | https://neovim.io/doc/user/provider.html
-- Although modern Neovim trend is moving away from provider-dependent plugins,
-- we keep them enabled for now to avoid breaking existing plugins.
vim.g.python3_host_prog = paths.bin_for_python3_venv() -- Python 3 host program (https://github.com/neovim/nvim-lspconfig/issues/2935)
vim.g.loaded_perl_provider = 0                         -- Disable perl provider
vim.g.rubycomplete_buffer_loading = 1                  -- Load classes in buffer
vim.g.rubycomplete_classes_in_global = 1               -- Load classes in global
vim.g.rubycomplete_rails = 1                           -- Load rails

-- GLOBAL LSP SETTINGS
vim.g.lsp_hover_mouse_delay = 1000 -- [go] Mouse hover delay in milliseconds for LSP hover documentation

-- GLOBAL GENERAL SETTINGS
vim.g.deprecation_warnings = false              -- Disable deprecation warnings | https://lazyvim.org/news#11x
vim.g.have_nerd_fonts = true                    -- [go] Whether the system has Nerd Fonts installed
vim.g.snacks_animate = false                    -- Disable snacks animation
vim.g.suffixes = '.bak,~,.o,.h,.info,.swp,.obj' -- [go] List of file suffixes to add to the 'wildignore' list
vim.g.ft_ignore_pat = '\\.\\(Z\\|gz\\|bz2\\|zip\\|tgz\\)$'
