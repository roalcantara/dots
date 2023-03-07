setup_palette = require 'opt/theme/palette'

setup = (name, colors)->
  setup_palette(colors)
  vim.cmd[[
    hi clear
    set background=dark
  ]]
  vim.cmd('colorscheme ' .. name)

return setup
