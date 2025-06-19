local M = {}

--- Custom Header with Neovim and LazyVim versions
--- @return string
M.header = function()
  local nvim = require("core/etc/nvim")

  return [[
      ███╗   ██╗ ██╗   ██╗ ██╗ ███╗   ███╗
      ████╗  ██║ ██║   ██║ ██║ ████╗ ████║
      ██╔██╗ ██║ ██║   ██║ ██║ ██╔████╔██║
      ██║╚██╗██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║
      ██║ ╚████║  ╚████╔╝  ██║ ██║ ╚═╝ ██║
      ╚═╝  ╚═══╝   ╚═══╝   ╚═╝ ╚═╝     ╚═╝
    ]] .. "(v" .. nvim.get_nvim_version() .. " / LazyVim v" .. nvim.get_lazyvim_version() .. ")"
end

return M
