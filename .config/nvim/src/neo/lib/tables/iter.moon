is_str = require 'neo/lib/lang/is_str'
is_table = require 'neo/lib/lang/is_table'
iterate_collection = require 'neo/lib/tables/iterate_collection'
lt = require 'neo/lib/lang/lt'

---Iterated over the collection
---@param value table A collection to iterate over.
---@return function result Returns the sorted collection.
iter = (value) ->
  if is_str(value)
    i = 0
    return () ->
      if lt(i, #value)
        i = i + 1
        c = value.sub(i, i)
        return i, c
  return iterate_collection(value) if is_table(value)
  return () ->

export iter
