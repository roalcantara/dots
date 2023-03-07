is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'

---Returns the last occurrence of an element in an array
---@param value any
---@return table result the last element or nil
to_args = (value) ->
  value = to_table(value) unless is_table(value)
  unpack(value)

return to_args
