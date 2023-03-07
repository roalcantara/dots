local push
push = function(collection, value)
  if not (require('etc/lang/is_table')(collection)) then
    collection = require('etc/lang/to_table')(collection)
  end
  table.insert(collection, value)
  return collection
end
return push
