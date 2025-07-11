--- Refreshes immediately the statusline after updating a toggle
---@param scope string -- The scope of the statusline to refresh: all/tabpage/window
---@param ... string|table -- The place(s) of the statusline to refresh: statusline/winbar/tabline
---@return table -- The result of the refresh
local function refresh(scope, ...)
  local places = { ... }
  if #places == 0 then
    places = { 'statusline', 'winbar', 'tabline' }
  end

  return require('lualine').refresh({
    force = true,
    scope = scope,
    place = places,
  })
end

return refresh
