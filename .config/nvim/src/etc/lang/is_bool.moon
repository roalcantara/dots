---Check if value is a boolean
---@param value any
---@return boolean result true if value is boolean, otherwise false
is_bool = (value) ->
  type(value) == 'boolean'

return is_bool
