---@param value any
---@return boolean result true if value is from given type, otherwise false
is_type = (type_name, value) ->
  return type(value) == 'table' and vim.tbl_islist(value) if type_name == 'list'
  return type(value) == 'table' and not vim.tbl_islist(value) if type_name == 'map'
  type(value) == type_name

return is_type
