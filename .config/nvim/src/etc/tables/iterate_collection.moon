keys = require 'etc/tables/keys'
lt = require 'etc/lang/lt'

---Iterated over the collection and returns it sorted
---@param table table A collection to iterate over.
---@param asc boolean | nil If true, sorts in ascending order.
---@return function result Returns the sorted collection.
iterate_collection = (table, asc = true) ->
  values = keys(table, asc) or {}
  i = 0
  return () ->
    if lt(i, #values) then
      i = i + 1
      key = values[i]
      return key, table[key]

return iterate_collection
