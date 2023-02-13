---Check if value is a string
---@param value any
---@return boolean result true if value is string, otherwise false
is_str = (value) ->
  type(value) == 'string'

return is_str
