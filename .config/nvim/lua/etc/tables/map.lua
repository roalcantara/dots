local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local each = require('etc/tables/each')
local push = require('etc/tables/push')
local map
map = function(collection, predicate, selfArg)
  local t = { }
  if not (is_table(collection)) then
    collection = to_table(collection)
  end
  each(collection, function(it)
    return push(t, predicate(it, selfArg))
  end)
  return t
end
return map
