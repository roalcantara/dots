local setup_palette = require('neo/theme/palette')
local setup
setup = function(name, colors)
  setup_palette(colors)
  vim.cmd([[    hi clear
    set background=dark
  ]])
  return vim.cmd('colorscheme ' .. name)
end
return setup
