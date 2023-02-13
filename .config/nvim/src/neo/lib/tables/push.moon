---Inserts element value at beginning of the table
---@param collection table
---@return table result a new table
push = (collection, value) ->
  collection = require('neo/lib/lang/to_table')(collection) unless require('neo/lib/lang/is_table')(collection)
  table.insert(collection, value)
  collection

return push
