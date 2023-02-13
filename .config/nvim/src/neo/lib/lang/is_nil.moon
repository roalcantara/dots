---Checks if value is nil.
---@param value any The object to query
---@return boolean result true if value is nil, otherwise false
is_nil = (value) ->
  type(value) == 'nil'

return is_nil
