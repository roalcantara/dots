is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'
is_str = require 'etc/lang/is_str'
gt = require 'etc/lang/gt'
lt = require 'etc/lang/lt'

---Creates an array of the own enumerable property names of object.
---@param object table The object to query.
---@param asc boolean The sort order asc, default is nil.
---@return table table Property names
---@example `keys({a=1, c=2, b=3})` => `{'a', 'c', 'b'}`
---@example `keys({a=1, c=2, c=3}, true)` => `{'a', 'b', 'c'}`
---@example `keys({a=1, c=2, c=3}, false)` => `{'c', 'b', 'a'}`
---@example `keys('acb')` => `{'a', 'c', 'b'}`
---@example `keys('acb', true)` => `{'a', 'b', 'c'}`
---@example `keys('acb', false)` => `{'c', 'b', 'a'}`
keys = (object, asc = nil) ->
  if is_str(object)
    tmp = {}
    for i = 1, #object do table.insert(tmp, i)
    object = tmp
  elseif not is_table(object)
    object = to_table(object)
  values = {}
  for k, _ in pairs(object) do table.insert(values, k)
  return table.sort(values, gt) unless asc
  return table.sort(values, lt) if asc
  values

return keys
