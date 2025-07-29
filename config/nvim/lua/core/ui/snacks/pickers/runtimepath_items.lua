local paths = require('core/vi/fn/paths')

--- List the items on Neovim runtimepath
--- @return table Table with runtimepath items
--- @see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
local function runtimepath_items()
  return Snacks.picker({
    title = "Neovim Runtimepath",
    items = paths.get_runtimepath_path_items(),
    format = "text",
  })
end

return runtimepath_items
