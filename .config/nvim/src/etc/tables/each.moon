is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'

--Iterates over elements of collection invoking Lodash.iteratee for each element.
--The iteratee is bound to selfArg and invoked with three arguments: (value, index|key, collection).
--Iteratee functions may exit Lodash.iteration early by explicitly returning false.
---@param collection table The collection to iterate over. (table|string)
---@param predicate function Thefunction invoked per Lodash.iteration
---@param selfArg any The self binding of predicate.
each = (collection, predicate, selfArg) ->
  collection = to_table(collection) unless is_table(collection)
  for k, v in pairs(collection) do
    predicate(v, k, selfArg)

return each
