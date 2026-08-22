-- `Neo` is a convenience global used from autocmd and plugin callbacks.
-- Resolve it on first access rather than at startup: eagerly requiring
-- core/neo here costs ~12ms before any plugin loads.
_G.Neo = setmetatable({}, {
  __index = function(_, key)
    local neo = require('core/neo')
    _G.Neo = neo
    return neo[key]
  end,
})

local paths = require('core/vi/paths')

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '                        -- LazyVim default: '\'

-- BASIC SETTINGS
vim.opt.timeoutlen = 500                          -- LazyVim default: 300
vim.opt.ttimeoutlen = 10      -- No wait for key code sequences. Faster key code timeout
vim.opt.redrawtime = 10000    -- Timeout for syntax highlighting redraw
vim.opt.maxmempattern = 20000 -- Max memory for pattern matching
vim.opt.spell = false         -- Disable spell checking
vim.opt.autochdir = false     -- Don't change directory automatically
vim.opt.iskeyword:append('-') -- Treat dash as part of a word

-- CMD/PUM/WILD/COMPLETION SETTINGS
vim.opt.cmdheight = 0                             -- [go, t] Number of screen lines to use for the command-line. Helps avoiding hit-enter prompts.
vim.opt.cmdwinheight = 7                          -- [go] Number of lines to use for the command-line window
vim.opt.pumheight = 50                            -- LazyVim default: 10
vim.opt.wildignorecase = true                     -- Case-insensitive tab completion in commands
vim.opt.wildmode = 'longest:full,full'            -- Completion mode for command-line
vim.opt.completeopt = 'menuone,noinsert,noselect' -- LazyVim default: 'menu,menuone,noselect'

-- MAIN UI/UX SETTINGS
vim.opt.background = 'dark'                                          -- [bo] Set background
vim.opt.colorcolumn = '+1'                                           -- [wo] colour the 81st (or 73rd) column so that we don't type over our limit
vim.opt.showcmdloc = 'statusline'                                    -- Show cmd in the statusline (https://github.com/nvim-lualine/lualine.nvim/issues/949)
vim.opt.winblend = 0                                                 -- Floating window transparency
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
vim.opt.number = false                            -- LazyVim default: true
vim.opt.textwidth = 72                 -- [bo] Maximum width of text that is being inserted
vim.opt.cursorline = false                        -- LazyVim default: true

-- VISUAL SETTINGS
vim.opt.concealcursor = '' -- Show markup even on cursor line
vim.opt.conceallevel = 0                          -- LazyVim default: 2
vim.opt.matchtime = 2      -- How long to show matching bracket
vim.opt.synmaxcol = 300    -- Syntax highlighting column limit
vim.opt.scrolloff = 10                            -- LazyVim default: 4
vim.opt.showtabline = 0    -- [go] Tells when the tab pages line is displayed => 0: never, 2: always, 1: only if there are at least two tab pages
vim.opt.numberwidth = 3    -- [wo] minimal number of columns to use for the line number {default 4}

-- WINDOW SPLITTING SETTINGS

-- INDENTATION & TABBING
vim.opt.autoindent = true                                          -- [bo] Copy indent from current line when starting a new line
vim.opt.preserveindent = true                                      -- [bo] Preserve the indent structure of the file
vim.opt.smarttab = true                                            -- [go] Use 'shiftwidth' when inserting <Tab>
vim.opt.softtabstop = 2                                            -- [bo] uses 'shiftwidth' counts for while performing editing operations
-- foldmethod / foldexpr / indentexpr are deliberately NOT set here.
-- LazyVim sets them per-FileType via LazyVim.set_default, guarded by
-- LazyVim.treesitter.have(ft, query), so buffers with no parser fall back
-- cleanly. Setting them globally defeats that guard.

-- FOLDING SETTINGS
vim.opt.foldcolumn =
'0'                                                  -- When and how to draw the foldcolumn: "0": disable (GOOD!); "auto": resize to the minimum amount of folds to display; "auto:[1-9]": resize to accommodate multiple folds up to the selected level; "[1-9]": displays a fixed col numb
vim.opt.foldenable = true                            -- Enable folds by default
vim.opt.foldlevelstart = 99                          -- Start unfolded
vim.opt.foldminlines = 1                             -- Minimum number of lines for a fold
vim.opt.foldnestmax = 3                              -- Maximum fold depth
-- foldmethod / foldexpr set per-FileType by LazyVim (see comment above).

-- SEARCH/FIND/REPLACE/GREP/SELECTION SETTINGS
vim.opt.hlsearch = true            -- When there is a previous search pattern, highlight all its matches
vim.opt.selection = 'inclusive'    -- Use inclusive selection
vim.opt.path:append('**')          -- Search into subfolders with `gf`
vim.opt.grepformat = '%f:%l:%c:%m' -- filename, line number, column, content

-- FILE HANDLING SETTINGS
vim.opt.autowrite = false                         -- LazyVim default: true
vim.opt.backup = false                       -- Don't create backup files
vim.opt.swapfile = false                     -- Don't create swap files
vim.opt.updatetime = 300                          -- LazyVim default: 200
vim.opt.writebackup = false                  -- Don't backup before overwriting
vim.opt.diffopt:append('vertical')           -- Vertical diff splits
vim.opt.diffopt:append('algorithm:patience') -- Better diff algorithm
vim.opt.diffopt:append('linematch:60')       -- Better diff highlighting (smart line matching)

-- UNDO SETTINGS
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
vim.g.autoformat = true -- LazyVim's format-on-save switch; replaces conform's opts.format_on_save
vim.g.have_nerd_fonts = true                    -- [go] Whether the system has Nerd Fonts installed
vim.g.snacks_animate = false                    -- Disable snacks animation
vim.g.suffixes = '.bak,~,.o,.h,.info,.swp,.obj' -- [go] List of file suffixes to add to the 'wildignore' list
vim.g.ft_ignore_pat = '\\.\\(Z\\|gz\\|bz2\\|zip\\|tgz\\)$'
