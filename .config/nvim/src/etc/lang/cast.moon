is_str = require 'etc/lang/is_str'
is_bool = require 'etc/lang/is_bool'
is_num = require 'etc/lang/is_num'
is_func = require 'etc/lang/is_func'
is_table = require 'etc/lang/is_table'
to_str = require 'etc/lang/to_str'
to_bool = require 'etc/lang/to_bool'
to_num = require 'etc/lang/to_num'
to_func = require 'etc/lang/to_func'
to_table = require 'etc/lang/to_table'

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
