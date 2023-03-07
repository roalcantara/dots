is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'
each = require 'etc/tables/each'
push = require 'etc/tables/push'

--Creates an array of values by running each element in collection thru iteratee.
--The iteratee is invoked with three arguments: (value, index|key, collection).
---@param collection table The collection to iterate over.
---@param predicate function The function invoked per iteration.
---@return table result The mapped array.
map = (collection, predicate, selfArg) ->
  t = {}
  collection = to_table(collection) unless is_table(collection)
  each(collection, (it) -> push(t, predicate(it, selfArg)))
  t

return map
