local entries = require('neo/lib/tables/entries')
local flatten = require('neo/lib/tables/flatten')
local flat_entries
flat_entries = function(collection, predicate)
  return flatten(entries(collection, predicate))
end
return flat_entries
