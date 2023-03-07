is_nil = require 'etc/lang/is_nil'
is_table = require 'etc/lang/is_table'
push = require 'etc/tables/push'

-- Creates an array with all falsey values removed. The values false, null, 0, "", undefined, and NaN are falsey.
---@vararg any @The values to compact.
---@return table result Returns the new array of filtered values.
compact = (...) ->
  args = ...
  t = {}
  return t if is_nil(args)
  args = { args } if not is_table(args)
  for _, v in pairs(...) do push(t, v) unless is_nil(v)
  t

return compact
