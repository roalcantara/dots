is_null = require 'etc/lang/is_null'
is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'
iter = require 'etc/tables/iter'
iterate = require 'etc/tables/iterate'

--Reduces collection to a value which is the accumulated result of running each element in collection thru iteratee,
--where each successive invocation is supplied the return value of the previous.
--If accumulator is not given, the first element of collection is used as the initial value.
--The iteratee is invoked with four arguments:(accumulator, value, index|key, collection).
---@param collection table The collection to iterate over.
---@param predicate function The function invoked per iteration.
---@param initial any The initial value.
---@param selfArg any The self binding of predicate.
---@return any result The reduced array.
---@example reduce({a: 1, b: 2}, (result, n, key) ->
---   result[key] = n * 3
---   return result;
---, {})
reduce = (collection, predicate, initial, selfArg) ->
  acc = initial
  collection = to_table(collection) unless is_table(collection)
  for k, v in iter(collection)
    if is_null(acc)
      acc = v
    else
      acc = iterate(predicate, selfArg, acc, v, k, collection)
  acc

return reduce
