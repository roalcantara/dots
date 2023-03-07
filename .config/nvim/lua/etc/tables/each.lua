local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local each
each = function(collection, predicate, selfArg)
  if not (is_table(collection)) then
    collection = to_table(collection)
  end
  for k, v in pairs(collection) do
    predicate(v, k, selfArg)
  end
end
return each
