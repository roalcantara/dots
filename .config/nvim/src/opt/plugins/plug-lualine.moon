-- A blazing fast and easy to configure neovim statusline plugin written in pure lua
-- https://github.com/nvim-lualine/lualine.nvim
_G.imports 'lualine', (plugin) ->
  plugin.setup {
    -- Lualine has sections as shown below.
    -- +-------------------------------------------------+
    -- | A | B | C                             X | Y | Z |
    -- +-------------------------------------------------+
    options: {
      theme: 'auto', -- 'onedark'
      -- When set to true
      -- left sections i.e. 'a','b' and 'c' can't take over the entire statusline
      -- even if neither of 'x', 'y' or 'z' are present.
      always_divide_middle: true,
      component_separators: {left: '', right: ''},
      disabled_filetypes: {},
      -- displays icons in alongside component
      icons_enabled: true,
      -- adds padding to the left and right of components
      padding: 1,
      section_separators: {left: '', right: ''},
      -- enable single statusline at bottom of neovim (>= 0.7)
      -- instead of one for every window
      globalstatus: true
    },
    -- Available components
    --
    --    branch (git branch)
    --    buffers (shows currently available buffers)
    --    diagnostics (diagnostics count from your preferred source)
    --    diff (git diff status)
    --    encoding (file encoding)
    --    fileformat (file format)
    --    filename
    --    filesize
    --    filetype
    --    hostname
    --    location (location in file in line:column format)
    --    mode (vim mode)
    --    progress (%progress in file)
    --    tabs (shows currently available tabs)
    --    windows (shows currently available windows)
    --
    -- Lua functions as lualine component
    --
    --    local function hello()
    --      return [[hello world]]
    --    end
    --    sections = { lualine_a = { hello } }
    --
    -- Vim functions as lualine component
    --
    --    sections = { lualine_a = {'FugitiveHead'} }
    --
    -- Vim's statusline items as lualine component
    --
    --    sections = { lualine_c = {'%=', '%t%m', '%3p'} }
    --
    -- Vim variables as lualine component
    --  Variables from g:, v:, t:, w:, b:, o, go:, vo:, to:, wo:, bo: scopes can be used. ex:
    --
    --    sections = { lualine_a = { 'g:coc_status', 'bo:filetype' } }
    --
    -- Lua expressions as lualine component
    --  You can use any valid lua expression as a component including:
    --    - oneliners
    --    - global variables
    --    - require statements
    --
    --    sections = { lualine_c = { "os.date('%a')", 'data', "require'lsp-status'.status()" } }
    --
    sections: {
      lualine_a: {'mode'},
      lualine_b: {'branch', 'diff', 'diagnostics'},
      lualine_c: {
        {
          'filename',
          -- Displays file status (readonly status, modified status)
          file_status: true,
          -- 0: Just the filename
          -- 1: Relative path
          -- 2: Absolute path
          -- 3: Absolute path, with tilde as the home directory
          path: 3,
          -- Shortens path to leave 40 spaces in the window
          -- for other components. (terrible name, any suggestions?)
          shorting_target: 40,
          symbols: {
            -- Text to show when the file is modified.
            modified: '[+]',
            -- Text to show when the file is non-modifiable or readonly.
            readonly: '[-]',
            -- Text to show for unnamed buffers.
            unnamed: '[New]'
          }
        }
      },
      lualine_x: {'encoding', 'fileformat', 'filetype'},
      lualine_y: {'progress'},
      lualine_z: {'location'}
    },
    inactive_sections: {
      lualine_a: {},
      lualine_b: {},
      lualine_c: {'filename'},
      lualine_x: {'location'},
      lualine_y: {},
      lualine_z: {}
    },
    tabline: {},
    -- Available extensions
    --   aerial
    --   chadtree
    --   fern
    --   fugitive
    --   fzf
    --   nerdtree
    --   neo-tree
    --   nvim-tree
    --   quickfix
    --   symbols-outline
    --   toggleterm
    extensions: {'quickfix', 'fzf', 'quickfix', 'symbols-outline'}
  }
