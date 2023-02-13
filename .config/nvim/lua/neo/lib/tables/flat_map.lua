local map = require('neo/lib/tables/map')
local flatten = require('neo/lib/tables/flatten')
local flat_map
flat_map = function(collection, iteratee)
  return flatten(map(collection, iteratee))
end
return flat_map
