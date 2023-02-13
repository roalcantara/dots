---Check if value is a table
---@param value any
---@return boolean result true if value is table, otherwise false
is_table = (value) ->
  type(value) == 'table'

return is_table
