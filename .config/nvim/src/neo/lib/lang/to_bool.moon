is_nil = require('neo/lib/lang/is_nil')
is_bool = require('neo/lib/lang/is_bool')
is_str = require('neo/lib/lang/is_str')
is_num = require('neo/lib/lang/is_num')
is_func = require('neo/lib/lang/is_func')

---Convert to boolean
---@param value any A value to be converted
---@vararg any | nil params, in the case of value if a function
---@return boolean | nil result true if value is a boolean, otherwise false
to_bool = (value, ...) ->
  return false if is_nil(value)
  return value if is_bool(value)
  return #value > 0 if is_str(value)
  return value ~= 0 if is_num(value)
  return to_bool(value(...)) if type(value) != 'nil' and is_func(value)
  return false

return to_bool
