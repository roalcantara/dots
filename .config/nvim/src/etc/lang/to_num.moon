is_num = require('etc/lang/is_num')
is_func = require('etc/lang/is_func')
is_bool = require('etc/lang/is_bool')

---Convert to number
---@param value any
---@return number | nil result
to_num = (value, ...) ->
  return value if is_num(value)
  return value and 1 or 0 if is_bool(value)
  return to_num(value(...)) if is_func(value)

return to_num
