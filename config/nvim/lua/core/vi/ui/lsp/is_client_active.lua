local has_active_clients = require("core/vi/ui/lsp/has_active_clients")

--- Checks if there is an active LSP client with the given name
---@param name string -- The client name to check
---@return boolean -- Whether there are active get_clients
local function is_client_active(name)
  return #has_active_clients({ name = name }) > 0
end

return is_client_active
