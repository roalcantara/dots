---Check if value is a function
---@param value any
---@return boolean result true if value is function, otherwise false
is_func = (value) ->
  type(value) == 'function'

return is_func
