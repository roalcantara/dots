is_table = require 'etc/lang/is_table'
extend = require 'etc/tables/extend'

theme = {
  ansi: {
    black: 0,
    red: 1,
    green: 2,
    yellow: 3,
    blue: 4,
    magenta: 5,
    cyan: 6,
    white: 7,
    gray: 8,
    red_bright: 9,
    green_bright: 10,
    yellow_bright: 11,
    blue_bright: 12,
    magenta_bright: 13,
    cyan_bright: 14,
    white_bright: 15
  },
  primary: {background: 16, foreground: 17}
}
colors = {}

get_theme = ()->
  extend(theme.ansi, theme.primary)

set_terminal_color = (key, value)->
  vim.g['terminal_color_' .. key] = value

set_terminal_ansi_color = (key, value)->
  vim.g.terminal_ansi_colors[key] = value

set = (values)->
  if is_table(values) then
    for k, value in pairs(values) do
      id = get_theme![k]
      set_terminal_color(id, value) if vim.fn.has('nvim') ~= 0
      set_terminal_ansi_color(id, value) if vim.fn.has('terminal') ~= 0
      _G.palette[id] = value
      colors[id] = value

setup_palette = (values)->
  _G.palette = _G.palette or {}
  vim.g.terminal_ansi_colors = vim.g.terminal_ansi_colors or {}
  set(values) if is_table(values)
  _G.palette

return setup_palette
