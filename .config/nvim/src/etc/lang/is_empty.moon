trim = require 'etc/strings/trim'

---Checks if value is nil or empty.
---@param value any The object to query
---@return boolean result true if value is nil or empty, else false.
is_empty = (value) ->
  return true if type(value) == 'nil'
  return #value == 0 if type(value) == 'table'
  return value > -1 if type(value) == 'number'
  return false if type(value) == 'boolean'
  return trim(value) == '' if type(value) == 'string'
  return is_empty(value()) if type(value) == 'function'
  false

return is_empty
