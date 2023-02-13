local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local each = require('neo/lib/tables/each')
local push = require('neo/lib/tables/push')
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
