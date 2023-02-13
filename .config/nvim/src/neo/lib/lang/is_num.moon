---Check if value is a number
---@param value any
---@return boolean result true if value is number, otherwise false
is_num = (value) ->
  type(value) == 'number'

return is_num
