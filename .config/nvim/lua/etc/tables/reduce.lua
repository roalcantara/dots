local is_null = require('etc/lang/is_null')
local is_table = require('etc/lang/is_table')
local to_table = require('etc/lang/to_table')
local iter = require('etc/tables/iter')
local iterate = require('etc/tables/iterate')
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
