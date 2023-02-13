is_str = require 'neo/lib/lang/is_str'
is_num = require 'neo/lib/lang/is_num'
cast = require 'neo/lib/lang/cast'

--Checks if value is greater than other.
---@param value any The value to compare.
---@param other any The other value to compare.
---@return boolean result true if value is greater than other, else false.
gt = (value, other, ...) ->
  return false if type(value) == 'nil' or type(other) == 'nil'
  value, other = cast(value, other)
  return value > other if is_str(value) or is_num(value)
  return value < other if is_str(value) or is_num(value)
  return gt(value(...), other(...)) if type(value) == 'function' and type(other) == 'function'
  false

return gt
