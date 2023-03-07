local map = require('etc/tables/map')
local flatten = require('etc/tables/flatten')
local flat_map
flat_map = function(collection, iteratee)
  return flatten(map(collection, iteratee))
end
return flat_map
