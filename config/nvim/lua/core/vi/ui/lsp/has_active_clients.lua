--- Checks if there are active LSP clients
---@param filter? table -- The filter to use to get the clients
---@return boolean -- Whether there are active get_clients
local function has_active_clients(filter)
  local clients = vim.lsp.get_clients(filter)
  return #clients > 0
end

return has_active_clients
