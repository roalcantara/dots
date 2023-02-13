local is_null = require('neo/lib/lang/is_null')
local is_table = require('neo/lib/lang/is_table')
local to_table = require('neo/lib/lang/to_table')
local iter = require('neo/lib/tables/iter')
local iterate = require('neo/lib/tables/iterate')
local reduce
reduce = function(collection, predicate, initial, selfArg)
  local acc = initial
  if not (is_table(collection)) then
    collection = to_table(collection)
  end
  for k, v in iter(collection) do
    if is_null(acc) then
      acc = v
    else
      acc = iterate(predicate, selfArg, acc, v, k, collection)
    end
  end
  return acc
end
return reduce
