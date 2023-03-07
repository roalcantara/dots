-- Checks if object contains the given key
---@param obj table The object to query.
---@param key string
---@return boolean True if object contains the given key
has = (obj, key) ->
  vim.fn.has_key(obj, key) ~= 0

return has
