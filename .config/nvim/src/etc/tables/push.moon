---Inserts element value at beginning of the table
---@param collection table
---@return table result a new table
push = (collection, value) ->
  collection = require('etc/lang/to_table')(collection) unless require('etc/lang/is_table')(collection)
  table.insert(collection, value)
  collection

return push
