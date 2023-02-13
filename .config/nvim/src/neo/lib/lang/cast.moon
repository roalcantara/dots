is_str = require 'neo/lib/lang/is_str'
is_bool = require 'neo/lib/lang/is_bool'
is_num = require 'neo/lib/lang/is_num'
is_func = require 'neo/lib/lang/is_func'
is_table = require 'neo/lib/lang/is_table'
to_str = require 'neo/lib/lang/to_str'
to_bool = require 'neo/lib/lang/to_bool'
to_num = require 'neo/lib/lang/to_num'
to_func = require 'neo/lib/lang/to_func'
to_table = require 'neo/lib/lang/to_table'

---Cast the given values
---@param a any
---@param b any
cast = (a, b) ->
  return a, b if type(a) == type(b)
  return a, to_str(b) if is_str(a)
  return a, to_bool(b) if is_bool(a)
  return a, to_num(b) if is_num(a)
  return a, to_func(b) if is_func(a)
  return a, to_table(b) if is_table(a)

return cast
