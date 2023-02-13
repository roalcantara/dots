local push
push = function(collection, value)
  if not (require('neo/lib/lang/is_table')(collection)) then
    collection = require('neo/lib/lang/to_table')(collection)
  end
  table.insert(collection, value)
  return collection
end
return push
