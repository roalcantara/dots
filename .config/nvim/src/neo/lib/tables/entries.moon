is_table = require 'neo/lib/lang/is_table'
to_table = require 'neo/lib/lang/to_table'
iter = require 'neo/lib/tables/iter'
push = require 'neo/lib/tables/push'

--Creates an array of values by running each element in collection thru iteratee.
--The iteratee is invoked with three arguments: (value, index|key, collection).
---@param collection table The collection to iterate over.
---@param predicate function The function invoked per iteration.
---@return table result The mapped array.
entries = (collection, predicate) ->
  t = {}
  collection = to_table(collection) unless is_table(collection)
  for k, v in iter(collection) do push(t, predicate(v, k))
  t

return entries
