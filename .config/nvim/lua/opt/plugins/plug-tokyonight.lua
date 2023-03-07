return _G.imports('tokyonight.colors', function(plugin)
  require('tokyonight').setup({
    style = 'moon',
    light_style = 'storm',
    transparent = true,
    terminal_colors = true,
    styles = {
      comments = {
        italic = true
      },
      keywords = {
        italic = true
      },
      functions = { },
      variables = { },
      sidebars = 'dark',
      floats = 'dark'
    },
    sidebars = {
      'qf',
      'vista_kind',
      'terminal',
      'packer'
    },
    hide_inactive_statusline = false,
    dim_inactive = true,
    lualine_bold = true,
    on_colors = function(colors) end,
    on_highlights = function(hl, c)
      local prompt = '#2d3149'
      hl.TelescopeNormal = {
        bg = c.bg_dark,
        fg = c.fg_dark
      }
      hl.TelescopeBorder = {
        bg = c.bg_dark,
        fg = c.bg_dark
      }
      hl.TelescopePromptNormal = {
        bg = prompt
      }
      hl.TelescopePromptBorder = {
        bg = prompt,
        fg = prompt
      }
      hl.TelescopePromptTitle = {
        bg = prompt,
        fg = prompt
      }
      hl.TelescopePreviewTitle = {
        bg = c.bg_dark,
        fg = c.bg_dark
      }
      hl.TelescopeResultsTitle = {
        bg = c.bg_dark,
        fg = c.bg_dark
      }
    end
  })
  local theme_colors = plugin.setup({ })
  return require('opt/theme').setup('tokyonight', {
    black = theme_colors.bg_dark,
    background = theme_colors.terminal_black,
    red = theme_colors.red,
    red_bright = theme_colors.red1,
    green = theme_colors.green,
    green_bright = theme_colors.green1,
    yellow = theme_colors.yellow,
    yellow_bright = theme_colors.orange,
    blue = theme_colors.blue,
    blue_bright = theme_colors.blue5,
    magenta = theme_colors.magenta,
    magenta_bright = theme_colors.magenta2,
    cyan = theme_colors.cyan,
    cyan_bright = theme_colors.blue6,
    white = theme_colors.fg_dark,
    white_bright = theme_colors.fg,
    gray = theme_colors.comment,
    foreground = theme_colors.fg
  })
end)
