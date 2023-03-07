cast = require 'etc/lang/cast'
is_str = require 'etc/lang/is_str'
is_num = require 'etc/lang/is_num'

--Checks if value is less than other.
---@param value any The value to compare.
---@param other any | function The other value to compare.
---@return boolean result true if value is equal to other, false otherwise
lt = (value, other, ...) ->
  return false if type(value) == 'nil' or type(other) == 'nil'
  value, other = cast(value, other)
  return value < other if is_str(value) or is_num(value)
  return lt(value(...), other(...)) if type(value) == 'function' and type(other) == 'function'
  false

return lt
