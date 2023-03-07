-- A clean, dark Neovim theme written in Lua, with support for lsp, treesitter and lots of plugins.
-- Includes additional themes for Kitty, Alacritty, iTerm and Fish.
-- https://github.com/folke/tokyonight.nvim/
_G.imports 'tokyonight.colors', (plugin) ->
  require('tokyonight').setup({
    -- your configuration comes here
    -- or leave it empty to use the default settings
    style: 'moon', -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
    light_style: 'storm', -- The theme is used when the background is set to light
    transparent: true, -- Enable this to disable setting the background color
    terminal_colors: true, -- Configure the colors used when opening a `:terminal` in Neovim
    styles: {
      -- Style to be applied to different syntax groups
      -- Value is any valid attr-list value for `:help nvim_set_hl`
      comments: {italic: true},
      keywords: {italic: true},
      functions: {},
      variables: {},
      -- Background styles. Can be "dark", "transparent" or "normal"
      sidebars: 'dark', -- style for sidebars, see below
      floats: 'dark' -- style for floating windows
    },
    sidebars: {'qf', 'vista_kind', 'terminal', 'packer'}, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
    hide_inactive_statusline: false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
    dim_inactive: true, -- dims inactive windows
    lualine_bold: true -- When `true`, section headers in the lualine theme will be bold

    --- You can override specific color groups to use other groups or a hex color
    --- function will be called with a ColorScheme table
    --- param colors ColorScheme
    on_colors: (colors) ->,

    --- You can override specific highlights to use other groups or a hex color
    --- function will be called with a Highlights and ColorScheme table
    --- param highlights Highlights
    --- param colors ColorScheme
    on_highlights: (hl, c)-> -- overide the highlight groups
        -- make Telescope borderless
        prompt = '#2d3149'
        hl.TelescopeNormal = {
          bg: c.bg_dark,
          fg: c.fg_dark,
        }
        hl.TelescopeBorder = {
          bg: c.bg_dark,
          fg: c.bg_dark,
        }
        hl.TelescopePromptNormal = {
          bg: prompt,
        }
        hl.TelescopePromptBorder = {
          bg: prompt,
          fg: prompt,
        }
        hl.TelescopePromptTitle = {
          bg: prompt,
          fg: prompt,
        }
        hl.TelescopePreviewTitle = {
          bg: c.bg_dark,
          fg: c.bg_dark,
        }
        hl.TelescopeResultsTitle = {
          bg: c.bg_dark,
          fg: c.bg_dark,
        }
  })

  theme_colors = plugin.setup({})
  require('opt/theme').setup('tokyonight', {
    black: theme_colors.bg_dark, -- #1f2335
    background: theme_colors.terminal_black, -- #414868

    red: theme_colors.red, -- #f7768e
    red_bright: theme_colors.red1, -- #db4b4b

    green: theme_colors.green, -- #9ece6a
    green_bright: theme_colors.green1, -- #73daca

    yellow: theme_colors.yellow, -- #e0af68
    yellow_bright: theme_colors.orange, -- #ff9e64

    blue: theme_colors.blue, -- #7aa2f7
    blue_bright: theme_colors.blue5, -- #89ddff

    magenta: theme_colors.magenta, -- #bb9af7
    magenta_bright: theme_colors.magenta2, -- #ff007c

    cyan: theme_colors.cyan, -- #7dcfff
    cyan_bright: theme_colors.blue6, -- #B4F9F8

    white: theme_colors.fg_dark, -- #a9b1d6
    white_bright: theme_colors.fg, -- #c0caf5
    gray: theme_colors.comment, -- #565f89

    foreground: theme_colors.fg -- #c0caf5
  })
