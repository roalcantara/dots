local paths = require('core/vi/fn/paths')

--- List the items on Neovim lua paths
--- @return table Table with lua paths items
--- @see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
local function lua_path_items()
  return Snacks.picker({
    title = "Neovim Lua Runtime Paths",
    items = paths.get_lua_runtime_paths_items(),
    format = "text",
  })
end

return lua_path_items
