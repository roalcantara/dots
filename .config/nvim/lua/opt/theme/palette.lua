local is_table = require('etc/lang/is_table')
local extend = require('etc/tables/extend')
local theme = {
  ansi = {
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7,
    gray = 8,
    red_bright = 9,
    green_bright = 10,
    yellow_bright = 11,
    blue_bright = 12,
    magenta_bright = 13,
    cyan_bright = 14,
    white_bright = 15
  },
  primary = {
    background = 16,
    foreground = 17
  }
}
local colors = { }
local get_theme
get_theme = function()
  return extend(theme.ansi, theme.primary)
end
local set_terminal_color
set_terminal_color = function(key, value)
  vim.g['terminal_color_' .. key] = value
end
local set_terminal_ansi_color
set_terminal_ansi_color = function(key, value)
  vim.g.terminal_ansi_colors[key] = value
end
local set
set = function(values)
  if is_table(values) then
    for k, value in pairs(values) do
      local id = get_theme()[k]
      if vim.fn.has('nvim') ~= 0 then
        set_terminal_color(id, value)
      end
      if vim.fn.has('terminal') ~= 0 then
        set_terminal_ansi_color(id, value)
      end
      _G.palette[id] = value
      colors[id] = value
    end
  end
end
local setup_palette
setup_palette = function(values)
  _G.palette = _G.palette or { }
  vim.g.terminal_ansi_colors = vim.g.terminal_ansi_colors or { }
  if is_table(values) then
    set(values)
  end
  return _G.palette
end
return setup_palette
