map = require 'etc/tables/map'
flatten = require 'etc/tables/flatten'

--Creates an array of values by running each element in collection thru iteratee.
--The iteratee is invoked with three arguments: (value, index|key, collection).
---@param collection table The collection to iterate over.
---@param iteratee function The function invoked per iteration.
---@return table result The mapped array.
flat_map = (collection, iteratee) ->
  flatten(map(collection, iteratee))

return flat_map
