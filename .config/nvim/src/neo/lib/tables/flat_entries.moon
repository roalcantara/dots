entries = require 'neo/lib/tables/entries'
flatten = require 'neo/lib/tables/flatten'

--Creates an array of values by running each element in collection thru iteratee.
--The iteratee is invoked with three arguments: (value, index|key, collection).
---@param collection table The collection to iterate over.
---@param predicate function The function invoked per iteration.
---@return table result The mapped array.
flat_entries = (collection, predicate) ->
  flatten(entries(collection, predicate))

return flat_entries
