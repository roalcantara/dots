local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local iter = require('etc/tables/iter')
local push = require('etc/tables/push')
local entries
entries = function(collection, predicate)
  local t = { }
  if not (is_table(collection)) then
    collection = to_table(collection)
  end
  for k, v in iter(collection) do
    push(t, predicate(v, k))
  end
  return t
end
return entries
